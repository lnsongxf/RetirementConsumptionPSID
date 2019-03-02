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

global drop_top_x 5 // 5 // can be 0, 1, or 5
global drop_by_income 1 // can be 1 to drop by income, 0 to drop by wealth

global estimate_reg_by_age 0 // 0 is our baseline where we estimate SUREG with everyone pooled together. 1 is alternative where we do two buckets
global cutoff_age 40

global no_age_coefs 0 // default is  0 (include age and age2). NOTE: I manually removed age and age2 from the SUR
global residualized_vars 1 // original version was 0 (no residualization) (NOTE: only works for log variables)
global house_price_by_age 0 // plot distribution of house price by age?

global compute_htm_persistence 0
global makeplots 0


cap net install xtserial.pkg

* TODO: add in mortgage debt vs house value
* TODO: drop imputed values (ex tab acc_homeequity)

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
** Aux Model Versions
****************************************************************************************************

* Version 5 (Original)
* local non_log_endog_vars WHtM PHtM dummy_mort housing

* Version 5 (New - remove dummy_mort b/c in the model dummy_mort is collinear with housing)
local non_log_endog_vars WHtM PHtM housing

****************************************************************************************************
** Find housing upgrades/downgrades (owner to owner transitions)
****************************************************************************************************
* note: can see if they take out a second mortgage... interesting!
tab type_mortgage1
tab type_mortgage2
tab year_moved

* it seems they only ask year_moved if you've moved
gen dif = year_moved - wave
tab year_moved

gen owner_transition1 = (year_moved == wave | year_moved == wave-1) & homeowner == 1 & homeowner == 1  & L.homeowner == 1
gen owner_transition2 = (year_moved == wave | year_moved == wave-1 | year_moved == wave-2) & L.homeowner == 1
gen owner_transition3 = (year_moved == wave | year_moved == wave-1 | year_moved == wave-2) & year_moved != L.year_moved & L.homeowner == 1
edit pid wave housevalue year_moved current_state owner_transition* room_count mortgage1 mortgage2 if homeowner == 1
tab owner_transition2 homeowner, missing
tab owner_transition2 owner_transition3

gen owner_transition = owner_transition3 // best definition
gen owner_upgrade = owner_transition & (housevalue_real > L.housevalue_real)
gen owner_downgrade = owner_transition & (housevalue_real <= L.housevalue_real)



****************************************************************************************************
** Look into home equity loans by year
****************************************************************************************************

/*
gen mortgage = (type_mortgage1 >= 1 & type_mortgage1 <= 7 ) | (type_mortgage2 >= 1 & type_mortgage2 <= 7 )
gen home_equity_loan = (type_mortgage1 == 3 | type_mortgage2 == 3) 
gen HELOC = (type_mortgage1 == 5 | type_mortgage2 == 5) 

collapse (sum) mortgage home_equity_loan HELOC, by(wave)
*/

****************************************************************************************************
** Define variables
****************************************************************************************************
keep if age >= 22 & age <= 65
* keep if age >= 20 & age <= 65

gen consumption = expenditure_exH_real_2015 // blundell expenditure excluding housing
gen liq_wealth = fam_liq_wealth_real // 2015 dollars
* gen housing_wealth = fam_LiqAndH_wealth_real - fam_liq_wealth_real // 2015 dollars (includes other housing wealth)
gen housing_wealth = homeequity_real
gen mortgage       = mortgage_debt_real
gen housing_price  = housing_wealth + mortgage
gen housing = housingstatus == 1 // renting or living with parents are considered as the same
gen income = inc_fam_real_2015 // TODO: will need to subtract out taxes using NBER TAXSIM
gen illiq_wealth = fam_wealth_real - fam_liq_wealth_real // NOTE: we do not use this in the regressions, just use it for our alternative measure of WHtM
gen HtM = liq_wealth <= (income / 24) // TODO: not sure it should be 24 exactly
gen dummy_mort = mortgage>0

