****************************************************************
****************************************************************
**************************** MACROS ****************************
****************************************************************
****************************************************************;

* Macro 1: 
* Function: 
* - Creates a subset of data, based on codes supplied in a second file (lookup file)
* Parameters: 
* - input: data to be subsetted
* - output: file you want to create
* - lookup_file: file with list of codes used to subset main dataset
* - ATC_colname_input: Column name with ATC codes in main dataset
* - ATC_colname_lookup: Column name with ATC codes in lookup file;

/*%macro create_subset(input, output, code_list, ATC_colname_input, ATC_colname_code_list);
	proc sql;
		create table &output. as
  			select A.*	
  			from &input. as A 
			inner join &code_list. as B 
			on prxmatch(cats('/^',B.&ATC_colname_code_list,'/i'),A.&ATC_colname_input) or
			prxmatch(cats('/^',A.&ATC_colname_input,'/i'),B.&ATC_colname_code_list);
            
	quit;
%mend create_subset;*/

*** ALTERNATIVE TO THE ABOVE USING HASHES;


%macro create_subset(input, output, code_list, ATC_colname_input, ATC_colname_code_list, ATC_TimeWindow);

	data &output.;

    	if _n_=1 then do;
  			if 0 then set &code_list.(rename=(&ATC_colname_code_list=_&ATC_colname_code_list));
			declare hash h(dataset:"&code_list.(rename=(&ATC_colname_code_list.=_&ATC_colname_code_list.))", multidata:'y');
			declare hiter hi('h');
  			h.definekey("_&ATC_colname_code_list");
  			h.definedata("_&ATC_colname_code_list","&ATC_TimeWindow");
            h.definedone();
            end;
    set &input.;

	do while(hi.next()=0);
	if &ATC_colname_input. =: strip(_&ATC_colname_code_list.) or _&ATC_colname_code_list. =: strip(&ATC_colname_input.) then output;
	end;
run;

%mend create_subset;

%create_subset(input=add_zindex1, output = vvv, code_list = LookUp, ATC_colname_input = ATC, ATC_colname_code_list = ATC, ATC_TimeWindow = TimeWindow);

* Macro 2:
* Function:
* - Creates columns of ATC codes in dataset
* - Assigns the value of 1 if the ATC code is found in the row of data;
* Parameters: 
* - input: subsetted data with ATcodes = output file from previous macro
* - ATC_code_colname: name of column with ATC codes
* - start_date: Initial date of treatment
* - index_date: start of use of drug 
* - timewindow: time frame used to determine cause-effect
* - To calculate ddd column, formula may change depending on the columns needed to calculate it. 
	- ddd 
	- perdag;

%macro create_cols(input, output, ATC_code_colname, start_date, index_date, timewindow, ddd, perdag);	
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
        			if &ATC_code_colname. = "&_v." and &start_date. ge &index_date. - &timewindow. and &start_date. < &index_date. then 
						do;
							&_v. = 1;
								if &ddd. > 0 then ddd_&_v. = (&ddd./1000)*(&perdag.);
								else ddd_&_v. = -9;
						end;
      				else 
						do;
							&_v. = 0;
							ddd_&_v. = 0;
		   				end;
      			end;
    	%end;
  	run;
%mend create_cols;



