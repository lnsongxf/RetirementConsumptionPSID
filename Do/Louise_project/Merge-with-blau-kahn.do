clear all
set more off

global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
* global folder "/Users/bibekbasnet/Documents/GitHub/RetirementConsumptionPSID"


* Sample Selection:
* We restrict our analysis of wages to respondents who were, as of the survey
* date, full-time employed wage and salary work- ers of ages 18– 65. To maximize
* sample size, we use both the PSID’s random sample and its poverty oversample
* populations and, in all analyses, employ the sampling weights supplied in the
* PSID files. The wage measure is aver- age real hourly earnings during the
* previous calendar year expressed in 1983 dollars using the Personal
* Consumption Expenditures deflator from the National Product Accounts. We
* exclude individuals earning less than $1 or more than $250 per hour in 1983
* dollars

use "$folder\Data\Raw\Blau_Kahn_JOLE_2013\1980_1990_1999_blau_kahn_regression_ready_jole_psid_data.dta" 

* gen long x11101ll = ER30001*1000 + ER30002
* lab var x11101ll "Person identification number"

gen long pid = id1968*1000 + personid68
lab var pid "Person identification number"

keep if female == 1
keep if year == 1999

keep pid *exp* age female empstat employed
order pid

rename age age_1999_BK
rename female female_BK
rename empstat empstat_1999
rename employed employed_1999

rename expf expf_1999
rename expp expp_1999
rename expfsq expfsq_1999
rename exppsq exppsq_1999
rename pexp pexp_1999

tempvar BK_data 
save `BK_data', replace

** ALTERNATVE
* use "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID/Data/Raw/PSID_Install/ind2015er", clear
* gen long x11101ll = ER30001*1000 + ER30002
* lab var x11101ll "Person identification number"
* rename x11101ll pid

*******************************************************************************************************
** Merge in experience data
*******************************************************************************************************
use "$folder/Data/Intermediate/Basic-Panel_Louise.dta", clear
keep if sex_indiv == 2 // only those who are female

xtset pid wave, delta(2)
merge m:1 pid using `BK_data'

* Only keep HHs with at least 4 waves of data
by pid, sort: egen count_pid = count(pid)
drop if count_pid < 4
tab _m

* What explains the unmatched households?
* We match almost all the BK households
* But have lots of HHs in our data that are not in BK
xtdescribe if _m == 1
drop if _m == 1 | _m == 2
drop _m
xtdescribe

* Whats up with these people where age doesnt match? It's not many... but still weird
* edit pid wave sex_indiv age age_1999_BK age_spouse rel2head sex_head if age != age_1999_BK

*******************************************************************************************************
** Clean up data
*******************************************************************************************************

do "$folder/Do/Louise_project/clean_variables.do"
sort pid wave

* Only keep households observed starting in 1999
by pid, sort: egen first_wave = min(wave)
keep if first_wave == 1999
* NOTE: if BK measure is inclusive of 1999, then we could keep HHs starting in 2001

*******************************************************************************************************
** Count cumulative experience since 1999
*******************************************************************************************************

* method 1: whether you are working in year of survey
gen working_odd_years = emp_status_1 == 1 | emp_status_2 == 1 | emp_status_3 == 1

* method 2: whether you had positive hours the year before the survey
gen working_even_years = hours_annual_female > 0
gen working_even_years_500 = hours_annual_female >= 500
gen working_even_years_FT = hours_annual_female >= 1500

* compare method 1 vs method 2
corr working_even_years working_odd_years
corr working_even_years_500 working_odd_years
corr working_even_years_FT working_odd_years

corr working_even_years L.working_even_years
corr working_odd_years L.working_odd_years

/*
preserve
	collapse working_*, by(wave)
	tsset wave
	tsline work*
restore
*/

* cumulative sum of both of these measures
by pid: gen cum_working_odd_years = sum( working_odd_years )

gen working_even_years_censored = working_even_years
replace working_even_years_censored = 0 if wave == 1999 // i suppose we should ignore work status in 1998
by pid: gen cum_working_even_years = sum( working_even_years_censored )
drop working_even_years_censored

gen cum_experience_since_1999 = cum_working_even_years + cum_working_odd_years

gen cum_experience = expp_1999 + cum_experience_since_1999

* question: is exp 1999 inclusive or exclusive of 1999?

*******************************************************************************************************
* Convert variables to real
*******************************************************************************************************

* Merge in CPI
gen year = wave - 1 // note that expenditure data is for year prior to interview
merge m:1 year using "$folder/Data/Intermediate/CPI.dta"
drop if _m == 2
drop year _m

local nominal_vars inc_fam inc_female inc_male inc_fam_nonlabor wage_rate_female wage_rate_male

foreach var of varlist `nominal_vars' {
	di "`var'"
	gen `var'_nominal = `var'
	replace `var'    = 100 * `var' / CPI_all_base_2015
}

* NOTE: inc_fam = inc_female + inc_male + inc_fam_nonlabor
preserve
	collapse inc_fam inc_male inc_female inc_fam_nonlabor *wage*, by(wave)
	tsset wave
	tsline inc*
	sum inc*
restore

*******************************************************************************************************
** Sample selection
*******************************************************************************************************

* Marital Status:
* there are some people who dont make sense... how can you be the spouse but not be married?
rename married marital_status
tab marital_status rel2head
drop if rel2head == 10 & marital_status == 1
drop if rel2head == 20 & marital_status == 2
drop if rel2head == 20 & marital_status == 3
drop if rel2head == 20 & marital_status == 4
drop if rel2head == 20 & marital_status == 5
tab marital_status rel2head 

tab marital_status
keep if marital_status == 1
keep if age >= 18 & age <= 65

* Keep only those observed 4 + waves (after sample selection)
* drop count_pid
by pid, sort: egen count_pid = count(pid)
drop if count_pid < 4
xtdescribe

saveold "$folder/Data/Intermediate/Basic-Panel-Louise-Final.dta", replace version(13)

* NOTE: should i drop cases where theres one year of missing data in the middle of four good obs?


* Questions:
* why some negative obs for inc_fam ?
* top coding on wage_rate_head etc?
* drop those with very high or low wages?

*******************************************************************************************************
** How many women work the whole four years?
*******************************************************************************************************

* Select women observed 1999 to 2005
by pid, sort: egen last_year = max(wave)
by pid, sort: egen first_year = min(wave)
keep if first_year == 1999
keep if last_year >= 2005

* Select women with no gaps between 1999 to 2005
keep if wave <= 2005
by pid, sort: egen c = count(wave)
tab c
keep if c == 4
xtdescribe

by pid, sort: egen years_working_even = total(working_even_years )
by pid, sort: egen years_working_odd = total(working_odd_years )
gen working_combined = working_even_years + working_odd_years
by pid, sort: egen years_working_combined = total( working_combined )

preserve
	keep if wave == 1999
	tab years_working_even
	tab years_working_odd
	tab years_working_combined
restore
