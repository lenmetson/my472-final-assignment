# Introduciton 

# Data 

To store the data I collect, I will use a local relational database. This will improve the efficiency of the storage because... It will also allow me to query only the variables I need for anlausis 

I draw on 4 endpoint from parlimanet's API to construct four three tables that I write out to database.

1. Oral questions 
2. Members
3. Constituencies 
4. Elections

Tables: 

1. oral_questions
2. mps
3. constituencies (containing election results)

I then will create an additional table with the results of the measurmeent I use to classify questions. 

4. question_topics 


## Parliament API 

First, I scraped all questions availble from the written and oral endpoints. Both endpoints only return up to 100 questions with one request. However, you can skip responses. Therefore, you can retrieve all questions by looping through... 

These reponses do not return the full text of each question, so I use these responses as a sampling frame 


Many MP characteristics change over time - such as the party they represent, the ministerial posts they hold, etc. Therefore, we have to construct a members table that accomodates these changes. The UK Parliament members API allows queries that specifiy a date. This will give us a unique response that is valid on the day of each question. I will write out this "summarised" version of the data to my database. Then in analysis, I can query the entry that is valid for when each question is asked 


- Constituency characteristics
  - Previous electoral results 
  - Socio-demographic features of the constituency


Constituency info
- We will get the cosntituency ID from the members pull. We can pull:
  - Election results for each constituency over different elections 
  - Shape files (for plotting later)
- Would like to add 
  - Basic demographic information 
  - Economic indicators 
  - Health indicators 




I obtained more constituency information from the UK House of Commons Library Constituecy dashboard. This does not have an API, and contains dynamic elements, so I use selinum to scrape it. 

This process was somewhat complicated by the fact that the dashboard is contained within an "iframe". This allows a different html tree to be embedded within the main html of the webpage meaning any CSS paths do not point to the actual path of the webpage. Do do this, we need to identify the iframe and use `switchToFrame()` to identify elements on the dashboard. 

HOUSEPRICE INFO ONLY IN ENG AND WALES, that's why so many NAs


DIAGRAM OF FINAL RELATIONAL DATABASE

# Analysis 

## Measure topics 

To measure whether a question is about (1) economic issues or (2) health and welfare, I use a simple dictionary approach. Whilst this approach is somewhat limited compared to supervised machine learning classification techniques, I could not find a pre-trained model implementable in R. Therefore, for this version of the project, I use dictionary string matching. A full version of the project should, however, train a supervised classification model as this is likely to perform much better at classifying known topics than the dictionary approach. 

I define questions about the economy as.. and questions about health and welfare as... 

These categories are not mutally exlusive. In fact, we would expect many to overlap. For example, a question about how the NHS will be funded would fall under both economic and health. Therefore, I measure the two classes separately. 

## Descriptive analysis 

Having measured question topics, I first plot how they vary over time and across the UK. 



## Exploratory analysis 

Next, I conduct an exporatory anlaysis to see which factors about an MP and their constituency might predict whether they ask economic or health/welfare questions. 

# Code appendix
