* *** Based on the paper The validity of the Rx-Risk Comorbidity Index using medicines mapped to the Anatomical Therapeutic Chemical (ATC) Classification System; 
* *** (Nicole L Pratt, Mhairi Kerr, John D Barratt, Anna Kemp-Casey, Lisa M Kalisch Ellett, Emmae Ramsay, Elizabeth Ellen Roughead);
* *** Table 1;

* 1. Data Prep -> transoposed data set -- each patient row lists all the ATC codes for that patient
* 2. Checks if patient has the diagnosis based on each risk category (v1-v46) 
* 3. Adds up the points for each patient to give rx risk score
* *** Weights are NOT used for the score!
* *** PBS item codes are not taken into account!
;


libname RiskCalc 'f:\Exchange\Magda';

*************************************************************
*************************************************************
**************************DATA PREP**************************
*************************************************************
*************************************************************;

* Sort both datasets; 
	
	proc sort data = RiskCalc.Cc_set_feb2015_controles;
		by CPB_PID;
	run;
	proc sort data = RiskCalc.Rx_controls_cc_set_mrt2013;
		by CPB_PID;
	run;

* Merge datasets;
* Remove rows with missing data (RADATUM = index date, OAPO_AFLDA = rx date, ATCODE = ATC code);
* Filters for complete ATC codes; 
* Filter data: index date to be with 1 year of rx date and not after rx_date;

	data join_ds (keep = CPB_PID ATCODE OAPO_AFLDA GESLACHT RADATUM);
		merge RiskCalc.Rx_controls_cc_set_mrt2013(in = ina) RiskCalc.Cc_set_feb2015_controles (in = inb) ;
		by CPB_PID;
		if ina and inb;
	run;

	data join_ds_a;
		set join_ds;
		if RADATUM ne . ;
                if OAPO_AFLDA ne .;
		where prxmatch("/\w\d\d\w\w\d\d/", ATCODE);
		ATCODE = upcase(ATCODE);
		if OAPO_AFLDA ge RADATUM - 365;
                if OAPO_AFLDA ng RADATUM;
 	run; 

        proc transpose data=join_ds_a out=join_ds_a_trans prefix=atcode;
                by cpb_pid geslacht;
                var atcode;
        run;

***********************************************************************************
***********************************************************************************
*****CHECKS IF PATIENT HAS ATC CODE IN EACH OF THE RISK COMORBIDITY CATEGORIES*****
***********************************************************************************
***********************************************************************************;

   data diagnosis_0_or_1;
  	set join_ds_a_trans;
    	array AllDiagCodes {764} $ atcode1 - atcode764;
    	v1 = 0; v2 = 0; v3 = 0; v4 = 0; v5 = 0; v6 = 0; v7 = 0; v8 = 0; v9 = 0; v10 = 0; 
    	v11 = 0; v12 = 0; v13 = 0; v14 = 0; v15 = 0; v16 = 0; v17 = 0; v18 = 0; v19 = 0; v20 = 0;
    	v21 = 0; v22 = 0; v23 = 0; v24 = 0; v25 = 0; v26 = 0; v27 = 0; v28 = 0; v29 = 0; v30 = 0;
    	v31 = 0; v32 = 0; v33 = 0; v34 = 0; v35 = 0; v36 = 0; v37 = 0; v38 = 0; v39 = 0; v40 = 0;
        v41 = 0; v42 = 0; v43 = 0; v44 = 0; v45 = 0; v46 = 0; 
    
    do i = 1 to 764;
    
* 1. Alcohol dependency; 
*    ATC codes: N07BB01-N07BB99; 

     if   substr(AllDiagCodes{i},1,5) = 'N07BB' then v1 = 1;

