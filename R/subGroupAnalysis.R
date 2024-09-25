CreateSubgroups <- function(connectionDetails,
                           cdmDatabaseSchema,
                           cohortDatabaseSchema,
                           cohortTable,
                           targetCohortId,
                           comparatorCohortId,
                           outputFolder){
  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))

  sql <- SqlRender::loadRenderTranslateSql("CreateSubgroups.sql",
                                           "ACESOCovid19",
                                           dbms = connectionDetails$dbms,
                                           cohortDatabaseSchema = cohortDatabaseSchema,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           targetCohortId = targetCohortId,
                                           comparatorCohortId = comparatorCohortId,
                                           cohortTable = cohortTable)
  DatabaseConnector::executeSql(connection, sql)
  
  # Check number of subjects in subgroups:
  message("Counting subgroup cohorts")
  counts <- CohortGenerator::getCohortCounts(connection = connection,
                                             cohortDatabaseSchema = cohortDatabaseSchema,
                                             cohortTable = cohortTable)
  
  counts <- addCohortNames(counts)
  write.csv(counts, file.path(outputFolder, "CohortCountsAll.csv"), row.names = FALSE)
}