gen bought = 0 
replace bought = 1 if housing ==1 & L.housing==0

gen sold = 0
replace sold = 1 if housing == 0 & L.housing == 1

// gen WHtM = HtM & housing == 1
// gen PHtM = HtM & housing == 0

* OR
 gen WHtM = HtM & housing_wealth > 0
 gen PHtM = HtM & housing_wealth <= 0 

gen LTV = (mortgage1 + mortgage2) / housevalue if t_homeownership == 0
gen underwater = LTV > 1 & LTV != .
tab underwater // just 58 observations

gen new_mort = dummy_mort == 1 & L.dummy_mort == 0


* TODO -- IMPORTANT
* As in Blundell Pistaferri 
* drop if income < 100 // important!!! about 100 people. many with negative income!

* New variables
// housevalue_real
// mortgage_debt_real
* TODO: if I combine these, do I get housing_wealth?


* HtM

if $aux_model_in_logs == 1{
  * Run the model in logs
  local level_vars consumption liq_wealth housing_wealth income mortgage
  local endog_vars 
  foreach var of varlist `level_vars' {
    gen log_`var' = log(`var')
    replace log_`var' = log(1) if `var' <= 0 & `var' != .
    local endog_vars `endog_vars' log_`var'
  }
  
  * Now add in the remaining "non log" variables
  local endog_vars `endog_vars' `non_log_endog_vars'
}
else if $aux_model_in_logs == 0{
  * Run the model in levels
  local level_vars
  local endog_vars housing consumption liq_wealth housing_wealth income mortgage
}


preserve
	collapse housing_wealth housing_price mortgage, by(age housing)
	xtset housing age 
	xtline housing_wealth housing_price mortgage, name(v1, replace)
restore

preserve
	collapse housing_wealth housing_price mortgage, by(age)
	tsset age 
	tsline housing_wealth housing_price mortgage, name(v2, replace)
restore


****************************************************************************************************
** Simple means and medians by age EXCLUDING TOP x%
****************************************************************************************************
* TODO: definie this based on fam_wealth_real or Liquid + Housing wealth?

if $drop_top_x > 0{
  gen NetWealth = liq_wealth + housing_wealth

  * local sort_var fam_wealth_real
  if $drop_by_income == 1 {
	local sort_var income
  }
  else{
	local sort_var NetWealth
  }
	
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

rename age_sq age2
gen age3 = age^3
local control_vars age age2 age3 bought 

* L(1 2).(bought underwater)
* sold L.housing new_mort
* underwater

****************************************************************************************************
** Calibrate initial liquid assets -- used for setting some params in model
****************************************************************************************************

preserve
	keep if age == 22
	// hist liq_wealth
	drop if log_liq_wealth == 0
	sum log_liq_wealth
restore


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
drop if housing == 0 & mortgage != 0 // no such people anyway :)

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
** HtM Persistence
****************************************************************************************************

// logit HtM L.HtM
// logit HtM L2.HtM
// logit HtM L3.HtM

if $compute_htm_persistence == 1{
forvalues i = 1/8 {
	gen L`i'_HtM = L`i'.HtM
	if `i' == 1{
		local outreg_opt replace
	}
	else{
		local outreg_opt
	}
	
	local outreg_opt_all drop(0bn.L`i'_HtM) tex(frag pretty) label title("Probability of HtM status conditional on past HtM status")  ctitle("Margins")
	local n = `i' * 2
	label var L`i'_HtM "\$ {HtM}_{i, t-`n'} $"
	
	logit HtM i.L`i'_HtM
	margins L`i'_HtM, atmeans post
	outreg2 using "$folder/Results/Aux_Model_Estimates/HtM_Persistence", `outreg_opt' `outreg_opt_all' ///
	addnote("Each cell represents the marginal probability of being HtM today conditional on being HtM x years ago,", "where marginal probabilities are evaluated at the means.")
	* ctitle(margins)
	
	logit HtM i.L`i'_HtM L`i'.log_income
	margins L`i'_HtM, atmeans post
	outreg2 using "$folder/Results/Aux_Model_Estimates/HtM_Persistence_Control_Income", `outreg_opt' `outreg_opt_all' ///
	addnote("Each cell represents the marginal probability of being HtM today conditional on being HtM x years ago,", "controlling for lagged income, where marginal probabilities are evaluated at the means.")

}
}

