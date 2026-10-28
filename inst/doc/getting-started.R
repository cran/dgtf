## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE, comment = "#>", fig.width = 6,
  fig.height = 4
)

## ----compile-install-package, eval = FALSE------------------------------------
# # # Compile and install this package locally
# # Rcpp::compileAttributes()
# # devtools::document()
# # devtools::install(build_vignettes = TRUE)

## ----setup--------------------------------------------------------------------
library(dgtf)
library(ggplot2)

## ----build-model--------------------------------------------------------------
mod <- dgtf_model(
  obs         = obs_nbinom(),
  link        = link_identity(),
  sys         = sys_shift(),
  gain        = gain_softplus(),
  lag         = lag_lognormal(meanlog = 1.35, sigma2 = 0.32),
  err         = err_gaussian(W = 0.01),
  seasonality = seas_period(1, init = 2)
)
mod

## ----simulate-----------------------------------------------------------------
sim <- dgtf_simulate_model(mod, ntime = 210, seed = 3269)
ytrain <- c(sim$y)[1:200]
ytest <- c(sim$y)[201:210]
Rt_train <- c(sim$Rt)[1:200]
Rt_test <- c(sim$Rt)[201:210]

print(sim)
plot(sim, what = "y", split = 200)
plot(sim, what = "Rt", split = 200)

## ----prior--------------------------------------------------------------------
prior <- dgtf_prior(
  seasonality = normal(0, 10),
  W           = inv_gamma(1, 1),
  rho         = inv_gamma(1, 1),
  lag         = list(par1 = normal(0, 1), par2 = inv_gamma(1, 1))
)

## ----infer, eval = FALSE------------------------------------------------------
# set.seed(123)
# m0_init <- dgtf_hawkes(
#   meanlog     = runif(1, 1, 2),
#   sigma2      = runif(1, 0.1, 0.5),
#   W           = 1 / rgamma(1, 10, 1),
#   seasonality = seas_period(1, init = runif(1, 1, 10))
# )
# 
# fit <- dgtf(
#   y       = ytrain,
#   model   = m0_init,
#   prior   = prior,
#   method  = "hva",
#   control = vb_control(iter = 1000, n_sample = 5000, n_particle = 500)
# )
# summary(fit)

## ----recovery, eval = FALSE---------------------------------------------------
# truth_list <- list(W = 0.01, seas = 2, rho = 30, par1 = 1.35, par2 = 0.32)
# param_recovery(fit, truth_list)

## ----inspect-plots, eval = FALSE----------------------------------------------
# plot(fit, what = "marglik")
# plot(fit, what = "Rt", truth = Rt_train)
# plot(fit, what = "W")

## ----ppc-hva, eval = FALSE, fig.alt = "Posterior intensity vs simulated series"----
# attr(fit, "ppc") <- posterior_predict(fit, nrep = 100, Rt = Rt_train)
# plot(fit, what = "yhat", truth = ytrain)
# summary(attr(fit, "ppc"))

## ----forecast, eval = FALSE---------------------------------------------------
# fc <- dgtf_forecast_fit(fit, h = 10, ypred_true = ytest)
# plot_dgtf_y(fit, fc)
# plot(fc)
# summary(fc)

## ----switch-method, eval = FALSE----------------------------------------------
# set.seed(123)
# 
# fit_mcmc <- dgtf(
#   y       = ytrain,
#   model   = m0_init,
#   prior   = prior,
#   method  = "mcmc",
#   control = mcmc_control(iter = 5000, warmup = 2000, thin = 5)
# ) # takes 45 ~ 50 mins
# 
# summary(fit_mcmc)

## ----mcmc-diagnostics, eval = FALSE-------------------------------------------
# plot(fit_mcmc, what = "Rt", truth = Rt_train)
# 
# plot(fit_mcmc, what = "W", truth = 0.01, type = "trace")
# plot(fit_mcmc, what = "W", truth = 0.01, type = "hist")
# 
# plot(fit_mcmc, what = "seas", truth = 2, type = "trace")
# 
# plot(fit_mcmc, what = "par1", truth = 1.35, type = "trace")
# plot(fit_mcmc, what = "par2", truth = 0.32, type = "hist")

