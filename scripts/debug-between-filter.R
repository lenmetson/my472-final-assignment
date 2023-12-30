source("scripts/00_setup.R")


# There must be questions that occur outside of the range of any member # CHECK this 

questions <- dbGetQuery(db, "SELECT * FROM oral_questions")
members_grouped <- dbGetQuery(db, "SELECT * FROM members")

dates <- dbGetQuery(db, 
  "
  SELECT REPLACE(question_tabled_when, '-', '')
  FROM oral_questions 
  ORDER BY REPLACE(question_tabled_when, '-', '')
  ")

# NOTE No date format in SQlite https://stackoverflow.com/questions/4428795/sqlite-convert-string-to-date

filtered2 <- dbGetQuery(db,
  "
  SELECT 
    oral_questions.question_id,
    oral_questions.question_tabled_when,
    members.latest_party_id,
    members.name_display


  FROM oral_questions

  JOIN members ON oral_questions.asking_member = members.member_id

    /* select row where date of question comes between the dates valid range  */

    AND REPLACE(oral_questions.question_tabled_when, '-', '') /* no date class in SQLite, so convert to string*/
      BETWEEN REPLACE(members.member_date_valid_min, '-', '') 
        AND REPLACE(members.member_date_valid_max, '-', '')

  JOIN parties ON members.latest_party_id = parties.party_id

    "
  )


# Unfiltered returns *more* rows than there are questions so filtered deffo works better - I think this is because it is duolicating rows 

unfiltered <- dbGetQuery(db,
  "
  SELECT 
    oral_questions.question_id,
    oral_questions.question_tabled_when,
    members.latest_party_id,
    members.name_display


  FROM oral_questions
  JOIN parties ON members.latest_party_id = parties.party_id
    JOIN members
      ON oral_questions.asking_member = members.member_id
    "
  )