****************************************************************************************************
** Compute income and consumption variance
****************************************************************************************************


gen d_log_income = D.log_income
drop if d_log_income < -0.8
drop if d_log_income > 5 & d_log_income != .

drop if log_consumption == 0
drop if log_income == 0

drop if exp(log_income) < 100	

count if exp(log_income) < 5000


keep if sex_head == 1


sum log_consumption, det 
sum log_income, det 



preserve
	keep if age >= 30 

	* Keep only those who are always employed!! Makes persistence in logY more similar to model
	keep if emp_status_head == 1 | emp_status_head_2 == 1 | emp_status_head_3 == 1 

	collapse (mean) log_consumption log_income (sd) sd_c = log_consumption sd_y = log_income, by(age)
	tsset age
	gen var_y = sd_y^2
	gen var_c = sd_c^2
	tsline log_*, name(logs, replace)
	tsline var_*, name(var, replace)
restore

preserve
	keep if age >= 30 

	* Keep only those who are always employed!! Makes persistence in logY more similar to model
	* eep if emp_status_head == 1 | emp_status_head_2 == 1 | emp_status_head_3 == 1 

	collapse (mean) log_consumption log_income (sd) sd_c = log_consumption sd_y = log_income, by(age)
	tsset age
	gen var_y = sd_y^2
	gen var_c = sd_c^2
	tsline log_*, name(logs_all, replace)
	tsline var_*, name(var_all, replace)
restore


****************************************************************************************************
** Convert endogenous variables to "residualized" variables
****************************************************************************************************

if $makeplots == 1{
preserve
	collapse log_housing_wealth log_mortgage housing_wealth mortgage housing_price , by(housing age)
	xtset housing age
	xtline log*, title("Housing Wealth") name("HW_by_housing_status_ORIG", replace)
	xtline housing_wealth mortgage housing_price , title("Housing Wealth") name("HW2", replace)
restore
}


