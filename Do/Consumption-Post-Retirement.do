set more off
graph close
*set autotabgraphs on

*global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"
* global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
global folder "/Users/bibekbasnet/Documents/GitHub/RetirementConsumptionPSID"


use "$folder/Data/Intermediate/Basic-Panel.dta", clear

* Switches
global quintiles_definition 2    // Defines quintiles. Can be 1, 2, 3, or 4. My preference is 4. I think the next best option is 2
                                 // Note: if you want tertiles, must use definition 2
global retirement_definition 0   // 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                 // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)
global ret_duration_definition 2 // Defines retirement year. Can be 1, 2, or 3. My preference is 3 (for the sharp income drop) although 2 is perhaps better when looking at consumption data (for smoothness)
global graphs_by_mean 0          // Graph by quintile. Can be 0 or 1
global graphs_by_quintile 1      // Graph by quintile. Can be 0 or 1
global graphs_by_tertile 1       // Tertiles
global allow_kids_to_leave_hh 1  // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                 // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)
global how_to_deal_with_spouse 1  // could be 1 2 3 4 5
global retirement_definition_spouse 1 //// 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                       // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)			 
								 
* Sample selection: households with same husband-wife over time
do "$folder/Do/Sample-Selection.do"

* Look for retirement transitions of the head
do "$folder/Do/Find-Retirements.do"
* NOTE: could also define retirement based on whether you worked < 500 hours that year. Might be worth exploring

* Generate aggregate consumption (following Blundell et al)
do "$folder/Do/Consumption-Measures.do"

do "$folder/Do/Scripts/Define-Quintiles.do"

do "$folder/Do/Scripts/Define-Ret-Duration.do"

****************************************************************************************************
** Look at consumption based on time since retirement
** Here retirement year is defined as the first survey wave where they say they are retired
** (though I exclude cases where the self reported ret_year is far from the observed transition)
****************************************************************************************************

** Only keep those who are observed for at least n waves
* by pid, sort: egen waves = count(wave)
* keep if waves >= 5
* tab waves if retirement_transition == 1

* Graph averages by ret_duration
if $graphs_by_mean == 1{
	collapse *expenditure* transportation_blundell (count) n = expenditure_blundell, by(ret_duration)
	
	drop if ret_duration == .
	keep if ret_duration >= -10 & ret_duration <= 10

	tsset ret_duration

	label var ret_duration "Duration of Head's Retirement"
	lab var transportation_blundell "Transportation Services"
	lab var gasolineexpenditure "Gasoline Expenditure"
	lab var healthcareexpenditure "Health care"
	lab var healthinsuranceexpenditure "Health insurance"
	lab var healthservicesexpenditure "Health services"
	lab var tripsexpenditure "Trips"
	lab var recreationexpenditure "Recreation"
	lab var clothingexpenditure "Clothing"
	lab var foodathomeexpenditure "Food at home"
	lab var foodawayfromhomeexpenditure "Food away from home"

	tsline expenditure_blundell, title("Blundell Expenditure") name("expenditure_blundell", replace)
	tsline expenditure_blundell_eq, title("Blundell Expenditure (Eq Scale)") name("expenditure_blundell_eq", replace)
	tsline expenditure_blundell_exhous, title("Blundell Expenditure Ex Housing") name("expenditure_blundell_exhous", replace)
	tsline expenditure_blundell_exhealth,  title("Blundell Expenditure Ex Health") name("expenditure_blundell_exhealth", replace)
	tsline expenditure_blundell_ex3, title("Blundell Expenditure Ex Edu, Child Care, Health") name("expenditure_blundell_ex3", replace)
	
	tsline foodawayfromhomeexpenditure foodathomeexpenditure, title("Food") name("food", replace)
	tsline taxiexpenditure, title("Taxis") name("taxis", replace)
	tsline recreationexpenditure clothingexpenditure tripsexpenditure, title("New Consumption Measures (Post 2005)") name("newmeasures", replace)
	tsline childcareexpenditure, title("Child care expenditure") name("ccare", replace)

	tsline educationexpenditure, title("Education Expenditure") name("education", replace)
	tsline transportation_blundell gasolineexpenditure, title("Transportation Expenditure") name("transportation", replace)
	tsline healthservicesexpenditure healthinsuranceexpenditure, title("Health Expenditure") name("health", replace)
}

