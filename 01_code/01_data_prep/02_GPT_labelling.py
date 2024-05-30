#%%
import re
from glob import glob
from pprint import pprint
from time import sleep, time
from datetime import datetime
from tqdm.auto import tqdm
import random
from IPython.display import display

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
pd.set_option('mode.chained_assignment', None) # suppress warning about setting values in copied DF

import openai
openai.api_key = 'xxx' #Insert openai API key here

import warnings
warnings.filterwarnings("ignore")

import dask.dataframe as dd
from dask.distributed import Client, LocalCluster, as_completed
cluster = LocalCluster(n_workers=1, processes=False)
scheduler = Client(cluster)



def humanForm(num, sigDigs=2):
	'''Print large numbers in a human readable format (e.g. "K" for thousands)'''
	num = float(f'{num:.{sigDigs}g}')
	magnitude = 0
	while abs(num) >= 1000:
		magnitude += 1
		num /= 1000.0
	return f'{f"{num:f}".rstrip("0").rstrip(".")}{["", "k", "m", "b", "t"][magnitude]}'

def getCost(completionDict):
	'''Helper function to get an idea of the cost of GPT task on the fly'''
	costPer1kToken = {
		'gpt-3.5-turbo-1106':   0.0010,
		'gpt-4-1106-preview':   0.0100,

		'text-davinci-003':     0.0200, 
		'text-curie-001':       0.0020, 
		'text-babbage-001':     0.0005, 
		'text-ada-001':         0.0004, 
		}

	numTokens = completionDict['usage']['total_tokens']
	model = completionDict['model']

	return round(numTokens/1000 * costPer1kToken[model], 4)

def getCompletionDict(model, text):
	'''Get GPT answer (i.e. "completion") for a given input text'''
	sleep(0.5)

	model = 'gpt-3.5-turbo-1106' if model == 3 else 'gpt-4-1106-preview'
	return openai.ChatCompletion.create(
		model=model,

		messages=[
			{'role': 'system',  'content': systemMessage},
			{'role': 'user',    'content': prompt(text)}
			],

		max_tokens=150, 
		temperature=0.0, 
		seed = 84, #Set seed inference parameter for reproducibility of answers. For details, see https://platform.openai.com/docs/api-reference/chat/create
		)


############################################################################################################################################################ 	

systemMessage = \
'''You are an excellent media research assistant that specialises in reading excerpts from TV transcripts and accurately answering multiple choice questions about them. 
You always select one of the answer options and write nothing else. You are very consistent with this.'''

costToday = 0
modelVersion = 4


questionTitles = {
	'climate': [
		'01_cc_about',
		'02_cc_policy_for_against',
		],

	'immigration': [
		'01_immigration_about',
		'02_immigration_restr_for_against',
		],

	'guns': [
		'01_guns_about',
		'02_guns_control_for_against', 
		], 

	'abortion': [
		'01_abortion_about',
		'02_abortion_rights_for_against',
		], 
}

topics = list(questionTitles.keys())







#%%############################################# get predictions #############################################

for topic in topics: 

	print('\n\n' + f' {topic} '.center(100, '#'))


	####################################### set up prompt #######################################

	# Set up an example of the expected output from GPT to help it answer consistently
	exampleAnswers = [f'{i}) {random.choice(["a)", "b)", "x)"])}' for i in range(1, len(questionTitles[topic])+1)]
	exampleAnswersString = '\n'.join(exampleAnswers)

	# different questions for each topic -> get them from file
	with open(f'../../01_code/01_data_prep/01_GPT_questions/gpt_questions_{topic}.txt') as f:
		questionText = f.read()


	# create dynamic prompt
	prompt = lambda tvSegmentString: \
f'''You are an excellent media research assistant that specialises in reading excerpts from TV transcripts and accurately answering multiple choice questions about them. 
You always select one of the answer options and nothing else. You follow this answer format exactly: 
{exampleAnswersString}


Now, read the following TV segment and answer the questions below it.

######################
...{tvSegmentString}...
######################

Questions:
{questionText}

Answers:

'''


	####################################### get predictions #######################################
	datetimeThisRun = datetime.now().strftime('%Y-%m-%d_%H-%M')
	print(f'Start run for {topic} at {datetimeThisRun}.')
	errors = {}

	## load segments
	df = pd.read_csv(f'../../02_data/01_TV_segments/02_interm/{topic}_segments.csv')
	print(f'Number of segments for {topic} is {len(df)}.')
	
	df['completion'] = np.nan # add completion column

	for i, row in tqdm(df.iterrows(), total=len(df), dynamic_ncols=True):
		try:
			# submit task, wait up to 60 seconds on it, then if time has passed, throw timeouterror
			future = scheduler.submit(getCompletionDict, model=modelVersion, text=row.textWindow)
			completionDict = future.result(timeout=60)
			completion = completionDict['choices'][0]['message']['content'].strip() # get completion text

		except Exception as e: #Handle exceptions
			completion = '\n'.join([' '] * len(questionTitles[topic])) # create 'nan' completion
			errors[str(e.__class__)] = errors.get(str(e.__class__), 0) + 1 # track errors
		
		costToday += getCost(completionDict) # Compute GPT cost as we go
		if i % 100 == 0:
			print(f'cost so far: ${costToday:.2f}')

		
		completion = completion.replace('\n', '\t\t') #Quick text cleaning
		df.loc[i, 'completion'] = completion

		if i % 500 == 0: #Every 500 segments, parse the answers and save the parsed answers
			df_interm = df[~df['completion'].isnull()]
			df_interm.to_csv(f'../../02_data/01_TV_segments/02_interm/{topic}_raw_answers.csv', index=False)
			try:
				# split completion into columns
				df_interm[questionTitles[topic]] = df_interm['completion'].str.split('\t\t', expand=True)

				# clean up individual answers
				for col in questionTitles[topic]:
					df_interm[col] = df_interm[col].str.replace(r'\d\)', '', regex=True).str.strip()
					df_interm[col] = df_interm[col].str.replace(r'\).*$', '', regex=True)

				# save to disk
				df_interm.drop(columns=['completion']).to_csv(f'../../02_data/01_TV_segments/03_processed/{topic}_segments_parsed_answers.csv', index=False)

			except:
				print(f'had a problem parsing completions for {topic} within iteration {i}')


	print(f'Cost after run on {topic} topic: ${costToday:.2f}')

	# once we're through all segments, save to disk (still as raw completions)
	df.to_csv(f'../../02_data/01_TV_segments/02_interm/{topic}_raw_answers.csv', index=False)

	if errors:
		print('errors'.center(100, '-'))
		pprint(errors, indent=4)

	####################################### parse answers #######################################
	try:
		# split completion into columns
		df[questionTitles[topic]] = df['completion'].str.split('\t\t', expand=True)

		# clean up individual answers
		for col in questionTitles[topic]:
			df[col] = df[col].str.replace(r'\d\)', '', regex=True).str.strip()
			df[col] = df[col].str.replace(r'\).*$', '', regex=True)

		df = df.drop(columns=['completion'])

		print('how many completions were parsed correctly?')
		display(df[questionTitles[topic]].isin(['a', 'b', 'x']).sum())

		print('how many were not nans?')
		display(df[questionTitles[topic]].isin(['a', 'b']).sum())


		# save to disk
		df.to_csv(f'../../02_data/01_TV_segments/03_processed/{topic}_segments_parsed_answers.csv', index=False)

	except:
		print(f'had a problem parsing completions for {topic}')

print('Finished GPT annotation.')



#%%
