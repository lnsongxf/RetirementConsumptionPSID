set more off
* global folder "C:\Users\pedm\Documents\Research\Cormac\RetirementConsumptionPSID"
* global folder "C:\Users\Person\Documents\GitHub\RetirementConsumptionPSID"
global folder "C:\Users\STUDENT\Documents\GitHub\RetirementConsumptionPSID"

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

****************************************************************************************************
** Notes
****************************************************************************************************

* TODO: look at consumption behavior of those who are actually constrained by down payment / LTV requirement x years before buying

* TODO: medians? Or drop the top 5%? / outliers?

* TODO: look at poorer people rather than just the median -- wealth

* TODO: make the wealth plot, taking out gifts

* Can create Di Belsky Liu type figure

* What percent of down payment have they accumulated one wave before buying house?



****************************************************************************************************
** Find home purchases
****************************************************************************************************

sort pid wave                                                // this is very important so that the runsum works correctly
gen homeowner                           = housingstatus == 1 // housing status can be rent, own, or other
by pid, sort: generate runsum_homeowner = sum(homeowner)     // will be 0 if they have never owned previously (in our sample)

sort pid wave
gen homepurchase_                       = wave if homeowner == 1 & L.runsum_homeowner == 0 // select the year that they are first observed owning a house

* TODO: drop those who make the first observed home purchase when older than age 40
* (we dont know for sure if they're a first time home buyer, but this helps)
* This drops us down to 1,332 first time home purchases (previously 2,000)
* TODO: WHATS THE IMPACT OF INCLUDING THIS?
replace homepurchase_ = . if age > 40

by pid, sort: egen homepurchase_year    = max(homepurchase_) // replicate this across waves
gen t_homeownership                     = wave - homepurchase_year // duration of homeownership

// we observe about 2000 home purchases during this time period
// note: can get more transitions if we go back before 1999 (using old wealth data)
// these observations are observed for at least 2 waves each
// if we restrict ourselves to observations with at least 5 waves, we observe 1193 home purchases

* TODO: can I get a better measure of home purchase year? for instance, do they ask people when they moved into their current house?


* I wonder if it would be interesting to look at savings rates before / after getting either a home equity loan or HELOC
tab type_mortgage2 wave
* (2,136 year-wave observations with home equity loan, 334 year-wave obs with HELOC. plus maybe a few more if we look in type_mortgage1)

****************************************************************************************************
** TODO: Find home purchases more precisely
****************************************************************************************************

* Use information on when they last moved to figure out how many months ago they purchased their home

lookfor month

count if t_homeownership == 0

tab year_moved // already very useful. but too bad there are missings here

tab year_moved if t_homeownership == 0


* Create time variable that stores both year and month (Jan = 0, Dec = 11/12)
gen t_survey = wave + (month-1)/12
gen t_moved = year_moved + (month_moved-1)/12 // NOOOOO. Sometimes we observe one but not the other. Do this later

sort pid wave
gen first_purchase = 1 if homeowner == 1 & L.runsum_homeowner == 0 // obs that are first observed owning a house
replace first_purchase = . if age > 40 // older heads - might not be first time home buyers
//
// * Store the time that they moved if it's their first purchase
// gen t_firstpurchase_ = t_moved if first_purchase == 1
// replace t_firstpurchase_ = wave - 1 + (6/12) if first_purchase == 1 & t_firstpurchase == . // We do not have t_moved for everyone, so let's just guess that they moved the summer before this wave


* TODO: this doesnt capture everyone. there are 1,579 cases where they have the home purchase year
* but 2009 first time home purchases


* How to find the time before buying the home?
* replace t_v2 = -1 if F.first_purchase == 1

* todo: should I just look at people who go from renting to owning?

* Category 1: has info on both year_moved and month_moved - can get exact number of months between renting and moving
sort pid wave
tempvar time_survey time_moved time_bought
gen `time_survey' = 12 * wave + month
gen `time_moved' = 12 * year_moved + month_moved if first_purchase == 1
by pid, sort: egen `time_bought' = max(`time_moved')
gen months_homeown = `time_survey' - `time_bought'
gen t_homeown = floor(months_homeown / 12)
gen q_homeown = floor(months_homeown / 3 )

gen time_bought_y = `time_bought' / 12
* Some contradictory individuals -- they still rent, but then next wave they say that they last moved before that wave
// edit pid age wave month year_moved month_moved housingstatus rentexp mortgageexp housevalue months_homeown t_homeown q_homeown time_bought_y if F.first_purchase == 1 & months_homeown > 0 & months_homeown <= 24
// edit pid age wave month year_moved month_moved housingstatus rentexp mortgageexp housevalue months_homeown t_homeown q_homeown time_bought_y if pid == 961033

replace months_homeown = -1 if F.first_purchase == 1 & months_homeown >= 0 // not yet bought a house
replace t_homeown = -1      if F.first_purchase == 1 & months_homeown >= 0 // not yet bought a house
replace q_homeown = -1      if F.first_purchase == 1 & months_homeown >= 0 // not yet bought a house

* Category 2: has info on year_moved only - can get reasonable guess of years between renting and moving
tempvar year_bought_1 year_bought
gen `year_bought_1' = year_moved if first_purchase == 1
by pid, sort: egen `year_bought' = max(`year_bought_1')

replace t_homeown = wave - `year_bought' if t_homeown == .

* THESE PPL MAKE NO SENSE
replace t_homeown = -1 if t_homeown == 0 & F.first_purchase == 1 // not yet bought a house

// first wave owning should be
// 2013 - 2013 = 0
// 2013 - 2012 = 1
// 2013 - 2011 = 2
//
// last wave renting should be:
// 2011 - 2013 // should be -2
// 2011 - 2012 // should be -1
// 2011 - 2011 // should be -1
//
// second to last wave renting should be
// 2009 - 2013 = -4
// 2009 - 2012 = -3
// 2009 - 2011 = -2


* Category 3: has info on neither - will just assume that they moved in the year in between
tempvar year_bought3_temp year_bought3
gen `year_bought3_temp' = wave - 1 if first_purchase == 1
by pid, sort: egen `year_bought3' = max(`year_bought3_temp')
replace t_homeown = wave - `year_bought3' if t_homeown == .


// gen time_bought = `time_bought'
// gen time_survey = `time_survey'
//time_bought time_survey 

tab t_homeown 			if (first_purchase == 1 | F.first_purchase == 1) , missing
tab t_homeownership 	if (first_purchase == 1 | F.first_purchase == 1) , missing

// edit pid age wave month year_moved month_moved housingstatus rentexp mortgageexp housevalue months_homeown t_homeown q_homeown if (first_purchase == 1 | F.first_purchase == 1) // & (year_moved == . & month_moved == .) 

gen years_before_first_home = -1 * t_homeown if t_homeown < 0
gen age_sq = age^2

* xtreg foodathomeexpenditure i.years_before_first_home children inc_fam educhead age age_sq i.married i.racehead, fe

****************************************************************************************************
** Looks at results with this new t_homeown variable
****************************************************************************************************

* TODO: lots fewer obs with t_homeown than t_homeownership... make a best guess for those with t_homeown missing

if $collapse_graphs == 1{
preserve

* Look at results
// keep if tripsexp != . // only needed when looking at trips / recreation
by pid, sort: egen min_t_homeown = min(t_homeown)
tab min_t_h
keep if min_t_home <= -4

tab t_homeown

foreach var of varlist food*{
	gen `var'_eq = `var' / equiv
}

collapse children fsize (mean) *expenditure* (count)c = foodexpenditure, by(t_homeown) // TODO: mean or median?
tsset t_
list
tsline food*e if t_ <= 0 & t_ >= -4
tsline food*eq if t_ <= 0 & t_ >= -4
// tsline children fsize if t_ <= 0 & t_ >= -4

tsline tripsexpenditure recreationexpenditure if t_ <= 0 & t_ >= -4
// tsline expenditure_blundell_eq_exH if t_ >= -4 & t_ <=0

restore
}

****************************************************************************************************
** Only keep those who are observed for at least n waves
****************************************************************************************************

* drop people with positive mortgage expenditure but who do not own a house
* all of these people responded "neither" to the rent or own question
* edit if mortgageexpenditure > 0 & t_homeownership < 0
drop if mortgageexpenditure > 0 & t_homeownership < 0 // these people do not make sense

* DO WE NEED TO DO THIS????
* by pid, sort: egen waves = count(wave)
* tab waves if homepurchase_ != .
* keep if waves >= 9

/*
* Only keep those observed at least 4 years before home purchase
by pid, sort: egen min_t = min(t_homeownership)
tab min_t
keep if min_t <= -4

* And do the same on the other side
by pid, sort: egen max_t = max(t_homeownership)
tab max_t
keep if max_t >= 4
*/

* After dropping based on min_t and max_t, I observe just 31 households making the transition :/

****************************************************************************************************
** Savings
****************************************************************************************************

* Dynan et al 2004 ("Do the rich save more?") have two ways to compute savings rates:
* consumption based savings rate = (Y-C) / Y (SCF)
* wealth difference savings rate = (At - At-1) / Y (SCF, PSID)

* Straub prefers the consumption based savings rate "because it is generally difficult 
* to distentagle ex-ante savings behavior from ex-post returns or transfers"
* Straub uses PSID. He faces the choice between the long running (70% measure)
* and short running but comprehensive measure. Chooses long running measure. But shows
* that switching to the comprehensive measure has only a small impact on results

* Largest categories missing pre 2005 are home repairs and maintenance, household furnishing, and clothing

* Includes all available expenditure categories including durable goods
* Since mortgage payments = imputed rents + accumulation of housing welath, he 
* replaces mortgage payments with imputed rent as computed by the PSID
* (notes that results are very similar if he computes imputed rents as 6% of the house price
* as in Blundell et al 2016 and Poterba and Sinai 2008. 

* Also uses post-tax household labor income (labor income of all family members minus taxes, computed using NBER's taxsim program)
* Discusses alternative: after-tax total income (including capital income as well as private and public transfers)
* Uses post-1999 longitudinal weights

* Straub:
* exclude households without a single non-missing consumption and income observation
* exclude extreme observations with income below 5% of yearly average income

* QUESTION: PSID reports imputed rents?
* Macro Handbook suggests that PSID housing expenditure is 

* In baseline results, includes durables in his expenditure measure, since those would scale linearly in permanent income
* But does robustness where he excludes 

* When using the post 2005 expenditure measure, excludes home repairs and maintenance costs since these are investments

* PS: 2007 wave asks the head about their reported bequest intention


****************************************************************************************************
** Collapse (-6 to 0)
****************************************************************************************************

if $collapse_graphs == 1{
preserve

* TODO: try t_homeown rather than t_homeownership -- tried already but looks too choppy

local time t_homeownership // original
// local time t_homeown // new version 

* Only keep those observed at least 6 years before home purchase
by pid, sort: egen min_t = min(`time')
tab min_t
keep if min_t <= -6

gen neither_rentown = housingstatus == 8

collapse (mean) *wealth* inc_* homeequity homeowner housevalue mortgage1 mortgage2 *expenditure* neither_rentown (count) n = inc_fam /* c_to_i  (count) n = c_to_i */, by(`time')
drop if `time' == .
drop if `time' < -6 | `time' > 0
tsset `time'

// tsline n, name("n", replace)
// tsline food*, name("foodeq", replace)
// tsline expenditure_blundell, name("blundell1", replace)
// tsline expenditure_blundell_eq, name("blundell_eq1", replace)
tsline expenditure_blundell_exhous, name("expenditure_blundell_exhousing1", replace)
tsline expenditure_blundell_eq_exH, name("expenditure_blundell_eq_exH1", replace)
// tsline furnishingsexpenditure, name("furnishingsexpenditure1", replace)
tsline neither_rentown, name("neither_rentown", replace)

restore
}


****************************************************************************************************
** Collapse (-4 to 4)
****************************************************************************************************

* Wow homeequity does some crazy things
* Lots of cases where they own a house and then homeequity becomes 0 for a year
* Or where homeequity is originally huge (perhaps whole value of home) then becomes very low (as in 10-20%)
* edit pid wave homeequity homeowner if t_homeownership != .


* drop if emp_status_head != 1 // only keep employed heads. Question: should I put this earlier? ie to split up HH?
* could do similar if spouse is unemployed?

// gen c_to_i = expenditure_blundell_exhous / inc_fam
// hist c_to_i if t_homeownership == -4

if $collapse_graphs == 1{
preserve

* Only keep those observed at least 4 years before home purchase
by pid, sort: egen min_t = min(`time')
tab min_t
keep if min_t <= -4


collapse (mean) *wealth* inc_* homeequity homeowner housevalue mortgage1 mortgage2 *expenditure* /* c_to_i  (count) n = c_to_i */, by(t_homeownership)
drop if t_homeownership == .
drop if t_homeownership < -4 | t_homeownership > 4
tsset t_homeownership


tsline inc_fam inc_head inc_spouse /* inc_transfer inc_ss_fam */ , title("Income (Nominal)") name("inc", replace)



tsline homeowner, name("homeowner", replace) // woaw. was not expecting that 20% of people who buy a home are back to renting 2 years later

tsline fam_wealth fam_wealth_ex_home homeequity bank_account_wealth stock_wealth homeequity, name("wealth", replace)
* TODO: will want to account for parental transfers
* Unfortunately home equity barely increases between t = 2 and 10
* HUGE jump in home equity at t = 0

gen mortgage_combined = mortgage1 + mortgage2
gen computed_homeequity = housevalue - mortgage_combined

tsline housevalue mortgage1 mortgage2, name("housev", replace) 
* Seems that the housevalue barely increases between t = 2 and 10
* Seems that the mortgage barely decreases between t = 2 and 10

tsline homeequity computed_homeequity, name("homeeq", replace)

tsline rentexpenditure mortgageexpenditure, name("expend", replace) // WARNING: there are some people who have housing status of "neither" before buying a home
* why do some people have mortgage expenditure before buying a house? weirdos
* interesting to notice that expenditure goes up substantially when buying the house. avg rent of 6k, avg mortgage of 8k 
* (and this is not being driven by marriage. still holds if i set waves >= 9)
* though what if we just look at those who are observed earlier?

* todo: issues related to nominal vs real?

tsline expenditure_blundell, name("blundell", replace)
tsline expenditure_blundell_eq, name("blundell_eq", replace)
tsline expenditure_blundell_exhous, name("expenditure_blundell_exhousing", replace)
tsline expenditure_blundell_eq_exH, name("expenditure_blundell_eq_exH", replace)
tsline furnishingsexpenditure, name("furnishingsexpenditure", replace)

// tsline c_to_i , name("c_to_i", replace) // WARNING: c is real, i is nominal


* question: do we know when the marriage takes place? i just realized that a "wife" can transition to wife. and this will still be included in current sample
restore
}


****************************************************************************************************
** Aguiar and Hurst Version: life cycle consumption
****************************************************************************************************

* Aguiar Hurst restrict cohorts to those that have at least 10 years in the sample
* Aka age 65 in 1980 (birth year >= 1915) and age 35 in 2003 (birth year <= 1968)
* Should I also trim off the tails? 
* Aka age 65 in 1999 (birth year >= 1934) and age 35 in 2015 (birth year <= 1980)
* keep if year_born >= 1934 & year_born <= 1980

* TODO: have the cutoff be 20 or 25?
keep if age >= 20 & age <= 75

* Create year dummies, where year dummies are normalized so that Ed_year=0 and Cov(d_year,trend)=0
quietly tab wave, gen(year_cat)
foreach num of numlist 3/9 {
	gen d_year_`num'=year_cat`num'+(1-`num')*year_cat2+(`num'-2)*year_cat1
}

gen married_dummy = married == 1 // just look at married or not (rather than divorced, never married, widowed, separated, etc)
gen log_expenditure_hurst = log(expenditure_hurst)
gen log_expenditure_hurst_nonH = log(expenditure_hurst_nonH)

* Question: is it right to use family weights rather than cross sectional? [pweight = family_weight]
* TODO: weights
* TODO: add fixed effects?

* Create age categories (aka 5 year brackets)
egen age_cat = cut(age), at( 20(5)75 ) // icodes label
* gen age_cat = age

gen log_inc_fam_real = log(inc_fam_real)

* Generate wealth categorical variable that we can interact with homeown_cat
// collapse (mean) fam_wealth_real (median) med_fam_wealth_real = fam_wealth_real if homeowner == 0, by(age)
// tsset age
// keep if age <= 40
// tsline *w*

* Find mean wealth for renters under age 40
sum fam_wealth_real if homeowner == 0 & age <= 40
local mean_wealth_renters_pre40 = r(mean)

* Create an indicator variable for HHs that start with wealth below that mean
tempvar fam_wealth_real_wave1 fam_wealth_real_start min_year
by pid, sort: egen `min_year' = min(wave)
gen `fam_wealth_real_wave1' = fam_wealth_real if wave == `min_year'
by pid, sort: egen `fam_wealth_real_start' = max(`fam_wealth_real_wave1')
gen low_wealth_at_start = `fam_wealth_real_start' <= `mean_wealth_renters_pre40'

tab low_wealth_at_start

* TODO: this makes no sense. Perhaps drop ppl who have wealth grow like crazy
* hist fam_wealth_real if low_wealth_at_start == 1


****************************************************************************************************
** Nondurables w and w/out housing (cross sectional)
****************************************************************************************************

local family_controls i.married_dummy i.fsize i.children i.children0_2 i.children3_5 i.children6_13 i.children14_17m i.children14_17f i.children18_21m i.children18_21f 
local reg_controls i.age_cat i.year_born d_year* `family_controls' // log_inc_fam_real
* NOTE: including log_inc_fam_real above really changes things

tempfile results

reg log_expenditure_hurst `reg_controls' 
regsave using `results', addlabel(lab, "Nondurables") replace

qui reg log_expenditure_hurst_nonH `reg_controls' 
regsave using `results', addlabel(lab, "Nondurables w/out Housing") append

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
lab var coef "Expenditure"
xtline coef, overlay name("Fig1_apc", replace) title("Life Cycle Profile using APC") note("Nondurables in PSID include food, gasoline, utilities, transportation services, and child care." "It does not include other components used in Aguiar Hurst, such as tobacco, clothing,""personal care, domestic services, airfare, nondurable entertainment, gambling, business" "services, and chartiable giving") ytitle(, margin(0 2 0 0))
restore

****************************************************************************************************
** Nondurables w and w/out housing
** Panel with FE
****************************************************************************************************

* NOTE: including log_inc_fam_real changes things a bit, but not too much, cause the fixed effect does a good job
local family_controls i.married_dummy i.fsize i.children i.children0_2 i.children3_5 i.children6_13 i.children14_17m i.children14_17f i.children18_21m i.children18_21f 
local reg_controls i.age_cat d_year* `family_controls' log_inc_fam_real // Remove i.year_born because we add fe
tempfile results

xtreg log_expenditure_hurst `reg_controls', fe
regsave using `results', addlabel(lab, "Nondurables") replace

qui xtreg log_expenditure_hurst_nonH `reg_controls', fe 
regsave using `results', addlabel(lab, "Nondurables w/out Housing") append

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
lab var coef "Expenditure"
xtline coef, overlay name("Fig1_fe", replace) title("Life Cycle Profile using FE") note("Nondurables in PSID include food, gasoline, utilities, transportation services, and child care." "It does not include other components used in Aguiar Hurst, such as tobacco, clothing,""personal care, domestic services, airfare, nondurable entertainment, gambling, business" "services, and chartiable giving") ytitle(, margin(0 2 0 0))
restore

****************************************************************************************************
** Nondurables w and w/out housing
** Panel with FE
** Add dummies for time before and after home purchase
****************************************************************************************************

* Setup time to homeownership dummies
gen     homeown_cat = "unknown" if t_homeownership == .
replace homeown_cat = "long before purchase" if t_homeownership <= -4
replace homeown_cat = "right before purchase" if t_homeownership == -2
replace homeown_cat = "after purchase" if t_homeownership >= 0 & t_homeownership != .
encode  homeown_cat, gen(homeown_cat_dummy)

gen long_before_purchase = t_homeownership <= -4
gen right_before_purchase = t_homeownership == -2

local family_controls i.married_dummy i.fsize i.children i.children0_2 i.children3_5 i.children6_13 i.children14_17m i.children14_17f i.children18_21m i.children18_21f 
local reg_controls i.age_cat d_year* `family_controls' log_inc_fam_real // Remove i.year_born because we add fe
tempfile results

* TODO: this xi thing is really messy... any cleaner way?
* TODO: try without homeowner dummy
char homeown_cat_dummy[omit] "after purchase"
xi i.long_before_purchase*low_wealth_at_start i.right_before_purchase*low_wealth_at_start
xtreg log_expenditure_hurst `reg_controls' i.homeowner _Ilong_befo_1 _IlonXlow_w_1 _Iright_bef_1 _IrigXlow_w_1, fe
regsave using `results', addlabel(lab, "Nondurables") replace

xtreg log_expenditure_hurst_nonH `reg_controls' i.homeowner long_before_purchase#low_wealth_at_start right_before_purchase#low_wealth_at_start, fe 
regsave using `results', addlabel(lab, "Nondurables w/out Housing") append

* NOTE: seems the unknown category is collinear with the fixed effect -- so thats why it gets dropped

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
	lab var coef "Expenditure"
	xtline coef, overlay name("Fig1_fe_housing", replace) title("Life Cycle Profile using FE & control for housing") note("Nondurables in PSID include food, gasoline, utilities, transportation services, and child care." "It does not include other components used in Aguiar Hurst, such as tobacco, clothing,""personal care, domestic services, airfare, nondurable entertainment, gambling, business" "services, and chartiable giving") ytitle(, margin(0 2 0 0))
restore