## ----ppc-mcmc, eval = FALSE, fig.alt = "Posterior intensity vs simulated series"----
# attr(fit_mcmc, "ppc") <- posterior_predict(fit_mcmc, nrep = 100, Rt = Rt_train)
# plot(fit_mcmc, what = "yhat", truth = ytrain)
# summary(attr(fit_mcmc, "ppc"))

## ----mcmc-forecast, eval = FALSE----------------------------------------------
# fc_mcmc <- dgtf_forecast_fit(fit_mcmc, h = 10, ypred_true = ytest)
# print(fc_mcmc)

## ----hva-mcmc-overlays, eval = FALSE------------------------------------------
# dgtf_compare_plot(
#   list(HVA = fit, MCMC = fit_mcmc),
#   what = "yhat"
# )
# 
# dgtf_compare_plot(
#   list(HVA = fit, MCMC = fit_mcmc, True = Rt_train),
#   what = "Rt"
# )
# 
# dgtf_compare_plot(
#   list(HVA = fit, MCMC = fit_mcmc, True = 2),
#   what = "seas"
# )
# 
# dgtf_compare_plot(
#   list(HVA = fit, MCMC = fit_mcmc, True = 0.01),
#   what = "W"
# )
# 
# dgtf_compare_plot(
#   list(HVA = fit, MCMC = fit_mcmc, True = 1.35),
#   what = "par1"
# )
# 
# dgtf_compare_plot(
#   list(HVA = fit, MCMC = fit_mcmc, True = 0.32),
#   what = "par2"
# )
# 
# dgtf_compare_plot(
#   list(HVA = fit, MCMC = fit_mcmc, True = 30),
#   what = "rho"
# )

## ----hva-mcmc-compare, eval = FALSE-------------------------------------------
# truth_list <- list(
#   W    = sim$model$err$params$var,
#   seas = sim$model$seasonality$init,
#   rho  = sim$model$obs_init[2],
#   par1 = sim$model$lag$params$par1,
#   par2 = sim$model$lag$params$par2
# )
# 
# dgtf_compare(list(HVA = fit, MCMC = fit_mcmc), truth = truth_list)

## ----hva-mcmc-params, eval = FALSE--------------------------------------------
# dgtf_compare_params(list(HVA = fit, MCMC = fit_mcmc), truth = truth_list)

## ----hva-mcmc-fc-compare, eval = FALSE----------------------------------------
# dgtf_compare(list(HVA = fc, MCMC = fc_mcmc))

## ----canonical, eval = FALSE--------------------------------------------------
# set.seed(123)
# 
# m1_fit <- dgtf(
#   y     = ytrain,
#   model = mod,
#   prior = dgtf_prior(
#     seasonality = normal(0, 10),
#     rho         = inv_gamma(1, 1),
#     lag         = list(par1 = normal(0, 1), par2 = inv_gamma(1, 1))
#   ),
#   method  = "hva",
#   control = vb_control(
#     iter            = 1000,
#     n_sample        = 5000,
#     n_particle      = 500,
#     use_discount    = TRUE,
#     discount_factor = 0.92
#   )
# )
# attr(m1_fit, "ppc") <- posterior_predict(m1_fit, nrep = 100, Rt = Rt_train)
# plot(m1_fit, what = "Rt", truth = Rt_train)
# m1_fc <- dgtf_forecast_fit(m1_fit, h = 10, ypred_true = ytest)
# 
# 
# m2_prior <- dgtf_prior(
#   seasonality = normal(0, 10),
#   W           = inv_gamma(1, 1),
#   rho         = inv_gamma(1, 1),
#   lag         = list(par1 = dist_beta(1, 1))
# )
# m2_init <- dgtf_distributed_lag(
#   r           = 4,
#   kappa       = 0.395,
#   seasonality = seas_period(1, init = runif(1, 0, 10))
# )
# m2_fit <- dgtf(
#   y       = ytrain,
#   model   = m2_init,
#   prior   = m2_prior,
#   method  = "hva",
#   control = vb_control(iter = 1000, n_sample = 5000, n_particle = 500)
# )
# attr(m2_fit, "ppc") <- posterior_predict(m2_fit, nrep = 100, Rt = Rt_train)
# m2_fc <- dgtf_forecast_fit(m2_fit, h = 10, ypred_true = ytest)
# 
# 
# set.seed(123)
# m3_prior <- dgtf_prior(
#   seasonality = normal(0, 10),
#   W           = inv_gamma(1, 1),
#   rho         = inv_gamma(1, 1)
# )
# m3_init <- dgtf_nb_ar(
#   p           = 3,
#   W           = 1 / rgamma(1, 10, 1),
#   seasonality = seas_period(1, init = runif(1, 0, 10))
# )
# m3_fit <- dgtf(
#   y       = ytrain,
#   model   = m3_init,
#   prior   = m3_prior,
#   method  = "hva",
#   control = vb_control(iter = 1000, n_sample = 5000, n_particle = 500)
# )
# attr(m3_fit, "ppc") <- posterior_predict(m3_fit, nrep = 100, Rt = Rt_train)
# m3_fc <- dgtf_forecast_fit(m3_fit, h = 10, ypred_true = ytest)
# 
# 
# set.seed(123)
# m4_prior <- dgtf_prior(
#   seasonality = normal(0, 10),
#   W           = inv_gamma(1, 1)
# )
# m4_init <- dgtf_poisson_ar(
#   p           = 5,
#   W           = 0.001,
#   seasonality = seas_period(1, init = runif(1, 0, 10))
# )
# m4_fit <- dgtf(
#   y       = ytrain,
#   model   = m4_init,
#   prior   = m4_prior,
#   method  = "hva",
#   control = vb_control(iter = 1000, n_sample = 5000, n_particle = 500)
# )
# attr(m4_fit, "ppc") <- posterior_predict(m4_fit, nrep = 100, Rt = Rt_train)

