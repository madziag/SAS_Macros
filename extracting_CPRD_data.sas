DM "log; clear; ";

libname rdata 'F:\Users\Gamba003\CRPD_data\COPD_data\SAS_data';

%let max_add = 2;
%let max_clin = 7;
%let max_cons = 8;
%let max_pat = 1;
%let max_prc = 1;
%let max_tst = 9;
%let max_ther = 19;


%macro readdata;

* patient files;
filename patient (
					%do i = 1 %to &max_pat.; 
						%if &i. < 10 %then %do;
							"F:\Users\Gamba003\CRPD_data\COPD_data\1.Patient\copd_study_Extract_Patient_00&i..txt"
						%end;
						%else %do;
							"F:\Users\Gamba003\CRPD_data\COPD_data\1.Patient\copd_study_Extract_Patient_0&i..txt"
						%end;
					%end;
				  );

data rdata.patient;

	infile patient dsd dlm='09'x firstobs=2 truncover;

	input 
		patid     : BEST12.   vmid      : BEST12. gender    : BEST12.   yob       : BEST12. 
		mob       : BEST12.   marital   : BEST12. famnum    : BEST12.   chsreg    : BEST12. 
		chsdate   : ddmmyy10. prescr    : BEST12. capsup    : BEST12.   frd       : ddmmyy10. 
		crd       : ddmmyy10. regstat   : BEST12. reggap    : BEST12.   internal  : BEST12.  
		tod       : ddmmyy10. toreason  : BEST12. deathdate : ddmmyy10. accept    : BEST12. ;

	format chsdate ddmmyy10. frd ddmmyy10. crd ddmmyy10. tod ddmmyy10. deathdate ddmmyy10.;

run;

* practice files;
filename practice (
					%do i = 1 %to &max_prc.; 
						%if &i. < 10 %then %do;
							"F:\Users\Gamba003\CRPD_data\COPD_data\2.Practice\copd_study_Extract_Practice_00&i..txt"
						%end;
						%else %do;
							"F:\Users\Gamba003\CRPD_data\COPD_data\2.Practice\copd_study_Extract_Practice_0&i..txt"
						%end;
					%end;
				  );

data rdata.practice;

	infile practice dsd dlm='09'x firstobs=2 truncover;

	input 	
		pracid : BEST12. region : BEST12. lcd    : ddmmyy10. uts    : ddmmyy10.;

	format lcd ddmmyy10. uts ddmmyy10.;

run;

*consultation files;
filename consult (
					%do i = 1 %to &max_cons.; 
						%if &i. < 10 %then %do; 
							"F:\Users\Gamba003\CRPD_data\COPD_data\4.Consultation\copd_study_Extract_Consultation_00&i..txt"
						%end;
						%else %do; 
							"F:\Users\Gamba003\CRPD_data\COPD_data\4.Consultation\copd_study_Extract_Consultation_0&i..txt"
						%end;
					%end;
				  );

data rdata.consult;

	infile consult dsd dlm='09'x firstobs=2 truncover;

	input 
		patid     : BEST12. eventdate : ddmmyy10. sysdate   : ddmmyy10. constype  : BEST12. 
		consid    : BEST12. staffid   : BEST12.   duration  : BEST12.;

	format eventdate ddmmyy10. sysdate ddmmyy10.;

	if patid eq . then delete;

run;

*clinical files;
filename clinical (
					%do i = 1 %to &max_clin.; 
						%if &i. < 10 %then %do; 
							"F:\Users\Gamba003\CRPD_data\COPD_data\5.Clinical\copd_study_Extract_Clinical_00&i..txt"
						%end;
						%else %do; 
							"F:\Users\Gamba003\CRPD_data\COPD_data\5.Clinical\copd_study_Extract_Clinical_0&i..txt"
						%end;
					%end;
				  );

data rdata.clinical;

	infile clinical dsd dlm='09'x firstobs=2 truncover;

	input 
		patid     : BEST12. eventdate : ddmmyy10. sysdate   : ddmmyy10. constype  : BEST12. consid    : BEST12. 
	    medcode   : BEST12. staffid   : BEST12.	  episode   : BEST12.	enttype   : BEST12. adid      : BEST12. ;

	format eventdate ddmmyy10. sysdate ddmmyy10.;

	if patid eq . then delete;

run;

*additional files;
filename addit (
					%do i = 1 %to &max_add.; 
						%if &i. < 10 %then %do;
							"F:\Users\Gamba003\CRPD_data\COPD_data\6.Additional\copd_study_Extract_Additional_00&i..txt"
						%end;
						%else %do;
							"F:\Users\Gamba003\CRPD_data\COPD_data\6.Additional\copd_study_Extract_.Additional_0&i..txt"
						%end;
					%end;
				  );

data rdata.additional;

	infile addit dsd dlm='09'x firstobs=2 truncover;

	input 
		patid   : BEST12.  enttype : BEST12.  adid    : BEST12.  data1   : $CHAR10. data2   : $CHAR10. 
		data3   : $CHAR10. data4   : $CHAR10. data5   : $CHAR10. data6   : $CHAR10. data7   : $CHAR10.;

 	if patid eq . then delete;

run;

*test files;
filename test 	  (
					%do i = 1 %to &max_tst.; 
						%if &i. < 10 %then %do;
							"F:\Users\Gamba003\CRPD_data\COPD_data\9.Test\copd_study_Extract_Test_00&i..txt"
						%end;
						%else %do;
							"F:\Users\Gamba003\CRPD_data\COPD_data\9.Test\copd_study_Extract_Test_0&i..txt"
						%end;
					%end;
				  );
data rdata.test;

	infile test dsd dlm='09'x firstobs=2 truncover;

	input 
		patid     : BEST12.	 eventdate : ddmmyy10.	sysdate   : ddmmyy10. 	constype  : BEST12.  	consid    : BEST12.
		medcode   : BEST12.	 staffid   : BEST12.	enttype   : BEST12.		data1     : $CHAR10.	data2     : $CHAR10.
		data3     : $CHAR10. data4     : $CHAR10.  	data5     : $CHAR10.	data6     : $CHAR10.	data7     : $CHAR10.
		data8     : $CHAR10.;

	format eventdate ddmmyy10. sysdate ddmmyy10.;

	if patid eq . then delete;

run;

*therapy files;
filename ther  (
					%do i = 1 %to &max_ther.; 
						%if &i. < 10 %then %do;
							"F:\Users\Gamba003\CRPD_data\COPD_data\10.Therapy\copd_study_Extract_Therapy_00&i..txt"
						%end;
						%else %do;
							"F:\Users\Gamba003\CRPD_data\COPD_data\10.Therapy\copd_study_Extract_Therapy_0&i..txt"
						%end;
					%end;
				  );
data rdata.therapy;

	infile ther dsd dlm='09'x firstobs=2 truncover;

	input 
		patid     : BEST12. eventdate : ddmmyy10. sysdate   : ddmmyy10. consid    : BEST12. prodcode  : BEST12. 
		staffid   : BEST12. dosageid  : $64. 	  bnfcode   : BEST12. 	qty       : BEST12. numdays   : BEST12. 
		numpacks  : BEST12. packtype  : BEST12.   issueseq  : BEST12.;

 	format eventdate ddmmyy10. sysdate ddmmyy10.;

	if patid eq . then delete;

run;

%mend readdata;















