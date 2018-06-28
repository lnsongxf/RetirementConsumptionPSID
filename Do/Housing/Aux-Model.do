****************************************************************************************************
** Run SUR for aux model
****************************************************************************************************

set more off
graph close
set autotabgraphs on

global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
use "$folder\Data\Intermediate\Basic-Panel.dta", clear
cap mkdir "$folder/Results/Aux_Model_Estimates/AuxModelLatex/"

* Switches
global allow_kids_to_leave_hh 1 // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH
                                // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)

* drop if emp_status_head != 1 // only keep employed heads. Question: should I put this so early? ie to split up HH? or later?

* cap ssc install mat2txt

global aux_model_in_logs 1 // 1 = logs, 0 = levels

global drop_top_x 0 // can be 0, 1, or 5

global estimate_reg_by_age 0 // 0 is our baseline where we estimate SUREG with everyone pooled together. 1 is alternative where we do two buckets
global cutoff_age 40

global no_age_coefs 0 // default is  0 (include age and age2). NOTE: I manually removed age and age2 from the SUR
global residualized_vars 1 // original version was 0 (no residualization) (NOTE: only works for log variables)
global house_price_by_age 0 // plot distribution of house price by age?

* TODO: add in mortgage debt vs house value

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
qui do "$folder\Do\Housing\Find-First-Home-Purchase.do"

****************************************************************************************************
** Define variables
****************************************************************************************************
keep if age >= 22 & age <= 65
* keep if age >= 20 & age <= 65

gen consumption = expenditure_exH_real_2015 // blundell expenditure excluding housing
gen liq_wealth = fam_liq_wealth_real // 2015 dollars
* gen housing_wealth = fam_LiqAndH_wealth_real - fam_liq_wealth_real // 2015 dollars (includes other housing wealth)
gen housing_wealth = homeequity_real
gen housing = housingstatus == 1 // renting or living with parents are considered as the same
gen income = inc_fam_real_2015 // TODO: will need to subtract out taxes using NBER TAXSIM
gen illiq_wealth = fam_wealth_real - fam_liq_wealth_real // NOTE: we do not use this in the regressions, just use it for our alternative measure of WHtM
gen hand_to_mouth = liq_wealth <= (income / 24)

* New variables
// housevalue_real
// mortgage_debt_real
* TODO: if I combine these, do I get housing_wealth?

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
** Look at distribution of house prices based on income
****************************************************************************************************

if $house_price_by_age == 1{
gen house_price_inc_ratio = housevalue_real / income if housing == 1 & income > 16000
hist house_price_inc_ratio, name("hist", replace) graphregion(color(white)) 

gen log_housevalue_real = log(housevalue_real)
gen log_house_price_inc_ratio = log_housevalue_real - log_income if housing == 1 & income > 1000
lab var log_house_price_inc_ratio "Log( House Price / Income)"
hist log_house_price_inc_ratio, name("hist_log", replace) graphregion(color(white)) title("House Price / Income")
graph export "$folder/Results/Homeownership/HousePriceIncomeRatio.pdf", as(pdf) replace

by pid, sort: egen log_income_mean = mean(log_income)
gen log_house_price_meaninc_ratio = log_housevalue_real - log_income_mean if housing == 1 & log_income_mean >= 6.9077553 // requires at least 1000 avg income
hist log_house_price_meaninc_ratio, name("hist_log_mean_inc", replace) graphregion(color(white)) 

* todo: take avg house price
by pid, sort: egen log_housevalue_real_mean = mean(log_housevalue_real)
}


****************************************************************************************************
** Convert endogenous variables to "residualized" variables
****************************************************************************************************

preserve
	collapse log_housing_wealth , by(housing age)
	xtset housing age
	xtline log, title("Housing Wealth") name("HW_by_housing_status_ORIG", replace)
restore


