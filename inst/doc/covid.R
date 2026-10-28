## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----libraries----------------------------------------------------------------
library(dgtf)
library(ggplot2)

## ----eval = FALSE-------------------------------------------------------------
# ytrain <- covid_scz_2020[1:250]
# ytest <- covid_scz_2020[251:264]
# ggplot(data = data.frame(x = 1:264, y = c(ytrain, ytest)), aes(x = x, y = y)) +
#   geom_line() +
#   geom_vline(xintercept = 250, linetype = "dashed") +
#   theme_minimal()

## ----eval = FALSE-------------------------------------------------------------
# set.seed(123)
# mod_DH <- dgtf_model(
#   obs = obs_nbinom(),
#   link = link_identity(),
#   sys = sys_shift(),
#   gain = gain_softplus(),
#   lag = lag_lognormal(
#     meanlog = rnorm(1, 1, 1),
#     sigma2 = 1 / rgamma(1, 10, 1)
#   ),
#   err = err_gaussian(W = 1 / rgamma(1, 10, 1)),
#   seasonality = seas_period(7, init = runif(7, 0, 10))
# )
# 
# mod_DL <- dgtf_distributed_lag(
#   r = 2,
#   kappa = runif(1, 0.1, 0.9),
#   seasonality = seas_weekly(init = runif(7, 0, 10))
# )
# 
# mod_AR <- dgtf_nb_ar(
#   p = 3,
#   W = 1 / rgamma(1, 10, 1),
#   seasonality = seas_weekly(init = runif(7, 0, 10))
# )

## ----eval = FALSE-------------------------------------------------------------
# prior_DH <- dgtf_prior(
#   seasonality = normal(0, 10),
#   W           = inv_gamma(1, 1),
#   rho         = inv_gamma(1, 1),
#   lag         = list(par1 = normal(0, 1), par2 = inv_gamma(1, 1))
# )
# 
# prior_DL <- dgtf_prior(
#   seasonality = normal(0, 10),
#   W           = inv_gamma(1, 1),
#   rho         = inv_gamma(1, 1),
#   lag         = list(par1 = dist_beta(1, 1))
# )
# 
# prior_AR <- dgtf_prior(
#   seasonality = normal(0, 10),
#   W           = inv_gamma(1, 1),
#   rho         = inv_gamma(1, 1)
# )

## ----eval = FALSE-------------------------------------------------------------
# set.seed(123)
# fit_DH <- dgtf(ytrain, mod_DH, prior_DH,
#   method = "hva",
#   control = vb_control(iter = 1000, n_sample = 5000, n_particle = 500)
# )
# summary(fit_DH)
# plot(fit_DH, what = "marglik") # Check convergence

## ----mcmc-fit, eval = FALSE---------------------------------------------------
# fit_DH_mcmc <- dgtf(ytrain, mod_DH, prior_DH,
#   method = "mcmc",
#   control = mcmc_control(iter = 10000, warmup = 5000, thin = 1)
# ) # takes ~50 minutes
# summary(fit_DH_mcmc)

## ----eval = FALSE-------------------------------------------------------------
# fit_DL <- dgtf(ytrain, mod_DL, prior_DL,
#   method = "hva",
#   control = vb_control(iter = 1000, n_sample = 5000, n_particle = 500)
# )
# print(summary(fit_DL))
# 
# fit_AR <- dgtf(ytrain, mod_AR, prior_AR,
#   method = "hva",
#   control = vb_control(iter = 1000, n_sample = 5000, n_particle = 500)
# )
# print(summary(fit_AR))

## ----hva-mcmc-params, eval = FALSE--------------------------------------------
# dgtf_compare_params(list(HVA = fit_DH, MCMC = fit_DH_mcmc))

## ----hva-mcmc-overlays, eval = FALSE------------------------------------------
# dgtf_compare_plot(
#   list(HVA = fit_DH, MCMC = fit_DH_mcmc),
#   what = "seas"
# )
# 
# dgtf_compare_plot(
#   list(HVA = fit_DH, MCMC = fit_DH_mcmc),
#   what = "Rt"
# )

## ----eval = FALSE-------------------------------------------------------------
# set.seed(123)
# attr(fit_DH, "ppc") <- posterior_predict(fit_DH)

## ----mcmc-ppc, eval = FALSE---------------------------------------------------
# attr(fit_DH_mcmc, "ppc") <- posterior_predict(fit_DH_mcmc)

## ----hva-mcmc-compare, eval = FALSE-------------------------------------------
# dgtf_compare(list(HVA = fit_DH, MCMC = fit_DH_mcmc))

