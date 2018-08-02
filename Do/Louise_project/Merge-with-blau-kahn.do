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
** Count experience since 1999
*******************************************************************************************************

do "$folder/Do/Louise_project/clean_variables.do"

inspect hours_annual_female
inspect emp_status_1
sdfsdf

* TODO: count experience here

* method 1: cum sum of emp_status_1 2 or 3 == working
* method 2: cum sum of years working above 1500 hours
* method 3: add both of those together


*******************************************************************************************************
* TODO: convert variables to real
*******************************************************************************************************




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

* saveold "$folder/Data/Intermediate/Basic-Panel-Louise-Final.dta", replace version(13)