* 2. Allergies; 
*    ATC codes: R01AC01-R01AD60, R06AD02-R06AX27, R06AB04;
	 
     if   substr(AllDiagCodes{i},1,5) = 'R01AC'  or 
          substr(AllDiagCodes{i},1,5) = 'R01AD'  or 
        ((substr(AllDiagCodes{i},1,5) = 'R06AD') and (AllDiagCodes{i} ne 'R06AD01')) or
          substr(AllDiagCodes{i},1,5) = 'R06AE'  or 
 	  substr(AllDiagCodes{i},1,5) = 'R06AK'  or
          substr(AllDiagCodes{i},1,6) = 'R06AX0' or 
          substr(AllDiagCodes{i},1,6) = 'R06AX1' or
	 (substr(AllDiagCodes{i},1,6) = 'R06AX2' and (AllDiagCodes{i} not in ('R06AX28', 'R06AX29'))) or
	  AllDiagCodes{i} = 'R06AB04' then v2 = 1;

* 3. Anticoagulants;
*    ATC codes: B01AA03-B01AB06, B01AE07, B01AF01, B01AF02, B01AX05;

     if  (substr(AllDiagCodes{i},1,5) = 'B01AA' and (AllDiagCodes{i} not in ('B01AA01', 'B01AA02'))) or
	 (substr(AllDiagCodes{i},1,6) = 'B01AB0' and (AllDiagCodes{i} not in ('B01AB07', 'B01AB08', 'B01AB09'))) or
          AllDiagCodes{i} in ('B01AE07', 'B01AF01', 'B01AF02', 'B01AX05') then v3 = 1;
          
* 4. Antiplatelets;
*    ATC codes: B01AC04-B01AC30;
     
     if  (substr(AllDiagCodes{i},1,5) = 'B01AC' and (AllDiagCodes{i} not in ('B01AC01', 'B01AC02', 'B01AC03', 'B01AC56'))) then v4 = 1;
     
* 5. Anxiety; 
*    ATC codes: N05BA01-N05BA12, N05BE01;

	   if   substr(AllDiagCodes{i},1,6) = 'N05BA0' or
	        AllDiagCodes{i} in ('N05BA10', 'N05BA11', 'N05BA12', 'N05BE01') then v5 = 1;
	        
* 6. Arrhythmia;
*    ATC codes:  C01AA05, C01BA01-C01BD01, C07AA07;

	   if   substr(AllDiagCodes{i},1,5) = 'C01BA' or
	        substr(AllDiagCodes{i},1,5) = 'C01BC' or
	        AllDiagCodes{i} in ('C01AA05', 'C01BD01', 'C07AA07') then v6 = 1;	
	        
* 7. Benign Prostatic Hyperplasia;
*    ATC codes: G04CB01, G04CB02;
*    Patient must be male;

	   if   substr(AllDiagCodes{i},1,5) = 'G04CA' or
		AllDiagCodes{i} = 'G04CB01' or 
	       (AllDiagCodes{i} = 'G04CB02' and Geslacht eq 'M') then v7 = 1;
	       
* 8. Bipolar Disorder; 
*    ATC codes: N05AN01;

	   if   AllDiagCodes{i} = 'N05AN01' then v8 = 1;
	   
* 9. Chronic Airways Disease;
*    ATC codes: R03AC02-R03DC03, R03DX05;

  	 if   substr(AllDiagCodes{i},1,5) = 'R03AC' or
	      substr(AllDiagCodes{i},1,5) = 'R03AH' or
	      substr(AllDiagCodes{i},1,5) = 'R03AK' or
              substr(AllDiagCodes{i},1,5) = 'R03AL' or
      	      substr(AllDiagCodes{i},1,4) = 'R03B'  or
              substr(AllDiagCodes{i},1,4) = 'R03C'  or
              substr(AllDiagCodes{i},1,5) = 'R03DA' or
              substr(AllDiagCodes{i},1,5) = 'R03DB' or
              AllDiagCodes{i} in ('R03DC01', 'R03DC02', 'R03DC03', 'R03DX05') then v9 = 1;	
          
