set more off
global folder "C:\Users\pedm\Documents\Research\Cormac\RetirementConsumptionPSID"
use "$folder\Data\Intermediate\Basic-Panel.dta", clear

* Switches
global quintiles_definition 4 // Defines quintiles. Can be 1, 2, 3, or 4. My preference is 4
global ret_duration_definition 2 // Defines retirement year. Can be 1, 2, or 3. My preference is 3 (for the sharp income drop) although 2 is perhaps better when looking at consumption data (for smoothness)
global graphs_by_quintile 1 // Graph by quintile. Can be 0 or 1
global allow_kids_to_leave_hh 1 // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)

* Sample selection: households with same husband-wife over time
do "$folder\Do\Sample-Selection.do"

* Look for retirement transitions of the head
do "$folder\Do\Find-Retirements.do"

* Generate aggregate consumption (following Blundell et al)
do "$folder\Do\Consumption-Measures.do"

****************************************************************************************************
** (1) Quintiles based on FAMILY social security income in retirement
**     (using the LAST observed social security income)
****************************************************************************************************
by pid, sort: egen max_year = max(wave)

if $quintiles_definition == 1{
	gen inc_ss_fam_last         = inc_ss_fam if wave == max_year
	xtile quintile_last         = inc_ss_fam_last if wave == max_year & retired == 1, n(5)
	by pid, sort: egen quintile = max(quintile_last)

	** Problem with this measure is that there are lots of cases where inc_ss_fam_last == 0
	** So the lowest quintile isn't made of households with the lowest permanent income
	* hist inc_ss_fam_last if wave == max_year & retired == 1, name("hist", replace)
}


****************************************************************************************************
** (2) Quintiles based on FAMILY social security income in retirement
**     (using the MAX observed social security income)
****************************************************************************************************

if $quintiles_definition == 2{
	by pid, sort: egen max_inc_ss_fam = max(inc_ss_fam)
	xtile quintile_last               = max_inc_ss_fam if wave == max_year & retired == 1, n(5)
	by pid, sort: egen quintile       = max(quintile_last)

	** Problem with this measure is that there are lots of cases where max_inc_ss_fam == 0
	** So the lowest quintile isn't made of households with the lowest permanent income
	* hist max_inc_ss_fam if wave == max_year & retired == 1, name("hist_max", replace)
}


****************************************************************************************************
** (3) Quintiles based on HEAD social security income in retirement
**     Only recorded for 2005 onwards, so when we compute stats by quintile, we exclude familes last 
**     observed before 2005
****************************************************************************************************

if $quintiles_definition == 3{
	xtile quintile_last         = inc_ss_head if wave == max_year & retired == 1 & inc_ss_head > 0, n(5)
	by pid, sort: egen quintile = max(quintile_last)

	** Problem with this measure is that there are lots of cases where inc_ss_head_last == 0
	** So the lowest quintile isn't made of households with the lowest permanent income
	* hist inc_ss_head if wave == max_year & retired == 1, name("hist_head", replace)
}

****************************************************************************************************
** (4) Quintiles based on wealth at time of retirement
****************************************************************************************************

if $quintiles_definition == 4{
	xtile quintile_last         = fam_wealth if retirement_transition == 1, n(5)
	by pid, sort: egen quintile = max(quintile_last)

	** Problem with this measure is that there are lots of cases where inc_ss_head_last == 0
	** So the lowest quintile isn't made of households with the lowest permanent income
	* hist fam_wealth if retirement_transition == 1, name("hist_wealth", replace)
}

label define quintile 1 "1 - Bottom Quintile" 2 "2" 3 "3" 4 "4" 5 "5 - Top Quintile"
label val quintile quintile

****************************************************************************************************
** Define ret_duration
****************************************************************************************************

if $ret_duration_definition == 1{
	** Here retirement year is defined based on whether they have been out of the labor force for more than 12 months
	gen generated_ret_year_               = wave if (month + months_out_lab_force <= 12) & retirement_transition == 1
	replace generated_ret_year_           = wave - 1 if (month + months_out_lab_force > 12) & retirement_transition == 1
	by pid, sort: egen generated_ret_year = max(generated_ret_year_)
	gen ret_duration                      = wave - generated_ret_year
}

if $ret_duration_definition == 2{
	** Here retirement year is defined as self reported retirement year
	gen generated_ret_year_               = wave if retirement_transition == 1
	by pid, sort: egen generated_ret_year = max(generated_ret_year_)
	gen ret_duration                      = wave - generated_ret_year
}

if $ret_duration_definition == 3{
	** Here retirement year is defined as the first survey wave where they say they are retired
	** (though I exclude cases where the self reported ret_year is far from the observed transition)
	gen generated_ret_year_               = ret_year if retirement_transition == 1 & (wave - ret_year) <= 3
	by pid, sort: egen generated_ret_year = max(generated_ret_year_)
	gen ret_duration                      = wave - generated_ret_year
}


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
if $graphs_by_quintile == 0{
	collapse *expenditure* transportation_blundell (count) n = expenditure_blundell, by(ret_duration)
	
	drop if ret_duration == .
	keep if ret_duration >= -10 & ret_duration <= 10

	tsset ret_duration

	label var ret_duration "Duration of Head's Retirement"
	lab var transportation_blundell "Transportation Services"
	lab var gasolineexpenditure "Gasoline Expenditure"

	tsline expenditure_blundell, title("Blundell Expenditure") name("expenditure_blundell", replace)
	tsline expenditure_blundell_eq, title("Blundell Expenditure (Eq Scale)") name("expenditure_blundell_eq", replace)
	tsline expenditure_blundell_exhousing, title("Blundell Expenditure Ex Housing") name("expenditure_blundell_exhousing", replace)

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
	
	label var ret_duration "Duration of Head's Retirement"
	lab var transportation_blundell "Transportation Services"
	lab var gasolineexpenditure "Gasoline Expenditure"

	xtline expenditure_blundell, byopts(title("Blundell Expenditure")) name("expenditure_blundell", replace) ylabel(#3)
	xtline expenditure_blundell_eq, byopts(title("Blundell Expenditure (Eq Scale)")) name("expenditure_blundell_eq", replace) ylabel(#3)
	xtline expenditure_blundell_exhousing, byopts(title("Blundell Expenditure Ex Housing")) name("expenditure_blundell_exhousing", replace) ylabel(#3)

	xtline foodawayfromhomeexpenditure foodathomeexpenditure, byopts(title("Food")) name("food", replace) ylabel(#3)
	xtline taxiexpenditure, byopts(title("Taxis")) name("taxis", replace) ylabel(#3)
	xtline recreationexpenditure clothingexpenditure tripsexpenditure, byopts(title("New Consumption Measures (Post 2005)") rescale ) name("newmeasures", replace) ylabel(#3)
	xtline childcareexpenditure, byopts(title("Child care expenditure")) name("ccare", replace) ylabel(#3)

	xtline educationexpenditure, byopts(title("Education Expenditure")) name("education", replace) ylabel(#3)
	xtline transportation_blundell, byopts(title("Transportation Expenditure")) name("transportation", replace) ylabel(#3)
	xtline gasolineexpenditure, byopts(title("Gasoline")) name("gas", replace) ylabel(#3)
	xtline healthservicesexpenditure healthinsuranceexpenditure, byopts(title("Health Expenditure")) name("health", replace) ylabel(#3)

}
