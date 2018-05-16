
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
