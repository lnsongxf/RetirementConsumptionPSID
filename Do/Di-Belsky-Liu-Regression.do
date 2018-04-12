****************************************************************************************************
** Reproduce Di Belsky Liu Regression using our sample
****************************************************************************************************

set more off
graph close
set autotabgraphs on

global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
cd "$folder\Results" // where to save outreg2 results
use "$folder\Data\Intermediate\Basic-Panel.dta", clear

* Switches
global allow_kids_to_leave_hh 1 // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH
                                // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)

* drop if emp_status_head != 1 // only keep employed heads. Question: should I put this so early? ie to split up HH? or later?

* cap ssc install outreg2
* cap ssc install egenmore

****************************************************************************************************
** Sample selection
****************************************************************************************************


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

* Kids
gen init_kids_ = children if wave == min_year
by pid, sort: egen init_kids = max(init_kids_)

gen end_kids_ = children if wave == max_year
by pid, sort: egen end_kids = max(end_kids_)

gen change_kids = end_kids - init_kids

****************************************************************************************************
** Select Sample
****************************************************************************************************

keep if min_year == 1999 & max_year == 2015
keep if wave == 2015
* TODO: relax the min_year == 1999 restriction

****************************************************************************************************
** Regression (Model A)
****************************************************************************************************

gen log_fam_wealth_real = log(fam_wealth_real) // wealth in final period

* Deal with missing values due to negative or zero wealth
replace log_fam_wealth_real = log(1) if log_fam_wealth_real == .
replace log_init_wealth = log(1) if log_init_wealth == .

gen married_2015 = married == 1
gen divorced_2015 = married == 4

/*inspect log_fam_wealth_real years_owning years_owning2 log_average_income log_init_wealth total_gifts black init_HS init_some_college init_college_plus educ_improvement init_age married_2015 divorced_2015 region metro_2015 change_kids*/


reg log_fam_wealth_real years_owning years_owning2 log_average_income log_init_wealth total_gifts i.black i.init_HS i.init_some_college i.init_college_plus educ_improvement init_age i.married_2015 i.divorced_2015 i.region i.metro_2015 change_kids
qui outreg2 using "DiBelskyLiu_Reg.xls", ctitle(Model A) excel replace nose noaster
qui outreg2 using "DiBelskyLiu_Means.xls", ctitle(Model A) excel replace nose noaster sum

* Years owning as dummy
qui reg log_fam_wealth_real i.years_owning log_average_income log_init_wealth total_gifts i.black i.init_HS i.init_some_college i.init_college_plus educ_improvement init_age i.married_2015 i.divorced_2015 i.region i.metro_2015 change_kids
qui outreg2 using "DiBelskyLiu_Reg.xls", ctitle(Model A Dummy) excel nose noaster
qui outreg2 using "DiBelskyLiu_Means.xls", ctitle(Model A Dummy) excel nose noaster sum

****************************************************************************************************
** Regression (Model B)
****************************************************************************************************

* Generate quartiles

egen init_wealth_quant = xtile(log_init_wealth), n(4)

reg log_fam_wealth_real years_owning years_owning2 log_average_income total_gifts i.init_wealth_quant i.black i.init_HS i.init_some_college i.init_college_plus educ_improvement init_age i.married_2015 i.divorced_2015 i.region i.metro_2015 change_kids
qui outreg2 using "DiBelskyLiu_Reg.xls", ctitle(Model B) excel nose noaster
qui outreg2 using "DiBelskyLiu_Means.xls", ctitle(Model B) excel nose noaster sum

qui reg log_fam_wealth_real i.years_owning log_average_income total_gifts i.init_wealth_quant i.black i.init_HS i.init_some_college i.init_college_plus educ_improvement init_age i.married_2015 i.divorced_2015 i.region i.metro_2015 change_kids
qui outreg2 using "DiBelskyLiu_Reg.xls", ctitle(Model B Dummy) excel nose noaster
qui outreg2 using "DiBelskyLiu_Means.xls", ctitle(Model B Dummy) excel nose noaster sum

****************************************************************************************************
** Means for each variable
****************************************************************************************************
