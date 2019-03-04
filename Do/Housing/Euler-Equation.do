****************************************************************************************************
** Run SUR for aux model
****************************************************************************************************

set more off
graph close
set autotabgraphs on

global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
global folder_output "$folder\Results\EulerEquation"

use "$folder\Data\Intermediate\Basic-Panel.dta", clear

cap mkdir "$folder/Results/Aux_Model_Estimates/AuxModelLatex/"

* Switches
global allow_kids_to_leave_hh 1 // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH
                                // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)

* drop if emp_status_head != 1 // only keep employed heads. Question: should I put this so early? ie to split up HH? or later?

* cap ssc install mat2txt

global aux_model_in_logs 1 // 1 = logs, 0 = levels

global drop_top_x 0 // 5 // can be 0, 1, or 5
global drop_by_income 1 // can be 1 to drop by income, 0 to drop by wealth

global estimate_reg_by_age 0 // 0 is our baseline where we estimate SUREG with everyone pooled together. 1 is alternative where we do two buckets
global cutoff_age 40

global no_age_coefs 0 // default is  0 (include age and age2). NOTE: I manually removed age and age2 from the SUR
global residualized_vars 1 // original version was 0 (no residualization) (NOTE: only works for log variables)
global house_price_by_age 0 // plot distribution of house price by age?

global compute_htm_persistence 0
global makeplots 0


* cap net install xtserial.pkg

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
* edit pid wave housevalue year_moved current_state owner_transition* room_count mortgage1 mortgage2 if homeowner == 1
tab owner_transition2 homeowner, missing
tab owner_transition2 owner_transition3

gen owner_transition = owner_transition3 // best definition
gen owner_upgrade = owner_transition & (housevalue_real > L.housevalue_real)
gen owner_downgrade = owner_transition & (housevalue_real <= L.housevalue_real)

* TODO: Not totally sure if we should look at wave-2 as well... not sure
gen housing_transition = (year_moved == wave | year_moved == wave-1) 


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

* As in Blundell Pistaferri 
drop if income < 100 // important!!! about 100 people. many with negative income!

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

/*
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
*/

****************************************************************************************************
** Simple means and medians by age EXCLUDING TOP x%
****************************************************************************************************
* TODO: define this based on fam_wealth_real or Liquid + Housing wealth?

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

/*
  * Plot the 95th and 99th percentiles
  preserve
  	keep age p95 p99
  	duplicates drop
  	sort age
  	list
  	tsset age
  	tsline p95 p99
  restore
*/

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

****************************************************************************************************
** Drop renters with home equity
****************************************************************************************************

drop if housing == 0 & housing_wealth != 0
drop if housing == 0 & mortgage != 0 // no such people anyway :)

/*sum housing_wealth if housing == 1
sum housing_wealth if housing == 0*/

****************************************************************************************************
** Consumption Euler Equation
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


drop if consumption == 0 | L.consumption == 0

gen y = log_income 
gen d_c = D.log_consumption
gen log_a = log_liq_wealth
gen a = liq_wealth

sum d_c, det
xtile p_d_c = d_c, nquantiles(100)
drop if p_d_c == 1 | p_d_c == 100 // results seem robust to doing this... magnitudes just change a bit. but it's a bit crazy to see such large changes in Consumption
* drop if p_d_c <= 5 | p_d_c >= 95 // results seem robust to doing this.... though magnitudes change a bit
* drop if p_d_c <= 10 | p_d_c >= 90 
sum d_c, det

gen d_y = D.y
/*
preserve
  collapse d_y, by(age)
  tsset age
  tsline d_y
restore
sum d_y, det
xtile p_d_y = d_y, nquantiles(100)
drop if p_d_y == 1 | p_d_y == 100
drop if p_d_y <= 5 | p_d_y >= 95
drop p_d_y
sum d_y, det
*/

* drop if d_c < -1 | d_c > 1

global controls a > 1000 & a != .  & age >= 25 & age <= 60 & housing_transition == 0
eststo clear 
qui eststo, title(baseline):              reg d_c       log_a if $controls
qui eststo, title(age control):           reg d_c i.age log_a if $controls
qui eststo, title(age polynomial):           reg d_c age age2 log_a if $controls
qui eststo, title(IV L.a):         ivregress 2sls d_c       (log_a = L.log_a) if $controls, first
qui eststo, title(IV L.a):         ivregress 2sls d_c       (log_a = L.log_a L.y) if $controls, first
qui eststo, title(IV a & y):         ivregress 2sls d_c i.age (log_a = L.log_a) if $controls, first
qui eststo, title(IV a & y):         ivregress 2sls d_c i.age (log_a = L.log_a L.y) if $controls, first
global esttab_opts keep(log_a _cons) ar2 label b(5) se(5) mtitles indicate(Age controls = *age*)
esttab , $esttab_opts title("Depvar: d_c. $controls")

* It seems that the L.HtM == 0 has a lot of bite
global controls a > 1000 & a < 500000 & a != . & age >= 25 & age <= 60 & housing_transition == 0 & HtM == 0  & L.HtM == 0
eststo clear 
qui eststo, title(baseline):              reg d_c       log_a if $controls
qui eststo, title(age control):           reg d_c i.age log_a if $controls
qui eststo, title(age polynomial):           reg d_c age age2 log_a if $controls
qui eststo, title(IV L.a):         ivregress 2sls d_c i.age (log_a = L.log_a) if $controls, first
qui eststo, title(IV L.y):         ivregress 2sls d_c i.age (log_a = L.y) if $controls, first
qui eststo, title(IV L.a L.y):         ivregress 2sls d_c i.age (log_a = L.log_a L.y) if $controls, first
qui eststo, title(IV L.a L.c L.y):         ivregress 2sls d_c i.age (log_a = L.log_a L.y L.log_consumption) if $controls, first
global esttab_opts keep(log_a _cons) ar2 label b(5) se(5) mtitles indicate(Age controls = *age*)
esttab , $esttab_opts title("Depvar: d_c. $controls")
esttab using "$folder_output\EE_PSID.tex", $esttab_opts longtable booktabs obslast replace title("PSID Euler Equation") addnotes("Sample: Households with liq assets between 1,000 and 500,000, ages 25 to 60, not moving homes that year, and not HtM today or yesterday")
esttab using "$folder_output\EE_PSID.csv", $esttab_opts csv obslast replace


* TODO: look at employment status & emp_status_head == 1 & L.emp_status_head == 1
* TODO: look at lagged log assets 

/*
eststo clear 
qui eststo, title(baseline):             reg d_c       L.log_a if $controls
qui eststo, title(age control):          reg d_c i.age L.log_a if $controls
qui eststo, title(age polynomial):       reg d_c age age2 L.log_a if $controls
* qui eststo, title(ee):              reg d_c       L.log_a exp_error if $controls 
* qui eststo, title(ee):              reg d_c i.age L.log_a exp_error if $controls 
* qui eststo, title(low ee):              reg d_c       L.log_a if $controls & abs(exp_error) < 0.2
* qui eststo, title(low ee):              reg d_c i.age L.log_a if $controls & abs(exp_error) < 0.2
global esttab_opts keep(L.log_a _cons) ar2 label b(5) se(5) mtitles indicate(Age dummies = *age*)
esttab , $esttab_opts title("Lag Log Assets")
*/

* TODO: look at loq assets + net housing wealth. when allowed to refinance, both should enter into EE

* TODO: restrict to those who do not change homes!
* TODO: Look at all ages, ie dont restrict to the not old
* TODO: control for interest rates?
