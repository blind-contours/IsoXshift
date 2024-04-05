#' Estimate the Exposure Mechanism via Generalized Propensity Score for Two
#' Exposure Variable
#'
#' @details Compute the propensity score (exposure mechanism) for the observed
#'  data, including the shift. This gives the propensity score for the observed
#'  data (at the observed A) the counterfactual shifted exposure levels (at
#'  {A - delta}, {A + delta}, and {A + 2 * delta}).
#'
#' @param exposures A \code{vector} of characters labeling the exposure
#' variables.
#' @param covars A \code{character} labeling the covariate variables
#' @param deltas A \code{numeric} value identifying a shift in the observed
#'  value of the exposure under which observations are to be evaluated.
#' @param g_learner Object containing a set of instantiated learners
#'  from \pkg{sl3}, to be used in fitting an ensemble model.
#' @param av A \code{dataframe} of validation data specific to the fold
#' @param at A \code{dataframe} of training data specific to the fold
#' @param adaptive_delta Whether to adaptively change the delta based on positivity
#' determined from the clever covariate being below the hn_trunc_thresh level
#' @param hn_trunc_thresh Truncation level of the clever covariate used in the
#' adaptive delta method
#' @param outcome_type Type of outcome variable
#' @param use_multinomial TRUE/FALSE for using multinomial for discretized exposure
#'
#' @importFrom data.table as.data.table setnames set copy
#' @importFrom stats predict
#' @importFrom assertthat assert_that
#'
#' @export
#'
#' @return A \code{data.table} with four columns, containing estimates of the
#'  generalized propensity score at a downshift (g(A - delta | W)), no shift
#'  (g(A | W)), an upshift (g(A + delta) | W), and an upshift of magnitude two
#'  (g(A + 2 delta) | W).

joint_stoch_shift_est_g_exp <- function(exposures,
                                        deltas,
                                        g_learner,
                                        covars,
                                        av,
                                        at,
                                        hn_trunc_thresh,
                                        outcome_type) {
  future::plan(future::sequential, gc = TRUE)

  av <- as.data.frame(av)
  at <- as.data.frame(at)

  results <- list()

  for (i in 1:length(exposures)) {
    if (i == 3) {
      exposure <- exposures[[i]][2]
      covars <- c(covars, exposures[[1]])
      delta <- deltas[[2]]
      index <- paste(exposures[[i]], collapse = "-")
    } else {
      exposure <- exposures[[i]]
      delta <- deltas[[i]]
      covars <- covars
      index <- exposure
    }


    sl_task <- sl3::sl3_Task$new(
      data = at,
      outcome = exposure,
      covariates = covars,
      outcome_type = outcome_type
    )

    sl_task_noshift_at <- sl3::sl3_Task$new(
      data = at,
      outcome = exposure,
      covariates = covars,
      outcome_type = outcome_type
    )

    sl_task_noshift_av <- sl3::sl3_Task$new(
      data = av,
      outcome = exposure,
      covariates = covars,
      outcome_type = outcome_type
    )

    g_model <- suppressWarnings(suppressMessages(g_learner$train(sl_task)))

    aggregate_results <- data.frame()

    for (obs in 1:nrow(av)) {
      obs_data <- av[obs, ]
      obs_data_shifted <- obs_data
      obs_data_shifted[exposure] <- delta

      task_obs_no_shift <- sl3::sl3_Task$new(
        data = obs_data,
        outcome = exposure,
        covariates = covars
      )

      obs_pred_no_shifted <- g_model$predict(task_obs_no_shift)
      grid1 <- seq(min(av[[exposure]]), max(av[[exposure]]), length.out = 50)
      replicated_data <- obs_data_shifted[rep(1:nrow(obs_data_shifted), each = 50), ]
      row.names(replicated_data) <- NULL
      replicated_data[, exposure] <- grid1

      task_obs_shift_rep <- sl3::sl3_Task$new(
        data = replicated_data,
        outcome = exposure,
        covariates = covars
      )

      obs_pred_shifted <- g_model$predict(task_obs_shift_rep)
      ratio <- obs_pred_no_shifted / obs_pred_shifted
      delta_diff <- abs(grid1 - delta)
      replicated_data$delta_diff <- delta_diff
      replicated_data$ratio <- ratio

      # Subset to rows where ratio is less than hn_trunc_thresh
      filtered_data <- replicated_data[replicated_data$ratio < hn_trunc_thresh, ]

      # Find the row with the minimum delta_diff within the filtered data
      min_diff_row <- filtered_data[which.min(filtered_data$delta_diff), ]
      min_diff_row$likelihood_shift <- obs_pred_shifted[as.numeric(rownames(min_diff_row))]
      min_diff_row$likelihood_no_shift <- obs_pred_no_shifted
      min_diff_row$delta <- min_diff_row[, exposure] - obs_data[, exposure]

      aggregate_results <- rbind(aggregate_results, min_diff_row)

      results[[index]] <- aggregate_results
    }
  }

  return(results)
}
