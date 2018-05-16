****************************************************************************************************
** Reproduce Di Belsky Liu Regression using our sample
****************************************************************************************************

******
****** PROBLEM: income is in 1982 dollars and wealth is in 2015
******

* NOTE: in the previous results, we were using wealth as measured in 1982-1984 real dollars.
* As of April 13, we updated wealth to 2015 dollars, so the results will be slightly different next time we run these regressions
* NOTE: when we plot the results , we just scale up from 1982-84 dollars to 2015 dollars


set more off
graph close
set autotabgraphs on

global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
cd "$folder\Results\Di_Belsky_Liu_Graph" // where to save outreg2 results
use "$folder\Data\Intermediate\Basic-Panel.dta", clear

* Switches
global allow_kids_to_leave_hh 1 // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH
                                // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)

* drop if emp_status_head != 1 // only keep employed heads. Question: should I put this so early? ie to split up HH? or later?

global allow_hh_present_for_part 1 // baseline = 1

global analyze_liquid_wealth 0

global add_cubic 1

global control_for_income 0 // baseline in Di et al is to control for income (1). 

* cap ssc install outreg2
* cap ssc install egenmore


****************************************************************************************************
** Sample selection
****************************************************************************************************


* Sample selection: households with same husband-wife over time
qui do "$folder\Do\Sample-Selection.do"
local file_suffix
*local file_suffix _unstable_coupes // only use this if we do not restrict ourselves to same husband-wife pairs

if $allow_hh_present_for_part == 1{
  local file_suffix _HH_partially_present
}

xtset pid wave, delta(2) // specify that we have data every other year

* Generate aggregate consumption (following Blundell et al)
qui do "$folder\Do\Consumption-Measures.do"

* TODO: make income / wealth real

* Todo: try before or after sample selection

* These people have misreported something
drop if housingstatus == 1 & housevalue == 0
drop if housingstatus == 1 & housevalue < 10000

* These people have a crazy change in wealth
* TODO: what do Aguiar and Hurst do
sort pid wave
/*gen change_wealth = (fam_wealth_real - L.fam_wealth_real) / L.fam_wealth_real
drop if change_w > 100 & change_w != . & L.fam_wealth_real > 10000

* These ppl also have a crazy change in wealth
drop if fam_wealth_real - L.fam_wealth_real > 100 * inc_fam_real & fam_wealth != . & L.fam_wealth_real != . & inc_fam_real != .*/

* To do: try with or without these guys
* drop if housingstatus == 8 // neither own nor rent

* Find first home purcahses (two alternative definitions)
qui do "$folder\Do\Find-First-Home-Purchase.do"

****************************************************************************************************
** Gifts / Inheritance
****************************************************************************************************

* Compute a running sum of gifts/inheritance for each HH
sort pid wave                                                // this is very important so that the runsum works correctly
by pid, sort: egen cummulative_gifts = sum(value_gifts_real)     // will be 0 if they have never gotten anything
by pid, sort: egen total_gifts = total(value_gifts_real)     // will be 0 if they have never gotten anything
lab var cummulative_gifts "Cummulative gifts/inheritance (real) since 1999"
* TODO: could include some reasonable rate of return on these gifts? dunno

****************************************************************************************************
** Define Variables
****************************************************************************************************

by pid, sort: egen min_year = min(wave)
by pid, sort: egen max_year = max(wave)

* Keep people renting in initial observation
gen initial_renter_ = housingstatus == 5 if wave == min_year
by pid, sort: egen initial_renter = max(initial_renter)
keep if initial_renter == 1

* Following Di et al and only keeping hhs who are observed from 1999 to 2015
count if min_year == 1999 & max_year == 2015 & wave == 2015
* we have 700 or so observations observed the whole time

* Duration of ownership
gen owner = housingstatus == 1
sort pid wave
by pid, sort: egen total_waves_as_owner = total(owner)

gen years_owning = 2 * total_waves_as_owner
replace years_owning = years_owning - 1 if years_owning > 0
gen years_owning2 = years_owning ^ 2

* Average income 1999-2015
by pid, sort: egen average_income = mean(inc_fam_real)
gen log_average_income = log(average_income)

* Initial Wealth in 1999
gen init_wealth_ = fam_wealth_real if wave == min_year
by pid, sort: egen init_wealth = max(init_wealth_)
gen log_init_wealth = log(init_wealth)

* Race
gen black = race == 2

* Age
gen init_age_ = age if wave == min_year
by pid, sort: egen init_age = max(init_age_)

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


****************************************************************************************************
** Select Sample
****************************************************************************************************

