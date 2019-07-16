* Clears log;
/* 	Creates treatment episodes: Different ATCode, different ddd;

	Parameters: 
	input = data set that you want to create treatment episodes for.
	output = table where you would like to save your results; 
	id = column with patient ID
	rx_date = column with prescription date
	days_supply = column with the number of days worth of medication supply
	tx_window = column with treatment window
	cohort_start_date = start of cohort date
	ddd = defined daily dosage
	atc = atcode
	EFU = date of last record in Pharmo
	*/


DM "log; clear; ";

%macro tx_episodes_atc_ddd (input, output, id, rx_date, days_supply, tx_window, cohort_start_date, ddd, atc, EFU);
	
	* Sort data by id and rx date;
	proc sort data = &input.; by &id. &rx_date.; run;

	* Create transposed tables for rx date, nr. of supply days and comparison variable (ddd and/or atcode);
    proc transpose data = &input. out = &output._1 (drop=_name_) prefix = &rx_date.; by &id.; var &rx_date.; run;
    proc transpose data = &input. out = &output._2 (drop=_name_) prefix = &days_supply.; by &id.; var &days_supply.; run;
	proc transpose data = &input. out = &output._3a (drop=_name_) prefix = &ddd.; by &id.; var &ddd.; run;
	proc transpose data = &input. out = &output._3b (drop=_name_) prefix = &atc.; by &id.; var &atc.; run;

	* Calculate the number of observations per patient ID, get the highest of these numbers and assign it to a macro variable;
	* This value is used to set the max number of columns when creating an array;
	proc sql noprint; create table &output. as select *, count(&rx_date.) as total from &input. group by &id.; quit;
	proc sql noprint; select max(total) into :max_total from &output.; quit; %put &max_total;
	
	%let max_tots = &max_total;

	%put &rx_date.&max_tots; 
	%put &days_supply.&max_tots; 
	%put supply_end&max_tots; 
	%put remaining_meds&max_tots; 
	%put start_episode&max_tots; 
	%put &ddd.&max_tots.;
	%put &atc.&max_tots.;
	
	* Calculate start episodes;
	data &output. (drop = i); 

	* Merge the above transposed tables;
		merge &output._1 &output._2 &output._3a &output._3b; 
		by &id.;
		
	* Create arrays;
		array &rx_date. (&max_total.); 
		array &days_supply. (&max_total.); 
		array supply_end (&max_total.); 
		array remaining_meds (&max_total.); 
		array start_episode (&max_total.); 
		array &ddd. (&max_total.); 
		array &atc. (&max_total.); 
		array medication_switch(&max_total.);
		
	* Format dates to DDMMYY format;
		format &rx_date.1 - &rx_date.&max_tots supply_end1 - supply_end&max_tots start_episode1 - start_episode&max_tots ddmmyy10.;
		
	* Loop over the arrays to give end of supply date, adjusted remaining days and episode start date;
	* For the first rx date, start episode is set to prescription date and remaining meds are set to 0;
		do i = 1 to dim(&rx_date.) while (&rx_date.(i) ne .);
			if i eq 1 then 
				do;
					supply_end[i] = &rx_date.[i] + &days_supply.[i];
					remaining_meds[i] = 0;
					start_episode[i] = &rx_date.[i];
					medication_switch[i] = 0;
				end;

	* For the following rx dates -> first compare if there was a change in ddd or atc codes or both;
	* There is no change between consecutive medications prescribed ->  check the value of the remaining meds, set medication_switch variable to 0;
			if ((i gt 1) and ((&ddd.[i] eq &ddd.[i-1]) and (&atc.[i] eq &atc.[i-1]))) then 
				do;
					medication_switch[i] = 0;
					remaining_meds[i] = supply_end[i-1] - &rx_date.[i];

	* Remaining meds: lt -&tx_window. -> patient has not been covered by the medication for over &tx_window. days -> This rx is considered the start of a new episode;
					if remaining_meds[i] lt -&tx_window. then 
						do;
							start_episode[i] = &rx_date.[i];
							remaining_meds[i] = 0;
							supply_end[i] = &rx_date.[i] + &days_supply.[i] + remaining_meds[i];
						end;

	* Remaining meds: between -&tx_window. and 0 -> patient has been slacking on filling his rx but not enough to consider this a new treatment episode -> adjust remaining meds value to 0 as patient starts afresh with the new rx; 
					if (remaining_meds[i] ge - &tx_window. and remaining_meds[i] lt 0) then 
						do; 
							remaining_meds[i] = 0;
							supply_end[i] = &rx_date.[i] + &days_supply.[i] + remaining_meds[i];
						end;

	* Remaining meds: gt than 90 -> Patient is a hoarder, he keeps filling his rx too early -> he is allowed to hoard max 90 days worth of medication -> remaining meds value is capped at 90;
					if remaining_meds[i] gt 90 then 
						do;
							remaining_meds[i] = 90;
							supply_end[i] = &rx_date.[i] + &days_supply.[i] + remaining_meds[i];
						end;

	* Remaining meds: between 0 and 90 -> Patient is a semi-hoarder -> he fills his Rx early, but less than 90 days worth -> His end of supply date is prolonged by this number of days;
					if (remaining_meds[i] ge 0 and remaining_meds[i] le 90) then 
						do;
							supply_end[i] = &rx_date.[i] + &days_supply.[i] + remaining_meds[i];
						end;
				end;
		
	* There is a change (ddd/atc/both) between consecutive medications prescribed -> change in treatment, medication_switch variable is set to 1; 
			if ((i gt 1) and ((&ddd.[i] ne &ddd.[i-1]) or (&atc.[i] ne &atc.[i-1]))) then 
				do;
					remaining_meds[i] = supply_end[i-1] - &rx_date.[i];

	* Remaining meds: lt -&tx_window. -> yes there was a change in medication, but also patient has not treated in over tx_window days which means this is a new episode start;
					if remaining_meds[i] lt - &tx_window. then 
						do;
							start_episode[i] = &rx_date.[i];
							remaining_meds[i] = 0;
							supply_end[i] = &rx_date.[i] + &days_supply.[i] + remaining_meds[i];
							medication_switch[i] = 1;
						end;

	* Remaining meds: ge -&tx_window. -> patient has switched medications within the tx_window -> remaining meds gets reset to 0 because this is a new medication and we assume any left overs from the prior rx will be discarded -> treatment episode will continue as patient is still treating for the same thing;
					if remaining_meds[i] ge - &tx_window. then 
						do;
							remaining_meds[i] = 0;
							supply_end[i] = &rx_date.[i] + &days_supply.[i] + remaining_meds[i];
							medication_switch[i] = 1;
						end;	
				end;
		end;
	run;

	* Transpose the table back into long format;

	proc transpose data = &output. out = &output._4 (drop = _NAME_) prefix = &rx_date.; by &id.; var &rx_date.1 - &rx_date.&max_tots; run;
	proc transpose data = &output. out = &output._5a (drop = _NAME_) prefix = &ddd.; by &id.; var &ddd.1 - &ddd.&max_tots; run;
	proc transpose data = &output. out = &output._5b (drop = _NAME_) prefix = &atc.; by &id.; var &atc.1 - &atc.&max_tots; run;
	proc transpose data = &output. out = &output._6 (drop = _NAME_) prefix = medication_switch; by &id.; var medication_switch1 - medication_switch&max_tots; run;
	proc transpose data = &output. out = &output._7 (drop = _NAME_) prefix = supply_end; by &id.; var supply_end1 - supply_end&max_tots; run;
	proc transpose data = &output. out = &output._8 (drop = _NAME_) prefix = &days_supply.; by &id.; var &days_supply.1 - &days_supply.&max_tots; run;
	proc transpose data = &output. out = &output._9 (drop = _NAME_) prefix = remaining_meds; by &id.; var remaining_meds1 - remaining_meds&max_tots; run;
	proc transpose data = &output. out = &output._10 (drop = _NAME_) prefix = start_episode; by &id.; var start_episode1 - start_episode&max_tots; run;

	* Merge the individual transposed tables into one, rename variable to something other than variable1;
	data &output. (	drop = filledx 
					rename = (	&rx_date.1 = &rx_date. 
								supply_end1 = supply_end 
								&days_supply.1 = &days_supply. 
								remaining_meds1 = remaining_meds 
								start_episode1 = start_episode 
								medication_switch1 = medication_switch 
								&ddd.1 = &ddd.
								&atc.1 = &atc.));
		merge &output._4 &output._5a &output._5b &output._6 &output._7 &output._8 &output._9 &output._10; 
		by &id.;

	* Remove all blank rows created by the merge;
		if &days_supply.1 ne .; 

	* Fill in the start_episode values for all the rows -> copy value from above;
		retain filledx; 
		if not missing(start_episode1) then filledx = start_episode1; 
		start_episode1 = filledx; 
	run;

	* Sort table by id, start episode and supply end descending. The point of this is to have the last supply date as the first value;
	proc sort data = &output.; by &id. start_episode descending supply_end; run;

	* Fill in the end_episode values for all the rows using the last supply end for each patient and start episode date;
	data  &output. (drop = filledx); 
		set  &output.; 
		by &id. start_episode; 
		format end_episode ddmmyy10.;

		if first.&id. or first.start_episode then end_episode = supply_end; 
		retain filledx; 
		if not missing(end_episode) then filledx = end_episode; 
		end_episode = filledx; 
	run;

	* Sort table by patient ID, rx date and start episode date;
	proc sort data = &output.; by &id &rx_date. start_episode; run;

	* Merge original table with the episode dates table; 
	data &output. (drop = supply_end remaining_meds);
		merge &input. &output.; 
		by &id. &rx_date.; 
		format adj_start_episode ddmmyy10.;

	* If the end_episode date is gt than the last documented date of records (EFU) then change the end_episode date to EFU (right censoring); 
		if end_episode ge &EFU. then end_episode = &EFU.; 

	* If the start episode date is before the entry cohort date and the end episode date is after the entry cohort date then adjust start date to entry cohort date (left censoring);
		if (start_episode lt &cohort_start_date. and end_episode ge &cohort_start_date.) then
			do;	
				adj_start_episode = &cohort_start_date.; 
				cohort_start_date_as_SE = 1;
			end; 
		 else 
			do; 
				adj_start_episode = start_episode;
				cohort_start_date_as_SE = 1;
			end;
	run; 

%mend tx_episodes_atc_ddd;