* 10. Congestive Heart Failure;
*     ATC codes: C03DA02-C03DA99, C07AB02-if PBS ITEM CODE IS 8732N, 8733P, 8734Q, 8735R, C07AB07, C07AG02, C07AB12;
*     *** PBS item codes not taken into account;
*     C03CA01-C03CC01) and (C09AA01-C09AX99, C09CA01-C09CX99);

	    if  (substr(AllDiagCodes{i},1,5) = 'C03DA' and AllDiagCodes{i} ne 'C03DA01') or 
	         AllDiagCodes{i} in ('C07AB02', 'C07AB07', 'C07AG02', 'C07AB12', 'C03DA04') then v10 = 1;
	    if   substr(AllDiagCodes{i},1,5) = 'C03CA' or
	         substr(AllDiagCodes{i},1,5) = 'C03CB' or
                 AllDiagCodes{i} = 'C03CC01' then v10a = 1;
            
* Must have at least 2 medicines prescribed with one of those medicines having an ATC code from C03CA01 - C03CC01
* and the other having ATC code from either C09AA01-C09AX99 OR C09CA01-C09CX99;
	    if   substr(AllDiagCodes{i},1,4) = 'C09A' or
	         substr(AllDiagCodes{i},1,4) = 'C09C' then v10b = 1; 
	    if   v10a = 1 and v10b = 1 then v10 = 1;

* 11. Dementia; 
*     ATC codes: N06DA02-N06DA04, N06DX01;

  	  if AllDiagCodes{i} in ('N06DA02', 'N06DA03', 'N06DA04', 'N06DX01') then v11 = 1;
  	  
* 12. Depression; 
*     ATC codes: N06AA01-N06AG02, N06AX03-N06AX11, N06AX13-N06AX18, N06AX21-N06AX26;

	    if   substr(AllDiagCodes{i},1,5) = 'N06AA' or
	         substr(AllDiagCodes{i},1,5) = 'N06AB' or
	         substr(AllDiagCodes{i},1,5) = 'N06AF' or
	       	(substr(AllDiagCodes{i},1,6) = 'N06AX0' and (AllDiagCodes{i} not in ('N06AX01', 'N06AX02'))) or
	        (substr(AllDiagCodes{i},1,6) = 'N06AX1' and (AllDiagCodes{i} not in ('N06AX12', 'N06AX19'))) or
	        (substr(AllDiagCodes{i},1,6) = 'N06AX2' and (AllDiagCodes{i} not in ('N06AX27', 'N06AX28', 'N06AX29'))) or
                 AllDiagCodes{i} = 'C03CC01' then v12 = 1; 

* 13. Diabetes;
*     ATC codes: A10AA01-A10BX99;

   	  if   substr(AllDiagCodes{i},1,4) = 'A10A' or
	       substr(AllDiagCodes{i},1,4) = 'A10B' then v13 = 1;
	         
* 14. Epilepsy;
*     ATC codes: N03AA01-N03AX99;
	    
	    if   substr(AllDiagCodes{i},1,4) = 'N03A' then v14 = 1;

* 15. Glaucoma;
*     ATC codes: S01EA01-S01EB03, S01EC03-S01EX99;
  
	    if   substr(AllDiagCodes{i},1,5) = 'S01EA' or 
                 AllDiagCodes{i} in ('S01EB01, S01EB02', 'S01EB03') or 
                (substr(AllDiagCodes{i},1,5) = 'S01EC' and (AllDiagCodes{i} not in ('S01EC01', 'S01EC02'))) or                   
                 substr(AllDiagCodes{i},1,5) = 'S01ED' or 
                 substr(AllDiagCodes{i},1,5) = 'S01EE' or 
                 substr(AllDiagCodes{i},1,5) = 'S01EX' then v15 = 1;
		       
* 16. Gastrooesophageal Reflux Disease; 
*     ATC codes: A02BA01-A02BX05;
	    if   substr(AllDiagCodes{i},1,5) = 'A02BA' or 
	         substr(AllDiagCodes{i},1,5) = 'A02BB' or 
                 substr(AllDiagCodes{i},1,5) = 'A02BC' or 
                 substr(AllDiagCodes{i},1,5) = 'A02BD' or
                 AllDiagCodes{i} in ('A02BX01', 'A02BX02', 'A02BX03','A02BX04','A02BX05') then v16 = 1;
            
