****************************************************************************************************
** Produce wealth by age figures using APC method
** Then look into the impact of duration of homeownership
****************************************************************************************************

set more off
graph close
set autotabgraphs on

global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"

use "$folder\Data\Intermediate\Basic-Panel.dta", clear

* Switches
global allow_kids_to_leave_hh 1 // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)

* drop if emp_status_head != 1 // only keep employed heads. Question: should I put this so early? ie to split up HH? or later?

* Sample selection: households with same husband-wife over time
qui do "$folder\Do\Sample-Selection.do"

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
gen change_wealth = (fam_wealth_real - L.fam_wealth_real) / L.fam_wealth_real
drop if change_w > 100 & change_w != . & L.fam_wealth_real > 10000

* These ppl also have a crazy change in wealth
drop if fam_wealth_real - L.fam_wealth_real > 100 * inc_fam_real & fam_wealth != . & L.fam_wealth_real != . & inc_fam_real != .

* To do: try with or without these guys
* drop if housingstatus == 8 // neither own nor rent

* Find first home purcahses (two alternative definitions)
qui do "$folder\Do\Find-First-Home-Purchase.do"

****************************************************************************************************
** Gifts / Inheritance
****************************************************************************************************

* Compute a running sum of gifts/inheritance for each HH
sort pid wave                                                // this is very important so that the runsum works correctly
by pid, sort: generate cummulative_gifts = sum(value_gifts_real)     // will be 0 if they have never gotten anything
lab var cummulative_gifts "Cummulative gifts/inheritance (real) since 1999"
* TODO: could include some reasonable rate of return on these gifts? dunno

****************************************************************************************************
** Setup APC
****************************************************************************************************

keep if age >= 20 & age <= 75

* Create age categories (aka 5 year brackets)
egen age_cat = cut(age), at( 20(5)75 ) // icodes label
* gen age_cat = age

