#install necessary packages
#install.packages("remotes")
#remotes::install_github("OHDSI/DatabaseConnector")
#remotes::install_github("OHDSI/CohortGenerator")
#remotes::install_github("OHDSI/ROhdsiWebApi")

library(EpiDrug)
library(dplyr)

# Input connection setting
connectionDetails = DatabaseConnector::createConnectionDetails(dbms = "dbms", #input your database manager
                                                               server = "server", #input your server details
                                                               user = "user", #input your user name
                                                               password = "pwd",
                                                               pathToDriver = '~/driver') #input your password to acess your server
cdmDatabaseSchema = 'database schema'
cohortDatabaseSchema = 'cohortdatabaseschema'
databaseId <- "database ID"

# Get cohort definitions from Atlas
cohortIds <- c(483, #Overall epilepsy cohort
               614, #epilepsy cohort without diagnostic
               604, #Death
               539:558 #Drugs exposure
)
baseUrl = 'http://Atlas.link/WebAPI' #input your Atlas API link
cohortDefinitionSet <- ROhdsiWebApi::exportCohortDefinitionSet(
  baseUrl = baseUrl,
  cohortIds = cohortIds,
  generateStats = TRUE
)

# Insert cohort definitions from ATLAS into package -----------------------
packageRoot=getwd()
saveCohortDefinitionSet(cohortDefinitionSet,
  settingsFileName = file.path(
    packageRoot, "inst/settings/CohortsToCreate.csv"
  ),
  jsonFolder = file.path(packageRoot, "inst/cohorts"),
  sqlFolder = file.path(packageRoot, "inst/sql/sql_server")
)
