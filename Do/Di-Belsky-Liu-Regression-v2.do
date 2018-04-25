****************************************************************************************************
** Reproduce Di Belsky Liu Regression 
** Now using same sample as in the aux model (all in 2015 $)
** And ignore all the other control vars in Di Belsky and Liu (one concern... we no longer control for total_gifts)
****************************************************************************************************

set more off
graph close
set autotabgraphs on

global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
global output "$folder\Results\Di_Belsky_Liu_v2" 
use "$folder\Data\Final\AuxModelPanel.dta", clear

cap mkdir "$output"
cd "$output"
order pid wave age consumption liq_wealth housing_wealth income housing

xtset pid wave, delta(2)
sort pid wave

* SWITCHES
global allow_hh_present_for_part 1 // baseline (1) allows households that were not present in both 1999 and 2015. instead only requires that they were present for at least 4 years
global analyze_liquid_wealth 0
global add_cubic 0
// global control_for_income 1 // baseline in Di et al is to control for income (1). 

* TODO: try this with the full panel. right now i just keep the last obs for each person


* Model A - control for initial wealth, income, & other controls
* Model B - control for initial wealth quartiles, income, & other controls
* Model C - control for initial wealth, NOT income, & others
* Model D - control for initial wealth quartiles, NOT income, & others
* Model E - control for initial wealth, income, & NOT other controls
* Model F - control for initial wealth quartiles, income, & NOT other controls
* Model G - control for initial wealth, NOT income, & NOT others
* Model H - control for initial wealth quartiles, NOT income, & NOT others
* Model I - control for none of these

****************************************************************************************************
** Prepare Data
****************************************************************************************************

gen net_wealth = liq_wealth + housing_wealth

by pid, sort: egen min_year = min(wave)
by pid, sort: egen max_year = max(wave)

* Keep people renting in initial observation
gen initial_renter_ = 1 if housing == 0 & wave == min_year
by pid, sort: egen initial_renter = max(initial_renter)
keep if initial_renter == 1
drop initial_renter_ initial_renter

* Duration of ownership (total)
by pid, sort: egen total_waves_as_owner = total(housing) // housing == 1 if owner (total over all waves)
gen years_owning = 2 * total_waves_as_owner
replace years_owning = years_owning - 1 if years_owning > 0
gen years_owning2 = years_owning ^ 2

* Duration of ownership (cummulative)
* by pid, sort: gen cum_waves_as_owner = sum(housing)
* TODO: try this  in the regression?

* Average income 1999-2015
by pid, sort: egen average_income = mean(income)
gen log_average_income = log(average_income)

* Initial Wealth
gen init_wealth_ = net_wealth if wave == min_year
by pid, sort: egen init_wealth = max(init_wealth_)
gen log_init_wealth = log(init_wealth)
replace log_init_wealth = log(1) if log_init_wealth == .

* Age
gen init_age_ = age if wave == min_year
by pid, sort: egen init_age = max(init_age_)

* Initial wealth (right before they buy a home)




****************************************************************************************************
** Controls
****************************************************************************************************

* Compute a running sum of gifts/inheritance for each HH
sort pid wave                                                // this is very important so that the runsum works correctly
by pid, sort: egen cummulative_gifts = sum(value_gifts_real)     // will be 0 if they have never gotten anything
by pid, sort: egen total_gifts = total(value_gifts_real)     // will be 0 if they have never gotten anything
lab var cummulative_gifts "Cummulative gifts/inheritance (real) since 1999"
* TODO: could include some reasonable rate of return on these gifts? dunno

* Race
gen black = race == 2

* Education
gen init_educ_ = educhead if wave == min_year
by pid, sort: egen init_educ = max(init_educ_)

gen end_educ_ = educhead if wave == max_year
by pid, sort: egen end_educ = max(end_educ_)

* Dummies for education level
gen init_HS = init_educ == 12
gen init_some_college = init_educ > 12 & init_educ < 16
gen init_college_plus = init_educ >= 16

gen end_HS = end_educ == 12
gen end_college = end_educ > 12 & end_educ < 16
gen end_college_plus = end_educ >= 16

