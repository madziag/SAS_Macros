%macro tots_multiple_vars(data, var, out, by_vars);

proc sort data = &data. out = &out.; by = by_vars.; run;


%mend tots_multiple_vars;





