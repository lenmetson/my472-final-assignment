## For oral questions 

oral_questions <- readRDS("data/oral_questions.RDS")
oral_question_ids <- c()

for(i in seq_along(oral_questions)){
    id <- oral_questions[[i]]$Id
    oral_question_ids <- c(oral_question_ids, id)
}


written_questions <- readRDS("data/written_questions.RDS")