* Improvement in educ between 1999 and 2015
gen educ_improvement = end_educ - init_educ
replace educ_improvement = 0 if educ_improvement == .
replace educ_improvement = (educ_improvement > 0) // make it a dummy as in Di Belsky Liu

* Kids
gen init_kids_ = children if wave == min_year
by pid, sort: egen init_kids = max(init_kids_)

gen end_kids_ = children if wave == max_year
by pid, sort: egen end_kids = max(end_kids_)

gen change_kids = end_kids - init_kids

by pid, sort: egen metro_mode = mode(metro_pre2015)

gen large_metro = metro_mode == 1 | metro_mode == 2
gen other_metro = metro_mode == 3 | metro_mode == 4
gen small_city  = metro_mode == 5 | metro_mode == 6 | metro_mode == 7 | metro_mode ==  8

gen married_end = married == 1
gen divorced_end = married == 4

****************************************************************************************************
** Select Sample
****************************************************************************************************

local file_suffix

* only keep households present in 1999 and 2015
if $allow_hh_present_for_part == 0{
  keep if min_year == 1999 & max_year == 2015
  keep if wave == 2015
  local file_suffix `file_suffix'_restrictiveSample
  local metro_var i.metro_2015

}

* relax the min_year == 1999 restriction
if $allow_hh_present_for_part == 1{
  keep if wave == max_year
  gen dif = max_year - min_year
  tab dif
  keep if dif >= 4 // only keep HHs observed for at least 4 years

  drop if metro == 0
  local metro_var i.metro
}

* Generate quartiles (must do after selecting the sample)
egen init_wealth_quant = xtile(log_init_wealth), n(4)

****************************************************************************************************
** Define the dep var
****************************************************************************************************

if $analyze_liquid_wealth == 0{
  gen log_net_wealth = log(net_wealth) // wealth in final period
  replace log_net_wealth = log(1) if log_net_wealth == . // Deal with missing values due to negative or zero wealth
  local dep_var log_net_wealth
}
else if $analyze_liquid_wealth == 1{
//   gen log_liq_wealth = log(liq_wealth) // wealth in final period
  replace log_liq_wealth = log(1) if log_liq_wealth == . // Deal with missing values due to negative or zero wealth
  local dep_var log_liq_wealth
  local file_suffix `file_suffix'_liquid
}

****************************************************************************************************
** Other switches
****************************************************************************************************

if $add_cubic == 0{
  local cubic
}
else if $add_cubic == 1{
  gen years_owning3 = years_owning^3
  local cubic years_owning3
}

// if $control_for_income == 1{
// 	local extra_controls log_average_income log_init_wealth
// 	local extra_controls2 log_average_income i.init_wealth_quant
// 	local file_suffix `file_suffix'
// }
// else if $control_for_income == 0 {
// 	local extra_controls 
// 	local extra_controls2
// 	local file_suffix `file_suffix'_noIncControl
// }

****************************************************************************************************
** Regression (Model A)
****************************************************************************************************
local extra_controls log_average_income log_init_wealth
local baseline_controls total_gifts i.black i.init_HS i.init_some_college i.init_college_plus educ_improvement age i.married_end i.divorced_end i.region `metro_var' change_kids

reg `dep_var' years_owning years_owning2 `cubic' `extra_controls' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle(Model A) excel replace nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle(Model A) excel replace nose noaster sum

* Years owning as dummy
qui reg `dep_var' i.years_owning `extra_controls' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle(Model A Dummy) excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle(Model A Dummy) excel nose noaster sum

****************************************************************************************************
** Regression (Model B)
****************************************************************************************************

local extra_controls2 log_average_income i.init_wealth_quant

// reg `dep_var' years_owning years_owning2 `cubic' `extra_controls2' init_age 
reg `dep_var' years_owning years_owning2 `cubic' `extra_controls2' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle(Model B) excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle(Model B) excel nose noaster sum

// qui reg `dep_var' i.years_owning `extra_controls2' init_age
qui reg `dep_var' i.years_owning `extra_controls2' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle(Model B Dummy) excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle(Model B Dummy) excel nose noaster sum

