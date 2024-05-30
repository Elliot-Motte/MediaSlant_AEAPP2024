#%%
import pandas as pd
import requests
import re
import os
from datetime import datetime, time
import json
from IPython.display import display

from io import StringIO
from pprint import pprint
from tqdm.auto import tqdm as _tqdm
tqdm = lambda *args, **kwargs: _tqdm(*args, **kwargs, dynamic_ncols=True)
from bs4 import BeautifulSoup

import dask
import dask.dataframe as dd
from dask.distributed import Client, LocalCluster, as_completed

cluster = LocalCluster(
    processes=False, 
    n_workers=4,
    # threads_per_worker=5,
    )
scheduler = Client(cluster)
print(scheduler.dashboard_link)

import warnings 
warnings.filterwarnings(action="ignore", category=UserWarning, module="bokeh.models.sources")  
warnings.simplefilter(action='ignore', category=UserWarning)

import logging
logging.getLogger('distributed.utils_perf').setLevel(logging.ERROR)



def assurePathExists(path):
    if not os.path.exists(os.path.dirname(path)):
        os.makedirs(os.path.dirname(path))




keywords = {
    'climate':      ['climate change', 'global warming'], 
    'guns':         ['gun rights', 'gun regulation', 'gun laws', 'gun control'],
    'abortion':     ['abortion', 'reproductive rights'],
    'immigration':  ['immigrants', 'immigration'], 
}

stations = [
    'MSNBC', 
    'FOXNEWS', 
    ]
topics = keywords.keys() 

timeSelection = 'primetimeOnly'
windowLength = 1000








#%% step 1: get all MSNBC & FoxNews episodes mentioning keywords of interest from GDELT TV API
for topic in tqdm(topics, desc='topic'):

    print('\n\n')
    print(f' {topic} '.center(100, '#'))
    
    for year in tqdm(range(2010, 2022+1), desc='year'):

        for station in stations:

            ###################################################### get data from api ######################################################
            # GDELT api doc: https://blog.gdeltproject.org/gdelt-2-0-television-api-debuts/
            keywordString = '(' + ' OR '.join([f'"{keyword}"' for keyword in keywords[topic]]) + ')'

            apiParams = {
                'query':            f'{keywordString} station:{station}',
                'format':           'csv',
                'maxrecords':       5000,
                'startdatetime':    datetime.strptime(f'{year}-01-01', '%Y-%m-%d').strftime('%Y%m%d%H%M%S'), 
                'enddatetime':      datetime.strptime(f'{year+1}-01-01', '%Y-%m-%d').strftime('%Y%m%d%H%M%S'), 
                }

            response = requests.get('https://api.gdeltproject.org/api/v2/tv/tv', params=apiParams)


            ###################################################### turn into df and clean a bit ######################################################
            csvFile = StringIO(response.text)
            df = pd.read_csv(csvFile)

            df = df.rename(columns={
                'MatchDateTime':    'datetime', 
                'Station':          'station',
                'Show':             'show',
                'URL':              'url',
                'Snippet':          'snippet',
                })


            # select only interesting columns
            df = df[['station', 'show', 'datetime', 'url', 'snippet']]

            # clean URLs and remove duplicate episodes
            df.url = df.url.str.extract(r'(.*)#')
            df = df.drop_duplicates(subset=['url'])


            # date/time selections
            df.datetime = pd.to_datetime(df.datetime)
            if timeSelection == 'primetimeOnly': # prime time (19-23 local) goes from 23h-7h UTC for UTC-4 to UTC-8. More precise filtering for local times in step 3
                df = df[(df.datetime.dt.hour >= 23) | (df.datetime.dt.hour < 7)] 

            if year == 2022: # remove the very few episodes aired on Jan 1st 2023
                df = df[df.datetime.dt.year == 2022]

            # save to disk
            outputPath = f'../../02_data/01_TV_segments/01_raw/{topic}/snippets/{topic}_{year}_{station}.csv'
            assurePathExists(outputPath)
            df.to_csv(outputPath, index=False)






