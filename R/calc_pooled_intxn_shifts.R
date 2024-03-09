#' Compute the Pooled Interaction Shift Parameter Estimate From the Fold
#' Specific Results
#'
#' @details Estimate the value of the pooled causal parameter alongside statistical
#'  inference for the parameter estimate based on the nuisance parameters from
#'  the fold specific results for the interaction parameter.
#'
#' @param intxn_shift_results A list of interaction results found across
#' the parallelized CV fold procedure
#' @param estimator The type of estimator to be fit, either \code{"tmle"} for
#'  targeted maximum likelihood estimation or \code{"onestep"} for a one-step
#'  estimator.
#' @param fluc_mod_out An object giving values of the logistic tilting model
#'  for targeted minimum loss estimation. This type of object should be the
#'  output of the internal routines to perform this step of the TML estimation
#'  procedure, as given by \code{\link{fit_fluctuation}}.
#' @param a_names List of exposure names
#' @param w_names List of covariate names
#' @param z_names List of mediator names
#' @param fluctuation Type of fluctuation to be used
#'
#' @importFrom stats var
#'
#' @return A \code{list} containing the parameter estimate, estimated variance
#'  based on the efficient influence function (EIF), the estimate of the EIF
#'  incorporating inverse probability of censoring weights, and the estimate of
#'  the EIF without the application of such weights.
calc_pooled_intxn_shifts <- function(intxn_shift_results,
                                     estimator = c("tmle", "onestep"),
                                     fluc_mod_out = NULL,
                                     a_names,
                                     w_names,
                                     z_names,
                                     fluctuation,
                                     n_folds) {
  # set TMLE as default estimator type
  estimator <- match.arg(estimator)

  names <- names(intxn_shift_results)
  names <- gsub("^(fold [0-9]+) :.*", "\\1", names)

  k_fold_results_list <- list()
  pooled_results_list <- list()



  test <- unlist(intxn_shift_results, recursive = FALSE)

    # Get clever covariate for each shift for each fold ----

    Hn_var1_shift <- do.call(rbind,test[stringr::str_detect(names(test), "Hn_var1_shift")])
    Hn_var2_shift <- do.call(rbind,test[stringr::str_detect(names(test), "Hn_var2_shift")])
    Hn_joint_shift <- do.call(rbind,test[stringr::str_detect(names(test), "Hn_joint_shift")])

    Qn_scaled_no_shift <- test[stringr::str_detect(names(test), "Qn_scaled_no_shift")]
    Qn_scaled_no_shift <- as.data.frame(unlist(Qn_scaled_no_shift, recursive = FALSE))
    rownames(Qn_scaled_no_shift) <- NULL

    Qn_scaled_var1_shift <- test[stringr::str_detect(names(test), "Qn_scaled_var1_shift")]
    Qn_scaled_var1_shift <- as.data.frame(unlist(Qn_scaled_var1_shift, recursive = FALSE))
    rownames(Qn_scaled_var1_shift) <- NULL
    Qn_scaled_var1_shift <- cbind(Qn_scaled_no_shift,Qn_scaled_var1_shift)
    colnames(Qn_scaled_var1_shift) <- c("noshift", "upshift")

    Qn_scaled_var2_shift <- test[stringr::str_detect(names(test), "Qn_scaled_var2_shift")]
    Qn_scaled_var2_shift <- as.data.frame(unlist(Qn_scaled_var2_shift, recursive = FALSE))
    rownames(Qn_scaled_var2_shift) <- NULL
    Qn_scaled_var2_shift <- cbind(Qn_scaled_no_shift,Qn_scaled_var2_shift)
    colnames(Qn_scaled_var2_shift) <- c("noshift", "upshift")


    Qn_scaled_joint_shift <- test[stringr::str_detect(names(test), "Qn_scaled_joint_shift")]
    Qn_scaled_joint_shift <- as.data.frame(unlist(Qn_scaled_joint_shift, recursive = FALSE))
    rownames(Qn_scaled_joint_shift) <- NULL
    Qn_scaled_joint_shift <- cbind(Qn_scaled_no_shift,Qn_scaled_joint_shift)
    colnames(Qn_scaled_joint_shift) <- c("noshift", "upshift")


    Qn_scaled <- list(Qn_scaled_var1_shift, Qn_scaled_var2_shift, Qn_scaled_joint_shift)
    Hn <- list(Hn_var1_shift, Hn_var2_shift, Hn_joint_shift)

    data <- do.call(rbind, test[stringr::str_detect(names(test), "data")])

    intxn_results_list <- list()


    for (i in 1:length(Hn)) {
      hn_estim <- Hn[[i]]
      qn_estim_scaled <- Qn_scaled[[i]]

      tmle_fit <- tmle_exposhift(
        data_internal = data,
        Qn_scaled = qn_estim_scaled,
        Hn = hn_estim,
        y = data$y,
      )

      intxn_results_list[[i]] <- tmle_fit
    }

    intxn_pooled <- calc_final_joint_shift_param(
      joint_shift_fold_results = intxn_results_list,
      fold_k = "Pooled TMLE",
      deltas_updated = deltas,
      exposures = c("Var 1", "Var 2", "Joint", "Interaction")
    )

    k_fold_results <- test[stringr::str_detect(names(test), "k_fold_result")]



  return(list("k_fold_results" = k_fold_results, "pooled_results" = intxn_pooled))
}