* Create year dummies, where year dummies are normalized so that Ed_year=0 and Cov(d_year,trend)=0
quietly tab wave, gen(year_cat)
foreach num of numlist 3/9 {
	gen d_year_`num'=year_cat`num'+(1-`num')*year_cat2+(`num'-2)*year_cat1
}

gen married_dummy = married == 1 // just look at married or not (rather than divorced, never married, widowed, separated, etc)


* NOTE: Cannot use log because many people have negative wealth... approx 18% of HHs
* gen log_fam_wealth_real = log(fam_wealth_real)
* gen log_fam_wealth_ex_home_real = log(fam_wealth_ex_home_real)
gen log_inc_fam_real = log(inc_fam_real)

* Normalize so that first home purchase == 100 (I do this because cannot have neg values  with indicator variable)
gen t_homeownership_100 = t_homeownership + 100
replace t_homeownership_100 = 92 if t_homeownership_100 < 92
replace t_homeownership_100 = 1000 if t_homeownership == .

****************************************************************************************************
** Generate wealth categorical variable that we can interact with homeown_cat
****************************************************************************************************

* Generate wealth categorical variable that we can interact with homeown_cat
// collapse (mean) fam_wealth_real (median) med_fam_wealth_real = fam_wealth_real if homeowner == 0, by(age)
// tsset age
// keep if age <= 40
// tsline *w*

* Find mean wealth for renters under age 40
// sum fam_wealth_real if homeowner == 0 & age <= 40
// local mean_wealth_renters_pre40 = r(mean)

* Create an indicator variable for HHs that start with wealth below that mean
// tempvar fam_wealth_real_wave1 fam_wealth_real_start min_year
// by pid, sort: egen `min_year' = min(wave)
// gen `fam_wealth_real_wave1' = fam_wealth_real if wave == `min_year'
// by pid, sort: egen `fam_wealth_real_start' = max(`fam_wealth_real_wave1')
// gen low_wealth_at_start = `fam_wealth_real_start' <= `mean_wealth_renters_pre40'

* TODO: this makes no sense. Perhaps drop ppl who have wealth grow like crazy
* hist fam_wealth_real if low_wealth_at_start == 1

* Question: is it right to use family weights rather than cross sectional? [pweight = family_weight]
* TODO: weights
* TODO: add fixed effects?

****************************************************************************************************
** Simple means and medians by age
****************************************************************************************************

gen log_fam_wealth_real = log(fam_wealth_real)
gen log_fam_wealth_ex_home_real = log(fam_wealth_ex_home_real)

preserve
	collapse (mean) log_fam_wealth_real log_fam_wealth_ex_home_real fam_wealth_real fam_wealth_ex_home_real, by(age_cat)
	tsset age_cat
	* tsline log_*, title("Mean Log Wealth") name("mean_log_wealth", replace)
	tsline fam_w*, title("Mean Wealth") name("mean_wealth_by_age", replace)
	graph export "$folder\Results\Wealth\mean_wealth_by_age.pdf", as(pdf) replace
restore

preserve
	collapse (median) log_fam_wealth_real log_fam_wealth_ex_home_real fam_wealth_real fam_wealth_ex_home_real, by(age_cat)
	tsset age_cat
	* tsline log_*, title("Median Log Wealth") name("median_log_wealth", replace)
	tsline fam_w*, title("Median Wealth") name("median_wealth_by_age", replace)
	graph export "$folder\Results\Wealth\median_wealth_by_age.pdf", as(pdf) replace
restore

* TODO: APC version of this?

****************************************************************************************************
** Simple means and medians by t_homeownership
****************************************************************************************************

gen fam_wealth_ex_gifts_real = fam_wealth_real - cummulative_gifts

preserve
	by pid, sort: egen min_t_homeownership = min(t_homeownership)
	keep if min_t_homeownership <= -6
	tab t_homeownership
	
	collapse (mean) fam_wealth_real fam_wealth_ex_home_real, by(t_homeownership)
	keep if t_ <= 10 & t_ >= -10
	tsset t_homeownership
	tsline fam_w*, title("Mean Wealth") name("mean_wealth", replace)
// 	graph export "$folder\Results\Wealth\mean_wealth_by_t_homeownership.pdf", as(pdf) replace
restore

preserve
	collapse (median) fam_wealth_real fam_wealth_ex_home_real fam_wealth_ex_gifts_real, by(t_homeownership)
	keep if t_ <= 10 & t_ >= -10
	tsset t_homeownership
	tsline fam_w*, title("Median Wealth") name("median_wealth", replace)
// 	graph export "$folder\Results\Wealth\median_wealth_by_t_homeownership.pdf", as(pdf) replace
restore

preserve
	by pid, sort: egen min_t_homeownership = min(t_homeownership)
	keep if min_t_homeownership <= -4
	tab t_homeownership
	
	collapse (median) fam_wealth_real fam_wealth_ex_home_real fam_wealth_ex_gifts_real (count) n = fam_wealth_real, by(t_homeownership)
	keep if t_ <= 10 & t_ >= -10
	list t_ n
	tsset t_homeownership
	tsline fam_w*, title("Median Wealth") name("median_wealth_tneg4", replace)
// 	graph export "$folder\Results\Wealth\median_wealth_by_t_homeownership.pdf", as(pdf) replace
restore


****************************************************************************************************
** APC Plots (OLS)
** Note: cannot use log because many people have negative wealth... approx 18% of HHs
****************************************************************************************************

local family_controls i.married_dummy i.fsize i.children i.children0_2 i.children3_5 ///
		i.children6_13 i.children14_17m i.children14_17f i.children18_21m i.children18_21f 

local reg_controls i.age_cat i.year_born d_year* `family_controls' // log_inc_fam_real
* NOTE: including log_inc_fam_real above really changes things

tempfile results

reg fam_wealth_real `reg_controls' 
regsave using `results', addlabel(lab, "Fam Wealth") replace

qui reg fam_wealth_ex_home_real `reg_controls' 
regsave using `results', addlabel(lab, "Fam Wealth ex Housing") append

preserve
	* Find coefs by age
	use `results', clear
	gen is_age = strpos(var, "age_cat")
	keep if is_age > 0
	drop is_age
	destring var, replace ignore("b.age_cat")
	rename var age
	
	* Plot results
	encode lab, gen(labels)
	xtset labels age
	lab var age "Age"
	lab var coef "Change in Wealth Relative to Age 20-24"
	xtline coef, overlay name("APC_fam_wealth", replace) title("Life Cycle Profile using APC") ytitle(, margin(0 2 0 0))
restore

*** 



***

* Now do it again, but add t_homeownership dummies
* TODO TODO TODO TODO
tempfile results

reg fam_wealth_real i.t_homeownership_100 i.age_cat /* i.year_born */ d_year* `family_controls'
// regsave using `results', addlabel(lab, "Fam Wealth") replace

qui reg fam_wealth_ex_home_real `reg_controls' 
regsave using `results', addlabel(lab, "Fam Wealth ex Housing") append

// preserve
// 	* Find coefs by age
// 	use `results', clear
// 	gen is_age = strpos(var, "age_cat")
// 	keep if is_age > 0
// 	drop is_age
// 	destring var, replace ignore("b.age_cat")
// 	rename var age
//	
// 	* Plot results
// 	encode lab, gen(labels)
// 	xtset labels age
// 	lab var age "Age"
// 	lab var coef "Change in Wealth Relative to Age 20-24"
// 	xtline coef, overlay name("APC_fam_wealth", replace) title("Life Cycle Profile using APC") ytitle(, margin(0 2 0 0))
// restore


** March 6th
** Potential wealth results

local family_controls i.married_dummy i.fsize i.children i.children0_2 i.children3_5 ///
		i.children6_13 i.children14_17m i.children14_17f i.children18_21m i.children18_21f 

reg fam_wealth_real i.t_homeownership_100 i.wave if t_homeownership != ., nocon vce(robust)
		
reg fam_wealth_real i.t_homeownership_100 i.age_cat i.wave i.homepurchase_year `family_controls' if t_homeownership != ., nocon vce(robust)


* Standard errors are so much better whenI do reg rather than xtreg
* I wonder if that would help with consumption results too?














****************************************************************************************************
** APC Plots (LAD)
****************************************************************************************************

local family_controls i.married_dummy i.fsize i.children i.children0_2 i.children3_5 ///
		i.children6_13 i.children14_17m i.children14_17f i.children18_21m i.children18_21f 

* For some reason, seems not to converge when I include cohort, period, and family effects
local reg_controls i.age_cat // i.year_born d_year* `family_controls' // log_inc_fam_real
* NOTE: including log_inc_fam_real above really changes things

tempfile results

qreg fam_wealth_real `reg_controls', wlsiter(100)
regsave using `results', addlabel(lab, "Fam Wealth") replace

qui qreg fam_wealth_ex_home_real `reg_controls', wlsiter(100)
regsave using `results', addlabel(lab, "Fam Wealth ex Housing") append

preserve
	* Find coefs by age
	use `results', clear
	gen is_age = strpos(var, "age_cat")
	keep if is_age > 0
	drop is_age
	destring var, replace ignore("b.age_cat")
	rename var age
	
	* Plot results
	encode lab, gen(labels)
	xtset labels age
	lab var age "Age"
	lab var coef "Change in Wealth Relative to Age 20-24"
	xtline coef, overlay name("APC_fam_wealth_LAD", replace) title("Life Cycle Profile using APC (Median)") ytitle(, margin(0 2 0 0))
restore


gen t_homeownership_trunc = t_homeownership
replace t_homeownership_trunc = -10 if t_homeownership < -10
replace t_homeownership_trunc = 10 if t_homeownership > 10 & t_homeownership != .
xi i.t_homeownership_trunc


qreg fam_wealth_real i.age_cat _It*, wlsiter(100)
tempfile results
regsave using `results', addlabel(lab, "Fam Wealth") replace