* 17. Gout;
*     ATC codes: M04AA01-M04AC01;
      
            if   substr(AllDiagCodes{i},1,5) = 'M04AA' or 
	         substr(AllDiagCodes{i},1,5) = 'M04AB' or
                 AllDiagCodes{i} = 'M04AC01' then v17 = 1;

* 18. Hepatitis B;
*     ATC codes: J05AF08, J05AF10, J05AF11;
	    
	    if   AllDiagCodes{i} in ('J05AF08', 'J05AF10', 'J05AF11') then v18 = 1;
	     
* 19. Hepatitis C; 
*     ATC codes: J05AB54, L03AB10, L03AB11, L03AB60, L03AB61, J05AE14, J05AE11-J05AE12, J05AX14, J05AX15, J05AX65, J05AB04;
	   
	   if   AllDiagCodes{i} in ('J05AB54', 'L03AB10', 'L03AB11', 'L03AB60', 'L03AB61', 'J05AE14', 'J05AE11', 'J05AE12', 'J05AX14', 'J05AX15', 'J05AX65', 'J05AB04') then v19 = 1; 	

* 20. HIV: 
*     ATC codes: J05AE01-J05AE10, J05AF12-J05AG05, J05AR01-J05AR99, J05AX07-J05AX09, J05AX12, J05AF01-J05AF07, J05AF09;

  	  if   substr(AllDiagCodes{i},1,5) = 'J05AE' or 
	       substr(AllDiagCodes{i},1,5) = 'J05AG' or 
               substr(AllDiagCodes{i},1,5) = 'J05AR' or 
              (substr(AllDiagCodes{i},1,6) = 'J05AF0' and AllDiagCodes{i} ne 'J05AF08')  or
                AllDiagCodes{i} in ('J05AF12', 'J05AF13', 'J05AX07', 'J05AX08', 'J05AX09', 'J05AX12') then v20 = 1; 

* 21. Hyperkalaemia 
*     ATC codes: V03AE01;
      if   AllDiagCodes{i}= 'V03AE01' then v21 = 1;

* 22. Hyperlipidaemia;
*     ATC codes: A10BH03, C10AA01-C10BX09;
  	  if   substr(AllDiagCodes{i},1,5) = 'C10AA'  or 
               substr(AllDiagCodes{i},1,5) = 'C10BA'  or 
               substr(AllDiagCodes{i},1,6) = 'C10BX0' or  
               AllDiagCodes{i} = 'A10BH03' then v22 = 1;

* 23. Hypertension;
*     ATC codes: C03AA01-C03BA11, C03DB01, C03DB99, C03EA01, C09BA02-C09BA09, C09DA02-C09DA08, C02AB01-C02AC05, C02DB02-C02DB99, (C03CA01-C03CC01 or C09CA01-C09CX99);
 
          if   substr(AllDiagCodes{i},1,4) = 'C03A'   or 
               substr(AllDiagCodes{i},1,6) = 'C03BA0' or 
              (substr(AllDiagCodes{i},1,6) = 'C09BA0' and AllDiagCodes{i} ne 'C09BA01') or   
	      (substr(AllDiagCodes{i},1,6) = 'C09DA0' and AllDiagCodes{i} not in ('C09DA01', 'C09DA09')) or 
               substr(AllDiagCodes{i},1,5) = 'C02AB'  or
	      (substr(AllDiagCodes{i},1,6) = 'C02AC0' and AllDiagCodes{i} ne 'C02AC06') or
       	      (substr(AllDiagCodes{i},1,5) = 'C02DB' and AllDiagCodes{i} ne 'C02DB01') or
	       AllDiagCodes{i} in ('C03BA10', 'C03BA11', 'C03DB01', 'C03DB99', 'C03EA01', 'C03CC01') or
               substr(AllDiagCodes{i},1,5) = 'C03CA'  or
               substr(AllDiagCodes{i},1,5) = 'C03CB'  or
     	       substr(AllDiagCodes{i},1,4) = 'C09C' then v23 = 1;
