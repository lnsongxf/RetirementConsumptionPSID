****************************************************************************************************
** Run SUR for aux model
****************************************************************************************************

set more off
graph close
set autotabgraphs on

global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
use "$folder\Data\Intermediate\Basic-Panel.dta", clear

* Switches
global allow_kids_to_leave_hh 1 // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH
                                // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)

* drop if emp_status_head != 1 // only keep employed heads. Question: should I put this so early? ie to split up HH? or later?

* cap ssc install mat2txt

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
** Define variables
****************************************************************************************************
keep if age >= 20 & age <= 65
* keep if age >= 20 & age <= 65

gen consumption = expenditure_exH_real_2015 // blundell expenditure excluding housing
gen liq_wealth = fam_liq_wealth_real // 2015 dollars
gen housing_wealth = fam_LiqAndH_wealth_real - fam_liq_wealth_real // 2015 dollars
gen housing = housingstatus == 1 // renting or living with parents are considered as the same
gen income = inc_fam_real_2015 // TODO: will need to subtract out taxes using NBER TAXSIM

local endog_vars housing
foreach var of varlist consumption liq_wealth housing_wealth income{
  gen log_`var' = log(`var')
  replace log_`var' = log(1) if `var' <= 0 & `var' != .
  local endog_vars `endog_vars' log_`var'
}

****************************************************************************************************
** Run regression
****************************************************************************************************

sureg (`endog_vars' = L.(`endog_vars') age age_sq)

matrix list e(b) // coefs
mat coefs = e(b)
// matrix list e(V) // variance-covariance matrix of the estimators
// mat list e(Sigma) // sigma hat = covariance matrix of the residuals
mat sigma = e(Sigma)

// e(sample)         marks estimation sample
local filename ""

mat2txt, matrix(coefs) saving("$folder/Results/Aux_Model_Estimates/coefs`filename'.txt") replace
mat2txt, matrix(sigma) saving("$folder/Results/Aux_Model_Estimates/sigma`filename'.txt") replace

gen sample = e(sample)

****************************************************************************************************
** Generate initial data for simulation
****************************************************************************************************

preserve
  by pid, sort: egen min_year = min(wave)
  keep if F.sample == 1 & age <= 30 & wave == min_year // first observation for each indiv is not in the sample b/c of the lag

  count
  keep pid `endog_vars' age age_sq
  order pid `endog_vars' age age_sq
  gen cons = 1
  export delimited using "$folder/Results/Aux_Model_Estimates/InitData.csv", replace
restore

****************************************************************************************************
** Save age patterns
****************************************************************************************************

preserve
  keep if F.sample == 1 | sample == 1
  keep pid `endog_vars' age age_sq
  order pid `endog_vars' age age_sq
  gen cons = 1

  collapse (median) housing-log_inc, by(age)
  tsset age
  save "$folder/Results/Aux_Model_Estimates/PSID_by_age_median.csv", replace
restore

preserve
  keep if F.sample == 1 | sample == 1
  keep pid `endog_vars' age age_sq
  order pid `endog_vars' age age_sq
  gen cons = 1

  collapse (mean) housing-log_inc, by(age)
  tsset age
  save "$folder/Results/Aux_Model_Estimates/PSID_by_age_mean.csv", replace
restore
