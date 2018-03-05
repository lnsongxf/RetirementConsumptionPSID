****************************************************************************************************
** Simple regressions on consumption before/after first home purchase 
****************************************************************************************************

set more off
graph close
set autotabgraphs on

global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"

use "$folder\Data\Intermediate\Basic-Panel.dta", clear

* Switches
global allow_kids_to_leave_hh 1 // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)
global collapse_graphs        0 // Do we want to see the graphs where we collapse by t_homeownership?

// drop if emp_status_head != 1 // only keep employed heads. Question: should I put this so early? ie to split up HH? or later?

* Sample selection: households with same husband-wife over time
qui do "$folder\Do\Sample-Selection.do"

* Generate aggregate consumption (following Blundell et al)
qui do "$folder\Do\Consumption-Measures.do"

* TODO: make income /wealth real 

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

drop if mortgageexpenditure > 0 & t_homeownership < 0 // these people do not make sense

* cap ssc install qregpd
* cap ssc install moremata

keep if age >= 22 & age <= 75

****************************************************************************************************
** Simple regressions -- t_homeownership only
****************************************************************************************************

gen log_inc_fam_real = log(inc_fam_real)
gen log_expenditure_hurst = log(expenditure_hurst)
gen married_dummy = married == 1

* Shift t_homeownership so that all values are positive (needed for i. command)
gen t_homeownership_100 = t_homeownership + 100
replace t_homeownership_100 = 92 if t_homeownership_100 < 92
replace t_homeownership_100 = 1000 if t_homeownership == .

* Shift t_homeown so that all values are positive (needed for i. command)
gen t_homeown_100 = t_homeown + 100
replace t_homeown_100 = 92 if t_homeown_100 < 92
replace t_homeown_100 = 1000 if t_homeown == .


* Simplify family controls with topcoding
gen fsize_topcode = fsize
gen children_topcode = children
replace fsize_topcode = 5 if fsize > 5 & fsize != .
replace children_topcode = 3 if children > 3 & children != .
foreach var of varlist children0_2 children3_5 children6_13 children14_17m ///
					   children14_17f children18_21m children18_21f{
	replace `var' = 1 if `var'> 0 & `var' != .
}