#%% step 2: for all episodes that include one of the keywords, download the full text of the episode
def downloadAndParse(url):
    try:
        response = requests.get(url)
        soup = BeautifulSoup(response.text, 'html.parser')

        return soup.get_text(separator=' ', strip=True)
    except:
        return ''
    


for topic in topics:    
    print('\n\n')
    print(f' {topic} '.center(100, '#'))


    # collect all data into one df 
    df = dd.read_csv(f'../../02_data/01_TV_segments/01_raw/{topic}/snippets/{topic}_*.csv', dtype='object').compute().reset_index(drop=True)
    display(df)


    ####################################################### launch downloading and parsing in parallel ######################################################
    # submit tasks to scheduler
    futures = scheduler.map(downloadAndParse, df.url) 

    # progress tracking and ETA calculation
    for future in tqdm(as_completed(futures), total=len(futures), smoothing=0.0):
        # future.result()
        pass

    results = scheduler.gather(futures)
    df['text'] = results
     

    ###################################################### save to disk ######################################################
    outputPath = f'../../02_data/01_TV_segments/01_raw/{topic}/{topic}_allChannels_fulltext.csv'
    assurePathExists(outputPath)
    df.to_csv(outputPath, index=False, sep='|')

    print(f'finished downloading transcripts of episodes for topic "{topic}".')








#%% step 3: filter out episodes not aired during local prime time and then re-search for keywords within the episode and define segments as 1000 character text window around the keyword matches
for topic in topics:
    print('\n\n')
    print(f' {topic} '.center(100, '#'))
    
    df = pd.read_csv(f'../../02_data/01_TV_segments/01_raw/{topic}/{topic}_allChannels_fulltext.csv', sep='|')
    


    segments = []
    for i, row in tqdm(df.iterrows(), total=len(df)):

        # removing website elements, keeping only the transcript text 
        text = str(row.text).replace('\n', ' ')
        start = text.find('\xa0\xa0')+2
        end = text.find('TOPIC FREQUENCY')
        text = text[start:end]

        ####################################################### parse local time from text, skip if not primetime #######################################################
        timeSample = text[:100]

        startTimePattern = r'(\d{1,2}:\d{2}(?:am|pm))(?:-\d{1,2}:\d{2}(?:am|pm))'
        startTimeMatches = re.findall(startTimePattern, text)
        if startTimeMatches:
            startTimeString = startTimeMatches[0]
        else:
            continue

        localTime = datetime.strptime(startTimeString, '%I:%M%p').time()
        if not time(19, 0) <= localTime < time(23, 0):
            continue

            
            
        ####################################################### find the keywords again, extract surrounding snippet ######################################################
        # find all matches of keywords in the episode
        matches = re.finditer('|'.join(keywords[topic]), text, re.IGNORECASE)
        
        # get 1000 characters around the match without overlap
        endWindow = 0
        for matchObject in matches:

            # skip all matches that are already contained in the last text window (prevent overlap)
            if matchObject.start() < endWindow:
                continue

            # create text window (500 character before and 500 character after match)
            startWindow     = max(matchObject.start()  - int(windowLength/2), 0)
            endWindow       = min(matchObject.end() + int(windowLength/2), len(text))
            textWindow      = text[startWindow:endWindow]


            # create a separate observation for each text window
            segments.append({
                'station':      row.station,
                'textWindow':   textWindow,
            })

  
    resultDF = pd.DataFrame(segments)
    resultDF = resultDF.drop_duplicates(subset=['textWindow']).reset_index(drop=True)
    resultDF['segment_id'] = range(len(resultDF)) # create segment id to identify segments later

    outputPath = f'../../02_data/01_TV_segments/02_interm/{topic}_segments.csv'
    assurePathExists(outputPath)
    resultDF.to_csv(outputPath, index=False)


