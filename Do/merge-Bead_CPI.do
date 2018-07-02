
    set more off
    graph close

   
    *set autotabgraphs on
    *set trace on

    * global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"
    * global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
    global folder "/Users/bibekbasnet/Documents/GitHub/RetirementConsumptionPSID"
   // global folder_output "$folder/Results/Regression_Table"

    cap mkdir "$folder_output"
    cap ssc install outreg2

    local expenditure_cats_all total_foodexp_home_real total_foodexp_away_real total_housing_real ///
        total_education_real total_transport_real total_recreation_2005_real total_clothing_2005_real total_healthexpense_real

 // forvalues spouse_def = 1/1 {   

use "$folder/Data/Intermediate/Basic-Panel.dta", clear

* Switches
global quintiles_definition 2    // Defines quintiles. Can be 1, 2, 3, or 4. My preference is 4. I think the next best option is 2
                                 // Note: if you want tertiles, must use definition 2
global retirement_definition 0   // 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                 // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)
global ret_duration_definition 2 // Defines retirement year. Can be 1, 2, or 3. My preference is 3 (for the sharp income drop) although 2 is perhaps better when looking at consumption data (for smoothness)
global graphs_by_mean 0          // Graph by quintile. Can be 0 or 1
global graphs_by_quintile 0      // Graph by quintile. Can be 0 or 1
global graphs_by_tertile 1       // Tertiles
global make_barplots 1
global allow_kids_to_leave_hh 1  // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                 // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)
global how_to_deal_with_spouse 1  // could be 1 2 3 4 5
global retirement_definition_spouse 1 //// 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                       // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)             
                                 
* Sample selection: households with same husband-wife over time
//do "$folder/Do/Sample-Selection.do"

* Look for retirement transitions of the head
do "$folder/Do/Find-Retirements.do"
* NOTE: could also define retirement based on whether you worked < 500 hours that year. Might be worth exploring

* Generate aggregate consumption (following Blundell et al)
do "$folder/Do/Consumption-Measures.do"

do "$folder/Do/Scripts/Define-Quintiles.do"

do "$folder/Do/Scripts/Define-Ret-Duration.do"

 gen year = wave - 1 // note that expenditure data is for year prior to interview
 merge m:1 year using "$folder/Data/Intermediate/CPI.dta"
 drop if _m == 2
 drop year _m

gen year = wave - 1 // note that expenditure data is for year prior to interview
merge m:1 year using "$folder/Data/Raw/bead.dta"
drop if _m == 2
drop year _m

// drop break_d

save "$folder/Data/Intermediate/Basic-Panel.dta", replace




