# functions for fitting logistic regression and summarize results

# returns a formula object for logistic regression
create_formula = function(outcome, variables) {
  return(as.formula(paste(outcome, paste(variables, collapse = " + "), sep = " ~ ")))
}

# fit a logistic regression for each specified outcome,
# returns a list of model objects;
# df: a data.frame object
# outcomes: a vector of outcome variables
# variables: a vector of covariates
fit_n_logistic = function(df, outcomes, variables) {
  mod_list = vector(mode="list", length=length(outcomes))
  for (i in 1:length(outcomes)) {
    outcome = outcomes[i]
    f = create_formula(outcome, variables)
    mod_list[[i]] = glm(f, data=df, family="binomial")
  }
  return(mod_list)
}

# calculate the odds ratios of each model,
# returns a data.frame object with odds ratios and CI
# mod_list: a list with model objects
calc_or = function(mod_list) {
  out_df = data.frame(row.names=rownames(summary(mod_list[[1]])$coefficients))
  for (mod in mod_list) {
    out_tmp = data.frame()
    for (x in rownames(summary(mod)$coefficients)) {
      ci = exp(summary(mod)$coefficients[x,1] + 
               qnorm(c(0.025,0.5,0.975))*summary(mod)$coefficients[x,2])
      ci = paste0(round(ci[2], 2), " (", round(ci[1], 2), ", ", round(ci[3], 2), ")")
      out_tmp = rbind(out_tmp, ci)
    }
    out_df = cbind(out_df, out_tmp)
  }
  return(out_df)
}

# main function:
# fit each logistic regression,
# calculate odds ratios for each model,
# returns a summarizing data.frame object
fit_result = function(df, outcomes, variables) {
  mod_list = fit_n_logistic(df, outcomes, variables)
  odds_ratios = calc_or(mod_list)
  colnames(odds_ratios) = outcomes
  return(odds_ratios)
}

# An example of how to use the fit_result function:
# outcomes = c("READMIT_30", "READMIT_90", "READMIT_180")
# variables = colnames(df_full)[c(5,6,7,8,10,12,13,14,15,16,17)]
# fit_result(df_full, outcomes, variables)
