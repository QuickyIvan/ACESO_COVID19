# Copyright 2022 Observational Health Data Sciences and Informatics
#
# This file is part of ACESOCovid19
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

createAnalysesDetails <- function(workFolder) {
  covarSettings <- FeatureExtraction::createDefaultCovariateSettings(addDescendantsToExclude = TRUE)
  
  getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(washoutPeriod = 183,
                                                                   restrictToCommonPeriod = FALSE,
                                                                   firstExposureOnly = TRUE,
                                                                   removeDuplicateSubjects = "remove all",
                                                                   studyStartDate = "",
                                                                   studyEndDate = "",
                                                                   excludeDrugsFromCovariates = FALSE,
                                                                   covariateSettings = covarSettings)
  
  createStudyPopArgs <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                      minDaysAtRisk = 1,
                                                                      riskWindowStart = 0,
                                                                      addExposureDaysToStart = FALSE,
                                                                      riskWindowEnd = 30,
                                                                      addExposureDaysToEnd = TRUE)
  
  fitOutcomeModelArgs1 <- CohortMethod::createFitOutcomeModelArgs(useCovariates = FALSE,
                                                                  modelType = "cox",
                                                                  stratified = FALSE)
  
  cmAnalysis1 <- CohortMethod::createCmAnalysis(analysisId = 1,
                                                description = "No matching",
                                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                createStudyPopArgs = createStudyPopArgs,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  createPsArgs <- CohortMethod::createCreatePsArgs(control = Cyclops::createControl(cvType = "auto",
                                                                                    startingVariance = 0.01,
                                                                                    noiseLevel = "quiet",
                                                                                    tolerance = 2e-07,
                                                                                    cvRepetitions = 10))
  
  matchOnPsArgs1 <- CohortMethod::createMatchOnPsArgs(maxRatio = 1)
  
  fitOutcomeModelArgs2 <- CohortMethod::createFitOutcomeModelArgs(useCovariates = FALSE,
                                                                  modelType = "cox",
                                                                  stratified = TRUE)
  
  cmAnalysis2 <- CohortMethod::createCmAnalysis(analysisId = 2,
                                                description = "One-on-one matching",
                                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                createStudyPopArgs = createStudyPopArgs,
                                                createPs = TRUE,
                                                createPsArgs = createPsArgs,
                                                matchOnPs = TRUE,
                                                matchOnPsArgs = matchOnPsArgs1,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitOutcomeModelArgs2)
  
  matchOnPsArgs2 <- CohortMethod::createMatchOnPsArgs(maxRatio = 100)
  
  cmAnalysis3 <- CohortMethod::createCmAnalysis(analysisId = 3,
                                                description = "Variable ratio matching",
                                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                createStudyPopArgs = createStudyPopArgs,
                                                createPs = TRUE,
                                                createPsArgs = createPsArgs,
                                                matchOnPs = TRUE,
                                                matchOnPsArgs = matchOnPsArgs2,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitOutcomeModelArgs2)
  
  stratifyByPsArgs <- CohortMethod::createStratifyByPsArgs(numberOfStrata = 5)
  
  cmAnalysis4 <- CohortMethod::createCmAnalysis(analysisId = 4,
                                                description = "Stratification",
                                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                createStudyPopArgs = createStudyPopArgs,
                                                createPs = TRUE,
                                                createPsArgs = createPsArgs,
                                                stratifyByPs = TRUE,
                                                stratifyByPsArgs = stratifyByPsArgs,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitOutcomeModelArgs2)
  
  interactionCovariateIds <- c(8532001, 201826210, 21600960413) # Female, T2DM, concurent use of antithrombotic agents
  
  fitOutcomeModelArgs3 <- CohortMethod::createFitOutcomeModelArgs(modelType = "cox",
                                                                  stratified = TRUE,
                                                                  useCovariates = FALSE,
                                                                  interactionCovariateIds = interactionCovariateIds)
  
  cmAnalysis5 <- CohortMethod::createCmAnalysis(analysisId = 5,
                                                description = "Stratification with interaction terms",
                                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                createStudyPopArgs = createStudyPopArgs,
                                                createPs = TRUE,
                                                createPsArgs = createPsArgs,
                                                stratifyByPs = TRUE,
                                                stratifyByPsArgs = stratifyByPsArgs,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitOutcomeModelArgs3)
  
  cmAnalysisList <- list(cmAnalysis1, cmAnalysis2, cmAnalysis3, cmAnalysis4, cmAnalysis5)
  
  CohortMethod::saveCmAnalysisList(cmAnalysisList, file.path(workFolder, "cmAnalysisList.json"))
}

createPositiveControlSynthesisArgs <- function(workFolder) {
  settings <- list(
    outputIdOffset = 10000,
    firstExposureOnly = TRUE,
    firstOutcomeOnly = TRUE,
    removePeopleWithPriorOutcomes = TRUE,
    modelType = "survival",
    washoutPeriod = 183,
    riskWindowStart = 0,
    riskWindowEnd = 30,
    addExposureDaysToEnd = TRUE,
    effectSizes = c(1.5, 2, 4),
    precision = 0.01,
    prior = Cyclops::createPrior("laplace", exclude = 0, useCrossValidation = TRUE),
    control = Cyclops::createControl(cvType = "auto",
                                     startingVariance = 0.01,
                                     noiseLevel = "quiet",
                                     cvRepetitions = 1,
                                     threads = 1),
    maxSubjectsForModel = 250000,
    minOutcomeCountForModel = 50,
    minOutcomeCountForInjection = 25,
    covariateSettings = FeatureExtraction::createCovariateSettings(useDemographicsAgeGroup = TRUE,
                                                                   useDemographicsGender = TRUE,
                                                                   useDemographicsIndexYear = TRUE,
                                                                   useDemographicsIndexMonth = TRUE,
                                                                   useConditionGroupEraLongTerm = TRUE,
                                                                   useDrugGroupEraLongTerm = TRUE,
                                                                   useProcedureOccurrenceLongTerm = TRUE,
                                                                   useMeasurementLongTerm = TRUE,
                                                                   useObservationLongTerm = TRUE,
                                                                   useCharlsonIndex = TRUE,
                                                                   useDcsi = TRUE,
                                                                   useChads2Vasc = TRUE,
                                                                   longTermStartDays = -365,
                                                                   endDays = 0) 
  )
  ParallelLogger::saveSettingsToJson(settings, file.path(workFolder, "positiveControlSynthArgs.json"))
}

