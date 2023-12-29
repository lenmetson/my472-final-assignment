# Introduction

What, if any, characteristics and factors discriminate MPs who tend to ask questions about economic issues from MPs who tend to ask questions about health and welfare issues?”

Parliamentary questions are a critical part of how MPs represent their constituents. Rather than the topic of the question, I operationalise asking questions by the ministers MPs ask questions to, rather than the content of the questions 





# Data 

To answer this question, I draw on two sources of data. First, the UK Parliament API endpoins provide data both on the questions that MPs ask, but also data on MPs and the electoral results of the constituencies they represent. However, more detailed information about constituencies is limited. The UK House of Commons Library publishes an interactive dashboard with information on the demographics of every constituency. I use Selinium to dynamically scrape data from this dashboard. 

TODO resrict to 2023? would make sense with the constituency information, and would be easier to reproduce 
- This would involve
  - Limiting query of questions
  - Limiting query of members
- Do this with a branch maybe? 

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

Many MP characteristics change over time - such as the party they represent, the ministerial posts they hold, etc. Therefore, we have to construct a members table that accomodates these changes. The UK Parliament members API allows queries that specifiy a date. This will give us a unique response that is valid on the day of each question. I will write out this "summarised" version of the data to my database. Then in analysis, I can query the entry that is valid for when each question is asked. 

I obtained more constituency information from the UK House of Commons Library Constituecy dashboard. This does not have an API, and contains dynamic elements, so I used Selinum to scrape it. 

```{r selinium-code}

```

This process was somewhat complicated by the fact that the dashboard is contained within an "iframe". This allows a different html tree to be embedded within the main html of the webpage meaning any CSS paths do not point to the actual path of the webpage. Do do this, we need to identify the iframe and use `switchToFrame()` to identify elements on the dashboard. 

HOUSEPRICE INFO ONLY IN ENG AND WALES, that's why so many NAs


DIAGRAM OF FINAL RELATIONAL DATABASE

# Analysis 

## Measure topics 

Instead of using the text of the questions to classify them, I instead classified questions by the government department they were asked to. 

I define the following departments as "economic"
- Treasury
- Department for Levelling Up, Housing and Communities - 211
- Department for Business, Energy and Industrial Strategy - 201
- Public Accounts Commission - 24
- Department for International Trade - 202
- Department for Business and Trade - 214

And the following departments as "health and welfare"
-  Department of Health and Social Care - 17
-  Department for Work and Pensions - 29



One limitation to this approach is that is misses questions asked about either topic to more general departments like the Prime Minister's Office, Scotland and  Wales Officies, etc. Therefore, in future iterations of this project, it would be interesting to compare my operationalisation of asking questions with one based on the content of the text. This would be best measured using supervised classification of the question texts. 

CHECK: should I mention dictionaries and say I tried??


## Descriptive analysis 

Having measured question topics, I first plot how they vary over time and across the UK. 

### Over time 

- Plot 
- Short anlaysis 


### Over constituency 

- Plot 
- Short analysis 


## Exploratory analysis 

TODO: operationalise electoral history
- Count party has won
- Av. majority in last 4 elections

Next, I conduct an exporatory anlaysis to see which factors about an MP and their constituency might predict whether they ask economic or health/welfare questions. 


Missing values
- Mean imputation 


Only two columns have NAs. This is Scotish and Northern Irish constituncies where house prices and universial credit claimants were not avialble

CANDO try with removal of NAs?

`sapply(analysis_df_econ, function(x) any(is.na(x)))`

# Code appendix