* Can have medicine dispensed with an ATC code C03CA01-C03CC01 or C09AA01-CO9AX99, but not both 
* as this would indicate chronic heart failure;
          if   substr(AllDiagCodes{i},1,5) = 'C03CA' or
               substr(AllDiagCodes{i},1,5) = 'C03CB' or
	       AllDiagCodes{i} = 'C03CC01' then v23a = 1;
          if   substr(AllDiagCodes{i},1,4) = 'C09A' then v23b = 1;
          if   v23a = 1 and v23 = 1 then v23 = 0;

* 24. Hyperthyroidism; 
*     ATC codes: H03BA02, H03BB01;
          if   AllDiagCodes{i} in ('H03BA02', 'H03BB01') then v24 = 1;

* 25. Hypothyroidism; 
*     ATC codes: H03AA01-H03AA02;

  	  if   AllDiagCodes{i} in ('H03AA01', 'H03AA02') then v25 = 1;

* 26. Irritable Bowel Syndrome; 
*     ATC codes: A07EC01A07EC04, A07EA01A07EA02, A07EA06, L04AA33;

  	  if   AllDiagCodes{i} in ('A07EC01', 'A07EC02', 'A07EC03', 'A07EC04', 'A07EA01', 'A07EA02', 'A07EA06', 'L04AA33') then v26 = 1;

* 27. Ischaemic Heart Disease, Angina; 
*     ATC codes: C01DA02C01DA14, C01DX16, C08EX02;
 
   	  if   substr(AllDiagCodes{i},1,6) = 'C01DA0' or
               AllDiagCodes{i} in ('C01DA11', 'C01DA12', 'C01DA13', 'C01DA14', 'C01DX16', 'C08EX02') then v27 = 1;

* 28. Ischaemic Heart Disease, Hypertension; 
*     ATC codes: C07AA01C07AA06, C07AA08C07AB01, C07AB02if PBS item code is not 8732N, 8733P, 8734Q, 8735R, C07AB03, C07AG01, C08CA01C08DB01, C09DB01C09DB04, C09DX01, C09BB02C09BB10, C09DX03, C10BX03;
*     *** PBS item codes not taken into account;

          if  (substr(AllDiagCodes{i},1,5) = 'C07AA' and AllDiagCodes{i} ne 'C07AA07') or  	
	       substr(AllDiagCodes{i},1,5) = 'C08CA'  or
               substr(AllDiagCodes{i},1,5) = 'C08CX'  or
	       substr(AllDiagCodes{i},1,4) = 'C08D'   or
	       substr(AllDiagCodes{i},1,6) = 'C09BB0' or
               AllDiagCodes{i} in ('C07AB01', 'C07AB02', 'C07AB03', 'C07AG01', 'C09BB10', 'C09DB01', 'C09DB02', 'C09DB04', 'C09DX01', 'C09DX03', 'C10BX03') then v28 = 1;

* 29. Incontinence; 
*     ATC codes: G04BD01G04BD99;

  	  if   substr(AllDiagCodes{i},1,6) = 'G04BD0' then v29 = 1; 

* 30. Inflammation/pain;
*     ATC codes: M01AB01M01AH06;
	  
	    if   substr(AllDiagCodes{i},1,5) = 'M01AB' or 
                 substr(AllDiagCodes{i},1,5) = 'M01AC' or 
                 substr(AllDiagCodes{i},1,5) = 'M01AE' or 
	         substr(AllDiagCodes{i},1,5) = 'M01AG' or 
                (substr(AllDiagCodes{i},1,6) = 'M01AH0' and AllDiagCodes{i} not in ('M01AH07', 'M01AH08', 'M01AH09')) then v30 = 1;
		      