* Graph averages by ret_duration and quintile
if $graphs_by_quintile == 1{
	collapse *expenditure* transportation_blundell (count) n = expenditure_blundell, by(ret_duration quintile)
	
	drop if ret_duration == .
	keep if ret_duration >= -10 & ret_duration <= 10

	xtset quintile ret_duration
	
	lab var ret_duration "Duration of Head's Retirement"
	lab var transportation_blundell "Transportation Services"
	lab var gasolineexpenditure "Gasoline Expenditure"
	lab var healthcareexpenditure "Health care"
	lab var healthinsuranceexpenditure "Health insurance"
	lab var healthservicesexpenditure "Health services"
	lab var tripsexpenditure "Trips"
	lab var recreationexpenditure "Recreation"
	lab var clothingexpenditure "Clothing"
	lab var foodathomeexpenditure "Food at home"
	lab var foodawayfromhomeexpenditure "Food away from home"
	lab var expenditure_blundell_eq "Nondurable Consumption (Equivalence Scale)"
	lab var workexpenditure "Work Related Expenditure" // excludes clothing
	
	xtline workexpenditure if (ret_duration != 10 | quintile != 3), byopts(title("Work Related Expenditure")) name("work_expenditure", replace) ylabel(#3)
	graph export "$folder/Results/ConsumptionPostRetirement/work.pdf", as(pdf) replace

	xtline expenditure_blundell, byopts(title("Blundell Expenditure")) name("expenditure_blundell", replace) ylabel(#3)
	
	xtline expenditure_blundell_eq, byopts(title("Nondurable Consumption") rescale) name("expenditure_blundell_eq", replace) ylabel(#3)
	graph export "$folder/Results/ConsumptionPostRetirement/expenditure_blundell_eq.pdf", as(pdf) replace
	
	xtline expenditure_blundell_exhous, byopts(title("Blundell Expenditure Ex Housing")) name("expenditure_blundell_exhous", replace) ylabel(#3)
	xtline expenditure_blundell_exhealth,  byopts(title("Blundell Expenditure Ex Health")) name("expenditure_blundell_exhealth", replace) ylabel(#3)

	xtline foodawayfromhomeexpenditure foodathomeexpenditure, byopts(title("Food")) name("food", replace) ylabel(#3)
	graph export "$folder/Results/ConsumptionPostRetirement/food.pdf", as(pdf) replace
	
	xtline taxiexpenditure, byopts(title("Taxis")) name("taxis", replace) ylabel(#3)
	xtline recreationexpenditure clothingexpenditure tripsexpenditure, byopts(title("New Consumption Measures (Post 2005)") rescale ) name("newmeasures", replace) ylabel(#3)
	
	xtline tripsexpenditure, byopts( title("Vacations/Trips Expenditure") rescale ) name("trips", replace) ylabel(#3)
	graph export "$folder/Results/ConsumptionPostRetirement/trips.pdf", as(pdf) replace
	
	xtline childcareexpenditure, byopts(title("Child care expenditure")) name("ccare", replace) ylabel(#3)

	xtline educationexpenditure, byopts(title("Education Expenditure")) name("education", replace) ylabel(#3)
	xtline transportation_blundell, byopts(title("Transportation Expenditure")) name("transportation", replace) ylabel(#3)
	xtline gasolineexpenditure, byopts(title("Gasoline")) name("gas", replace) ylabel(#3)
	xtline healthservicesexpenditure healthinsuranceexpenditure, byopts(title("Health Expenditure")) name("health", replace) ylabel(#3)
}

local expenditure_cats total_foodexp_home_real total_foodexp_away_real total_housing_real ///
		total_education_real total_healthexpense_real total_transport_real transport_durables

local expenditure_cats_2005 total_foodexp_home_real total_foodexp_away_real ///
		total_education_real total_healthexpense_real total_transport_real transport_durables ///
		total_housing_2005_real total_recreation_2005_real total_clothing_2005_real 
		
egen expenditure_cats_2005       = rowtotal(`expenditure_cats_2005') if wave >= 2005

		
lab var ret_duration "Duration of Head's Retirement"


****************************************************************************************************
** Graphs by tertile
****************************************************************************************************

if $graphs_by_tertile == 1{
preserve
	cap mkdir "$folder/Results/ConsumptionPostRetirement/Tertile_$how_to_deal_with_spouse/"
	
	collapse `expenditure_cats' , by(ret_duration tertile)
	
	drop if ret_duration == .
	keep if ret_duration >= -10 & ret_duration <= 10

	xtset tertile ret_duration
		
	foreach var of varlist `expenditure_cats' {
		xtline `var', byopts(title("`var'") rows(1) rescale ) name("`var'", replace) ylabel(#3)
		graph export "$folder/Results/ConsumptionPostRetirement/Tertile_$how_to_deal_with_spouse/`var'.pdf", as(pdf) replace
	}
restore


preserve
	keep if wave >= 2005
	collapse `expenditure_cats_2005' , by(ret_duration tertile)
	xtset tertile ret_duration

	drop if ret_duration == .
	keep if ret_duration >= -10 & ret_duration <= 10

	foreach var of varlist `expenditure_cats_2005' {
		di "`var'"
		xtline `var', byopts(title("`var'") rescale ) name("`var'", replace) ylabel(#3) 
		graph export "$folder/Results/ConsumptionPostRetirement/Tertile_$how_to_deal_with_spouse/`var'.pdf", as(pdf) replace
	}
restore
}

******************

****************************************************************************************************
** Stacked bar plots - how do the categories add up
****************************************************************************************************

* Compare the sum 
preserve
	collapse `expenditure_cats' expenditure_total_pre2005_real, by(age)
	egen expenditure_total_imputed = rowtotal(`expenditure_cats')
	tsset age
	tsline expenditure_total_imputed expenditure_total_pre2005_real, name(expenditure_pre2005, replace)
restore


preserve
	collapse `expenditure_cats' expenditure_total_pre2005_real, by(ret_duration)
	egen expenditure_total_imputed = rowtotal(`expenditure_cats')
	tsset ret_duration
	tsline expenditure_total_imputed expenditure_total_pre2005_real
restore

** Doing this by tertile
graph bar `expenditure_cats', over(ret_duration) stack name("fig1", replace)
graph bar expenditure_total_pre2005_real, over(ret_duration) stack name("fig2", replace)

label variable total_foodexp_home_real "Food at Home"
graph bar total_foodexp_home_real , over(ret_duration ) 

preserve
	keep if ret_duration >= -8 & ret_duration <= 8
	graph bar `expenditure_cats' if tertile == 1, over(ret_duration) stack name("tertile1", replace) percent title("Bottom Tertile")
	graph bar `expenditure_cats' if tertile == 2, over(ret_duration) stack name("tertile2", replace) percent title("Middle Tertile")
	graph bar `expenditure_cats' if tertile == 3, over(ret_duration) stack name("tertile3", replace) percent title("Top Tertile")
restore

***
** For the post 2005 consumption expenditure
/*
 graph bar `expenditure_cats_2005', over(ret_duration) stack name ("fig3", replace)
 graph bar `expenditure_total_post2005_real', over(ret_duration) stack name("fig4", replace)

*/
 
 ****************************************************************************************************
** Post 2005: Stacked bar plots - how do the categories add up
****************************************************************************************************
* Compare the Sum 

preserve
	collapse `expenditure_cats_2005' expenditure_total_post2005_real, by(age)
	egen expenditure_total_imputed_2005 = rowtotal(`expenditure_cats_2005')
	tsset age
	tsline expenditure_total_imputed_2005 expenditure_total_post2005_real, name(expenditure_post2005, replace)
restore

preserve
	collapse `expenditure_cats_2005' expenditure_total_post2005_real, by(ret_duration)
	egen expenditure_total_imputed_2005 = rowtotal(`expenditure_cats_2005')
	tsset ret_duration
	tsline expenditure_total_imputed_2005 expenditure_total_post2005_real
restore


* Post 2005: Doing by tertile

graph bar `expenditure_cats_2005', over(ret_duration) stack name("fig3", replace)
graph bar expenditure_total_post2005_real, over(ret_duration) stack name("fig4", replace)

preserve
	keep if ret_duration >= -8 & ret_duration <= 8
	graph bar `expenditure_cats_2005' if tertile == 1, over(ret_duration) stack name("tertile1_post2005", replace) percent title("Bottom Tertile")
	graph bar `expenditure_cats_2005' if tertile == 2, over(ret_duration) stack name("tertile2_post2005", replace) percent title("Middle Tertile")
	graph bar `expenditure_cats_2005' if tertile == 3, over(ret_duration) stack name("tertile3_post2005", replace) percent title("Top Tertile")
restore

 
* 1) make a new category of durables so that fig 1 has same as fig2 (durables in health? transportation? ...?) (any nondurables that we're missing?)
* More or less they add up. But the category we created is slightly higher than the expenditure in total. I beleive it is mostly due to 

* 2) do the same thing, post 2005 (with new variables)
* more variation compared ot the pre 2005 calculations 

* 3) make bar plots by tertile
* plotted

* 4) income graphs by different definitions of retirement (aka spouse never works, etc.)
* Done/ Did for four categories. Since the categories. Since the category five, is 

* 5) expenditure categories by retirement duration, based on the 5 definitions of what the spouse does
**** by tertile, 1 categories, 5 definitions of what the spouse does
* loop
* expenditure_category_x_spouse_definition_y.pdf

* 6) tertile figures - we'll make it be 3 columns
	



