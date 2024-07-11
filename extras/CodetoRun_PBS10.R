
#install.packages("remotes")
#remotes::install_github("OHDSI/CohortGenerator")
#remotes::install_github("OHDSI/DatabaseConnector")
#remotes::install_github("darwin-eu-dev/‘TreatmentPatterns")

library(TreatmentPatterns)
library(CohortGenerator)
library(DatabaseConnector)
library(dplyr)

# Input temp folder & root folder
options(andromedaTempFolder = "~/andromedaTemp")
rootPackage=getwd()

# Input connection setting
connectionDetails = DatabaseConnector::createConnectionDetails(dbms = "dbms", #input your database manager
                                                               server = "server", #input your server details
                                                               user = "user", #input your user name
                                                               password = "pwd", #input your password to acess your server
                                                               pathToDriver = '~/driver')
cdmDatabaseSchema = 'database schema'
cohortDatabaseSchema = 'cohortdatabaseschema'
databaseId <- "database ID"

# Input cohort table
cohortTable <- 'Epilesy_drug'
cohortTableNames <- CohortGenerator::getCohortTableNames(cohortTable = cohortTable)
outputFolder=file.path(rootPackage,'ouput')

# Generate cohort on remote ----
cohortDefinitionSet <- getCohortDefinitionSet(
  settingsFileName = file.path(rootPackage,"inst/settings/CohortsToCreate.csv"),
  jsonFolder = file.path(rootPackage,"inst/cohorts"),
  sqlFolder = file.path(rootPackage,"inst/sql/sql_server")
)

CohortGenerator::createCohortTables(
  connectionDetails = connectionDetails,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTableNames = cohortTableNames,
  incremental = TRUE
)
cohortToCreate<-CohortGenerator::generateCohortSet(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortTableNames = cohortTableNames,
  cohortDefinitionSet = cohortDefinitionSet,
  cohortDatabaseSchema = cohortDatabaseSchema,
  incremental = TRUE,
  incrementalFolder = file.path(outputFolder, "incremental")
)

# Set up cohorts for  TreatmentPatterns
num_rows <- cohortToCreate %>%
  slice(-2) %>% # change to (-1) if your Atlas have condition occurence
  nrow()
cohorts <- cohortToCreate %>%
  slice(-2) %>% # change to (-1) if your Atlas have condition occurence
  select("cohortId",'cohortName',) %>%
  mutate(type = c("target", "exit", rep("event", num_rows - 2)))

# Execute Treatment Patterns
executeTreatmentPatterns(
  cohorts = cohorts,
  cohortTableName = cohortTable,
  connectionDetails = connectionDetails,
  cdmSchema=cdmDatabaseSchema,
  resultSchema=cohortDatabaseSchema,
  outputPath = outputFolder,
  minEraDuration = 30,
  eraCollapseSize = 30,
  combinationWindow = 30,
  minCellCount = 5
)

# Run Shiny apps to explore the result
launchResultsExplorer()