* 31. Liver Failure; 
*     ATC codes: A06AD11, A07AA11;
      
           if   AllDiagCodes{i} in ('A06AD11', 'A07AA11') then v31 = 1;		

* 32. Malignancies;
*     ATC codes: L01AA01L01XX41;
	
	    if   substr(AllDiagCodes{i},1,4) = 'L01A'   or  	
        	 substr(AllDiagCodes{i},1,4) = 'L01B'   or
                 substr(AllDiagCodes{i},1,4) = 'L01C'   or
                 substr(AllDiagCodes{i},1,4) = 'L01D'   or
                 substr(AllDiagCodes{i},1,5) = 'L01XA'  or
                 substr(AllDiagCodes{i},1,5) = 'L01XB'  or  	
   	         substr(AllDiagCodes{i},1,5) = 'L01XC'  or
                 substr(AllDiagCodes{i},1,5) = 'L01XD'  or
	         substr(AllDiagCodes{i},1,5) = 'L01XE'  or
                 substr(AllDiagCodes{i},1,6) = 'L01XX0' or
	         substr(AllDiagCodes{i},1,6) = 'L01XX1' or
	         substr(AllDiagCodes{i},1,6) = 'L01XX2' or
	         substr(AllDiagCodes{i},1,6) = 'L01XX3' or
	         AllDiagCodes{i} in ('L01XX40', 'L01XX41') then v32 = 1;	
		       
* 33. Malnutrition; 
*     ATC codes:B05BA01B05BA10;
	  
	    if   substr(AllDiagCodes{i},1,5) = 'B05BA' then v33 = 1; 
	    
* 34. Migrane: 
*     ATC codes: N02CA01N02CX01;
      
            if   substr(AllDiagCodes{i},1,5) = 'N02CA' or  	
                 substr(AllDiagCodes{i},1,5) = 'N02CB' or
   	         substr(AllDiagCodes{i},1,5) = 'N02CC' or
	         AllDiagCodes{i}= 'N02CX01' then v34 = 1;	
	         
* 35. Osteoporosis/Pagets;
*     ATC codes: M05BA01M05BB05, M05BX03, M05BX04, G03XC01, H05AA02;

            if   substr(AllDiagCodes{i},1,5) = 'M05BA' or  	
		 AllDiagCodes{i} in ('M05BB01', 'M05BB02', 'M05BB03', 'M05BB04', 'M05BB05', 'M05BX03', 'M05BX04', 'G03XC01', 'H05AA02') then v35 = 1;	
		  
* 36. Pain; 
*     ATC codes: N02AA01N02AX02, N02AX06, N02AX52, N02BE51;
	  
	    if   substr(AllDiagCodes{i},1,5) = 'N02AA' or  	
		 substr(AllDiagCodes{i},1,5) = 'N02AB' or
	         substr(AllDiagCodes{i},1,5) = 'N02AC' or
	         substr(AllDiagCodes{i},1,5) = 'N02AD' or
     	  	 substr(AllDiagCodes{i},1,5) = 'N02AE' or
	         substr(AllDiagCodes{i},1,5) = 'N02AF' or  	
	         substr(AllDiagCodes{i},1,5) = 'N02AG' or
	         substr(AllDiagCodes{i},1,5) = 'N02AJ' or
	         AllDiagCodes{i} in ('N02AX01', 'N02AX02', 'N02AX06', 'N02AX52', 'N02BE51') then v36 = 1;	
		       
* 37. Pancreatic Insufficiency; 
*     ATC codes: A09AA02;
      
            if   AllDiagCodes{i} = 'A09AA02' then v37 = 1;	
      
* 38. Parkinsons Disease; 
*     ATC codes: N04AA01N04BX02;
	  
	    if   substr(AllDiagCodes{i},1,4) = 'N04A' or  	
	        (substr(AllDiagCodes{i},1,4) = 'N04B' and AllDiagCodes{i} not in ('N04BX03', 'N04BX04')) then v38 = 1;

