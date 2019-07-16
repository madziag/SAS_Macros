* This macro replaces missing values (numeric or character) with values chosen by the user;
* Input = Data with missing values;
* Ouput = Data with missing values replaced;
* a = representation of missing values e.g. . in numeric columns and '' in character columns;
* b = value used to replace the missing value with 
* Num_or_Char = can be numeric or character, depending on the columns with the values you would like to replace
;

%macro replace_missing_values(input, output, a, b, NumOrChar);
data &output.;
set &input.;
array miss_vals(*) _&NumOrChar._;
do i=1 to dim(miss_vals);
if miss_vals(i) = &a. then miss_vals(i) = &b.;
end;
drop i;
run;
%mend replace_missing_values;


* run macro;
*%replace_missing_values(input = test_data, output = test_result1, a= '' , b = 'abcdefg', NumOrChar = character);

