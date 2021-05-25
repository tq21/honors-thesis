source('./scripts/clean.R')
library(survival)

df_full_tmp = rbind(df_readmit[, colnames(df_noreadmit)], df_noreadmit)

## section 2.2: study population
nrow(df_full_tmp)
nrow(df_readmit)
nrow(df_noreadmit)
sum(df_full$GLUCOSE_1_TESTED == 0 | df_full$A1C_1_TESTED == 0)

## section 2.3: data pre-processing
# glucose tested
M <- as.table(cbind(summary(df_readmit$GLUCOSE_1_TESTED),
                    summary(df_noreadmit$GLUCOSE_1_TESTED)))
dimnames(M) <- list(a_type = levels(df_readmit$GLUCOSE_1_TESTED),
                    status = c('readmitted','non-readmitted'))
chisq.test(M)

# a1c tested
M <- as.table(cbind(summary(df_readmit$A1C_1_TESTED),
                    summary(df_noreadmit$A1C_1_TESTED)))
dimnames(M) <- list(a_type = levels(df_readmit$A1C_1_TESTED),
                    status = c('readmitted','non-readmitted'))
chisq.test(M)

## section 2.5: exploratory analysis
sum(df_full_tmp$GENDER == 'M')
sum(df_full_tmp$GENDER == 'F')

# chi-squared: gender
M <- as.table(cbind(summary(df_readmit$GENDER), summary(df_noreadmit$GENDER)))
dimnames(M) <- list(gender = c('F', 'M'),
                    status = c('readmitted','non-readmitted'))
chisq.test(M) # 0.0007818

# median age
median(df_readmit$AGE)
median(df_noreadmit$AGE)

# Medicaid/Medicare percentage
n_medicaid = sum(df_full_tmp$INSURANCE == 'Medicaid')
n_medicare = sum(df_full_tmp$INSURANCE == 'Medicare')
n_medicaid / 13085
n_medicare / 13085
nrow(subset(df_full_tmp, INSURANCE == 'Medicare' & AGE < 65)) /
  n_medicare
median(subset(df_full_tmp, INSURANCE == 'Medicaid')$AGE)

# t-test: age
t.test(subset(df_full_tmp, ETHNICITY == 'BLACK/AFRICAN AMERICAN')$AGE,
       subset(df_full_tmp, ETHNICITY == 'WHITE')$AGE) # < 2.2e-16

# t-test: length of stay
t.test(df_readmit$LENGTH_OF_STAY, df_noreadmit$LENGTH_OF_STAY) # 0.00713

# t-test: A1C
t.test(df_readmit$A1C_1, df_noreadmit$A1C_1) # < 2.2e-16

# t-test: glucose
t.test(df_readmit$GLUCOSE_1, df_noreadmit$GLUCOSE_1) # 0.125

# Wilcoxon signed-rank: glucose and A1C
wilcox.test(df_readmit$GLUCOSE_1, df_readmit$GLUCOSE_2) # 1.994e-06
wilcox.test(df_readmit$A1C_1, df_readmit$A1C_2) # < 2.2e-16

# median time-to-readmission
median(subset(df_readmit, GENDER == 'F')$TIME_TO_READMIT)
median(subset(df_readmit, GENDER == 'M')$TIME_TO_READMIT)

