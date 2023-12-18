
oral_questions <- readRDS("data/oral_questions.RDS")

### Convert elements of the list into tables ###

# Members asking

for (i in seq_along(oral_questions)) {
  if (i == 1) {

    # Extract asking member information
    member_df <- data.frame(lapply(
      oral_questions[[i]]$AskingMember,
      function(x) ifelse(is.null(x), NA, x)))

    member_df$question_id <- oral_questions[[i]]$Id

    oral_questions[[i]]$AskingMember <- NULL 
  } else {

    member_df2 <- data.frame(lapply(
      oral_questions[[i]]$AskingMember,
      function(x) ifelse(is.null(x), NA, x)))

    member_df2$question_id <- oral_questions[[i]]$Id
    member_df <- rbind(member_df, member_df2)

    oral_questions[[i]]$AskingMember <- NULL
  }
 print(paste0("MEMBERS: ", i, "/", length(oral_questions), " done."))
}

# Ministers answering

minister_df <- data.frame() # Initialise empty dataframe 

for (i in seq_along(oral_questions)) {
  if (is.null(oral_questions[[i]]$AnsweringMinister) == FALSE){
    
    if (nrow(minister_df) == 0) { # Check whether this is the first to have an answering minister

      minister_df <- data.frame(lapply(
        oral_questions[[i]]$AnsweringMinister,
        function(x) ifelse(is.null(x), NA, x)))

      minister_df$question_id <- oral_questions[[i]]$Id

      oral_questions[[i]]$AnsweringMinister <- NULL # Remove old sublist

    } else {

      minister_df2 <- data.frame(lapply(
        oral_questions[[i]]$AnsweringMinister,
        function(x) ifelse(is.null(x), NA, x)))

      minister_df2$question_id <- oral_questions[[i]]$Id

      minister_df <- rbind(minister_df, minister_df2)

      oral_questions[[i]]$AnsweringMinister <- NULL # Remove old sublist
    }

  } else {
    oral_questions[[i]][["AnsweringMinister"]] <- NULL
  }
 print(paste0("MINISTERS: ", i, "/", length(oral_questions), " done."))
}

# Questions

for (i in seq_along(oral_questions)) {
  if (i == 1){
    question_df <- data.frame(lapply(
      oral_questions[[i]],
      function(x) ifelse(is.null(x), NA, x)))
  } else {
    question_df2 <- data.frame(lapply(
      oral_questions[[i]],
      function(x) ifelse(is.null(x), NA, x)))

    question_df <- rbind(question_df, question_df2)
  }
 print(paste0("QUESTIONS: ", i, "/", length(oral_questions), " done."))
}

rm(member_df2, minister_df2, question_df2, i)

### Save matching tables ###

party_table <- member_df %>%
  select(PartyId, Party) %>%
  unique()

answering_body_table <- question_df %>%
  select(AnsweringBodyId, AnsweringBody) %>%
  unique()


### Clean dataframes and merge into one table ####

question_df <- question_df %>%
  select(
    question_id = Id,
    question_short_text = QuestionText,
    question_status = Status,
    question_tabled_when = TabledWhen,
    question_answering_when = AnsweringWhen,
    question_answering_body_id = AnsweringBodyId)

minister_df <- minister_df %>%
  select(
    question_id,
    minister_Mnis_ID = MnisId,
    minister_constituency = Constituency,
    minister_party_ID = PartyId)

member_df <- member_df %>%
  select(
    question_id,
    member_asking_Mnis_ID = MnisId,
    member_asking_constituency = Constituency,
    member_asking_party_ID = PartyId)


question_table_main <- 
  left_join(question_df, member_df, by = "question_id")

question_table_main <- 
  left_join(question_table_main, minister_df, by = "question_id")

### Write out to database ###

