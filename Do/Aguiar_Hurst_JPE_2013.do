set more off
global folder "C:\Users\STUDENT\Documents\GitHub\RetirementConsumptionPSID"
use "$folder\Data\Intermediate\Basic-Panel.dta", clear

* Switches
global quintiles_definition 4    // Defines quintiles. Can be 1, 2, 3, or 4. My preference is 4. I think the next best option is 2
global retirement_definition 0   // 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                 // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)
global ret_duration_definition 2 // Defines retirement year. Can be 1, 2, or 3. My preference is 3 (for the sharp income drop) although 2 is perhaps better when looking at consumption data (for smoothness)
global graphs_by_quintile 1      // Graph by quintile. Can be 0 or 1
global allow_kids_to_leave_hh 1  // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                 // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)
								 
global cohort_graphs 0           // plot graphs by age and cohort (1) or just age controlling for cohort (0) 
								 
* Sample selection: households with same husband-wife over time
* qui do "$folder\Do\Sample-Selection.do"

* Look for retirement transitions of the head
* do "$folder\Do\Find-Retirements.do"

* Generate aggregate consumption (following Blundell et al)
qui do "$folder\Do\Consumption-Measures.do"

****************************************************************************************************
** Aguiar and Hurst prep
****************************************************************************************************

* cap ssc install regsave

keep if age >= 25 & age <= 75

* Aguiar and Hurst:
* We also restrict the sample to households that record a nonzero annual 
* expenditure on six key sub-omponents of the consumption basket: food, 
* entertainment, transportation, clothing and personal care, utilities, and housing/rent.

* In the PSID, they impute missing values
* TODO: find the values thare are imputed
egen missings = rowmiss(foodexpenditure transportationexp utilityexpenditure rent_imputed)
tab missings

* Convert to logs
local collapse_vars 
foreach var of varlist expenditure_hurst expenditure_hurst_nonH ///
	foodathomeexpenditure workrelatedexpenditure nonwork_nondur_expenditure{
	gen log_`var' = log(`var')
	local collapse_vars `collapse_vars' log_`var'
}

xtset pid wave, delta(2)

****************************************************************************************************
** Create cohorts and collapse
****************************************************************************************************
if $cohort_graphs == 1{

egen cohort = cut(year_born), at( 1940(10)1990 ) icodes label
tab cohort, missing
drop if cohort == .

// Panel A plots mean log expenditure
// by age conditional on cohort, normalized year, and family status controls. Each point
// represents the coefficient on the corresponding age dummy from the estimation of equation 4, 
// with age 25 being the omitted group.

collapse  `collapse_vars' (count) c = log_expenditure_hurst (count) c_2005 = workrelatedexpenditure ///
		 [pweight = family_weight], by(age cohort)
		 
keep if c >= 5000
xtset cohort age

****************************************************************************************************
** Figure 1a - by cohorts
** mean log expenditure by age conditional on cohort, normalized year, and family status controls
****************************************************************************************************

xtline  log_expenditure_hurst, overlay name("Fig1a", replace) ///
		title("Fig 1a. Life cycle profiles of nondurable expenditures") 
		
xtline  log_expenditure_hurst_nonH, overlay name("Fig1a_exH", replace) ///
		title("Fig 1a. Life cycle profiles of nondurable expenditures") subtitle("Excluding housing") 

****************************************************************************************************
** Figure 2a - by cohorts
****************************************************************************************************

// The categories are food at home;
// work-related expenses which include transportation, food away from home, and clothing/personal care;
// and core nondurables which include all other categories of total nondurable
// expenditure, including housing services but excluding alcohol and tobacco.

xtline  log_foodathomeexpenditure, overlay name("Fig2a_food", replace) ///
		title("Fig 2a. Food at Home Expenditure") 

xtline  log_workrelatedexpenditure /* if c_2005 >= 5000 */, overlay name("Fig2a_work", replace) ///
		title("Fig 2a. Work Related Expenditure") 
		
xtline  log_nonwork_nondur_expenditure, overlay name("Fig2a_nonwork", replace) ///
		title("Fig 2a. Non Work Non Durable Expenditure") 

}
****************************************************************************************************
** Figure 1a - Control for cohorts as in Aguiar and Hurst
****************************************************************************************************
else{

local family_controls i.married i.fsize i.children i.children0_2 i.children3_5 i.children6_13 i.children14_17m i.children14_17f i.children18_21m i.children18_21f 
* Technically numchild in AH includes all children, not just those under 17
* Question - should i include divorce in marital?

* TODO: d_year*

// quietly reg ln_nondurable age_cat* cohort_cat*  d_year* marital_cat*  hhsize_cat* numchild_cat* child12_cat* child35_cat* child613_cat* 
// child1417m_cat* child1417f_cat* child1821m_cat* child1821f_cat* [aw=adjwt];



reg log_expenditure_hurst i.age i.year_born `family_controls'
tempfile results
regsave using `results', addlabel(lab, "Nondurable Expenditure") replace

reg log_expenditure_hurst_nonH i.age i.year_born `family_controls'
regsave using `results', addlabel(lab, "Nondurable Expenditure w/out housing") append

preserve
use `results', clear

* Find coefs by age
gen is_age = strpos(var, "age")
keep if is_age > 0
drop is_age
destring var, replace ignore("b.age")
rename var age

* Plot results
encode lab, gen(labels)
xtset labels age
lab var age "Age"
lab var coef "Expenditure"
xtline coef, overlay name("Fig1", replace)
restore

****************************************************************************************************
** Figure 2a - Control for cohorts as in Aguiar and Hurst
****************************************************************************************************

reg log_foodathomeexpenditure i.age i.year_born `family_controls'
tempfile results
regsave using `results', addlabel(lab, "Food at Home") replace

reg log_workrelatedexpenditure i.age i.year_born `family_controls'
regsave using `results', addlabel(lab, "Work Related") append

reg log_nonwork_nondur_expenditure i.age i.year_born `family_controls'
regsave using `results', addlabel(lab, "Non Work Related") append

use `results', clear

* Find coefs by age
gen is_age = strpos(var, "age")
keep if is_age > 0
drop is_age
destring var, replace ignore("b.age")
rename var age

* Plot results
encode lab, gen(labels)
xtset labels age
lab var age "Age"
lab var coef "Expenditure"
xtline coef, overlay name("Fig2", replace)


}
