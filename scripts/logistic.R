source("./scripts/clean.R")
source("./scripts/logistic_functions.R")

# create readmission indicators
df_reg = df_full
df_reg$READMIT_30 = ifelse(df_reg$TIME_TO_READMIT <= 30, 1, 0)
df_reg$READMIT_90 = ifelse(df_reg$TIME_TO_READMIT <= 90 & 
                              df_reg$TIME_TO_READMIT > 30, 1, 0)
df_reg$READMIT_180 = ifelse(df_reg$TIME_TO_READMIT <= 180 & 
                               df_reg$TIME_TO_READMIT > 90, 1, 0)
df_reg$READMIT_above_180 = ifelse(df_reg$TIME_TO_READMIT > 180, 1, 0)

# logistic regression model fitting
outcomes = c("READMIT_30", "READMIT_90", "READMIT_180")
variables = colnames(df_reg)[c(6,8,10,12,15,16,17,22,23,24,25)]
out = fit_result(df_reg, outcomes, variables)
out