## ----compare-plots, eval = FALSE----------------------------------------------
# plot_dgtf_y(fit, fc)
# plot_dgtf_y(m1_fit, m1_fc)
# 
# dgtf_compare_plot(
#   list(M0 = fit, M1 = m1_fit, M2 = m2_fit, M3 = m3_fit, M4 = m4_fit,
#        True = ytrain),
#   what = "yhat"
# )
# 
# dgtf_compare_plot(
#   list(M0 = fit, M1 = m1_fit, M2 = m2_fit, True = Rt_train),
#   what = "Rt"
# )

## ----compare-scores, eval = FALSE---------------------------------------------
# dgtf_compare(list(M0 = fit, M1 = m1_fit, M2 = m2_fit, M3 = m3_fit, M4 = m4_fit),
#              Rt_truth = Rt_train)

## ----compare-params, eval = FALSE---------------------------------------------
# dgtf_compare_params(list(M0 = fit, M1 = m1_fit, M2 = m2_fit, M3 = m3_fit, M4 = m4_fit))

## ----compare-fc, eval = FALSE-------------------------------------------------
# dgtf_compare(list(M0 = fc, M1 = m1_fc, M2 = m2_fc, M3 = m3_fc))

## ----compare-fc-plot, eval = FALSE--------------------------------------------
# dgtf_compare_plot(
#   list(M0 = fc, M1 = m1_fc, M2 = m2_fc, M3 = m3_fc, True = ytest),
#   what = "yhat",
#   time = length(ytrain) + seq_len(fc$horizon)
# )
# 
# fits_list <- list(M0 = fit, M1 = m1_fit, M2 = m2_fit, M3 = m3_fit)
# fcs_list  <- list(M0 = fc,  M1 = m1_fc,  M2 = m2_fc,  M3 = m3_fc)
# 
# plot_dgtf_y_compare(fits_list, fcs_list)

## ----compare-lag, eval = FALSE------------------------------------------------
# plot_dgtf_lag(list(M0 = fit, M1 = m1_fit, M2 = m2_fit), xlim = 21)

## ----epiestim, eval = FALSE---------------------------------------------------
# # Serial interval mean / sd implied by the simulator's lognormal kernel
# # `lag_lognormal(meanlog = 1.35, sigma2 = 0.32)`:
# #   mean = exp(meanlog + sigma2 / 2)      ~= 4.53
# #   sd   = mean * sqrt(exp(sigma2) - 1)   ~= 2.78
# epi_baseline <- epiestim_baseline(
#   y       = ytrain,
#   mean_si = 4.53,
#   sd_si   = 2.78,
#   method  = "parametric_si",
#   window  = 7
# )
# epi_baseline

## ----epiestim-compare, eval = FALSE-------------------------------------------
# dgtf_compare_plot(
#   list(M0 = fit, EpiEstim = epi_baseline, True = Rt_train),
#   what = "Rt"
# )

