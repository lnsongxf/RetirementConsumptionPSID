set more off
global folder "C:\Users\pedm\Documents\Research\Cormac\RetirementConsumptionPSID"
use "$folder\Data\Intermediate\Basic-Panel.dta", clear

* Sample selection: households with same husband-wife over time
do "$folder\Do\Sample-Selection.do"

* Look for retirement transitions of the head
do "$folder\Do\Find-Retirements.do"

* Generate aggregate consumption (following Blundell et al)
do "$folder\Do\Consumption-Measures.do"

****************************************************************************************************
** Look at consumption based on time since retirement
** Here retirement year is defined as the first survey wave where they say they are retired
** (though I exclude cases where the self reported ret_year is far from the observed transition)
****************************************************************************************************

* preserve

	gen generated_ret_year_ = ret_year if retirement_transition == 1 & (wave - ret_year) <= 3
	by pid, sort            : egen generated_ret_year = max(generated_ret_year_)

	* Generate time since retirement 
	gen ret_duration = wave - generated_ret_year
	
	collapse *expenditure* transportation_blundell (count) n = expenditure_blundell, by(ret_duration)
	
	drop if ret_duration == .
	keep if ret_duration >= -10 & ret_duration <= 10

	tsset ret_
	label var ret_duration "Duration of Head's Retirement (ret year as self reported)"
	tsline expenditure_blundell, title("") name("expenditure_blundell_3", replace)

	lab var transportation_blundell "Transportation Services"
	lab var gasolineexpenditure "Gasoline Expenditure"
	tsline transportation_blundell gasolineexpenditure, title("Transportation Expenditure") name("transportation", replace)

	tsline healthservicesexpenditure, title("Health Expenditure") name("health", replace)

* restore

