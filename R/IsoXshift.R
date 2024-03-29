#' @title Data-adaptive estimation of interactions, effect modification, and
#' mediation using stochastic shift intervention target parameters. In many mixed exposure settings,
#' interactions in the mixture, effect modifiers in the covariates that modify the
#' impact of an exposure and mediating pathways from exposure to outcome are generally unknown. IsoXshift finds these variable sets
#' on one part of the data and estimates counterfactual outcome changes given shifts to exposure on an estimation part of the data.
#' Using cross-validation and targeted learning, estimators are created that utlize machine learning that are unbiased and have the
#' minimum variance.
#'
#' @description The IsoXshift function provides an efficient approach to estimate
#' interactions, effect modification, and mediation using targeted minimum loss
#' estimators for counterfactual mean differences under various target parameters.
#' The procedure employs data-adaptive ensemble b-spline models and stochastic interventions,
#' leveraging the \pkg{sl3} package for ensemble machine learning. The data is split into V folds, in each fold
#' the training data is used to find variable sets using flexible basis function estimators. Given the different variable sets,
#' stochastic intervention target parameters are applied with cross-validated targeted learning.
#'
#' @param w A \code{matrix}, \code{data.frame}, or similar containing a set of
#' baseline covariates. These variables are measured before exposures.
#' @param a \code{matrix}, \code{data.frame}, or similar containing individual or
#' multiple exposures.
#' @param z \code{matrix}, \code{data.frame}, or similar containing individual or
#' multiple mediators (optional).
#' @param y \code{numeric} vector of observed outcomes.
#' @param deltas A \code{numeric} value indicating the shift in exposures to
#' define the target parameter, with respect to the scale of the exposures (A). If adaptive_delta
#' is true, these values will be reduced.
#' @param var_sets A list specifying variable sets for deterministic IsoXshift usage.
#' Example: var_sets <- c("A_1", "A_1-Z_2") where the analyst provides variable sets
#' for exposures, exposure-mediator, or exposure-covariate relationships.
#' @param estimator The type of estimator to fit: \code{"tmle"} for targeted
#' maximum likelihood estimation, or \code{"onestep"} for a one-step estimator.
#' @param fluctuation Method used in the targeting step for TML estimation: "standard" or "weighted".
#' This determines where to place the auxiliary covariate in the logistic tilting regression.
#' @param pi_learner Learners for fitting Super Learner ensembles to densities via \pkg{sl3}.
#' @param mu_learner Learners for fitting Super Learner ensembles to the outcome model via \pkg{sl3}.
#' @param g_learner Learners for fitting Super Learner ensembles to the g-mechanism
#' g(A|W) (a probability estimator, not a density estimator) for mediation via \pkg{sl3}.
#' @param e_learner Learners for fitting Super Learner ensembles to the e-mechanism
#' g(A|Z,W) (a probability estimator, not a density estimator) for mediation via \pkg{sl3}.
#' @param zeta_learner Learners for fitting Super Learner ensembles to the outcome model via \pkg{sl3}..
#' @param n_folds Number of folds to use in cross-validation, default is 2.
#' @param outcome_type Data type of the outcome, default is "continuous".
#' @param mediator_type Data type of the mediator, default is "continuous".
#' @param quantile_thresh Threshold based on quantiles of the F-statistic, used to
#' identify "important" basis functions in the data-adaptive procedure.
#' @param verbose Whether to run verbosely (default: FALSE).
#' @param parallel Whether to parallelize across cores (default: TRUE).
#' @param parallel_type Type of parallelization to use if parallel is TRUE:
#' "multi_session" (default), "multicore", or "sequential".
#' @param num_cores Number of CPU cores to use in parallelization (default: 2).
#' @param seed \code{numeric} seed value to be passed to all functions.
#' @param hn_trunc_thresh Truncation level for the clever covariate (default: 10).
#' @param adaptive_delta If TRUE, reduces the user-specified delta until
#' the Hn calculated for a shift does not have any observation greater
#' than hn_trunc_thresh (default: FALSE).
#' @param n_mc_sample Number of iterations to be used for the Monte Carlo integration
#' procedure when using continuous exposures (default: 1000).
#' @param exposure_quantized Whether the exposure has been discretized into bins,
#' in which case the integration procedure is skipped and weighted sums are used instead (default: FALSE).
#' @param mediator_quantized If the mediator is discretized, a multinomial ML function
#' is used in this regression to avoid density estimation (default: FALSE).
#' @param density_type Type of density estimation to be used: "sl" for Super Learner
#' (default) or "hal" for highly adaptive lasso.
#' @param n_bins Number of bins for quantizing the exposure if mediation is detected (default: 10).
#' @param max_degree Maximum degree of interactions used in the highly adaptive lasso
#' density estimator if used (default: 1).
#' @param integration_method Type of integration to be used in the continuous exposure
#' case: "MC" for Monte Carlo integration (default) or "AQ" for adaptive quadrature.
#' @param use_multinomial Whether to use multinomial regression for binned exposures
#' (default: FALSE).
#' @param discover_only TRUE/FALSE. If TRUE, only the data-adaptive path discovery
#' is done. No estimates are delivered only exposure mediator sets. If FALSE paths
#' are both discovered and estimated.
#'
#' @return An S3 object of class \code{IsoXshift} containing the results of the
#' procedure to compute a TML or one-step estimate of the counterfactual mean
#' under a modified treatment policy that shifts a continuous-valued exposure
#' by a scalar amount \code{delta}. These exposures are data-adaptively
#' identified using the CV-TMLE procedure.
#' @export
#' @importFrom MASS mvrnorm
#' @importFrom foreach %dopar%
#' @importFrom magrittr %>%
#' @importFrom stats as.formula glm p.adjust plogis predict qlogis qnorm qunif rnorm runif
#' @importFrom rlang :=
#' @importFrom stringr str_count
#' @import furrr
#' @importFrom purrr map
#' @importFrom data.table rbindlist

