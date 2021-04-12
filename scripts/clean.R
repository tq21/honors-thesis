# readmitted patients (8143 entries after cleaning)
df_readmit = read.csv("./data/data_iv.csv", stringsAsFactors=FALSE)
# non-readmitted patients (9462 entries after cleaning)
df_full = read.csv("./data/data_iv_full.csv", stringsAsFactors=FALSE)

# full data, exclude death during first hospital stay
df_full = subset(df_full, DISCHARGE_LOCATION != 'DIED' & DISCHARGE_LOCATION != '')
df_full$DISCHARGE_LOCATION = as.factor(df_full$DISCHARGE_LOCATION)
df_readmit = subset(df_readmit, ADMISSION_TYPE_1 != 'AMBULATORY OBSERVATION')

# readmitted: convert to factors
df_readmit$GENDER = as.factor(df_readmit$GENDER)
df_readmit$ADMISSION_TYPE = as.factor(df_readmit$ADMISSION_TYPE_1)
df_readmit$ADMISSION_TYPE_2 = as.factor(df_readmit$ADMISSION_TYPE_2)
df_readmit$INSURANCE = as.factor(df_readmit$INSURANCE)
df_readmit$MARITAL_STATUS = as.factor(df_readmit$MARITAL_STATUS)
df_readmit$ETHNICITY = as.factor(df_readmit$ETHNICITY)
df_readmit$HYPERTENSION = as.factor(df_readmit$HYPERTENSION)
df_readmit$HYPERLIPIDEMIA = as.factor(df_readmit$HYPERLIPIDEMIA)
df_readmit$CKD = as.factor(df_readmit$CKD)

# readmitted: exclude death during first hospital stay
df_readmit = subset(df_readmit, DISCHARGE_LOCATION != 'DIED' & DISCHARGE_LOCATION != '')
df_readmit$DISCHARGE_LOCATION = as.factor(df_readmit$DISCHARGE_LOCATION)

# readmitted: time
df_readmit$ADMIT_TIME = as.POSIXct(df_readmit$ADMIT_TIME, tz="GMT", format="%Y-%m-%dT%H:%M:%S")
df_readmit$DISCH_TIME = as.POSIXct(df_readmit$DISCH_TIME, tz="GMT", format="%Y-%m-%dT%H:%M:%S")
df_readmit$READMIT_TIME = as.POSIXct(df_readmit$READMIT_TIME, tz="GMT", format="%Y-%m-%dT%H:%M:%S")
df_readmit = subset(df_readmit, READMIT_TIME > ADMIT_TIME & 
                                READMIT_TIME > DISCH_TIME &
                                DISCH_TIME > ADMIT_TIME)

# extract non-readmitted patients
df_noreadmit = subset(df_full, DISCH_TIME > ADMIT_TIME)
df_noreadmit = df_noreadmit[!df_noreadmit$SUBJECT_ID %in% df_readmit$SUBJECT_ID,]
df_noreadmit = subset(df_noreadmit, ADMISSION_TYPE != 'AMBULATORY OBSERVATION')

# non-readmitted: convert vars to factors
df_noreadmit$GENDER = as.factor(df_noreadmit$GENDER)
df_noreadmit$ADMISSION_TYPE = as.factor(df_noreadmit$ADMISSION_TYPE)
df_noreadmit$INSURANCE = as.factor(df_noreadmit$INSURANCE)
df_noreadmit$MARITAL_STATUS = as.factor(df_noreadmit$MARITAL_STATUS)
df_noreadmit$ETHNICITY = as.factor(df_noreadmit$ETHNICITY)
df_noreadmit$HYPERTENSION = as.factor(df_noreadmit$HYPERTENSION)
df_noreadmit$HYPERLIPIDEMIA = as.factor(df_noreadmit$HYPERLIPIDEMIA)
df_noreadmit$CKD = as.factor(df_noreadmit$CKD)

# 0 -> missing; 1 -> available
missing_val = function(df, col_name, new_col_name) {
  indicator = ifelse(sapply(df[, col_name], is.na), 0, 1)
  df[, new_col_name] = as.factor(indicator)
  return(df)
}

# readmitted: use indicator for missing vals of tests during first hospital stay
df_readmit = missing_val(df_readmit, 'GLUCOSE_1', 'GLUCOSE_1_TESTED')
df_readmit = missing_val(df_readmit, 'A1C_1', 'A1C_1_TESTED')
# non-readmitted: use indicator for missing vals of tests during first hospital stay
df_noreadmit = missing_val(df_noreadmit, 'GLUCOSE_1', 'GLUCOSE_1_TESTED')
df_noreadmit = missing_val(df_noreadmit, 'A1C_1', 'A1C_1_TESTED')
# full data: use indicator for missing vals of tests during first hospital stay
df_full = missing_val(df_full, 'GLUCOSE_1', 'GLUCOSE_1_TESTED')
df_full = missing_val(df_full, 'A1C_1', 'A1C_1_TESTED')

max_time = max(df_readmit$TIME_TO_READMIT)
df_noreadmit$TIME_TO_READMIT = rep(max_time, nrow(df_noreadmit))
df_full = rbind(df_readmit[, colnames(df_noreadmit)], df_noreadmit)

# full data:
# if readmitted: readmit = 1
# if not readmitted: readmit = 0
readmitted = ifelse(df_full[, 'SUBJECT_ID'] %in% df_readmit[, 'SUBJECT_ID'], 1, 0)
df_full[, 'READMITTED'] = readmitted

# standardize
length_of_stay_sd = round(sd(df_full$LENGTH_OF_STAY))
df_full$LENGTH_OF_STAY_ST = df_full$LENGTH_OF_STAY / length_of_stay_sd
glucose_sd = round(sd(na.omit(df_full$GLUCOSE_1)), 2)
df_full$GLUCOSE_1_ST = df_full$GLUCOSE_1 / glucose_sd
a1c_sd = round(sd(na.omit(df_full$A1C_1)), 2)
df_full$A1C_1_ST = df_full$A1C_1 / a1c_sd
df_full$AGE_ST = df_full$AGE / 10

# set factor levels
df_full$ETHNICITY = as.character(df_full$ETHNICITY)
df_full = subset(df_full, ETHNICITY != "UNKNOWN")
df_full$ETHNICITY = as.factor(df_full$ETHNICITY)
df_full$ETHNICITY = relevel(df_full$ETHNICITY, ref = "WHITE")
df_full$INSURANCE = relevel(df_full$INSURANCE, ref = "Medicare")
df_full$ADMISSION_TYPE = relevel(df_full$ADMISSION_TYPE, ref = "OBSERVATION ADMIT")

# readmitted
df_full[df_full$TIME_TO_READMIT == 0, "TIME_TO_READMIT"] = 1