****************************************************************************************************
** Regression (Model C)
****************************************************************************************************
local extra_controls log_init_wealth // do not control for income
local baseline_controls total_gifts i.black i.init_HS i.init_some_college i.init_college_plus educ_improvement age i.married_end i.divorced_end i.region `metro_var' change_kids
local model_name "Model C"

reg `dep_var' years_owning years_owning2 `cubic' `extra_controls' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle(`model_name') excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle(`model_name') excel nose noaster sum

* Years owning as dummy
qui reg `dep_var' i.years_owning `extra_controls' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle("`model_name' Dummy") excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle("`model_name' Dummy") excel nose noaster sum

****************************************************************************************************
** Regression (Model D)
****************************************************************************************************
local extra_controls2 i.init_wealth_quant // do not control for income
local model_name "Model D"

reg `dep_var' years_owning years_owning2 `cubic' `extra_controls2' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle(`model_name') excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle(`model_name') excel nose noaster sum

qui reg `dep_var' i.years_owning `extra_controls2' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle("`model_name' Dummy") excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle("`model_name' Dummy") excel nose noaster sum

****************************************************************************************************
** Regression (Model E)
****************************************************************************************************
local extra_controls log_average_income log_init_wealth 
local baseline_controls age
local model_name "Model E"

reg `dep_var' years_owning years_owning2 `cubic' `extra_controls' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle(`model_name') excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle(`model_name') excel nose noaster sum

* Years owning as dummy
qui reg `dep_var' i.years_owning `extra_controls' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle("`model_name' Dummy") excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle("`model_name' Dummy") excel nose noaster sum

****************************************************************************************************
** Regression (Model F)
****************************************************************************************************
local extra_controls2 log_average_income i.init_wealth_quant
local model_name "Model F"

reg `dep_var' years_owning years_owning2 `cubic' `extra_controls2' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle(`model_name') excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle(`model_name') excel nose noaster sum

qui reg `dep_var' i.years_owning `extra_controls2' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle("`model_name' Dummy") excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle("`model_name' Dummy") excel nose noaster sum

****************************************************************************************************
** Regression (Model G)
****************************************************************************************************
local extra_controls log_init_wealth 
local baseline_controls age
local model_name "Model G"

reg `dep_var' years_owning years_owning2 `cubic' `extra_controls' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle(`model_name') excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle(`model_name') excel nose noaster sum

* Years owning as dummy
qui reg `dep_var' i.years_owning `extra_controls' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle("`model_name' Dummy") excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle("`model_name' Dummy") excel nose noaster sum

****************************************************************************************************
** Regression (Model H)
****************************************************************************************************
local extra_controls2 i.init_wealth_quant
local model_name "Model H"

reg `dep_var' years_owning years_owning2 `cubic' `extra_controls2' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle(`model_name') excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle(`model_name') excel nose noaster sum

qui reg `dep_var' i.years_owning `extra_controls2' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle("`model_name' Dummy") excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle("`model_name' Dummy") excel nose noaster sum

****************************************************************************************************
** Regression (Model I)
****************************************************************************************************
local extra_controls2 
local model_name "Model I"

reg `dep_var' years_owning years_owning2 `cubic' `extra_controls2' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle(`model_name') excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle(`model_name') excel nose noaster sum

qui reg `dep_var' i.years_owning `extra_controls2' `baseline_controls'
qui outreg2 using "Coefs`file_suffix'.xls", ctitle("`model_name' Dummy") excel nose noaster
qui outreg2 using "Means`file_suffix'.xls", ctitle("`model_name' Dummy") excel nose noaster sum


di "See Results in:"
di "$output"
di "Coefs`file_suffix'.xls"
di "Means`file_suffix'.xls"


* Model A - control for initial wealth, income, & other controls
* Model B - control for initial wealth quartiles, income, & other controls
* Model C - control for initial wealth, NOT income, & others
* Model D - control for initial wealth quartiles, NOT income, & others

* Model E - control for initial wealth, income, & NOT other controls
* Model F - control for initial wealth quartiles, income, & NOT other controls
* Model G - control for initial wealth, NOT income, & NOT others
* Model H - control for initial wealth quartiles, NOT income, & NOT others

* Model I - control for none of these
