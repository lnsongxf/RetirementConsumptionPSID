clear all
set more off

*global folder "C:\Users\Person\Documents\GitHub\RetirementConsumptionPSID"
*Setting folder "C: "
global folder "/Users/bibekbasnet/Documents/GitHub/RetirementConsumptionPSID"

//use "$folder/Data/Intermediate/Basic-Panel_Louise.dta", clear
use "$folder/Data/Intermediate/Basic-Panel_Louise.dta", clear

keep if sex_indiv == 2
// only those who are female

preserve

drop if emp_status_spouse == . 
* Create a dummy variable of 1 if a spouse works, 0 otherwise
gen spouse_is_working = (emp_status_spouse == 1)

* Collapse by wave
collapse (mean) percent_of_spouses_working = spouse_is_working, by(wave)

restore

//count if status_average == 1 

// based on family_id, it creates mean of emp_status_spouse. 
// If the average is 1, then we know that that the person is working in each of the waves. 

/// drop if emp_status_spouse == 0
/// collapse (mean) status_aver = emp_status_spouse, by(pid) 

// keep if emp_status_spouse == 1 | emp_status_spouse_2 == 1 | emp_status_spouse_3 == 1
//keeps data of those who said they are working

// tab emp_status_spouse if emp_status_spouse == 1 & wave == 1999
// 2,540  this is the total number of women who report that they are working in 1999

// table wave emp_status_spouse if emp_status_spouse == 1
// note: We are using a very strict defination of employment_status of women. If the number of observations is low, 
// we can use a different defination. We are using self reported status of working. This does not include part time work. 
// We can probably people who work part time if we need higher sample size. 
// count if rep78 > 4 & weight < 3000
table wave emp_status_spouse if emp_status_spouse == 1 

// count if emp_status_spouse == 1 & year == 1999 & emp_status_spouse == 1 & year == 2001 ///
// emp_status_spouse == 1 & year == 2003

keep pid wave family_id rel2head age sex_indiv children fsize ///
emp_status_spouse hours_annual_female inc_head inc_fam inc_spouse inc_fam_nofemale ///
wage_rate_female total_hours_head emp_status_head emp_status_indiv ///
educ_female spouse_father_educlevel spouse_mother_educlevel year_left_college ret_year ret_year_spouse ///
children0_2 children3_5 children6_13 children14_17m children14_17f children18_21m children18_21f 


label variable pid "Parent Idenfication"
label variable wave "year in which survey was conducted"
label variable family_id "Idenfication number of the family"
label variable rel2head "Relation to the head of the household"
label variable age "age of the individual"
label variable sex_indiv "Sex of the individual"
label variable children "Number of children in a Family Unit"
label variable fsize "Size of the family"
label variable educ_female "Education label of the female"
label variable emp_status_spouse "Employment status of spouse"
label variable hours_annual_female "Total number of hours worked by a female in an year"
label variable inc_head "Income of the head"
label variable inc_fam "Total income of the family"
label variable inc_spouse "Total income of the spouse"
label variable inc_fam_nofemale "Total income of the family without spouse contribution"
label variable spouse_father_educlevel "Educaton level of the spouse's father"
label variable spouse_mother_educlevel "Education level of the spouse's mother"
label variable year_left_college "The year an individual left the highest degree of education"

save "$folder/Data/Intermediate/Basic-Panel_Louise-final.dta", replace

