set more off
global folder "C:\Users\pedm\Documents\Research\Cormac\RetirementConsumptionPSID"
use "$folder\Data\Intermediate\Basic-Panel.dta", clear

global retirement_definition 0   // 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                 // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)
global allow_kids_to_leave_hh 1  // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                 // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)

* Sample selection: households with same husband-wife over time
do "$folder\Do\Sample-Selection.do"

* Look for retirement transitions of the head
do "$folder\Do\Find-Retirements.do"

****************************************************************************************************
** Look at income based on time since retirement
** Here time since retirement is based on my generated retirement year
****************************************************************************************************

local inc_measures inc_fam inc_head inc_spouse inc_transfer inc_ss_fam

preserve
	* Generate my best guess of the year that they retired (assuming some retirement_transition variable as baseline)
	* Guess is based on whether they have been out of the labor force for more than 12 months
	* WARNING: months_out_lab_force does not exist in 1999 and 2001
	gen generated_ret_year_               = wave if (month + months_out_lab_force <= 12) & retirement_transition == 1
	replace generated_ret_year_           = wave - 1 if (month + months_out_lab_force > 12) & retirement_transition == 1
	by pid, sort: egen generated_ret_year = max(generated_ret_year_)
	
	gen dif2 = generated_ret_year_ - ret_year if retirement_transition == 1 
	tab dif2

	* Generate time since retirement 
	gen ret_duration = wave - generated_ret_year
	
	collapse inc_*, by(ret_duration)
	
	tsset ret_
	label var ret_duration "Duration of Head's Retirement (ret year = first retired wave - months out)"
	tsline `inc_measures', title("Income based on time since head's retirement") name("income_by_ret_duration", replace) ylabel(#3)
restore


****************************************************************************************************
** Look at income based on time since retirement
** Here retirement year is defined as self reported retirement year
****************************************************************************************************

preserve
	gen generated_ret_year_               = wave if retirement_transition == 1
	by pid, sort: egen generated_ret_year = max(generated_ret_year_)

	* Generate time since retirement 
	gen ret_duration = wave - generated_ret_year
	
	collapse inc_*, by(ret_duration)
	
	tsset ret_
	label var ret_duration "Duration of Head's Retirement (ret year = first retired wave)"
	tsline `inc_measures', title("Income based on time since head's retirement") name("income_by_ret_duration_2", replace) ylabel(#3)
restore


****************************************************************************************************
** Look at income based on time since retirement
** Here retirement year is defined as the first survey wave where they say they are retired
** (though I exclude cases where the self reported ret_year is far from the observed transition)
****************************************************************************************************

preserve
	gen generated_ret_year_               = ret_year if retirement_transition == 1 & (wave - ret_year) <= 3
	by pid, sort: egen generated_ret_year = max(generated_ret_year_)

	* Generate time since retirement 
	gen ret_duration = wave - generated_ret_year
	
	collapse inc_*, by(ret_duration)
	
	tsset ret_
	label var ret_duration "Duration of Head's Retirement (ret year as self reported)"
	tsline `inc_measures', title("Income based on time since head's retirement") name("income_by_ret_duration_3", replace) ylabel(#3)
restore