if $allow_hh_present_for_part == 0{
  keep if min_year == 1999 & max_year == 2015
  keep if wave == 2015

  local metro_var i.metro_2015
}

* relax the min_year == 1999 restriction
if $allow_hh_present_for_part == 1{
  keep if wave == max_year

  gen dif = max_year - min_year
  tab dif
  keep if dif >= 4

  /*local metro_var large_metro other_metro small_city*/
  drop if metro == 0
  local metro_var i.metro
}

****************************************************************************************************
** Wealth data
****************************************************************************************************


if $analyze_liquid_wealth == 0{
  gen log_fam_wealth_real = log(fam_wealth_real) // wealth in final period

  * Deal with missing values due to negative or zero wealth
  replace log_fam_wealth_real = log(1) if log_fam_wealth_real == .

  local dep_var log_fam_wealth_real
}
else if $analyze_liquid_wealth == 1{
  gen log_fam_liq_wealth_real = log(fam_liq_wealth_real) // wealth in final period

  * Deal with missing values due to negative or zero wealth
  replace log_fam_liq_wealth_real = log(1) if log_fam_liq_wealth_real == .

  local dep_var log_fam_liq_wealth_real
  local file_suffix `file_suffix'_liquid
}

replace log_init_wealth = log(1) if log_init_wealth == .


if $add_cubic == 0{
  local cubic
}
else if $add_cubic == 1{
  gen years_owning3 = years_owning^3
  local cubic years_owning3
}

if $control_for_income == 1{
	local extra_controls log_average_income log_init_wealth
	local extra_controls2 log_average_income i.init_wealth_quant
	local file_suffix `file_suffix'
}
else if $control_for_income == 0 {
	local extra_controls 
	local extra_controls2
	local file_suffix `file_suffix'_noIncControl
}

****************************************************************************************************
** Regression (Model A)
****************************************************************************************************

gen married_end = married == 1
gen divorced_end = married == 4

inspect years_owning years_owning2 `cubic' `extra_controls' total_gifts black init_HS init_some_college init_college_plus educ_improvement init_age married_end divorced_end region metro_2015 change_kids


reg `dep_var' years_owning years_owning2 `cubic' `extra_controls' total_gifts i.black i.init_HS i.init_some_college i.init_college_plus educ_improvement init_age i.married_end i.divorced_end i.region `metro_var' change_kids
qui outreg2 using "DiBelskyLiu_Reg`file_suffix'.xls", ctitle(Model A) excel replace nose noaster
qui outreg2 using "DiBelskyLiu_Means`file_suffix'.xls", ctitle(Model A) excel replace nose noaster sum

* Years owning as dummy
qui reg `dep_var' i.years_owning `extra_controls' total_gifts i.black i.init_HS i.init_some_college i.init_college_plus educ_improvement init_age i.married_end i.divorced_end i.region `metro_var' change_kids
qui outreg2 using "DiBelskyLiu_Reg`file_suffix'.xls", ctitle(Model A Dummy) excel nose noaster
qui outreg2 using "DiBelskyLiu_Means`file_suffix'.xls", ctitle(Model A Dummy) excel nose noaster sum

****************************************************************************************************
** Regression (Model B)
****************************************************************************************************

* Generate quartiles

egen init_wealth_quant = xtile(log_init_wealth), n(4)

reg `dep_var' years_owning years_owning2 `cubic' `extra_controls2' total_gifts  i.black i.init_HS i.init_some_college i.init_college_plus educ_improvement init_age i.married_end i.divorced_end i.region `metro_var' change_kids
qui outreg2 using "DiBelskyLiu_Reg`file_suffix'.xls", ctitle(Model B) excel nose noaster
qui outreg2 using "DiBelskyLiu_Means`file_suffix'.xls", ctitle(Model B) excel nose noaster sum

qui reg `dep_var' i.years_owning `extra_controls2' total_gifts i.black i.init_HS i.init_some_college i.init_college_plus educ_improvement init_age i.married_end i.divorced_end i.region `metro_var' change_kids
qui outreg2 using "DiBelskyLiu_Reg`file_suffix'.xls", ctitle(Model B Dummy) excel nose noaster
qui outreg2 using "DiBelskyLiu_Means`file_suffix'.xls", ctitle(Model B Dummy) excel nose noaster sum

di "See Results in:"
di "DiBelskyLiu_Reg`file_suffix'.xls"
di "DiBelskyLiu_Means`file_suffix'.xls"

* NOTE: in the previous results, we were using wealth as measured in 1982-1984 real dollars.
* As of April 13, we updated wealth to 2015 dollars, so the results will be slightly different next time we run these regressions
* NOTE: when we plot the results , we just scale up from 1982-84 dollars to 2015 dollars
