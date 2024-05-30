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


import warnings 
warnings.filterwarnings(action="ignore", category=UserWarning, module="bokeh.models.sources")  
warnings.simplefilter(action='ignore', category=UserWarning)

import logging
logging.getLogger('distributed.utils_perf').setLevel(logging.ERROR)




topics = ['climate', 'immigration', 'guns', 'abortion']




####################################################################

#%%##### Table A1: number of segments by station and topic
#Concatenate all topic DFs
dfs = []
for topic in topics:    
    df = pd.read_csv(f'../../02_data/01_TV_segments/02_interm/{topic}_segments.csv')
    df['topic'] = topic

    dfs.append(df)

df = pd.concat(dfs)
df['wordcount'] = df.textWindow.str.split().str.len()


# This produces the input numbers for Table A1 which is created manually
print('\n\n' + ' number of segments by topic and station '.center(80, '#'))
print(pd.crosstab(
    index=df.station,
    columns=df.topic,
    margins=True,
).round(1))






################# calculating stats for the data section of manuscript #################
#Average wordcount of 1000 character segments by topic and station (with margins)
print('\n\n' + ' mean wordcount of textwindows by topic and station '.center(80, '#'))
print(pd.crosstab(
    index=df.station,
    columns=df.topic,
    values=df.wordcount,
    aggfunc='mean',
    margins=True,
).round(1))

   
#%% stage 1: raw snippets returned by GDELT TV API
dfs = []
for topic in topics:    
    df = dd.read_csv(f'../../02_data/01_TV_segments/01_raw/{topic}/snippets/{topic}_*.csv', dtype='object').compute().reset_index(drop=True)
    df['topic'] = topic

    dfs.append(df)

df = pd.concat(dfs)
df['wordcount'] = df.snippet.str.split().str.len()


print('\n\n' + ' number of search results by topic and station '.center(80, '#'))
print(pd.crosstab(
    index=df.station,
    columns=df.topic,
    margins=True,
).round(1))


print('\n\n' + ' mean wordcount of snippets by topic and station '.center(80, '#'))
print(pd.crosstab(
    index=df.station,
    columns=df.topic,
    values=df.wordcount,
    aggfunc='mean',
    margins=True,
).round(1))