* 39. Psoriasis;
*     ATC codes: D05AA01D05AA99, D05BB01, D05BB02, D05AX02, D05AC01D05AC51, D05AX52;

   	  if   substr(AllDiagCodes{i},1,5) = 'D05AA' or  	
	       substr(AllDiagCodes{i},1,5) = 'D05AC' or
	       AllDiagCodes{i} in ('D05BB01', 'D05BB02', 'D05AX02', 'D05AX52') then v39 = 1;	

* 40. Psychotic Illness;
*     ATC codes: N05AA01N05AB02, N05AB06N05AL07, N05AX07N05AX13;

	    if   substr(AllDiagCodes{i},1,5) = 'N05AA' or  
	        (substr(AllDiagCodes{i},1,5) = 'N05AB' and AllDiagCodes{i} not in ('N05AB03', 'N05AB04', 'N05AB05')) or 
                 substr(AllDiagCodes{i},1,5) = 'N05AC' or
		 substr(AllDiagCodes{i},1,5) = 'N05AD' or
		 substr(AllDiagCodes{i},1,5) = 'N05AE' or
                 substr(AllDiagCodes{i},1,5) = 'N05AF' or
		 substr(AllDiagCodes{i},1,5) = 'N05AG' or
	         substr(AllDiagCodes{i},1,5) = 'N05AH' or
	         substr(AllDiagCodes{i},1,5) = 'N05AL' or
	         AllDiagCodes{i} in ('N05AX07', 'N05AX08', 'N05AX09', 'N05AX10', 'N05AX11', 'N05AX12', 'N05AX13') then v40 = 1;	

* 41. Pulmonary Hypertension;
*     ATC codes: C02KX01C02KX05, PBS item code 9547L, 9605M; 
*     *** PBS item codes not taken into account;
  
             if   substr(AllDiagCodes{i},1,6) = 'C02KX0' then v41 = 1;
       
* 42. Renal Disease;
*     ATC codes: B03XA01B03XA03, A11CC01A11CC04, V03AE02, V03AE03, V03AE05;
      
             if   AllDiagCodes{i} in ('B03XA01','B03XA02' 'B03XA03', 'A11CC01', 'A11CC02', 'A11CC03', 'A11CC04', 'V03AE02', 'V03AE03', 'V03AE05') then v42 = 1;	

* 43. Smoking Cessasion; 
*     ATC codes: N07BA01N07BA03, N06AX12;

            if   AllDiagCodes{i} in ('N07BA01','N07BA02' 'N07BA03', 'N06AX12') then v43 = 1;	

* 44. Steroid Responsive Disease; 
*     ATC codes: H02AB01H02AB10;

            if   substr(AllDiagCodes{i},1,6) = 'H02AB0' or  
	         AllDiagCodes{i} = 'H02AB10' then v44 = 1;

* 45. Transplant;
*     ATC codes: L04AA06, L04AA10, L04AA18, L04AD01, L04AD02;
     
            if   AllDiagCodes{i} in ('L04AA06', 'L04AA10', 'L04AA18', 'L04AD01', 'L04AD02') then v45 = 1;	

* 46. Tuberculosis;
*     ATC codes: J04AC01J04AC51, J04AM01J04AM99; 
  
            if   substr(AllDiagCodes{i},1,5) = 'J04AC' or
                 substr(AllDiagCodes{i},1,5) = 'J04AM' then v46 = 1;
    
    end;
    drop i v10a v10b v23a v23b; 
  run; 


************************************************************************************
************************************************************************************
**************ADDS POINTS ACROSS CATEGORIES TO CALCULATE RX-RISK SCORE**************
************************************************************************************
************************************************************************************;

* Add score across columns for each patient; 
	data risc_calc (drop = _name_ geslacht atcode1-atcode764 v1-v46);
		set diagnosis_0_or_1;
		by CPB_PID;
		rx_risk_score = sum(of v1-v46);
	run;
