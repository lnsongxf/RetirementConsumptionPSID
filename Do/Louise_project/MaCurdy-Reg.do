
clear all
set more off

global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
use "$folder/Data/Intermediate/Basic-Panel-Louise-1999-to-2005.dta", clear

* Drop people who say they are working but have zero wage
gen obs_to_drop = (wage_rate_female == 0 | wage_rate_female == .) & working_even_years_100 == 1
tab obs_to_drop
by pid, sort: egen pid_to_drop = max(obs_to_drop)
drop if pid_to_drop == 1
save "$folder/Data/Intermediate/Basic-Panel-Louise-1999-to-2005-Clean.dta", replace


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

reg hours_robinson log_wage_rate_robinson inc_nonwife_robinson, nocons
