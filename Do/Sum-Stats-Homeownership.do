set more off
global folder "C:\Users\pedm\Documents\Research\Cormac\RetirementConsumptionPSID"
use "$folder\Data\Intermediate\Basic-Panel.dta", clear

* Switches
global allow_kids_to_leave_hh 1 // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)

drop if emp_status_head != 1 // only keep employed heads. Question: should I put this earlier? ie to split up HH? or later?

* Sample selection: households with same husband-wife over time
do "$folder\Do\Sample-Selection.do"

* Generate aggregate consumption (following Blundell et al)
do "$folder\Do\Consumption-Measures.do"

****************************************************************************************************
** Find home purchases
****************************************************************************************************

gen homeowner                           = housingstatus == 1 // housing status can be rent, own, or other
by pid, sort: generate runsum_homeowner = sum(homeowner) // will be 0 if they have never owned previously (in our sample)
gen homepurchase_                       = wave if homeowner == 1 & L.runsum_homeowner == 0 // select the year that they are first observed owning a house
by pid, sort: egen homepurchase_year    = max(homepurchase_) // replicate this across waves
gen t_homeownership                     = wave - homepurchase_year // duration of homeownership

tab homepurchase_ 
// we observe about 2000 home purchases during this time period
// note: can get more transitions if we go back before 1999 (using old wealth data)
// these observations are observed for at least 2 waves each
// if we restrict ourselves to observations with at least 5 waves, we observe 1193 home purchases

* TODO: can I get a better measure of home purchase year? for instance, do they ask people when they moved into their current house?

****************************************************************************************************
** Only keep those who are observed for at least n waves
****************************************************************************************************

by pid, sort: egen waves = count(wave)
tab waves if homepurchase_ != .
keep if waves >= 9

* Only keep those observed at least 4 years before home purchase
by pid, sort: egen min_t = min(t_homeownership)
keep if min_t <= -4

* And do the same on the other side
by pid, sort: egen max_t = max(t_homeownership)
keep if max_t >= 4

****************************************************************************************************
** Collapse
****************************************************************************************************

* Wow homeequity does some crazy things
* Lots of cases where they own a house and then homeequity becomes 0 for a year
* Or where homeequity is originally huge (perhaps whole value of home) then becomes very low (as in 10-20%)
* edit pid wave homeequity homeowner if t_homeownership != .


* drop if emp_status_head != 1 // only keep employed heads. Question: should I put this earlier? ie to split up HH?
* could do similar if spouse is unemployed?

gen c_to_i = expenditure_blundell_exhousing / inc_fam
hist c_to_i if t_homeownership == -4

collapse *wealth* homeequity homeowner housevalue mortgage1 mortgage2 *expenditure* c_to_i (count) n = c_to_i, by(t_homeownership)
drop if t_homeownership == .

drop if t_homeownership < -4 | t_homeownership > 4

tsset t_homeownership

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

tsline rentexpenditure mortgageexpenditure, name("expend", replace) 
* why do some people have mortgage expenditure before buying a house? weirdos
* interesting to notice that expenditure goes up substantially when buying the house. avg rent of 6k, avg mortgage of 8k 
* (and this is not being driven by marriage. still holds if i set waves >= 9)
* though what if we just look at those who are observed earlier?

* todo: issues related to nominal vs real?

tsline expenditure_blundell, name("blundell", replace)
tsline expenditure_blundell_eq, name("blundell_eq", replace)
tsline expenditure_blundell_exhousing, name("expenditure_blundell_exhousing", replace)
tsline expenditure_blundell_eq_exH, name("expenditure_blundell_eq_exH", replace)
tsline furnishingsexpenditure, name("furnishingsexpenditure", replace)

tsline c_to_i , name("c_to_i", replace)


* question: do we know when the marriage takes place? i just realized that a "wife" can transition to wife. and this will still be included in current sample