IsoXshift <- function(w,
                      a,
                      y,
                      target_outcome_lvl,
                      epsilon,
                      estimator = "tmle",
                      mu_learner = NULL,
                      g_learner = NULL,
                      pi_learner = NULL,
                      n_folds = 2,
                      outcome_type = "continuous",
                      parallel = TRUE,
                      parallel_type = "multi_session",
                      num_cores = 2,
                      seed = seed,
                      hn_trunc_thresh = 10,
                      top_n = 1) {

  # coerce W to matrix and, if no names in W, assign them generically
  if (!is.data.frame(w)) w <- as.data.frame(w)
  w_names <- colnames(w)
  if (is.null(w_names)) {
    w_names <- paste0("w", seq_len(ncol(w)))
    colnames(w) <- w_names
  }


  # coerce W to matrix and, if no names in W, assign them generically
  a <- data.frame(a)
  a_names <- colnames(a)

  if (is.null(a_names)) {
    a_names <- paste0("a", seq_len(ncol(a)))
    colnames(a) <- a_names
  }

  if (is.null(mu_learner)) {
    sls <- create_sls()
    mu_learner <- sls$mu_learner
  }

  if (is.null(g_learner)) {
    sls <- create_sls()
    g_learner <- sls$g_learner
  }


  if (is.null(pi_learner)) {
    sls <- create_sls()
    pi_learner <- sls$pi_learner
  }

  if (parallel == TRUE) {
    if (parallel_type == "multi_session") {
      future::plan(future::multisession,
        workers = num_cores,
        gc = TRUE
      )
    } else {
      future::plan(future::multicore,
        workers = num_cores,
        gc = TRUE
      )
    }
  } else {
    future::plan(future::sequential,
      gc = TRUE
    )
  }

  data_internal <- data.table::data.table(w, a, y)
  `%notin%` <- Negate(`%in%`)

  if (outcome_type == "binary") {
    ## create the CV folds
    data_internal$folds <- create_cv_folds(n_folds, data_internal$y)
  } else {
    data_internal$folds <- create_cv_folds(n_folds, data_internal$y)
  }

  fold_basis_results <- furrr::future_map(unique(data_internal$folds),
    function(fold_k) {
      at <- data_internal[data_internal$folds != fold_k, ]
      av <- data_internal[data_internal$folds == fold_k, ]

      intxn_results <- find_min_concentrations(
        data = at,
        a_names = a_names,
        w_names = w_names,
        outcome = "y",
        target_outcome_lvl = target_outcome_lvl,
        outcome_type = outcome_type,
        mu_learner = mu_learner,
        seed = seed,
        epsilon = epsilon
      )
    },
    .options = furrr::furrr_options(seed = seed, packages = "IsoXshift")
  )

  pie_min_effort_shift <- list()

  fold_IsoXshift_results <- furrr::future_map(
    unique(data_internal$folds), function(fold_k) {
      fold_intxn_results <- fold_basis_results[[fold_k]]

      var1 <- fold_intxn_results$Variable1
      var2 <- fold_intxn_results$Variable2
      level1 <- fold_intxn_results$IntervenedLevel1
      level2 <- fold_intxn_results$IntervenedLevel2

      at <- data_internal[data_internal$folds != fold_k, ]
      av <- data_internal[data_internal$folds == fold_k, ]

      exposures <- as.list(c(var1, var2))
      deltas <- c(level1, level2)
      exposures[[3]] <- unlist(exposures)

      covars <- c(w_names)

      joint_gn_exp_estims <- joint_stoch_shift_est_g_exp(
        exposures,
        deltas,
        g_learner = pi_learner,
        covars = covars,
        av = av,
        at = at,
        hn_trunc_thresh = hn_trunc_thresh,
        outcome_type = "continuous"
      )

      joint_gn_exp_estims[[3]]$likelihood_shift <-
        joint_gn_exp_estims[[1]]$likelihood_shift *
          joint_gn_exp_estims[[3]]$likelihood_shift

      joint_gn_exp_estims[[3]]$likelihood_no_shift <-
        joint_gn_exp_estims[[1]]$likelihood_no_shift *
          joint_gn_exp_estims[[3]]$likelihood_no_shift

      joint_gn_exp_estims[[3]]$ratio <-
        joint_gn_exp_estims[[3]]$likelihood_no_shift /
          joint_gn_exp_estims[[3]]$likelihood_shift

      covars <- c(a_names, w_names)

      joint_qn_estims <- joint_stoch_shift_est_Q(
        exposures = exposures,
        mu_learner = mu_learner,
        covars = covars,
        joint_gn_exp_estims = joint_gn_exp_estims,
        at = at,
        av = av,
        outcome_type = outcome_type
      )

      intxn_results_list <- list()
      qn_estim_scaled_list <- list()
      joint_hn_estims <- list()

      for (i in 1:length(joint_qn_estims$shift)) {
        hn_estim <- cbind(
          rep(1, length(joint_gn_exp_estims[[i]]$ratio)),
          joint_gn_exp_estims[[i]]$ratio
        )
        colnames(hn_estim) <- c("noshift", "shift")
        hn_estim <- as.data.frame(hn_estim)

        qn_estim <- cbind(joint_qn_estims$noshift, joint_qn_estims$shift[[i]])
        colnames(qn_estim) <- c("noshift", "upshift")
        qn_estim <- as.data.frame(qn_estim)

        tmle_fit <- tmle_exposhift(
          data_internal = av,
          Qn_scaled = qn_estim,
          Hn = hn_estim,
          y = av$y
        )

        intxn_results_list[[i]] <- tmle_fit
        joint_hn_estims[[i]] <- hn_estim
      }

      syngery_in_fold <- calc_final_joint_shift_param(
        joint_shift_fold_results = intxn_results_list,
        fold_k = fold_k,
        exposures = exposures
      )

      pie_min_effort_shift[[
        paste("fold", fold_k, ":", paste(var1, var2, sep = "-"))
      ]] <- list(
        "data" = av,
        "Qn_scaled_no_shift" = joint_qn_estims$noshift,
        "Qn_scaled_var1_shift" = joint_qn_estims$shift[[1]],
        "Qn_scaled_var2_shift" = joint_qn_estims$shift[[2]],
        "Qn_scaled_joint_shift" = joint_qn_estims$shift[[3]],
        "Hn_var1_shift" = joint_hn_estims[[1]],
        "Hn_var2_shift" = joint_hn_estims[[2]],
        "Hn_joint_shift" = joint_hn_estims[[3]],
        "k_fold_result" = syngery_in_fold
      )

      pie_min_effort_shift
    },
    .options = furrr::furrr_options(seed = seed, packages = "IsoXshift")
  )

  fold_min_shift_results <- unlist(fold_IsoXshift_results, recursive = FALSE)


  pooled_synergy_shift_results <- calc_pooled_intxn_shifts(
    intxn_shift_results = fold_min_shift_results,
    a_names = a_names,
    w_names = w_names,
    z_names = z_names,
    n_folds = n_folds
  )

  results_list <- list(
    "Oracle Pooled Results" = pooled_synergy_shift_results$pooled_results,
    "K-fold Results" = pooled_synergy_shift_results$k_fold_results,
    "K Fold Oracle Targets" = fold_basis_results
  )

  return(results_list)
}