if $residualized_vars == 1{
	* Generate controls
	egen edu = cut(educhead), at(0, 12, 14, 16 20)
	gen white = racehead == 1
	gen black = racehead == 2
	gen otherrace = racehead != 1 & racehead != 2
	gen metro2 = metro == 2 // 3 categories, but category 0 is very small
	
// 	egen cohort = cut(year_born), at( 1920, 1940(10)1980, 2000 ) icodes label
	egen cohort = cut(year_born), at( 1920, 1950(20)2000 ) icodes label
	
	* Define Regression
	* PROBLEM: cohort picks up a lot of the age effect, b/c people born early are the ones who are old in our sample
	local X_vars ib12.edu black otherrace metro2 ib2015.wave // i.cohort // race education metro_area year (?) and cohort

	// 	local var log_income
	
	foreach var of varlist log_income log_consumption log_liq_wealth log_housing_wealth log_mortgage {
		
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
		if $makeplots == 1{
		preserve
			collapse `var' `var'_resid, by(age)
			tsset age
			replace `var'_resid = `var'_resid 
// 			tsline `var', name(`var', replace)
// 			tsline `var'_resid, name(`var'_resid, replace)
			tsline `var' `var'_resid, name(`var', replace)
		restore
		}
		
		* Overwrite the original variable
		drop `var'
		rename `var'_resid `var'
		
		* Deal with non homeowners!
		if "`var'" == "log_housing_wealth" | "`var'" == "log_mortgage"{
			replace `var' = 0 if housing == 0
			* TODO: will need to do same more mortgage debt down the road
		}
		if "`var'" == "log_mortgage"{
			replace `var' = 0 if dummy_mort == 0
			* TODO: will need to do same more mortgage debt down the road
		}
		
	}
}


* WARNING!!! Make sure you cannot have housing wealth if you don't own a house!
if $makeplots == 1{
preserve
	collapse log_housing_wealth log_mortgage, by(housing age)
	xtset housing age
	xtline log*, title("Housing Wealth") name("HW_by_housing_status", replace)
restore
preserve
	collapse log_mortgage, by(dummy_mort age)
	xtset dummy_mort age
	xtline log*, title("Mortgage Debt") name("mortgage_by_mort_dummy", replace)
restore
}

* TODO: what happens when you don't own a house? you should not be able to have housing wealth....

* TODO: make sure you cannot have mortgage debt if you don't own a house
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
** Look at residual income variance
****************************************************************************************************
* * from median 
* local inc_reg_age2 = -0.05277766141931223
* local Y0_std_scale = 0.9525554036827213
* local inc_reg_constant = 5.9946025528994085
* local inc_reg_age3 = 0.0031580528858719016
* local inc_reg_age = 0.28652374573188877

* *from mean
* local inc_reg_constant = 7.353390893779766
* local inc_reg_age      = 0.16497734614396434
* local inc_reg_age2     = -0.023644664413939136
* local inc_reg_age3     = 0.001
* local Y0_std_scale     = 0.8394452421339706

* * Note: already in logs
* gen G = `inc_reg_constant' + age * `inc_reg_age' + ((age^2) * `inc_reg_age2' / 10) + ((age^3) * `inc_reg_age3' / 100)

* preserve
* 	keep age G
* 	duplicates drop
* 	tsset age
* 	tsline G, name(G1, replace)
* restore

* preserve
* 	collapse G log_income, by(age)
* 	tsset age
* 	tsline G log_income, name(G2, replace)
* restore

* gen y_resid = log_income - G

* preserve
* 	collapse (mean) y_resid (sd) sd = y_resid, by(age)
* 	gen var = sd ^ 2
* 	tsset age 
* 	tsline y_resid, name(y, replace)
* 	tsline var, name(var, replace)
* restore

* preserve
* 	gen Z = log_income - G
* 	collapse Z (sd) sd = Z, by(age)
* 	gen var = sd^2
* 	tsset age
* 	tsline var, name(varZ, replace)
* restore

****************************************************************************************************
** New regressions -- Euler Equation estimation 
****************************************************************************************************

* Exactly what we were running on the model
reg D.log_consumption log_liq_wealth if liq_wealth > 1000 

* NICEEEEEEE
reg D.log_consumption log_liq_wealth age age2 if liq_wealth > 1000 

* NICEEEEEE
reg D.log_consumption log_liq_wealth i.age if liq_wealth > 1000 

reg D.log_consumption log_liq_wealth i.age if liq_wealth > 500

* These are not as nice... but in the end i think using the income restriction is wrong
reg D.log_consumption log_liq_wealth if liq_wealth > 10000 & abs(D.log_income) < 0.1
reg D.log_consumption log_liq_wealth if liq_wealth > 10000 & abs(D.log_income) < 0.1 & owner_transition == 0
* Slightly different specification - significant at last
* AHH but it's not significant on the model! 
reg D.log_consumption log_liq_wealth if liq_wealth > 5000 & liq_wealth < 500000 & abs(D.log_income) < 0.2




gen y = log_income 
gen d_c = D.log_consumption
gen log_a = log_liq_wealth
gen a = liq_wealth

global controls a > 1000 & a != . 
eststo clear 
qui eststo, title(baseline):              reg d_c       log_a if $controls
qui eststo, title(age control):           reg d_c i.age log_a if $controls
qui eststo, title(age polynomial):           reg d_c age age2 log_a if $controls

qui eststo, title(IV):         ivregress 2sls d_c       (log_a = L.log_a) if $controls, first

qui eststo, title(IV):         ivregress 2sls d_c       (log_a = L.log_a L.y) if $controls, first
qui eststo, title(IV):         ivregress 2sls d_c i.age (log_a = L.log_a L.y) if $controls, first
global esttab_opts keep(log_a _cons) ar2 label b(5) se(5) mtitles indicate(Age controls = *age*)
esttab , $esttab_opts title("Log Assets")

* TODO: try all of this without the residualized data!!!!!!!!!!!!

* TODO: look at lagged log assets 

sdfdsf

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

if $no_age_coefs == 0 {
	local exog_vars `control_vars'
}

if $no_age_coefs == 1 {
	local exog_vars 
}

****************************************************************************************************
** SUREG with contemporaneous terms
****************************************************************************************************

/*
local sureg_command = ""
foreach var in `endog_vars'{
	
	* remove var from the list of endog_vars
	* for info on using subinstr in this way, see "help extended_fcn"
	local endog_vars_string "`endog_vars' "
	local contemp_var : subinstr loc endog_vars_string "`var' " " "
	* reg `var' `contemp_var' L.(`endog_vars') `exog_vars'
	
	* append to the sureg command
	local sureg_command "`sureg_command' (`var' = `contemp_var' L.(`endog_vars') `exog_vars' )"
}
di "`sureg_command'"		 
sureg `sureg_command'
		 
*/


****************************************************************************************************
** Income Calibration - very complicated
****************************************************************************************************
* TODO: try this with vs without residualized variables!


* collapse log_income, by(age)


* gen age2d = age2/10
reg log_income age age2 age3
predict residuals, xb


duplicates tag pid age, gen(dup)
edit if dup == 1

keep pid age residuals wave

by pid, sort: egen c = count(residuals)

drop if c == 1 // is this needed?

duplicates tag pid age, gen(dup)
drop if dup == 1
drop dup c

keep if age <= 50

gen d_age = D.age
tab d_age 


xtset pid age
tsfill, full

gen d = residuals != .
replace residuals = 0 if residuals == .
rename residuals u

keep pid age u d

reshape wide u d, i(pid) j(age)

preserve
keep pid u*
export delimited using "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID\Data\IncomeResiduals\u.csv", replace
restore

preserve
keep pid d*
export delimited using "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID\Data\IncomeResiduals\d.csv", replace
restore

sdfsdf

****************************************************************************************************
** Run SU regression
****************************************************************************************************



// qui reg housing log_consumption log_liq_wealth log_housing_wealth log_income log_mortgage L.(`endog_vars') `exog_vars' 
// di e(rmse)
// qui reg  log_consumption housing log_liq_wealth log_housing_wealth log_income log_mortgage L.(`endog_vars') `exog_vars' 
// di e(rmse)
// qui reg log_liq_wealth housing log_consumption log_housing_wealth log_income log_mortgage L.(`endog_vars') `exog_vars' 
// di e(rmse)
// qui reg log_housing_wealth housing log_consumption log_liq_wealth log_income log_mortgage L.(`endog_vars') `exog_vars' 
// di e(rmse)
// qui reg log_income housing log_consumption log_liq_wealth log_housing_wealth log_mortgage L.(`endog_vars') `exog_vars' 
// di e(rmse)
// qui reg log_mortgage housing log_consumption log_liq_wealth log_housing_wealth log_income L.(`endog_vars') `exog_vars' 
// di e(rmse)


save "$folder\Data\Intermediate\Basic-Panel-Ready-for-SUREG.dta", replace

if $estimate_reg_by_age == 0{
	di "sureg (`endog_vars' =  L.(`endog_vars') `exog_vars' )"	
    sureg (`endog_vars' =  L.(`endog_vars') `exog_vars' ), corr
	
	* TODO: check whether thie regression is well specified from an econometric sense
	* test serially uncorrelated errors with durbin watson, test homoskedasticity with breusch-pagan, test normal residuals with  Jarque-Bera-test of normality perhaps, test for nonlinearities in the data
	* https://stats.idre.ucla.edu/stata/webbooks/reg/chapter2/stata-webbooksregressionwith-statachapter-2-regression-diagnostics/
	* to test nonlinearity: plot y predicted on y. should make a linear line. if not linear, you might be missing some linearity
	
* 	reg log_consumption L.(log_consumption log_liq_wealth log_housing_wealth log_income log_mortgage WHtM PHtM housing) age age2 age3 bought
* 	reg log_housing_wealth L.(log_consumption log_liq_wealth log_housing_wealth log_income log_mortgage WHtM PHtM housing) age age2 age3 bought
* 	reg log_housing_wealth L(1).(log_consumption log_liq_wealth log_housing_wealth log_income log_mortgage WHtM PHtM housing) age age2 age3 bought sold owner_upgrade owner_downgrade
	
* 	reg log_mortgage L(1).(log_consumption log_liq_wealth log_housing_wealth log_income log_mortgage WHtM PHtM housing) age age2 age3 bought sold owner_upgrade owner_downgrade

* 	* look at residuals
* 	* http://campusguides.lib.utah.edu/c.php?g=160853&p=1054157
* 	cap drop r
* 	predict r, resid
* 	sum r, detail
* // 	replace r = . if housing == 0	
* pnorm r, name(pnorm, replace)
* 	qnorm r, name(qnorm, replace)
* 	swilk r // P value is based on the assumption that the distribution is normal. Very large p value -> cannot reject that r is normally distributed
* 			// Small p value, <= 0.05: evidence against the null hypothesis, thus reject the null. Large p value -> cannot reject the null
* 	kdensity r, normal  name(kdens, replace)
	
	
	
// 	gen lag_log_consumption = L.log_consumption
// 	xtset, clear
// 	reg log_consumption lag_log_consumption age age2 age3 bought
//	
// 	estat bgodfrey
// 	estat dwatson
	
	* doesnt work b/c takes the first difference
	* xtserial log_consumption lag_log_consumption age age2 age3 bought, output
	
	* estat hettest
	* estat imtest // is this needed?
	* estat ovtest
	
	
    * matrix list e(b) // coefs
    mat coefs = e(b)
    mat sigma = e(Sigma)

    // e(sample)         marks estimation sample
    local filename ""
//     mat2txt, matrix(coefs) saving("$folder/Results/Aux_Model_Estimates/AuxModelLatex/coefs`filename'.txt") replace
    mat2txt, matrix(sigma) saving("$folder/Results/Aux_Model_Estimates/AuxModelLatex/sigma.txt") replace

	// export coefs to latex
	preserve
		matrix c = e(b)'
		xsvmat c, norestore roweqname(xvar)
		split xvar, parse(":")
		drop xvar
		replace xvar2 = subinstr(xvar2, ".", "_", .)
		
		* export to csv for julia
		export delimited using "$folder/Results/Aux_Model_Estimates/AuxModelLatex/coefs_list.csv", replace
		
		reshape wide c1, i(xvar1) j(xvar2) string
// 		reshape wide c1, i(xvar2) j(xvar1) string

		rename c1_cons c1constant
		foreach var of varlist c1* {
			local newname = substr("`var'", 3, .)
			rename `var' `newname'
		}
		
		rename xvar Y
		rename L_log_consumption L_logC
		rename L_log_housing_wealth L_logHW
		rename L_log_income L_logY
		rename L_log_liq_wealth L_logLW
		rename L_log_mortgage L_logM
		cap rename L_dummy_mort L_mort
		cap rename L_housing L_H
		

		
		mkmat L* cons age*, matrix(newcoefs) rownames(Y)
// 		mkmat PHtM-logM , matrix(newcoefs) rownames(Y)
		outtable using "$folder/Results/Aux_Model_Estimates/AuxModelLatex/coefs", nobox mat(newcoefs) replace f(%9.3f)  caption("Coefficients (transposed)")
		mat2txt, matrix(newcoefs) saving("$folder/Results/Aux_Model_Estimates/AuxModelLatex/coefs.txt") replace
	restore
	
	// export coefs to latex (transposed)
	preserve
		matrix c = e(b)'
		xsvmat c, norestore roweqname(xvar)
		split xvar, parse(":")
		drop xvar
		replace xvar2 = subinstr(xvar2, ".", "_", .)
// 		reshape wide c1, i(xvar1) j(xvar2) string
		reshape wide c1, i(xvar2) j(xvar1) string

// 		rename c1_cons c1constant
		foreach var of varlist c1* {
			local newname = substr("`var'", 3, .)
			rename `var' `newname'
		}
		rename xvar Y
// 		rename L_log_consumption L_logC
// 		rename L_log_housing_wealth L_logHW
// 		rename L_log_income L_logY
// 		rename L_log_liq_wealth L_logLW
// 		rename L_log_mortgage L_logM
// 		rename L_dummy_mort L_mort
// 		rename L_housing L_H
		
		desc
		rename log_consumption logC
		rename log_housing_wealth logHW
		rename log_income logY
		rename log_liq_wealth logLW
		rename log_mortgage logM
		cap rename dummy_mort mort
		cap rename housing H
		
		list
		
		* dataout, save("$folder/Results/Aux_Model_Estimates/AuxModelLatex/coefs") tex replace auto(3)
// 		mkmat L* cons age*, matrix(newcoefs) rownames(Y)
		mkmat PHtM-logM , matrix(newcoefs) rownames(Y)
		outtable using "$folder/Results/Aux_Model_Estimates/AuxModelLatex/coefs_transposed", nobox mat(newcoefs) replace f(%9.3f)  caption("Coefficients (transposed)")
		mat2txt, matrix(newcoefs) saving("$folder/Results/Aux_Model_Estimates/AuxModelLatex/coefs_transposed.txt") replace
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


****************************************************************************************************
** Generate initial data for simulation
****************************************************************************************************
/*
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
*/
****************************************************************************************************
** Generate initial means for simulation
****************************************************************************************************

/*
preserve
  by pid, sort: egen min_year = min(wave)
  keep if F.sample == 1 & age == 25 // just look at the youngest age
  
  sum housing
  collapse (mean) log_consumption log_liq_wealth log_housing_wealth log_income log_mortgage `control_vars', by(housing)
  gen pid = 1
  keep pid `endog_vars' `control_vars'
  order pid `endog_vars' `control_vars'
  gen cons = 1
  export delimited using "$folder/Results/Aux_Model_Estimates/InitDataMeans.csv", replace
restore
*/

****************************************************************************************************
** Save sample used in aux model
****************************************************************************************************

di "`endog_vars'"
di "`control_vars'"
di "`level_vars'"

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

* MEDIANS
preserve
  keep if F.sample == 1 | sample == 1
  keep pid `endog_vars' `level_vars' `control_vars'
  order pid `endog_vars' `level_vars' `control_vars'
  gen cons = 1
  gen log_housing_wealth_if_owner = log_housing_wealth if housing == 1

  collapse (median) `endog_vars' `level_vars' log_housing_wealth_if_owner, by(age)
  tsset age
  sort age
  export delimited using "$folder/Results/Aux_Model_Estimates/PSID_by_age_median.csv", replace
  
  * Export Plots
  set scheme s2mono
  tsline income, title("Median Household Income") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Medians\income.pdf", as(pdf) replace
  
  tsline consumption, title("Median Consumption")  graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Medians\consumption.pdf", as(pdf) replace
  
  tsline liq_wealth, title("Median Liquid Wealth") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Medians\liq_wealth.pdf", as(pdf) replace
  
  tsline housing_wealth, title("Median Housing Wealth (Net)") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Medians\housing_wealth.pdf", as(pdf) replace

  tsline mortgage, title("Median Mortgage Balance") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Medians\mortgage.pdf", as(pdf) replace

  tsline housing, title("Fraction Homeowners") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Medians\housing.pdf", as(pdf) replace
    
  tsline WHtM, title("Fraction WHtM") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Medians\WHtM.pdf", as(pdf) replace
    
  tsline PHtM, title("Fraction PHtM") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Medians\PHtM.pdf", as(pdf) replace
restore



* MEANS
preserve
  keep if F.sample == 1 | sample == 1
  keep pid `endog_vars' `level_vars' `control_vars'
  order pid `endog_vars' `level_vars' `control_vars'
  gen cons = 1
  gen log_housing_wealth_if_owner = log_housing_wealth if housing == 1

  * Compute means and sd's
	local collapse_cmd ""
	foreach var of varlist `endog_vars' `level_vars' log_housing_wealth_if_owner {
		local collapse_cmd " `collapse_cmd' (mean) `var' (sd) sd_`var' = `var' "
	}
	di "`collapse_cmd'"


  collapse `collapse_cmd', by(age)
  tsset age
  sort age

  foreach var of varlist `endog_vars' `level_vars' log_housing_wealth_if_owner {
  	gen var_`var' = sd_`var' ^ 2
  }

  export delimited using "$folder/Results/Aux_Model_Estimates/PSID_by_age_mean.csv", replace
  
  * Export Plots
  set scheme s2mono
  tsline income, title("Mean Household Income") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Means\income.pdf", as(pdf) replace
  
  tsline consumption, title("Mean Consumption") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Means\consumption.pdf", as(pdf) replace
  
  tsline liq_wealth, title("Mean Liquid Wealth") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Means\liq_wealth.pdf", as(pdf) replace
  
  tsline housing_wealth, title("Mean Housing Wealth (Net)") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Means\housing_wealth.pdf", as(pdf) replace

  tsline mortgage, title("Mean Mortgage Balance") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Means\mortgage.pdf", as(pdf) replace

  tsline housing, title("Fraction Homeowners") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Means\housing.pdf", as(pdf) replace
    
  tsline WHtM, title("Fraction WHtM") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Means\WHtM.pdf", as(pdf) replace
    
  tsline PHtM, title("Fraction PHtM") graphregion(color(white))
  graph export "$folder\Results\Aux_Model_Estimates\Means\PHtM.pdf", as(pdf) replace
    
restore


** Compute by 5 year age buckets
preserve
  keep if F.sample == 1 | sample == 1
  keep pid `endog_vars' `level_vars' `control_vars'
  order pid `endog_vars' `level_vars' `control_vars'
  gen cons = 1
  gen log_housing_wealth_if_owner = log_housing_wealth if housing == 1

  * Compute means and sd's
  local collapse_cmd ""
  foreach var of varlist `endog_vars' `level_vars' log_housing_wealth_if_owner {
  	local collapse_cmd " `collapse_cmd' (mean) `var' (sd) sd_`var' = `var' "
  }
  di "`collapse_cmd'"

  * age buckets
  * defined based on the right hand
  egen age_bucket = cut(age), at(21(5)66)
  replace age_b = age_b + 4

  collapse `collapse_cmd', by(age_bucket)
  tsset age
  sort age

  foreach var of varlist `endog_vars' `level_vars' log_housing_wealth_if_owner {
  	gen var_`var' = sd_`var' ^ 2
  }

  export delimited using "$folder/Results/Aux_Model_Estimates/PSID_by_age_buckets_mean.csv", replace
restore


****************************************************************************************************
** Look at wealthy hand to mouth
****************************************************************************************************

* Note: here WHtM are defined based on housing wealth (above WHtM was defined based on housing status)

preserve
  drop *HtM*
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
  drop *HtM*
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
