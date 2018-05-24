set more off
graph close
*set autotabgraphs on

*global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"
* global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
global folder "/Users/bibekbasnet/Documents/GitHub/RetirementConsumptionPSID"

* Switches
global quintiles_definition 2    // Defines quintiles. Can be 1, 2, 3, or 4. My preference is 4. I think the next best option is 2
                                 // Note: if you want tertiles, must use definition 2
global retirement_definition 0   // 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                 // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)
global ret_duration_definition 2 // Defines retirement year. Can be 1, 2, or 3. My preference is 3 (for the sharp income drop) although 2 is perhaps better when looking at consumption data (for smoothness)
global graphs_by_mean 0          // Graph by quintile. Can be 0 or 1
global graphs_by_quintile 0      // Graph by quintile. Can be 0 or 1
global graphs_by_tertile 1       // Tertiles
global allow_kids_to_leave_hh 1  // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                 // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)
global how_to_deal_with_spouse 3  // could be 1 2 3 4 5
global retirement_definition_spouse 1 //// 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                       // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)			 
									 

** LOAD AND PREPARE DATA
use "$folder/Data/Intermediate/Basic-Panel.dta", clear
					 
* Sample selection: households with same husband-wife over time
do "$folder/Do/Sample-Selection.do"

* Look for retirement transitions of the head
do "$folder/Do/Find-Retirements.do"
* NOTE: could also define retirement based on whether you worked < 500 hours that year. Might be worth exploring

* Generate aggregate consumption (following Blundell et al)
do "$folder/Do/Consumption-Measures.do"

do "$folder/Do/Scripts/Define-Quintiles.do"

do "$folder/Do/Scripts/Define-Ret-Duration.do"

	drop if ret_duration == .
	keep if ret_duration >= -10 & ret_duration <= 10

	xtset tertile ret_duration
		preserve
	foreach var of varlist `how_to_deal_with_spouse' {
		xtline expenditure_total_imputed_2005 if spouse = `var' & tertile == 1, over(ret_duration), byopts(title("`var'")rescale ) name("`var'", replace) ylabel(#3)
		xtline expenditure_total_imputed_2005 if spouse  = `var' & tertile == 2, over(ret_duration), byopts(title("`var'")rescale ) name("`var'", replace) ylabel(#3)
		xtline expenditure_total_imputed_2005 if spouse  = `var' & tertile == 3, over(ret_duration), byopts(title("`var'")rescale ) name("`var'", replace) ylabel(#3)

		//graph export "$folder/Results/ConsumptionPostRetirement/Tertile_$how_to_deal_with_spouse/`var'.pdf", as(pdf) replace
		restore

}

* make the plots

