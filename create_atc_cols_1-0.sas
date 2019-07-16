* Function:
* - Creates columns of ATC codes in dataset
* - Assigns the value of 1 if the ATC code is found in the row of data;
* Parameters: 
* - input: subsetted data with ATcodes = output file from previous macro
* - ATC_code_colname: name of column with ATC codes
* - start_date: Initial date of treatment
* - index_date: start of use of drug 
* - timewindow: time frame used to determine cause-effect;


%macro create_cols(input, output, ATC_code_colname, start_date, index_date, timewindow);	
	proc sql noprint;
    	select distinct &ATC_code_colname. into :mvals separated by '|'
    	from &input.;
    	%let mdim=&sqlobs;
    quit;

    data &output.;
    	set &input.;
    	%do _i=1 %to &mdim.;
      		%let _v = %scan(&mvals., &_i., |);
      		if VType(&ATC_code_colname)='C' then 
				do;
        			if &ATC_code_colname. = "&_v." and &start_date. ge &index_date. - &timewindow. and &start_date. < &index_date. then &_v. = 1;
					else &_v. = 0;
      			end;
    	%end;
  	run;
%mend create_cols;
