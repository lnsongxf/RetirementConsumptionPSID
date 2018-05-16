********************************************************************************
** Look at LTV at time of purchase
**
** (1) Prepare data
********************************************************************************

set more off
graph close
set autotabgraphs on

*global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"
global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"

use "$folder/Data/Intermediate/Basic-Panel.dta", clear

* Switches
global allow_kids_to_leave_hh 1 // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)
global collapse_graphs        0 // Do we want to see the graphs where we collapse by t_homeownership?

// drop if emp_status_head != 1 // only keep employed heads. Question: should I put this so early? ie to split up HH? or later?

* Sample selection: households with same husband-wife over time
qui do "$folder/Do/Sample-Selection.do"

* Generate aggregate consumption (following Blundell et al)
qui do "$folder/Do/Consumption-Measures.do"

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
qui do "$folder/Do/Find-First-Home-Purchase.do"

drop if mortgageexpenditure > 0 & t_homeownership < 0 // these people do not make sense

* cap ssc install qregpd
* cap ssc install moremata

keep if age >= 22 & age <= 75

********************************************************************************
** Look at LTV at time of purchase
********************************************************************************

* I think this is the best way to compute LTV
gen LTV = (mortgage1 + mortgage2) / housevalue if t_homeownership == 0
* Better than this option gen LTV = ( housevalue - homeequity) / housevalue which I am guessing suffers from PSID imputation

* Maybe I should ignore the people who have LTV == 0?
sum LTV if t_homeownership == 0 & LTV <= 2 & LTV > 0, detail

sum LTV if t_homeownership == 0  & mortgage1 > 0, detail
* reg LTV i.wave if t_homeownership == 0 , nocon
reg LTV i.wave if t_homeownership == 0 & mortgage1 > 0, nocon




* Muelbauer reports that LTVs for first time home buyers rose from 85% in 1990 to 87.5 in 2000 to around 92.5% around 2005
* http://onlinelibrary.wiley.com/doi/10.1111/j.1468-0297.2011.02424.x/epdf

* Derived from the American Housing Survey (AHS), this series
* implies that down-payment constrain ts were eased early this decade (Figure 1), in line
* with Doms and KrainerÕs (2007) finding that homeownership rates rose among the
* young.

* NOTE: the AHS also has info on the source of down payment
* But they ask if of all people (no matter how long youve owned the house)
* So when looking online, obviously the big source of DP comes from previous sale
* https://www.census.gov/content/dam/Census/programs-surveys/ahs/data/2011/h150-11.pdf
* Could take a look at first time home buyers -- what are their sources?
* Probably mostly "Savings or cash on hand"
* Note: could also look at refi prevalence using this data
* Though dunno if that's useful



* TODO: try more robust SEs
* Look at consumption w/out the panel aspect -> better SEs?
* Look at food consumption

* Look at LTV at purchase