if $residualized_vars == 1{
	* Generate controls
	egen edu = cut(educhead), at(0, 12, 14, 16 20)
	gen white = racehead == 1
	gen black = racehead == 2
	gen otherrace = racehead != 1 & racehead != 2
	gen metro2 = metro == 2 // 3 categories, but category 0 is very small
	
// 	egen cohort = cut(year_born), at( 1920, 1940(10)1980, 2000 ) icodes label
	egen cohort = cut(year_born), at( 1920, 1950(10)1980, 2000 ) icodes label
	
	* Define Regression
	* PROBLEM: cohort picks up a lot of the age effect, b/c people born early are the ones who are old in our sample
	local X_vars ib12.edu black otherrace metro2 ib2015.wave // i.cohort // race education metro_area year (?) and cohort

	// 	local var log_income
	
	foreach var of varlist log_income log_consumption log_liq_wealth log_housing_wealth {
		
		* Compute residuals (Note: results look weird without the constant
		if "`var'" == "log_housing_wealth"{
			reg `var' `X_vars' if housing == 1
		}
		else{
			reg `var' `X_vars' 
		}
		predict `var'_resid, residuals
		replace `var'_resid = `var'_resid + _b[_cons] // add the constant back in (we want to control for someone being high or low educated... but we dont want to take out the constant) I think
		

		* Plot the results
		/*
		preserve
			collapse `var' `var'_resid, by(age)
			tsset age
			replace `var'_resid = `var'_resid 
			tsline `var', name(`var', replace)
			tsline `var'_resid, name(`var'_resid, replace)
		restore
		*/
		* Overwrite the original variable
		drop `var'
		rename `var'_resid `var'
		
		* Deal with non homeowners!
		if "`var'" == "log_housing_wealth"{
			replace `var' = 0 if housing == 0
			* TODO: will need to do same more mortgage debt down the road
		}
		
	}
}


* WARNING!!! Make sure you cannot have housing wealth if you don't own a house!
preserve
	collapse log_housing_wealth , by(housing age)
	xtset housing age
	xtline log, title("Housing Wealth") name("HW_by_housing_status", replace)
restore
* TODO: what happens when you don't own a house? you should not be able to have housing wealth....


****************************************************************************************************
** Look at wealth by age
****************************************************************************************************

* TODO: why do these results look so different ???

/*
preserve
	collapse (median) housing_wealth liq_wealth HL_ratio, by(age)
	tsset age
	tsline housing_w liq_w, name("median", replace)
restore

preserve
	collapse (mean) housing_wealth liq_wealth HL_ratio, by(age)
	tsset age
	tsline housing_w liq_w, name("mean", replace)
restore

*/

****************************************************************************************************
** Test our version of SU regression
****************************************************************************************************
/*
sureg (log_income log_consumption = L.(log_income log_consumption) )
mat list e(Sigma)

reg log_income L.(log_income log_consumption) 
predict double resid1, residuals

reg log_consumption L.(log_income log_consumption) 
predict double resid2, residuals

corr resid1 resid2, covariance

** WOOHOO! It works
** Equation by equation OLS is equivalent to system OLS or FGLS when all the regressors are the same across equations
** For more info, see Wooldridge screen shots in the Notes folder
*/

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

	// export coefs to latex
	preserve
		matrix c = e(b)'
		xsvmat c, norestore roweqname(xvar)
		split xvar, parse(":")
		drop xvar
		replace xvar2 = subinstr(xvar2, ".", "_", .)
		reshape wide c1, i(xvar1) j(xvar2) string
		rename c1_cons c1constant
		foreach var of varlist c1* {
			local newname = substr("`var'", 3, .)
			rename `var' `newname'
		}
		rename xvar1 Y
		rename L_log_consumption L_log_cons
		rename L_log_housing_wealth L_log_h_wealth
		* dataout, save("$folder/Results/Aux_Model_Estimates/AuxModelLatex/coefs") tex replace auto(3)
		mkmat L* cons age*, matrix(newcoefs) rownames(Y)
		outtable using "$folder/Results/Aux_Model_Estimates/AuxModelLatex/coefs", nobox mat(newcoefs) replace f(%9.3f)  caption("Coefficients")
	restore
	
	// export var covar to latex
	outtable using "$folder/Results/Aux_Model_Estimates/AuxModelLatex/sigma", ///
		nobox mat(sigma) replace f(%9.3f) caption("Variance Covariance Matrix")
		
	// export RMSE
	preserve
	clear
	set obs 1
	gen Equation = ""
	gen RSS = .
	gen RMSE = .
	gen R2 = .
	local counter = 1
	foreach var in `e(depvar)' {
		set obs `counter'
		replace Equation = "`var'" in `counter'
		replace RSS = e(rss_`counter') in `counter'
		replace RMSE = e(rmse_`counter') in `counter'
		replace R2 = e(r2_`counter') in `counter'
		di "`counter'"
		di e(rmse_`counter')
		local counter = `counter' + 1
	}
	mkmat RSS RMSE R2, matrix(RMSE) rownames(Equation)
	outtable using "$folder/Results/Aux_Model_Estimates/AuxModelLatex/rmse", ///
		nobox mat(RMSE) replace f(%9.0fc %9.3f %9.3f) caption("Model Fit")
	restore
	
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

sdfsdf

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
** Save sample used in aux model
****************************************************************************************************

preserve
  keep if F.sample == 1 | sample == 1
  keep pid wave `endog_vars' `level_vars' `control_vars' race educhead children metro metro_pre2015 metro_2015 value_gifts_real married region
  order pid wave `endog_vars' `level_vars' `control_vars'
  * gen cons = 1
  * gen log_housing_wealth_if_owner = log_housing_wealth if housing == 1
  sort pid wave
  save "$folder/Data/Final/AuxModelPanel.dta", replace
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
  sort age
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
  sort age
  save "$folder/Results/Aux_Model_Estimates/PSID_by_age_mean.csv", replace
restore

****************************************************************************************************
** Look at wealthy hand to mouth
****************************************************************************************************


preserve
  gen HtM = liq_wealth <= (income / 24)
  gen WHtM = HtM & housing_wealth > 0
//   gen PHtM = HtM & housing_wealth == 0 // should this be <= 0 ?
  gen PHtM = HtM & housing_wealth <= 0 
  collapse (mean) *HtM*, by(age)
  tsset age
  lab var WHtM "Share of Wealthy HtM"
  lab var PHtM "Share of Poor HtM"
  tsline WHtM PHtM,  title("Hand to Mouth Households") subtitle("(using only liquid & housing wealth)") name("WHTM1", replace) graphregion(color(white)) 
  graph export "$folder\Results\AuxModel\PSID_HtM.pdf", as(pdf) replace

restore
* (homeowners with liq wealth < 2 weeks income)
* (renters with liq wealth < 2 weeks income)



preserve
  gen HtM = liq_wealth <= (income / 24)
  gen WHtM = HtM & illiq_wealth > 0
  gen PHtM = HtM & illiq_wealth == 0
  gen PHtM2 = HtM & illiq_wealth <= 0 
  collapse (mean) *HtM*, by(age)
  tsset age
  lab var WHtM "Share of Wealthy HtM"
  lab var PHtM "Share of Poor HtM (illiq w == 0)"
  lab var PHtM2 "Share of Poor HtM (illiq w < 0)"
  tsline WHtM* PHtM*, title("Hand to Mouth Households") subtitle("(using liquid & illiquid wealth)") name("WHTM2", replace) graphregion(color(white)) 
  graph export "$folder\Results\AuxModel\PSID_HtM_all_illiq.pdf", as(pdf) replace
restore
* NOTE: which did we prefer, phtm1 or 2?
