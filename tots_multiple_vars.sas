
%macro tots_multiple_vars(data, var, out, by_vars);

proc sort data = &data. ; by &by_vars.; run;

* Transposes one variable at a time;
	%macro makewide_basis(data, out, var, by_vars);
		* Transpose data;
		proc transpose 	data = &data. out = &out. (drop=_name_) prefix = &var.; by &by_vars.; var &var.; run;
		
		%let firstvar = %scan("&by_vars.", 1, " "); 
		%let secondvar = %scan("&by_vars.", 2, " "); 

		* Gets the number of transposed variable columns;
		proc sql noprint; create table tots_&data. as select *, count(&var.) as total from &data. group by &firstvar., &secondvar.; quit;
		proc sql noprint; select max(total) into :max_total from tots_&data.; quit; 
		
		%let max_tots = &max_total;

		* Calculates the sum of the variable values; 
		data &out.; set &out.; sum_&var. = sum(of &var.1-&var.&max_tots.); run; 

	%mend makewide_basis;

* calculate the number of variables;
%let c = 1; 
%do %while(%scan(&var, &c) NE); %let c = %eval(&c+1); %end; 
%let nvars=%eval(&c-1);

%if &nvars = 1 %then %do; %makewide_basis(data = &data., out = &out., var = &var., by_vars = &by_vars.) %end;
%else %do; 
		%do i = 1 %to &nvars; %makewide_basis(data = &data., out = _mw_tmp_&i, var = %scan(&var., &i), by_vars = &by_vars.) %end;	
		data &out. (keep = &by_vars. sum_:); merge %do i = 1 %to &nvars; _mw_tmp_&i. %end; ; by &by_vars.; run;
		%end;

%mend tots_multiple_vars;





