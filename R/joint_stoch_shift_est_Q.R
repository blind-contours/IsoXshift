#' Estimate the Outcome Mechanism
#'
#' @details Compute the outcome regression for the observed data, including
#'  with the shift imposed by the intervention. This returns the outcome
#'  regression for the observed data (at A) and under the counterfactual shift
#'  shift (at A + delta).
#'
#' @param exposures A \code{character} vector of exposures to be shifted.
#' @param covars A \code{character} vector covariates to adjust for.
#' @param deltas A \code{numeric} indicating the magnitude of the shift to be
#'  computed for the exposure \code{A}. This is passed to the internal
#'  \code{\link{shift_additive}} and is currently limited to additive shifts.
#' @param mu_learner Object containing a set of instantiated learners from the
#'  \pkg{sl3}, to be used in fitting an ensemble model.
#' @param av A \code{dataframe} of validation data specific to the fold
#' @param at A \code{dataframe} of training data specific to the fold
#' @param outcome_type Variable type of the outcome
#' @importFrom stats glm as.formula predict
#' @importFrom data.table as.data.table setnames copy set
#' @importFrom stringr str_detect
#' @importFrom assertthat assert_that
#' @export
#' @return A \code{data.table} with two columns, containing estimates of the
#'  outcome mechanism at the natural value of the exposure Q(A, W) and an
#'  upshift of the exposure Q(A + delta, W).

joint_stoch_shift_est_Q <- function(exposures,
                                    deltas,
                                    mu_learner,
                                    covars,
                                    joint_gn_exp_estims,
                                    at,
                                    av,
                                    outcome_type) {
  future::plan(future::sequential, gc = TRUE)

  if (outcome_type != "binary") {
    y_star_av <- scale_to_unit(vals = av$y)
    y_star_at <- scale_to_unit(vals = at$y)

    av$y <- y_star_av
    at$y <- y_star_at
  }


  results <- list()

  at_task_noshift <- suppressMessages(sl3::sl3_Task$new(
    data = at,
    covariates = covars,
    outcome = "y",
    outcome_type = "quasibinomial"
  ))

  av_task_noshift <- suppressMessages(sl3::sl3_Task$new(
    data = av,
    covariates = covars,
    outcome = "y",
    outcome_type = "quasibinomial"
  ))

  sl <- Lrnr_sl$new(
    learners = mu_learner,
    metalearner = sl3::Lrnr_nnls$new()
  )

  sl_fit <- suppressMessages(sl$train(at_task_noshift))
  av_preds_no_shift <- bound_precision(sl_fit$predict(av_task_noshift))


  for (i in 1:length(exposures)) {
    exposure <- exposures[[i]]
    av_i <- joint_gn_exp_estims[[i]]

    if (i == 3) {
      av_i[[exposures[[1]]]] <- joint_gn_exp_estims[[1]][[exposure[[1]]]]
      av_i[[exposures[[2]]]] <- joint_gn_exp_estims[[2]][[exposure[[2]]]]
    }

    if (outcome_type != "binary") {
      y_star_av <- scale_to_unit(vals = av_i$y)
      y_star_at <- scale_to_unit(vals = av_i$y)

      av_i$y <- y_star_av
      av_i$y <- y_star_at
    }

    av_task_shift <- suppressMessages(sl3::sl3_Task$new(
      data = av_i,
      covariates = covars,
      outcome = "y",
      outcome_type = "quasibinomial"
    ))

    shift_av_results_i <- bound_precision(sl_fit$predict(av_task_shift))


    results[[i]] <- shift_av_results_i
  }

  return(list("noshift" = av_preds_no_shift, "shift" = results))
}
