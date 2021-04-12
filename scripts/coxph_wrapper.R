library(survival)
library(flexsurv)

create_formula = function(surv_obj, variable) {
  return(as.formula(paste(surv_obj, " ~ ", variable)))
}

fit_n_coxph = function(df, surv_obj, variables) {
  mod_list = vector(mode="list", length=length(variables))
  for (i in 1:length(variables)) {
    variable = variables[i]
    f = create_formula(surv_obj, variable)
    mod_list[[i]] = coxph(f, data=df)
  }
  return(mod_list)
}

fit_n_aft = function(df, surv_obj, variables, dist) {
  mod_list = vector(mode="list", length=length(variables))
  for (i in 1:length(variables)) {
    variable = variables[i]
    f = create_formula(surv_obj, variable)
    mod_list[[i]] = flexsurvreg(f, dist=dist, data=df)
  }
  return(mod_list)
}

calc_haz = function(mod_list_cox, mod_list_aft) {
  out_df = data.frame()
  for (i in 1:length(mod_list_cox)) {
    mod_cox = mod_list_cox[[i]]
    mod_aft = mod_list_aft[[i]]
    sum_tab_cox = summary(mod_cox)$conf.int
    sum_tab_aft = mod_aft$res
    out_tmp = data.frame()
    for (j in 1:nrow(sum_tab_cox)) {
      hr = sum_tab_cox[j,1]
      ci_cox = c(sum_tab_cox[j,3], sum_tab_cox[j,4])
      ci_cox = paste0(round(hr, 2), " (", round(ci_cox[1], 2), ", ", round(ci_cox[2], 2), ")")
      var_name = rownames(sum_tab_cox)[j]
      aft_res = as.numeric(sum_tab_aft[var_name,])
      ci_aft = paste0(round(exp(aft_res[1]), 2), " (", round(exp(aft_res[2]), 2), ", ", round(exp(aft_res[3]), 2), ")")
      ci = c(var_name, ci_cox, ci_aft)
      out_tmp = rbind(out_tmp, ci)
      colnames(out_tmp) = c("Covariate", "Hazard Ratios", "Median Reamit Time Ratios")
    }
    out_df = rbind(out_df, out_tmp)
  }
  return(out_df)
}

fit_coxph_result = function(df, surv_obj, variables, dist) {
  mod_list_cox = fit_n_coxph(df, surv_obj, variables)
  mod_list_aft = fit_n_aft(df, surv_obj, variables, dist)
  haz_ratios = calc_haz(mod_list_cox, mod_list_aft)
  return(haz_ratios)
}




