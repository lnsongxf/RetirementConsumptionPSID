* clear all
* set more off

* global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
* * global folder "/Users/bibekbasnet/Documents/GitHub/RetirementConsumptionPSID"

* use "$folder/Data/Intermediate/Basic-Panel_Louise.dta", clear

keep if sex_indiv == 2 // only those who are female

* Generate new variables
gen inc_female = .
replace inc_female = inc_head if sex_head == 2 & rel2head == 10
replace inc_female = inc_spouse if rel2head == 20 & inc_female == .

inspect inc_female
sum inc_female inc_fam

gen inc_male = .
replace inc_male = inc_head if sex_head == 1 & rel2head == 20
replace inc_male = inc_spouse if rel2head == 10 & inc_male == .

gen wage_rate_female = .
replace wage_rate_female = wage_rate_head if sex_head == 2 & rel2head == 10
replace wage_rate_female = wage_rate_spouse if rel2head == 20 & wage_rate_female == .
inspect wage_rate_female

gen hours_annual_female = .
replace hours_annual_female =  total_hours_head if sex_head == 2 & rel2head == 10
replace hours_annual_female =  total_hours_spouse if rel2head == 20 & hours_annual_female == .

gen educ_female = .
replace educ_female =  educhead if sex_head == 2 & rel2head == 10
replace educ_female =  educspouse if rel2head == 20 & educ_female == .

* gen inc_fam_nofemale = .
* replace inc_fam_nofemale = inc_fam - inc_head if sex_head == 2 & rel2head == 10
* replace inc_fam_nofemale = inc_fam - inc_spouse if sex_indiv == 2 & rel2head == 20 & inc_fam_nofemale == . 

gen race_indiv = .
replace race_indiv = racehead if sex_head == 2 & rel2head == 10
replace race_indiv = race_spouse if rel2head == 20 & race_indiv == .
label values race_indiv race

gen wage_rate_male = .
replace wage_rate_male = wage_rate_head if sex_head == 1 & rel2head == 20

gen emp_status_1 = .
replace emp_status_1 = emp_status_head if sex_head == 2 & rel2head == 10
replace emp_status_1 = emp_status_spouse if rel2head == 20 & emp_status_1 == .
label values emp_status_1 emp_status_lab

gen emp_status_2 = .
replace emp_status_2 = emp_status_head_2 if sex_head == 2 & rel2head == 10
replace emp_status_2 = emp_status_spouse_2 if rel2head == 20 & emp_status_2 == .
label values emp_status_2 emp_status_lab

gen emp_status_3 = .
replace emp_status_3 = emp_status_head_3 if sex_head == 2 & rel2head == 10
replace emp_status_3 = emp_status_spouse_3 if rel2head == 20 & emp_status_3 == .
label values emp_status_3 emp_status_lab

// Old method
// egen inc_fam_nonlabor = rowtotal(inc_transfer inc_ss_head inc_ss_spouse inc_ss_ofum foodstamp)
// asset income is not currently included here 

// New method: take family income and subtract head and spouse labor income
egen labor_income_fam = rowtotal(inc_head inc_spouse)
gen inc_fam_nonlabor = inc_fam - labor_income_fam
// TODO: why some ppl with negative?
count if inc_fam_nonlabor < 0

* preserve

* 	drop if emp_status_spouse == . 
* 	* Create a dummy variable of 1 if a spouse works, 0 otherwise
* 	gen spouse_is_working = (emp_status_spouse == 1)

* 	* Collapse by wave
* 	collapse (mean) percent_of_spouses_working = spouse_is_working, by(wave)

* restore

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
* table wave emp_status_spouse if emp_status_spouse == 1 

// count if emp_status_spouse == 1 & year == 1999 & emp_status_spouse == 1 & year == 2001 ///
// emp_status_spouse == 1 & year == 2003



* Clean up race variable -- simplify it to 3 categories
* Also there appear to be some reporting issues: people who claim their races changes. Let's take the mode
replace race_indiv = 7 if ( race_indiv >= 3 & race_indiv != . ) | race_indiv == 0
by pid, sort: egen race_indiv_mode = mode(race_indiv), minmode
drop race_indiv
rename race_indiv_mode race_indiv
label var race_indiv race

label var emp_status_indiv emp_status_lab

keep pid wave family_id rel2head age sex_indiv children fsize ///
 hours_annual_female inc_fam inc_female inc_male inc_fam_nonlabor  ///
wage_rate_female total_hours_head emp_status_indiv ///
educ_female spouse_father_educlevel spouse_mother_educlevel year_left_college ret_year ret_year_spouse ///
children0_2 children3_5 children6_13 children14_17m children14_17f children18_21m children18_21f married ///
race_indiv wage_rate_male emp_status_1 emp_status_2 emp_status_3 ///
expf_1999 expp_1999 pexp_1999

* Exclude inc_fam_nofemale
* inc_head inc_spouse

* Exclude these b/c head vs spouse can change
* emp_status_head emp_status_spouse


label variable pid "Person ID"
label variable wave "Wave (year survey was conducted)"
label variable family_id "ID number of the family"
label variable rel2head "Relation to the head of the household"
label variable age "age of the individual"
label variable sex_indiv "Sex of the individual"
label variable children "Number of children in a Family Unit"
label variable fsize "Size of the family unit"
label variable educ_female "Education label of the female"
* label variable emp_status_spouse "Employment status of spouse" // Error: will be missing if the head is not married
label variable hours_annual_female "Total number of hours worked by a female in an year"
* label variable inc_head "Income of the head"
label variable inc_fam "Family income (includes labor and non labor)"
label variable inc_female "Labor income of female"
label variable inc_male "Labor income of male"
label variable inc_fam_nonlabor "Family income minus male and female labor income"

* label variable inc_spouse "Total income of the spouse"
* label variable inc_fam_nofemale "Total income of the family without spouse contribution"
label variable spouse_father_educlevel "Education level of the spouse's father"
label variable spouse_mother_educlevel "Education level of the spouse's mother"
label variable year_left_college "The year an individual left the highest degree of education"

xtset pid wave, delta(2)

* saveold "$folder/Data/Intermediate/Basic-Panel-Louise-Final.dta", replace version(13)

