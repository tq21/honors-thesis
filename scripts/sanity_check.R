source('./scripts/clean.R')

n = nrow(df_clean)
# SUBJECT_ID
if (n == length(unique(df_clean$SUBJECT_ID))) {
  print("PASS")
} else {
  print("SUBJECT_ID HAS DUPLICATES")
}

# HADM_ID_1
if (n == length(unique(df_clean$HADM_ID_1))) {
  print("PASS")
} else {
  print("HADM_ID_1 HAS DUPLICATES")
}

# HADM_ID_2
if (n == length(unique(df_clean$HADM_ID_2))) {
  print("PASS")
} else {
  print("HADM_ID_2 HAS DUPLICATES")
}

# ADMIT_TIME, DISCH_TIME, READMIT_TIME
if (sum(df_clean$DISCH_TIME > df_clean$ADMIT_TIME) == n) {
  print("PASS")
} else {
  print("DISCH_TIME EARLIER THAN ADMIT_TIME")
}
if (sum(df_clean$DISCH_TIME < df_clean$READMIT_TIME) == n) {
  print("PASS")
} else {
  print("READMIT_TIME EARLIER THAN DISCH_TIME")
}
if (sum(df_clean$READMIT_TIME > df_clean$ADMIT_TIME) == n) {
  print("PASS")
} else {
  print("READMIT_TIME EARLIER THAN ADMIT_TIME")
}