local family_controls i.married_dummy i.fsize_topcode i.children_topcode /* i.children0_2 i.children3_5 i.children6_13 i.children14_17m i.children14_17f i.children18_21m i.children18_21f  */
local reg_controls /*i.age_cat d_year* */ i.wave `family_controls'

* Note: To set the base to 100, use ib100

* Currently seeing that consumption is a bit lower 4 years prior rather than 2 years prior
* Perhaps exclude child care expenditure?
* Perhaps look at rent expenditure
* Perhaps look at food away from home? Or food? (I suppose transportation is too work focused -- cant cut back)
* (Why is married identified? I thought all HHs were same head spouse pair? No variation with time...)
* Perhaps drop outliers? Extreme consumption values? Top 5%?
xtreg log_expenditure_hurst ib100.t_homeownership_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe

xtreg log_expenditure_hurst ib100.t_homeown_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe 


/*
* This looks good!! Median consumption falls at t=-2. But no fixed effect
* Though the fixed effect might be important! I find a similar drop when I use reg without the FE
qreg log_expenditure_hurst ib100.t_homeownership_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave 

char t_homeownership_100[omit] 100
xi i.t_homeownership_100 i.married_dummy i.fsize_topcode i.children_topcode 
qregpd log_expenditure_hurst log_inc_fam_real _I*, id(pid) fix(wave) q(50)
* WOOHOO! Results are good
* Though why no standard errors for the homeownership coefs?
* consumption drops 5.7% 2 years before purchase. whereas just 4.5% 4 years before purchase

sdfsdf
*/

* An important aspects of this is the convergence of the MCMC algorithm. In really bad cases, output will not show standard errors because there is too little (or zero) variation in the parameter across draws. This might happen when the objective function is steppier, as sometimes happens at extreme quantiles. So, in your case, you might have trouble with the .99 quantile and even the .95 quantile. In development, these extreme situations gave us a few problems.
* Pursuant to that, one thing I might recommend is burning in the run using a slow but productive drawing method such as Metropolis-Within-Gibbs scheme (so each parameter is drawn separately holding the others constant). Once this has run for awhile, switching to a global drawing scheme (where all parameters are drawn together. Here is an example. Note in the first run the use of the sampler(mwg) option, and in the second run the use of the from(starts) option:
* https://www.statalist.org/forums/forum/general-stata-discussion/general/1354388-comparing-coefficients-after-qregpd

* Some concern with reliability
* https://www.statalist.org/forums/forum/general-stata-discussion/general/1403552-different-results-for-differents-seeds-qregpd

* Does this make sense?
* https://www.statalist.org/forums/forum/general-stata-discussion/general/1331987-new-packages-on-ssc-genqreg-and-qregpd-generalized-quantile-regression-and-quantile-regression-with-panel-data

****************************************************************************************************
** Drop if cons > inc
****************************************************************************************************

* Woaw! 536 people fall into this category... out of only 6000ish with t_homeownership != .
tab age if expenditure_hurst > inc_fam_real & t_homeownership != .
// drop if expenditure_hurst >= inc_fam_real // & t_homeownership != .

xtreg log_expenditure_hurst ib100.t_homeownership_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe
xtreg log_expenditure_hurst ib100.t_homeown_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe 



gen log_expenditure_total_70 = log(expenditure_total_70)
gen log_foodawayfromhomeexpenditure = log(foodawayfromhomeexpenditure )
gen log_furnishingsexpenditure = log(furnishingsexpenditure )
gen log_foodexpenditure = log(foodexpenditure)
gen log_housingexpenditure = log(housingexpenditure)
gen log_expenditure_blundell = log(expenditure_blundell)

gen log_fooddeliveredexpenditure = log(fooddeliveredexpenditure)
replace log_fooddeliveredexpenditure = 0 if fooddeliveredexpenditure < 1

gen age_2 = age^2
keep if age <= 40

* These results make sense! You buy WAY more furnishings in the year you buy your house obviously
/*
xtreg log_furnishingsexpenditure age age_2 ib100.t_homeownership_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe
xtreg log_furnishingsexpenditure age age_2 ib100.t_homeown_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe 
*/

* Looks pretty good!!! 
* Blundell expenditure = AguiarHurst expenditure + healthinsuranceexpenditure + healthservicesexpenditure  
* + educationexpenditure - fooddeliveredexpenditure - propertytaxexpenditure
* Though I suppose education is kinda a durable good
* Results are not significant but still broadly in line with our model
* Question: do I mess it up if I add i.not_observed_buying?
xtreg log_expenditure_blundell age age_2 ib100.t_homeownership_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe
coefplot, keep(*t_homeown*) xline(0) name("blundell_homeownership", replace)
xtreg log_expenditure_blundell age age_2 ib100.t_homeown_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe 
coefplot, keep(*t_homeown*) xline(0) name("blundell", replace)

* exclude education, health, child care
* uh oh it's not as good...
gen log_expenditure_blundell_ex3 = log(expenditure_blundell_ex3)
xtreg log_expenditure_blundell_ex3 age age_2 ib100.t_homeownership_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe
coefplot, keep(*t_homeown*) xline(0) name("blundell_homeownership_ex3", replace)
xtreg log_expenditure_blundell_ex3 age age_2 ib100.t_homeown_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe 

* exclude edu only
gen log_expenditure_blundell_exedu = log(expenditure_blundell_exedu)
xtreg log_expenditure_blundell_exedu age age_2 ib100.t_homeownership_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe
coefplot, keep(*t_homeown*) xline(0) name("blundell_homeownership_ex_edu", replace)
xtreg log_expenditure_blundell_exedu age age_2 ib100.t_homeown_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe 

* interact with income at time of home purchase
* results look good!
cap drop bottom_half t_homeownership_100_bottom_half t_homeownership_100_top_half bottom_half_t0
qui sum log_inc_fam_real if t_homeownership == 0, d
gen bottom_half_t0 = log_inc_fam_real <= r(p50) if t_homeownership == 0
by pid, sort: egen bottom_half = max(bottom_half_t0)
replace bottom_half = 0 if bottom_half == .
gen t_homeownership_100_bottom_half = t_homeownership_100 * bottom_half
gen t_homeownership_100_top_half = t_homeownership_100 * (bottom_half == 0)

xtreg log_expenditure_blundell_exedu i.age i.bottom_half ib100.t_homeownership_100_bottom_half ib100.t_homeownership_100_top_half log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe
coefplot, keep(*t_homeownership_100_bottom_half) xline(0) name("bottomhalf", replace)


sdfdsf

****************************************************************************************************
** Trim the top consumption expenditure
****************************************************************************************************

* Trim the top 1%
* Problem: not by age, so we're probably just dropping old people

by age, sort: egen p_cutoff5 = pctile(expenditure_hurst), p(95)

preserve
keep age p_cutoff5
duplicates drop
list
restore

sum expenditure_hurst if age <= 40, de
gen expenditure_hurst_trim = expenditure_hurst if expenditure_hurst <= r(p99) & age <= 40
gen log_expenditure_hurst_trim = log(expenditure_hurst_trim)

// hist age if expenditure_hurst != . & expenditure_hurst_trim == . & age <= 40

xtreg log_expenditure_hurst_trim ib100.t_homeownership_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe

xtreg log_expenditure_hurst_trim ib100.t_homeown_100 log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe 

