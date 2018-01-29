set more off
* global folder "C:\Users\pedm\Documents\Research\Cormac\RetirementConsumptionPSID"
global folder "C:\Users\Person\Documents\GitHub\RetirementConsumptionPSID"

use "$folder\Data\Intermediate\Basic-Panel.dta", clear

* Switches
global allow_kids_to_leave_hh 1 // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)

// drop if emp_status_head != 1 // only keep employed heads. Question: should I put this so early? ie to split up HH? or later?

* Sample selection: households with same husband-wife over time
do "$folder\Do\Sample-Selection.do"

* Generate aggregate consumption (following Blundell et al)
do "$folder\Do\Consumption-Measures.do"

****************************************************************************************************
** Find home purchases
****************************************************************************************************

sort pid wave                                                // this is very important so that the runsum works correctly
gen homeowner                           = housingstatus == 1 // housing status can be rent, own, or other
by pid, sort: generate runsum_homeowner = sum(homeowner)     // will be 0 if they have never owned previously (in our sample)

sort pid wave
gen homepurchase_                       = wave if homeowner == 1 & L.runsum_homeowner == 0 // select the year that they are first observed owning a house
by pid, sort: egen homepurchase_year    = max(homepurchase_) // replicate this across waves
gen t_homeownership                     = wave - homepurchase_year // duration of homeownership

tab homepurchase_ 
// we observe about 2000 home purchases during this time period
// note: can get more transitions if we go back before 1999 (using old wealth data)
// these observations are observed for at least 2 waves each
// if we restrict ourselves to observations with at least 5 waves, we observe 1193 home purchases

* TODO: can I get a better measure of home purchase year? for instance, do they ask people when they moved into their current house?


* I wonder if it would be interesting to look at savings rates before / after getting either a home equity loan or HELOC
tab type_mortgage2 wave
* (2,136 year-wave observations with home equity loan, 334 year-wave obs with HELOC. plus maybe a few more if we look in type_mortgage1)

****************************************************************************************************
** Only keep those who are observed for at least n waves
****************************************************************************************************

* drop people with positive mortgage expenditure but who do not own a house
* all of these people responded "neither" to the rent or own question
* edit if mortgageexpenditure > 0 & t_homeownership < 0
drop if mortgageexpenditure > 0 & t_homeownership < 0 // these people do not make sense

by pid, sort: egen waves = count(wave)
tab waves if homepurchase_ != .
keep if waves >= 9

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
** Collapse
****************************************************************************************************

* Wow homeequity does some crazy things
* Lots of cases where they own a house and then homeequity becomes 0 for a year
* Or where homeequity is originally huge (perhaps whole value of home) then becomes very low (as in 10-20%)
* edit pid wave homeequity homeowner if t_homeownership != .


* drop if emp_status_head != 1 // only keep employed heads. Question: should I put this earlier? ie to split up HH?
* could do similar if spouse is unemployed?

// gen c_to_i = expenditure_blundell_exhous / inc_fam
// hist c_to_i if t_homeownership == -4

collapse *wealth* inc_* homeequity homeowner housevalue mortgage1 mortgage2 *expenditure* /* c_to_i  (count) n = c_to_i */, by(t_homeownership)
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

tsline rentexpenditure mortgageexpenditure, name("expend", replace) 
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
