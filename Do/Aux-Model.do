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

global aux_model_in_logs 1 // 1 = logs, 0 = levels

global drop_top_x 0 // can be 0, 1, or 5

global estimate_reg_by_age 1 // 0 is our baseline where we estimate SUREG with everyone pooled together. 1 is alternative where we do two buckets
global cutoff_age 50

global no_age_coefs 1 // default is  0 (include age and age2)

* NOTE: I manually removed age and age2 from the SUR

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
keep if age >= 25 & age <= 65
* keep if age >= 20 & age <= 65

gen consumption = expenditure_exH_real_2015 // blundell expenditure excluding housing
gen liq_wealth = fam_liq_wealth_real // 2015 dollars
* gen housing_wealth = fam_LiqAndH_wealth_real - fam_liq_wealth_real // 2015 dollars (includes other housing wealth)
gen housing_wealth = homeequity_real
gen housing = housingstatus == 1 // renting or living with parents are considered as the same
gen income = inc_fam_real_2015 // TODO: will need to subtract out taxes using NBER TAXSIM
gen illiq_wealth = fam_wealth_real - fam_liq_wealth_real // NOTE: we do not use this in the regressions, just use it for our alternative measure of WHtM
gen hand_to_mouth = liq_wealth <= (income / 24)

if $aux_model_in_logs == 1{
  * Run the model in logs
  local level_vars consumption liq_wealth housing_wealth income
  local endog_vars housing
  foreach var of varlist `level_vars' {
    gen log_`var' = log(`var')
    replace log_`var' = log(1) if `var' <= 0 & `var' != .
    local endog_vars `endog_vars' log_`var'
  }
}
else if $aux_model_in_logs == 0{
  * Run the model in levels
  local level_vars
  local endog_vars housing consumption liq_wealth housing_wealth income
}


****************************************************************************************************
** Simple means and medians by age EXCLUDING TOP x%
****************************************************************************************************
* TODO: definie this based on fam_wealth_real or Liquid + Housing wealth?

if $drop_top_x > 0{
  gen NetWealth = liq_wealth + housing_wealth

  * local sort_var fam_wealth_real
  local sort_var NetWealth

  * Find top x% by age
  by age, sort: egen p95 = pctile(`sort_var'), p(95)
  by age, sort: egen p99 = pctile(`sort_var'), p(99)
  * TODO: try this with a dif measure of wealth ?

  * Plot the 95th and 99th percentiles
  preserve
  	keep age p95 p99
  	duplicates drop
  	sort age
  	list
  	tsset age
  	tsline p95 p99
  restore

  * Flag observations in the top x%
  gen top_95_ = `sort_var' >= p95 & `sort_var' != .
  gen top_99_ = `sort_var' >= p99 & `sort_var' != .

  * Flag HHs with any observation in the top x%
  by pid, sort: egen top_95 = max(top_95_)
  by pid, sort: egen top_99 = max(top_99_)

  tab top_95
  tab top_99

  * Plot while excluding those in top 1% in any wave
  if $drop_top_x == 1 {
    drop if top_99 == 1
  }
  if $drop_top_x == 5 {
    drop if top_95 == 1
  }

  sort pid wave

}


local control_vars age age_sq
* local control_vars hand_to_mouth age age_sq

****************************************************************************************************
** Consumption before purchase
****************************************************************************************************

/** Shift t_homeownership so that all values are positive (needed for i. command)
gen t_homeownership_100 = t_homeownership + 100
replace t_homeownership_100 = 92 if t_homeownership_100 < 92
replace t_homeownership_100 = 1000 if t_homeownership == . // | t_homeownership_100 >= 102

gen LTV = (mortgage1 + mortgage2) / housevalue if t_homeownership == 0
// gen ignore_t0 = (LTV == 0 | LTV < 0.1 | mortgage1 == 0 ) & t_homeownership == 0
/*gen ignore_t0 = (LTV == 0 | LTV < 0.7 | mortgage1 == 0 | LTV > 1) & t_homeownership == 0*/
gen ignore_t0 = (LTV == 0 | LTV < 0.1 | mortgage1 == 0 ) & t_homeownership == 0
by pid, sort: egen ignore = max(ignore_t0)
gen t_homeownership_100_w_mortgage = t_homeownership_100 * (ignore != 1)




* TODO: add dummy if they have a mortgage when they buy home
reg log_consumption ib100.t_homeownership_100_w_mortgage /* L.(`endog_vars') */ `control_vars'
/* log_inc_fam_real i.married_dummy i.fsize_topcode i.children_topcode i.wave, fe vce(robust) */

by pid, sort: egen min_t_homeownership_100 = min(t_homeownership_100)
keep if min_t_homeownership_100 <= 94
collapse (median) log_consumption log_liq_wealth log_housing_wealth log_income consumption liq_wealth housing_wealth housing income, by( t_homeownership_100_w_mortgage )*/


****************************************************************************************************
** Drop renters with home equity
****************************************************************************************************

drop if housing == 0 & housing_wealth != 0

/*sum housing_wealth if housing == 1
sum housing_wealth if housing == 0*/

****************************************************************************************************
** Run SU regression
****************************************************************************************************
if $no_age_coefs == 0 {
	local exog_vars `control_vars'
}

