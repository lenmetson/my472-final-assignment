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


################
# READ IN DATA #
################

# Apply for econ

econ_forest_df <- dbGetQuery(
  db, 
  "
  SELECT 
    
   question_topics.is_econ AS is_econ,
    
    constituencies.uc_claimants_hoclib23 AS uc_claimants,
    constituencies.median_house_price_hoclib23 AS median_house_price,
    constituencies.region_nation_hoclib23 AS con_region,
    constituencies.population_hoclib23/constituencies.area_hoclib23 AS con_ppl_per_sqkm,

    constituencies.age_0_29_hoclib23 AS age_29,
    constituencies.age_30_64_hoclib23 AS age_30_64,
    constituencies.age_65_plus_hoclib23 AS age_65,

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
    constituencies.last_election_4_result

  FROM questions
  
  JOIN question_topics ON questions.question_id = question_topics.question_id
  
  LEFT JOIN members ON questions.asking_member = members.member_id
    /* this has to be joined before anything */ 
    /* from members to avoid dropping rows */
    /* select row where date of question comes between the dates valid range */

    AND REPLACE(questions.question_tabled_when, '-', '') 
    /* no date class in SQLite, so convert to string*/
    
      BETWEEN REPLACE(members.member_date_valid_min, '-', '') 
        AND REPLACE(members.member_date_valid_max, '-', '')
  
  LEFT JOIN constituencies ON members.latest_constituency = constituencies.constituency_id
  LEFT JOIN parties ON parties.party_id = members.latest_party_id

  WHERE 
    constituencies.region_nation_hoclib23 NOT IN ('Northern Ireland', 'Scotland')
  "
  ) %>%
  replace_na_chr() %>% # When flattening the API responses, we replaced null values with character "NA" values, this function converts them back to NAs that R can recognise.
  mutate(is_econ = factor(is_econ, levels = (c(0,1)), labels = c("no", "yes"))) %>%
  mutate( # Convert majority variables into +/- depending on whether current MP won or lost  
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
  mutate(  # Calculate marginality 
    marginality_1 = (last_election_1_majority / last_election_1_electorate),
    marginality_2 = (last_election_2_majority / last_election_2_electorate),
    marginality_3 = (last_election_3_majority / last_election_3_electorate),
    marginality_4 = (last_election_4_majority / last_election_4_electorate)
  ) %>%

  mutate( # Calcualte mean marginality 
    mean_marginality = rowMeans(select(., starts_with("marginality_")))
  ) %>%
  select( # Drop auxillary variables
    -c(
      last_election_1_result, last_election_2_result, last_election_3_result, last_election_4_result, party_abbreviation,
      last_election_1_majority, last_election_2_majority, last_election_3_majority, last_election_4_majority, 
      last_election_1_electorate, last_election_2_electorate,last_election_3_electorate,last_election_4_electorate, 
      marginality_1, marginality_2, marginality_3, marginality_4))

# Check which columns are missing
sapply(econ_forest_df, function(x) any(is.na(x)))

# Apply the function to columns with NA

econ_forest_df$mean_marginality <- 
  replace_na_with_mean(econ_forest_df$mean_marginality)


# Health welf

health_welf_forest_df <- dbGetQuery(
  db, 
  "
  SELECT 
    
   question_topics.is_health_welf AS is_health_welf,
    
    constituencies.uc_claimants_hoclib23 AS uc_claimants,
    constituencies.median_house_price_hoclib23 AS median_house_price,
    constituencies.region_nation_hoclib23 AS con_region,
    constituencies.population_hoclib23/constituencies.area_hoclib23 AS con_ppl_per_sqkm,

    constituencies.age_0_29_hoclib23 AS age_29,
    constituencies.age_30_64_hoclib23 AS age_30_64,
    constituencies.age_65_plus_hoclib23 AS age_65,

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
    constituencies.last_election_4_result

  FROM questions
  
  JOIN question_topics ON questions.question_id = question_topics.question_id
  
  LEFT JOIN members ON questions.asking_member = members.member_id
    /* this has to be joined before anything */ 
    /* from members to avoid dropping rows */
    /* select row where date of question comes between the dates valid range */

    AND REPLACE(questions.question_tabled_when, '-', '') 
    /* no date class in SQLite, so convert to string*/
    
      BETWEEN REPLACE(members.member_date_valid_min, '-', '') 
        AND REPLACE(members.member_date_valid_max, '-', '')
  
  LEFT JOIN constituencies ON members.latest_constituency = constituencies.constituency_id
  LEFT JOIN parties ON parties.party_id = members.latest_party_id

  WHERE 
    constituencies.region_nation_hoclib23 NOT IN ('Northern Ireland', 'Scotland')
  "
  )  %>%
  replace_na_chr() %>% # When flattening the API responses, we replaced null values with character "NA" values, this function converts them back to NAs that R can recognise.
  mutate(is_health_welf = factor(is_health_welf, levels = (c(0,1)), labels = c("no", "yes"))) %>%
  mutate( # Convert majority variables into +/- depending on whether current MP won or lost  
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
  mutate(  # Calculate marginality 
    marginality_1 = (last_election_1_majority / last_election_1_electorate),
    marginality_2 = (last_election_2_majority / last_election_2_electorate),
    marginality_3 = (last_election_3_majority / last_election_3_electorate),
    marginality_4 = (last_election_4_majority / last_election_4_electorate)
  ) %>%

  mutate( # Calcualte mean marginality 
    mean_marginality = rowMeans(select(., starts_with("marginality_")))
  ) %>%
  select( # Drop auxillary variables
    -c(
      last_election_1_result, last_election_2_result, last_election_3_result, last_election_4_result, party_abbreviation,
      last_election_1_majority, last_election_2_majority, last_election_3_majority, last_election_4_majority, 
      last_election_1_electorate, last_election_2_electorate,last_election_3_electorate,last_election_4_electorate, 
      marginality_1, marginality_2, marginality_3, marginality_4))

# Check which columns are missing
sapply(health_welf_forest_df, function(x) any(is.na(x)))

# Apply the function to columns with NA

health_welf_forest_df$mean_marginality <- 
  replace_na_with_mean(health_welf_forest_df$mean_marginality)

###################
# Apply functions #
###################

apply_random_forest(
  df = econ_forest_df,
  dv_name = "is_econ",
  output_name = "econ",
  seed = 1145,
  initial_split_prop = 0.8,
  folds = 5,
  tuning_levels = 6,
  cores = parallel::detectCores())

apply_random_forest(
  df = health_welf_forest_df,
  dv_name = "is_health_welf",
  output_name = "health_welf",
  seed = 1145,
  initial_split_prop = 0.8,
  folds = 5,
  tuning_levels = 6,
  cores = parallel::detectCores())


# Variable importance plot

#PICKUP
# TODO merge in branch if want to keep RFs

# Variable importance plot


econ_last_fit <- readRDS("data/random-forest-outputs/econlast_fit.Rds")

econ_vi_plot <- econ_last_fit %>%
  pluck(".workflow", 1) %>%
  extract_fit_parsnip() %>%
  vip(num_features = 10) + #  CANDO can vary this
  labs(title = "Variable importance for asking Economic Questions")



health_welf_last_fit <- readRDS("data/random-forest-outputs/health_welflast_fit.Rds")

health_welf_plot <- health_welf_last_fit %>%
  pluck(".workflow", 1) %>%
  extract_fit_parsnip() %>%
  vip(num_features = 10) + #  CANDO can vary this
  labs(title = "Variable importance for asking Health & Welfare Questions")


grid.arrange(econ_vi_plot, health_welf_plot)

# Model performance

econ_tune <- readRDS("data/random-forest-outputs/econ_tune.Rds")

econ_tune_plot <- econ_tune %>% autoplot() + 
    theme(
        aspect.ratio = 1, 
        panel.background = element_rect(fill = "white", color = "black"),
        panel.grid = element_blank())

econ_tune %>% show_best("roc_auc")


health_welf_tune <- readRDS("data/random-forest-outputs/health_welf_tune.Rds")

health_welf_tune_plot <- health_welf_tune %>% autoplot() + 
    theme(
        aspect.ratio = 1, 
        panel.background = element_rect(fill = "white", color = "black"),
        panel.grid = element_blank())

health_welf_tune %>% show_best("roc_auc")




