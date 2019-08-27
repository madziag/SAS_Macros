%macro indicate_new_and_old_users (input, output, id, start_epi, rx_date, cohort_entry_date);

	data &output.; set &input.; by &id. &start_epi.;
		rx_year =  year(&rx_date.); rx_month = month(&rx_date.); rx_day = day(&rx_date.);
		if rx_month le 6 then part_year = 1; if rx_month gt 6 then part_year = 2; 
		if first.&id. then new_starter = 1; else new_starter = 0; 
		if (first.&id. or first.&start_epi.) and new_starter ne 1 then restarter = 1; else restarter = 0;
		if new_starter eq 1 or restarter eq 1 then new_user = 1; else new_user = 0; 
	run; 

	proc sql noprint; create table &output._1 as select *, count(&id.) as total from &output. group by &id., rx_year, part_year; quit;
	proc sql noprint; select max(total) into :max_total from &output._1; quit; %put &max_total;

	%let max_users = &max_total;
	%put new_user&max_users;
	
   	proc transpose data = &output._1 out = &output._1 (drop=_name_) prefix = new_user; by &id. rx_year part_year; var new_user; run;

	data &output._1 (drop = i new_user1 - new_user&max_users); set &output._1;
		array new_user (&max_total); old_users = 1;
		do i = 1 to dim(new_user) while (new_user(i) ne .); if new_user[i] = 1 then old_users = 0; end;
	run; 

	data &output. (drop = old_users);
		merge &output.  &output._1 ;
		by &id. rx_year part_year;
		if ((first.&id. or first.rx_year or first.part_year) and old_users eq 1) then old_user = 1; else old_user = 0;
		if end_episode le &cohort_entry_date. then delete;
		if &rx_date. ge &cohort_entry_date.;
   	run;

%mend indicate_new_and_old_users;