## ----eval = FALSE-------------------------------------------------------------
# fc_DH <- dgtf_forecast_fit(fit_DH, h = 14, ypred_true = ytest)

## ----hva-mcmc-fc-compare, eval = FALSE----------------------------------------
# fc_DH_mcmc <- dgtf_forecast_fit(fit_DH_mcmc, h = 14, ypred_true = ytest)
# summary(fc_DH_mcmc)
# plot_dgtf_y(fit_DH_mcmc, fc_DH_mcmc)
# dgtf_compare(list(HVA = fc_DH, MCMC = fc_DH_mcmc))

## ----eval = FALSE-------------------------------------------------------------
# plot(fit_DH, what = "yhat")
# summary(attr(fit_DH, "ppc"))

## ----mcmc-yhat, eval = FALSE--------------------------------------------------
# plot(fit_DH_mcmc, what = "yhat")
# summary(attr(fit_DH_mcmc, "ppc"))

## ----eval = FALSE-------------------------------------------------------------
# set.seed(123)
# attr(fit_DL, "ppc") <- posterior_predict(fit_DL, nrep = 100)
# attr(fit_AR, "ppc") <- posterior_predict(fit_AR, nrep = 100)
# 
# plot(fit_DL, what = "yhat")
# summary(attr(fit_DL, "ppc"))
# 
# plot(fit_AR, what = "yhat")
# summary(attr(fit_AR, "ppc"))

## ----eval = FALSE-------------------------------------------------------------
# dgtf_compare(
#   list(
#     DH = fit_DH,
#     DL = fit_DL,
#     AR = fit_AR
#   )
# )

## ----eval = FALSE-------------------------------------------------------------
# deseason_counts <- function(y, period = 7L, start_day = 1L) {
#   n <- length(y)
#   day_idx <- ((start_day - 1L + seq_len(n) - 1L) %% period) + 1L
#   sds <- vapply(seq_len(period), function(d) {
#     sd(y[day_idx == d], na.rm = TRUE)
#   }, numeric(1))
#   sds <- sds / sum(sds) * period
#   round(y / sds[day_idx])
# }
# 
# y_adj <- deseason_counts(ytrain, period = 7L)
# 
# epi <- epiestim_baseline(
#   y       = y_adj,
#   mean_si = 4.7,
#   sd_si   = 2.9,
#   method  = "parametric_si",
#   window  = 7
# )
# epi

## ----eval = FALSE-------------------------------------------------------------
# dgtf_compare_plot(
#   list(
#     DH = fit_DH,
#     DL = fit_DL,
#     EpiEstim = epi
#   ),
#   what = "Rt"
# )
# 
# dgtf_compare_plot(
#   list(
#     DH = fit_DH,
#     DL = fit_DL,
#     AR = fit_AR
#   ),
#   what = "yhat"
# )
# 
# dgtf_compare_plot(
#   list(
#     DH = fit_DH,
#     DL = fit_DL,
#     AR = fit_AR
#   ),
#   what = "seas"
# )

## ----eval = FALSE-------------------------------------------------------------
# plot_dgtf_lag(list(
#   DH = fit_DH,
#   DL = fit_DL
# ), xlim = 14)

## ----eval = FALSE-------------------------------------------------------------
# fc_DL <- dgtf_forecast_fit(fit_DL, h = 14, ypred_true = ytest)
# fc_AR <- dgtf_forecast_fit(fit_AR, h = 14, ypred_true = ytest)

## ----eval = FALSE-------------------------------------------------------------
# dgtf_compare(
#   list(
#     DH = fc_DH,
#     DL = fc_DL,
#     AR = fc_AR
#   )
# )

## ----eval = FALSE-------------------------------------------------------------
# fc_DH
# summary(fc_DH)
# plot_dgtf_y(fit_DH, fc_DH)

## ----eval = FALSE-------------------------------------------------------------
# fc_DL
# summary(fc_DL)
# plot_dgtf_y(fit_DL, fc_DL)

## ----eval = FALSE-------------------------------------------------------------
# fc_AR
# summary(fc_AR)
# plot_dgtf_y(fit_AR, fc_AR)

## ----eval = FALSE-------------------------------------------------------------
# dgtf_compare_plot(list(
#   DH = fc_DH,
#   DL = fc_DL,
#   AR = fc_AR
# ), what = "yhat")
# 
# fits_list <- list(
#   DH = fit_DH,
#   DL = fit_DL,
#   AR = fit_AR
# )
# 
# fcs_list <- list(
#   DH = fc_DH,
#   DL = fc_DL,
#   AR = fc_AR
# )
# 
# plot_dgtf_y_compare(fits_list, fcs_list)

