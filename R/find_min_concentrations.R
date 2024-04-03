#' @title Data adaptively discover the shift interventions that require minimal change to achieve target outcome
#'
#' @description The `find_min_concentrations` function provides a g-computation approach to finding minimal shift interventions.
#' This function fits a super learner, then for a grid of exposure levels, predicts the expected outcome. It selects the exposure levels
#' which produce an outcome target within epsilon which are closest to the exposure averages under no shift.
#'
#' @param data A \code{data.frame} containing all the variables needed for the analysis, including
#' baseline covariates, exposures, and the outcome.
#' @param deltas A named \code{list} or \code{vector} specifying the shift in exposures to define the target parameter.
#' Each element should correspond to an exposure variable specified in \code{a_names}, detailing the amount
#' by which that exposure is to be shifted.
#' @param a_names A \code{character} vector specifying the names of the exposure variables within \code{data}.
#' @param w_names A \code{character} vector specifying the names of the covariate variables within \code{data}.
#' @param outcome The name of the outcome variable in \code{data}.
#' @param outcome_type A \code{character} string indicating the type of the outcome variable; either "continuous",
#' "binary", or "count".
#' @param mu_learner A list of \code{\link[sl3]{Lrnr_sl}} learners specifying the ensemble machine learning models to be used
#' for outcome prediction within the Super Learner framework.
#' @param top_n An \code{integer} specifying the number of top positive and negative effects to return.
#' @param seed An \code{integer} value to set the seed for reproducibility.
#'
#' @return A list containing the top effects and interactions identified and estimated by the function.
#' It includes elements for top positive and negative individual effects as well as top synergistic and antagonistic interactions.
#'
#' @examples
#' \dontrun{
#' data <- data.frame(matrix(rnorm(100 * 10), ncol = 10))
#' names(data) <- c(paste0("X", 1:8), "exposure", "outcome")
#' deltas <- list(exposure = 0.1)
#' a_names <- "exposure"
#' w_names <- paste0("X", 1:8)
#' outcome <- "outcome"
#' outcome_type <- "continuous"
#' mu_learner <- list(sl3::Lrnr_mean$new(), sl3::Lrnr_glm$new())
#' top_n <- 3
#' seed <- 123
#'
#' results <- find_synergy_antagonism(data, deltas, a_names, w_names, outcome, outcome_type, mu_learner, top_n, seed)
#' print(results)
#' }
#'
#' @importFrom sl3 make_sl3_Task Lrnr_sl
#' @export

find_min_concentrations <- function(data, a_names, w_names, outcome, outcome_type, mu_learner, target_outcome_lvl, epsilon, seed) {
  future::plan(future::sequential, gc = TRUE)
  set.seed(seed)

  task <- sl3::make_sl3_Task(data = data, covariates = c(a_names, w_names), outcome = outcome, outcome_type = outcome_type)
  sl <- sl3::Lrnr_sl$new(learners = mu_learner)
  sl_fit <- sl$train(task)

  results_df <- data.frame(
    Variable1 = character(),
    Variable2 = character(),
    ObservedLevel1 = numeric(),
    ObservedLevel2 = numeric(),
    IntervenedLevel1 = numeric(),
    IntervenedLevel2 = numeric(),
    AvgDiff = numeric(),
    Difference = numeric(),
    stringsAsFactors = FALSE
  )

  for (indices in combn(seq_along(a_names), 2, simplify = FALSE)) {
    vars <- a_names[indices]

    grid1 <- seq(min(data[[vars[1]]]), max(data[[vars[1]]]), length.out = 20)
    grid2 <- seq(min(data[[vars[2]]]), max(data[[vars[2]]]), length.out = 20)

    for (level1 in grid1) {
      for (level2 in grid2) {
        shifted_data <- data
        shifted_data[[vars[1]]] <- level1
        shifted_data[[vars[2]]] <- level2

        predictions <- sl_fit$predict(sl3::make_sl3_Task(data = shifted_data, covariates = c(a_names, w_names), outcome = outcome))
        mean_prediction <- mean(predictions)

        diff <- abs(mean_prediction - target_outcome_lvl)

        if (diff <= epsilon) {
          avg_diff <- (abs(level1 - mean(data[[vars[1]]])) + abs(level2 - mean(data[[vars[2]]]))) / 2

          results_df <- rbind(results_df, data.frame(
            Variable1 = vars[1],
            Variable2 = vars[2],
            ObservedLevel1 = mean(data[[vars[1]]]),
            ObservedLevel2 = mean(data[[vars[2]]]),
            IntervenedLevel1 = level1,
            IntervenedLevel2 = level2,
            AvgDiff = avg_diff,
            Difference = diff
          ))
        }
      }
    }
  }

  results_df <- results_df[order(results_df$AvgDiff), ]
  top_result <- head(results_df, 1)

  return(top_result)
}
