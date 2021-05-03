library(survival)
library(flexsurv)
library(xtable)

source('./scripts/clean.R')
source('./scripts/plot_zph.R')

s_df = with(df_full, Surv(TIME_TO_READMIT, READMITTED))
variables = colnames(df_full)[c(6,8,10,12,15,16,17,22,25,23,24)]
out = fit_coxph_result(df_full, "s_df", variables, "weibull")
out

# testing whether excluding missing observations change inferences
df_without_missing = subset(df_full, GLUCOSE_1_TESTED == 1 & A1C_1_TESTED == 1)
s_df = with(df_without_missing, Surv(TIME_TO_READMIT, READMITTED))
variables = colnames(df_without_missing)[c(6,8,10,12,15,16,17,22,25,23,24)]
out_tmp = fit_coxph_result(df_without_missing, "s_df", variables, "weibull")
out_tmp