if $no_age_coefs == 1 {
	local exog_vars 
}


if $estimate_reg_by_age == 0{
    sureg (`endog_vars' =  L.(`endog_vars') `exog_vars' )

    * matrix list e(b) // coefs
    mat coefs = e(b)
    mat sigma = e(Sigma)

    // e(sample)         marks estimation sample
    local filename ""
    mat2txt, matrix(coefs) saving("$folder/Results/Aux_Model_Estimates/coefs`filename'.txt") replace
    mat2txt, matrix(sigma) saving("$folder/Results/Aux_Model_Estimates/sigma`filename'.txt") replace
    gen sample = e(sample)


}
else if $estimate_reg_by_age == 1{
  ** Below cutoff  age
  sureg (`endog_vars' =  L.(`endog_vars') `exog_vars' ) if age >= 20 & age <= $cutoff_age
  mat coefs = e(b)
  mat sigma = e(Sigma)
  local filename "_below_$cutoff_age"
  mat2txt, matrix(coefs) saving("$folder/Results/Aux_Model_Estimates/coefs`filename'.txt") replace
  mat2txt, matrix(sigma) saving("$folder/Results/Aux_Model_Estimates/sigma`filename'.txt") replace
  gen sample_below = e(sample)

  ** Above cutoff age
  sureg (`endog_vars' =  L.(`endog_vars') `exog_vars') if age > $cutoff_age
  mat coefs = e(b)
  mat sigma = e(Sigma)
  local filename "_above_$cutoff_age"
  mat2txt, matrix(coefs) saving("$folder/Results/Aux_Model_Estimates/coefs`filename'.txt") replace
  mat2txt, matrix(sigma) saving("$folder/Results/Aux_Model_Estimates/sigma`filename'.txt") replace
  gen sample_above = e(sample)

  gen sample = sample_below + sample_above
}

****************************************************************************************************
** Generate initial data for simulation
****************************************************************************************************

preserve
  by pid, sort: egen min_year = min(wave)
  keep if F.sample == 1 & age <= 30 & wave == min_year // first observation for each indiv is not in the sample b/c of the lag

  tab age
  count
  keep pid `endog_vars' `control_vars'
  order pid `endog_vars' `control_vars'
  gen cons = 1
  export delimited using "$folder/Results/Aux_Model_Estimates/InitData.csv", replace
restore

****************************************************************************************************
** Generate initial means for simulation
****************************************************************************************************

preserve
  by pid, sort: egen min_year = min(wave)
  keep if F.sample == 1 & age == 25 // just look at the youngest age
  
  sum housing
  collapse (mean) log_consumption log_liq_wealth log_housing_wealth log_income `control_vars', by(housing)
  gen pid = 1
  keep pid `endog_vars' `control_vars'
  order pid `endog_vars' `control_vars'
  gen cons = 1
  export delimited using "$folder/Results/Aux_Model_Estimates/InitDataMeans.csv", replace
restore

****************************************************************************************************
** Save age patterns
****************************************************************************************************

preserve
  keep if F.sample == 1 | sample == 1
  keep pid `endog_vars' `level_vars' `control_vars'
  order pid `endog_vars' `level_vars' `control_vars'
  gen cons = 1
  gen log_housing_wealth_if_owner = log_housing_wealth if housing == 1

  collapse (median) `endog_vars' `level_vars' log_housing_wealth_if_owner, by(age)
  tsset age
  save "$folder/Results/Aux_Model_Estimates/PSID_by_age_median.csv", replace
restore

preserve
  keep if F.sample == 1 | sample == 1
  keep pid `endog_vars' `level_vars' `control_vars'
  order pid `endog_vars' `level_vars' `control_vars'
  gen cons = 1
  gen log_housing_wealth_if_owner = log_housing_wealth if housing == 1

  collapse (mean) `endog_vars' `level_vars' log_housing_wealth_if_owner, by(age)
  tsset age
  save "$folder/Results/Aux_Model_Estimates/PSID_by_age_mean.csv", replace
restore

****************************************************************************************************
** Look at wealthy hand to mouth
****************************************************************************************************


preserve
  gen HtM = liq_wealth <= (income / 24)
  gen WHtM = HtM & housing_wealth > 0
  gen PHtM = HtM & housing_wealth == 0 // should this be <= 0 ?
//   gen PHtM2 = HtM & housing_wealth <= 0 
  collapse (mean) *HtM*, by(age)
  tsset age
  tsline *HtM*,  title("Hand to Mouth Households") subtitle("(using only liquid & housing wealth)") name("WHTM1", replace)
  graph export "$folder\Results\AuxModel\PSID_HtM.pdf", as(pdf) replace

restore




preserve
  gen HtM = liq_wealth <= (income / 24)
  gen WHtM = HtM & illiq_wealth > 0
  gen PHtM = HtM & illiq_wealth == 0
  gen PHtM2 = HtM & illiq_wealth <= 0 
  collapse (mean) *HtM*, by(age)
  tsset age
  tsline *HtM*, title("Hand to Mouth Households") subtitle("(using liquid & illiquid wealth)") name("WHTM2", replace)
  graph export "$folder\Results\AuxModel\PSID_HtM_all_illiq.pdf", as(pdf) replace
restore

