
clear all
set more off

global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
use "$folder/Data/Intermediate/Basic-Panel-Louise-1999-to-2005.dta", clear

/*
use "$folder/Data/Intermediate/Basic-Panel-Louise-2009-to-2015.dta", clear
sort pid wave
replace urbanicity = L.urbanicity if wave == 2015
replace wave = 1999 if wave == 2009
replace wave = 2001 if wave == 2011
replace wave = 2003 if wave == 2013
replace wave = 2005 if wave == 2015
*/

* Drop people who say they are working but have zero wage
gen obs_to_drop = (wage_rate_female == 0 | wage_rate_female == .) & working_even_years_100 == 1
tab obs_to_drop
by pid, sort: egen pid_to_drop = max(obs_to_drop)
drop if pid_to_drop == 1
saveold "$folder/Data/Intermediate/Basic-Panel-Louise-1999-to-2005-Clean.dta", replace version(13)


gen inc_nonwife = (inc_fam_nonlabor + inc_male) / 1000
gen log_wage_rate = log(wage_rate_female)
gen mobility = urbanicity * CPI_gasoline
gen cum_experience2 = cum_experience ^ 2
gen inc_nonwife2 = inc_nonwife ^ 2
drop if pid == 1094173 // weirdo




reg working_even_years_100 inc_nonwife age children0_2 children3_5 children6_13 cum_experience mobility cum_experience2 inc_nonwife2 if wave == 1999, nocons 
predict p1999obs if wave == 1999, xb

reg working_even_years_100 inc_nonwife age children0_2 children3_5 children6_13 cum_experience mobility cum_experience2 inc_nonwife2 if wave == 2001, nocons 
predict p2001obs if wave == 2001, xb

reg working_even_years_100 inc_nonwife age children0_2 children3_5 children6_13 cum_experience mobility cum_experience2 inc_nonwife2 if wave == 2003, nocons 
predict p2003obs if wave == 2003, xb

reg working_even_years_100 inc_nonwife age children0_2 children3_5 children6_13 cum_experience mobility cum_experience2 inc_nonwife2 if wave == 2005, nocons 
predict p2005obs if wave == 2005, xb

forvalues y = 1999(2)2005{
	by pid, sort: egen p`y' = max( p`y'obs)
	drop p`y'obs 

	forvalues i = 2(1)4{
		gen p`y'_`i' = p`y'^`i'
	}
}

sum p2001*
gen interact_1 = c.p1999*c.p2001
gen interact_2 = c.p2001*c.p2003
gen interact_3 = c.p2003*c.p2005

by pid, sort: egen counter = sum(working_even_years_100)
tab counter

gen hours = hours_annual_female
sort pid wave
foreach var of varlist hours log_wage_rate inc_nonwife {

	gen d_`var' = D.`var'

	reg d_`var' p1999* p2001* p2003* p2005* interact_* if wave == 2001 & counter == 4, nocons
	predict d_`var'_conditioned_2001 if wave == 2001 & counter == 4, xb

	reg d_`var' p1999* p2001* p2003* p2005* interact_* if wave == 2003 & counter == 4, nocons
	predict d_`var'_conditioned_2003 if wave == 2003 & counter == 4, xb

	reg d_`var' p1999* p2001* p2003* p2005* interact_* if wave == 2005 & counter == 4, nocons
	predict d_`var'_conditioned_2005 if wave == 2005 & counter == 4, xb

	gen d_`var'_conditioned = .
	replace d_`var'_conditioned = d_`var'_conditioned_2001 if wave == 2001
	replace d_`var'_conditioned = d_`var'_conditioned_2003 if wave == 2003
	replace d_`var'_conditioned = d_`var'_conditioned_2005 if wave == 2005	

	gen `var'_robinson = d_`var' - d_`var'_conditioned
}

sum d_*_conditioned, detail
sum *_robinson, detail

reg hours log_wage_rate inc_nonwife if counter == 4, nocons

* MaCurdy Regression (not controlling for selection)
reg d_hours d_log_wage_rate d_inc_nonwife if counter == 4, nocons

* Robinson Regression
reg hours_robinson log_wage_rate_robinson inc_nonwife_robinson if counter == 4, nocons

sdfsdf
* Heckman
heckman hours log_wage_rate inc_nonwife, select(working_even_years_100 = inc_nonwife age children0_2 children3_5 children6_13 cum_experience mobility cum_experience2 inc_nonwife2) mills(mills_ratio)

sdfdsf

* Question: why doesnt this command recover the previous coefs?
reg hours log_wage_rate inc_nonwife mills_ratio


heckman hours log_wage_rate inc_nonwife if wave == 2001, select(working_even_years_100 = inc_nonwife age children0_2 children3_5 children6_13 cum_experience mobility cum_experience2 inc_nonwife2) mills(mills_ratio1)
heckman hours log_wage_rate inc_nonwife if wave == 2003, select(working_even_years_100 = inc_nonwife age children0_2 children3_5 children6_13 cum_experience mobility cum_experience2 inc_nonwife2) mills(mills_ratio2)
heckman hours log_wage_rate inc_nonwife if wave == 2005, select(working_even_years_100 = inc_nonwife age children0_2 children3_5 children6_13 cum_experience mobility cum_experience2 inc_nonwife2) mills(mills_ratio3)

gen mills = .
replace mills = mills_ratio1 if wave == 2001
replace mills = mills_ratio2 if wave == 2003
replace mills = mills_ratio3 if wave == 2005

* gen d_mills_ratio = D.mills_ratio
* reg d_hours d_log_wage_rate d_inc_nonwife d_mills_ratio
