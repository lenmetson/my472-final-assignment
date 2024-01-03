What, if any, characteristics and factors discriminate MPs who tend to ask questions about economic issues from MPs who tend to ask questions about health and welfare issues?”

```{r basic-setup}
```

# Introduction

NOTE (52w)
Parliamentary questions are a critical part of how MPs represent their constituency. Therefore, I focus on asking what factors about the constituency an MP represents drives their focus on economic or health and welfare topics in 2023. I operationalise “focus” as the proportion of questions a member asks about a given topic. 

TODO
[ summary of results]

# Data 
# NOTE data section = 522w

I drew on data from two sources: the UK Parliament API (“API”), and the [UK House of Commons constituency dashboard](https://commonslibrary.parliament.uk/constituency-dashboard/) (“dashboard”). I limit my analysis to questions asked in 2023. I store data efficiently, I used a local relational database. 

## API 

First, I pulled the text of questions from the API oral and written question endpoints. For oral questions, the API only returns questions asked in the House of Commons. However, the written question endpoint returns questions from both the House of Lords and the House of Commons. Therefore, I added a parameter to the request URL to only return written questions asked by members of the House of Commons. After flattening and cleaning the responses and adding a variable `oral_written` to distinguish the question type, I merged both types of question into one dataframe and wrote it to my database as `"questions"`. 


```{r pull-oral-questions}
```

```{r pull-written-questions}
```

```{r clean-questions}
```

For each question, I wanted to be able to pull in additional data about the MP who had asked it and the minister they asked it to. Some MP characteristics, such as their party affiliation or seat, change over time. The API members endpoint allows queries to specify a date. It then returns data as valid from that date. To pull make the fewest possible requests, I created unique MP-date pairs from my `questions` table. 

Many MP characteristics change over time - such as the party they represent, the ministerial posts they hold, etc. Therefore, we have to construct a members table that accommodates these changes. The API allows queries that specify a date. This will give us a unique response that is valid on the day of each question. I will write out this "summarised" version of the data to my database. Then in analysis, I can query the entry that is valid for when each question is asked. 

```{r pull-members-endpoint}
```

However, because characteristics do not change very frequently, I did not want to write out a table with data on each MP for every day they had asked a question. Therefore, I grouped the clean response table by each unique combination of MP and their characteristics and summarised the earliest and latest date this combination was valid for. This reduced the number of rows I would write to my `members` table from 4225 to 482.

```{r clean-members-pull}
```

I then used the constituency endpoints to pull the results of the last 4 elections held in each constituency and a shapefile for each constituency. 

```{r pull-constituency-endpoints}
```

 
## Dashboard

The data on the demographics of constituencies from the UK Parliament API is very limited. Therefore, I used the Commons Library constituency dashboard to add demographic variables. This data source does not have an API endpoint and requires each constituency to be looked up using a search tool. Therefore, I used Selenium to interactively scrape the data. One limitation of this data source was that data on the median house price in each constituency was not available for constituencies in Scotland and Northern Ireland. 

```{r selenium-scrape-hoc-dashboard}
```

After merging the scraped data with the constituency data pulled from the API, I wrote out the clean dataframe to `constituencies`. 

```{r clean-constituency-data}
```

## Final database 

Finally, I obtained party names and colours from the API and wrote out the results as the table `"parties"` for use in plotting. 

```{r pull-party-info}
``` 

This resulted in 4 tables in my local database:

1. questions
2. members
3. constituencies 
4. parties 
  

CANDO
DIAGRAM OF FINAL RELATIONAL DATABASE

# Analysis 


$ econ\_slant = \frac{N (\text{economic questions})}{\text{N questions}} - \frac{N(\text{health & welfare questions})}{\text{N questions}}  $


# Code appendix
