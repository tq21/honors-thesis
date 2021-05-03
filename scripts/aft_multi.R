source('./scripts/clean.R')
source('./scripts/coxph_functions.R')

df_mod = data.frame(df_full$SUBJECT_ID)
df_mod$TIME_TO_READMIT = df_full$TIME_TO_READMIT
df_mod$READMITTED = df_full$READMITTED
df_mod$ADMISSION = ifelse(df_full$ADMISSION_TYPE == 'DIRECT EMER.' |
                          df_full$ADMISSION_TYPE == 'EW EMER.' |
                          df_full$ADMISSION_TYPE == 'URGENT',
                          1, 0)
df_mod$INSURANCE = ifelse(df_full$INSURANCE == 'Other', 0, 1)
df_mod$ETHNICITY_RISK = ifelse(df_full$ETHNICITY == 'AMERICAN INDIAN/ALASKA NATIVE' |
                               df_full$ETHNICITY == 'BLACK/AFRICAN AMERICAN' |
                               df_full$ETHNICITY == 'HISPANIC/LATINO',
                               1, 0)
df_mod$HTN = df_full$HYPERTENSION
df_mod$HLD = df_full$HYPERLIPIDEMIA
df_mod$CKD = df_full$CKD
df_mod$LOS = df_full$LENGTH_OF_STAY_ST
df_mod$SEX = df_full$GENDER
df_mod$A1C = df_full$A1C_1_ST
df_mod = na.omit(df_mod)

s_df = with(df_full, Surv(TIME_TO_READMIT, READMITTED))
var_names = colnames(df_full)[c(6,8,10,12,15,16,17,22,25,23,24)]
p_vals = rep(0, length(var_names))
for (i in 1:length(var_names)) {
  f = create_formula("s_df", var_names[i])
  fit = coxph(f, data=df_full)
  p_vals[i] = as.numeric(summary(fit)$waldtest["pvalue"])
}

p_val_df = data.frame(var_names, p_vals)
p_val_df[order(p_vals),]

# likelihood ratio test
# for cases where change in degrees of freedom is 1
lr_test = function(mod_1, mod_2) {
  1-pchisq(2*(mod_2$loglik-mod_1$loglik), df=1)
}

s_df = with(df_mod, Surv(TIME_TO_READMIT, READMITTED))
fit_1 = flexsurvreg(s_df ~ CKD, dist="weibull", data=df_mod)
fit_2 = flexsurvreg(s_df ~ CKD + A1C, dist="weibull", data=df_mod)
lr_test(fit_1, fit_2) # significant

fit_3 = flexsurvreg(s_df ~ CKD + A1C + LOS, dist="weibull", data=df_mod)
lr_test(fit_2, fit_3) # significant

fit_4 = flexsurvreg(s_df ~ CKD + A1C + LOS + ADMISSION, dist="weibull", data=df_mod)
lr_test(fit_3, fit_4) # significant

fit_5 = flexsurvreg(s_df ~ CKD + A1C + LOS + ADMISSION + ETHNICITY_RISK, dist="weibull", data=df_mod)
lr_test(fit_4, fit_5) # significant

fit_final = fit_5

var_names = c("CKD1", "A1C", "LOS", "ADMISSION", "ETHNICITY_RISK")
est = rep(0, length(var_names))
for (i in 1:length(var_names)) {
  aft_res = as.numeric(fit_final$res[var_names[i],])
  est[i] = paste0(round(exp(aft_res[1]), 2), " (", round(exp(aft_res[2]), 2), ", ", round(exp(aft_res[3]), 2), ")")
}

aft_multi_df = data.frame(var_names, est)
