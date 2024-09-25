cohortMapping <- function(connectionDetails,
                          cdmDatabaseSchema,
                          cohortDatabaseSchema,
                          cohortTable,
                          targetCohortId,
                          comparatorCohortId,
                          outputFolder) {
  
  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  # pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = "ACESOCovid19")
  # TcosOfInterest <- read.csv(pathToCsv)
  targetCohortId <- targetCohortId
  comparatorCohortId <- comparatorCohortId
  
  # Map people in compartor cohort with all potential people in target cohort
  sql <- SqlRender::loadRenderTranslateSql("TargetComparatorMapping.sql",
                                           "ACESOCovid19",
                                           dbms = connectionDetails$dbms,
                                           cohortDatabaseSchema = cohortDatabaseSchema,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           targetCohortId = targetCohortId,
                                           comparatorCohortId = comparatorCohortId,
                                           cohortTable = cohortTable)
  dataMapping <- DatabaseConnector::renderTranslateQuerySql(connection, sql)
  
  `%>%` <- magrittr::`%>%`
  # Indicate people in comparator cohort who are mapped to more than one index date in target cohort
  dataMapping <- dataMapping %>% 
    dplyr::group_by(PERSON_ID_C) %>% 
    dplyr::mutate(n_t = dplyr::n()) %>% 
    dplyr::ungroup()
  
  # Randomly map people in comparator cohort to people in target cohort if they are mapped to more than one person in target cohort
  dataMappingF <- comparatorRandomSelection(dataMapping)
  
  dataComparator <- dataMappingF %>% 
    dplyr::mutate(COHORT_DEFINITION_ID = comparatorCohortId) %>% 
    dplyr::select(COHORT_DEFINITION_ID, SUBJECT_ID = PERSON_ID_C,
                  COHORT_START_DATE = INDEX_DATE_T, COHORT_END_DATE = OBSERVATION_PERIOD_END_DATE_C)
  
  # Remove original comparator cohort records in cohortTable
  sql <- "delete from @cohortDatabaseSchema.@cohortTable where cohort_definition_id = @comparatorCohortId"
  DatabaseConnector::renderTranslateExecuteSql(connection = connection,
                                               sql,
                                               cohortDatabaseSchema = cohortDatabaseSchema,
                                               cohortTable = cohortTable,
                                               comparatorCohortId = comparatorCohortId)
  
  # Insert update comparator data to cohortTable            
  DatabaseConnector::insertTable(connection = connection,
                                 databaseSchema = cohortDatabaseSchema,
                                 tableName = cohortTable,
                                 data = dataComparator,
                                 dropTableIfExists = FALSE,
                                 createTable = FALSE,
                                 progressBar = TRUE)
  
  
  # Check number of subjects per cohort:
  message("Counting updated cohorts")
  counts <- CohortGenerator::getCohortCounts(connection = connection,
                                             cohortDatabaseSchema = cohortDatabaseSchema,
                                             cohortTable = cohortTable)
  
  counts <- addCohortNames(counts)
  write.csv(counts, file.path(outputFolder, "CohortCounts.csv"), row.names = FALSE)
}

comparatorRandomSelection <- function(data){
  data_selected <- data.frame()
  
  `%>%` <- magrittr::`%>%`
  
  for (n in sort(unique(data$n_t))){
    if(n==1){
      data_selected <- rbind(data_selected, data %>% dplyr::filter(n_t==n))
    } else {
  
      set.seed(12345)
      random_n = sample(1:n, size = 1)
      
      data_n <- data %>% 
        dplyr::filter(n_t==n) %>% 
        dplyr::arrange(PERSON_ID_C, PERSON_ID_T) %>% 
        dplyr::group_by(PERSON_ID_C) %>% 
        dplyr::mutate(selectionID = 1:n) %>% 
        dplyr::ungroup() %>% 
        dplyr::filter(selectionID==random_n)
      
      data_selected <- rbind(data_selected, data_n %>% dplyr::select(-selectionID))
    }
  }
  return(data_selected)
}
