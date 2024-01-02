source("scripts/00_setup.R")

# Function for mean imputation

dir.create("data/random-forest-outputs")

replace_na_with_mean <- function(x) {
  mean_value <- mean(x, na.rm = TRUE)
  ifelse(is.na(x), mean_value, x)
}

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
    
    print(paste0("LOG | ", output_name, " | ", Sys.time(), " | Splits done." ))

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

  print(paste0("LOG | ", output_name, " | ", Sys.time(), " | Tuning started." ))
  set.seed(seed)
  tune <- workflow %>%
    tune_grid(
      resamples = folds, 
      grid = tuning_grid)

  saveRDS(tune, paste0("data/random-forest-outputs/", output_name, "_tune.Rds"))
  print(paste0("LOG | ", output_name, " | ", Sys.time(), " | Tuning done." ))
  
  final <- workflow %>%
    finalize_workflow(parameters = select_best(tune, "roc_auc"))

  set.seed(seed)

  last_fit <- final %>%
    last_fit(split = split)
  
  saveRDS(last_fit, paste0("data/random-forest-outputs/", output_name, "last_fit.Rds") )

  print(paste0("LOG | ", output_name, " | ", Sys.time(), " | Final output done :)" ))
  }


analysis_df_econ <- dbGetQuery(
  db, 
  "
  SELECT 
    question_topics.is_econ AS is_econ,
    
    members.latest_party_id AS asking_MP_party,
    parties.party_abbreviation AS party_abbreviation, 
    members.gender AS asking_MP_gender,
    /* Majority */ 
    constituencies.last_election_1_majority, 
    constituencies.last_election_2_majority, 
    constituencies.last_election_3_majority, 
    constituencies.last_election_4_majority,

    constituencies.last_election_1_electorate,
    constituencies.last_election_2_electorate,
    constituencies.last_election_3_electorate,
    constituencies.last_election_4_electorate,

    /* results */    
    constituencies.last_election_1_result,
    constituencies.last_election_2_result,
    constituencies.last_election_3_result,
    constituencies.last_election_4_result,
    /* turnout */ 
    constituencies.last_election_1_turnout,
    constituencies.last_election_2_turnout,
    constituencies.last_election_3_turnout,
    constituencies.last_election_4_turnout,
   /* registration rates */ 
    constituencies.last_election_1_electorate/constituencies.population_hoclib23 AS con_registration_rate_1,
    constituencies.last_election_2_electorate/constituencies.population_hoclib23 AS con_registration_rate_2,
    constituencies.last_election_3_electorate/constituencies.population_hoclib23 AS con_registration_rate_3,
    constituencies.last_election_4_electorate/constituencies.population_hoclib23 AS con_registration_rate_4,
    /* constituency demographics */ 
    constituencies.region_nation_hoclib23 AS con_region,
    constituencies.population_hoclib23/constituencies.area_hoclib23 AS con_ppl_per_sqkm,
    constituencies.age_0_29_hoclib23 AS con_0_29_prop,
    constituencies.age_30_64_hoclib23 AS con_30_64_prop,
    constituencies.age_65_plus_hoclib23 AS con_65_plus_prop,
    constituencies.uc_claimants_hoclib23 AS con_uc_claimants,
    constituencies.median_house_price_hoclib23 AS con_house_price


  FROM oral_questions
  
  JOIN question_topics ON oral_questions.question_id = question_topics.question_id
  
  LEFT JOIN members ON oral_questions.asking_member = members.member_id
    /* this has to be joined before anything */ 
    /* from members to avoid dropping rows */
    /* select row where date of question comes between the dates valid range */

    AND REPLACE(oral_questions.question_tabled_when, '-', '') 
    /* no date class in SQLite, so convert to string*/
    
      BETWEEN REPLACE(members.member_date_valid_min, '-', '') 
        AND REPLACE(members.member_date_valid_max, '-', '')
  
  LEFT JOIN constituencies ON members.latest_constituency = constituencies.constituency_id
  LEFT JOIN parties ON parties.party_id = members.latest_party_id
  
  WHERE 
    parties.party_name IN ('Conservative', 'Labour', 'Liberal Democrat', 'Green Party')
  "
  )  

# Convert majority variables into +/- depending on whether current MP won or lost  
analysis_df_econ <- analysis_df_econ %>%
  mutate(
    last_election_1_majority = 
      ifelse(str_detect(last_election_1_result, party_abbreviation), 
        last_election_1_majority, 
        last_election_1_majority * -1),
    last_election_2_majority = 
      ifelse(str_detect(last_election_2_result, party_abbreviation), 
        last_election_2_majority, 
        last_election_2_majority * -1),
    last_election_3_majority = 
      ifelse(str_detect(last_election_3_result, party_abbreviation), 
        last_election_3_majority, 
        last_election_3_majority * -1),
    last_election_4_majority = 
      ifelse(str_detect(last_election_4_result, party_abbreviation), 
        last_election_4_majority, 
        last_election_4_majority * -1)
  ) %>% 
  mutate(
    marginality_1 =(analysis_df_econ$last_election_1_majority/analysis_df_econ$last_election_1_electorate),
    marginality_2 =(analysis_df_econ$last_election_2_majority/analysis_df_econ$last_election_2_electorate),
    marginality_3 =(analysis_df_econ$last_election_3_majority/analysis_df_econ$last_election_3_electorate),
    marginality_4 =(analysis_df_econ$last_election_4_majority/analysis_df_econ$last_election_4_electorate), 
  ) %>%
  mutate(
    is_econ = factor(is_econ, levels = c(0,1), labels = c(FALSE, TRUE))) %>%
  select(-party_abbreviation)


# CANDO average election results

# TODO decide whether to filter by party, or by England and Wales, or keep all in

# CANDO: should I just exclude and focus on English and Welsh MPs?

# Check which columns are missing
sapply(analysis_df_econ, function(x) any(is.na(x)))

# Apply the function to columns with NA
analysis_df_econ$con_house_price <- 
  replace_na_with_mean(analysis_df_econ$con_house_price)


apply_random_forest(
  df = analysis_df_econ,
  dv_name = "is_econ",
  output_name = "econ",
  seed = 1145,
  initial_split_prop = 0.8,
  folds = 5,
  tuning_levels = 4,
  cores = parallel::detectCores())


econ_last_fit <- readRDS("data/random-forest-outputs/econlast_fit.Rds")

# Variable importance plot

econ_vi_plot <- econ_last_fit %>%
  pluck(".workflow", 1) %>%
  extract_fit_parsnip() %>%
  vip(num_features = 10) + #  CANDO can vary this
  labs(title = "Variable importance for asking Economic Questions")

econ_vi_plot
