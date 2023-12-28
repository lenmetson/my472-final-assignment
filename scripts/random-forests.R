
# Define function to install or load packages
load_packages <- function(x) {
  y <- x %in% rownames(installed.packages())
  if(any(!y)) install.packages(x[!y])
  invisible(lapply(x, library, character.only=T))
  rm(x, y)
}

# Load required packagess
load_packages(c(
    "tidyverse",
    "here",
    # Database management
    "DBI",
    "RSQLite",
    # APIs and webscraping
    "httr",
    "RSelenium",
    # Text analysis 
    "tm", 
    # Geospatial plots
    "tmap", 
    "sf", 
    "ggrepel", 
    # Random forests
    "parallel",
    "ranger",
    "tidymodels",
    "vip", 
    "rpart", 
    "rpart.plot"
    ))

db <- DBI::dbConnect(RSQLite::SQLite(), here("data/parliament_database.sqlite"))




# TODO: deal with missing values 

apply_random_forest <- function(
  df, 
  dv_name = "",
  output_name = "",
  seed = 123, 
  initial_split_prop = 0.8, 
  folds = 5, 
  tuning_levels = 4, 
  cores = parallel::detectCores()) {

    df <- df %>%
      rename(dv = all_of(dv_name))

    set.seed(seed)
    split <- initial_split(df, prop = initial_split_prop)

    train <- training(split)
    test <- testing(split)
    folds <- vfold_cv(train, v = folds)
    
    print(paste0("LOG | ", Sys.time(), " | Splits done." ))

    recipe <- recipe(dv ~ ., data = df)

    spec <- rand_forest(
      mtry = tune(), 
      trees = tune(), 
      min_n = tune()) %>%
    set_mode("classification") %>%
    set_engine("ranger", num.threads = cores, importance = "impurity")

  workflow <- workflow() %>%
    add_recipe(recipe) %>%
    add_model(spec)
  
  tuning_grid <- grid_regular(
    mtry(range = c(1, ncol(df)-1)), # Change to number of independent variables
    trees(),
    min_n(),
    levels = tuning_levels
    )

  print(paste0("LOG | ", Sys.time(), " | Tuning started." ))
  set.seed(seed)
  tune <- workflow %>%
    tune_grid(
      resamples = folds, 
      grid = tuning_grid)

  saveRDS(tune, paste0("data/random-forest-outputs/", output_name, "_tune.Rds"))
  print(paste0("LOG | ", Sys.time(), " | Tuning done." ))
  
  final <- workflow %>%
    finalize_workflow(parameters = select_best(tune, "roc_auc"))

  set.seed(seed)

  last_fit <- final %>%
    last_fit(split = split)
  
  saveRDS(last_fit, paste0("data/random-forest-outputs/", output_name, "last_fit.Rds") )

  print(paste0("LOG | ", Sys.time(), " | Final output for '", output_name, "' done. :)" ))
  }


# Apply for econ

analysis_df_econ <- dbGetQuery(
  db, 
  "
  SELECT 
    question_topics.is_econ AS is_econ,

    members.member_latest_party,
    members.member_gender,
    constituencies.last_election_1_electorate,   
    constituencies.last_election_1_turnout,         
    constituencies.last_election_1_majority,               
    constituencies.last_election_1_isGeneralElection,              
    constituencies.region_nation_hoclib23,           
    constituencies.population_hoclib23,          
    constituencies.area_hoclib23,                   
    constituencies.age_0_29_hoclib23,            
    constituencies.age_30_64_hoclib23,               
    constituencies.age_65_plus_hoclib23,         
    constituencies.uc_claimants_hoclib23,            
    constituencies.median_house_price_hoclib23 

  FROM oral_questions
  JOIN question_topics
    ON oral_questions.question_id = question_topics.question_id
  JOIN members 
    ON oral_questions.member_asking_Mnis_ID = members.member_Mnis_ID
      AND oral_questions.question_tabled_when BETWEEN members.member_date_valid_min AND members.member_date_valid_max
  JOIN constituencies 
    ON members.member_latest_constituency = constituencies.constituency_id
  
  LIMIT 2000
  "
) %>%
  mutate(is_econ = factor(is_econ)) # TODO: check convert to factor works


apply_random_forest(
  df = analysis_df_econ, 
  dv_chr = "is_econ", 
  output_name = "econ",
  seed = 1145, 
  initial_split_prop = 0.8,
  folds = 5,
  tuning_levels = 4,
  cores = parallel::detectCores())
