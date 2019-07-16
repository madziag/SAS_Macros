* Macro 1: 
* Function: 
* - Creates a subset of data, based on codes supplied in a second file (lookup file)
* Parameters: 
* - input: data to be subsetted
* - output: file you want to create
* - lookup_file: file with list of codes used to subset main dataset
* - ATC_colname_input: Column name with ATC codes in main dataset
* - ATC_colname_lookup: Column name with ATC codes in lookup file;
* - Timewindow: Column name with timewindow;

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

%mend create_subset;*/
