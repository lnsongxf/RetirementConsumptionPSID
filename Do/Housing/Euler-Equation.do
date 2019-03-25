****************************************************************************************************
** Run SUR for aux model
****************************************************************************************************

set more off
graph close
set autotabgraphs on
pause on 

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

* Estimate the euler equation using food consumption (1) or total nondurable consumption (0)
global EE_Food_Consumption 0 

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
** Extra variables
****************************************************************************************************

* Convert to real              : bank_account_wealth stock_wealth

replace bank_account_wealth    = 100 * bank_account_wealth / CPI_all_base_2015
replace stock_wealth           = 100 * stock_wealth / CPI_all_base_2015
lab var bank_account_wealth "Real Bank Balances"
lab var stock_wealth "Real Stock Holdings"

gen log_bank_account_wealth     = log(bank_account_wealth + 100)
gen log_stock_wealth            = log(stock_wealth + 100)
gen non_pos_bank_account_wealth = log_bank_account_wealth <= 0
gen non_pos_stock_wealth        = log_stock_wealth <= 0

lab var log_bank_account_wealth "Log Bank Balances"
lab var log_stock_wealth "Log Stock Holdings"

gen log_homeequity = log(homeequity_real + 1)
lab var log_stock_wealth "Log Home Equity"


gen texas = current_state == 48

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

gen consumption     = expenditure_exH_real_2015 // blundell expenditure excluding housing
gen liq_wealth      = fam_liq_wealth_real // 2015 dollars
* gen housing_wealth= fam_LiqAndH_wealth_real - fam_liq_wealth_real // 2015 dollars (includes other housing wealth)
gen housing_wealth  = homeequity_real
gen mortgage        = mortgage_debt_real
gen housing_price   = housing_wealth + mortgage
gen housing         = housingstatus == 1 // renting or living with parents are considered as the same
gen income          = inc_fam_real_2015
gen illiq_wealth    = fam_wealth_real - fam_liq_wealth_real // NOTE: we do not use this in the regressions, just use it for our alternative measure of WHtM
gen HtM             = liq_wealth <= (income / 24) // TODO: not sure it should be 24 exactly
gen dummy_mort      = mortgage>0

gen bought          = 0 
replace bought      = 1 if housing ==1 & L.housing==0

gen sold            = 0
replace sold        = 1 if housing == 0 & L.housing == 1

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
** Generate variables
****************************************************************************************************

sum consumption, det
drop if consumption < 1000
sum consumption, det

gen y     = log_income 
gen d_y   = D.y
gen d_c   = D.log_consumption
gen log_a = log_liq_wealth
gen a     = liq_wealth

lab var log_a "Log Liquid Assets"
lab var a "Liquid Assets"

****************************************************************************************************
** ALTERNATIVE: Try euler equation with food consumption
****************************************************************************************************

if $EE_Food_Consumption {
    drop d_c consumption log_consumption
    
    * gen consumption = foodawayfromhomeexpenditure
    * gen consumption = foodathomeexpenditure
    gen consumption = foodathomeexpenditure + foodawayfromhomeexpenditure + foodstamp
    
    sum consumption, det
    replace consumption = . if consumption < 1000
    sum consumption, det
    
    gen log_consumption = log(consumption)
    gen d_c = D.log_consumption
}

****************************************************************************************************
** Consumption Euler Equation
****************************************************************************************************

/*
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
*/

replace consumption = . if consumption == 0 | L.consumption == 0
* drop if consumption == 0 | L.consumption == 0

/*
preserve
  collapse d_y, by(age)
  tsset age
  tsline d_y
restore
*/
/*
sum d_y, det
xtile p_d_y = d_y, nquantiles(100)
drop if p_d_y == 1 | p_d_y == 100
* drop if p_d_y <= 5 | p_d_y >= 95
drop p_d_y
sum d_y, det
*/

sum d_c, det
xtile p_d_c = d_c, nquantiles(100)
drop if p_d_c == 1 | p_d_c == 100 // results seem robust to doing this... magnitudes just change a bit. but it's a bit crazy to see such large changes in Consumption
drop if p_d_c <= 5 | p_d_c >= 95 // much better IV results from this
* drop if p_d_c <= 10 | p_d_c >= 90 
sum d_c, det
pause

* TODO: should we drop those with 700% change in income?

* drop if d_c < -1 | d_c > 1


****************************************************************************************************
** Consumption Euler Equation - Baseline used for Indirect Inference
****************************************************************************************************

* reg d_c age age2 log_a if a > 1000 & a < 500000 & a != . & age >= 25 & age <= 60 & housing_transition == 0 & HtM == 0  & L.HtM == 0 & L.a > 1000

* NOTE: Looks like we can get rid of the HtM and L.HtM requirement as long as everyone holds at least $1,000 today and yesterday
reg d_c age age2 log_a if a > 1000 & a < 500000 & a != . & age >= 25 & age <= 60 & housing_transition == 0 & L.a > 1000

****************************************************************************************************
** Tables with Consumption Euler Equation
****************************************************************************************************

* Produce EE version controlling for assets today, but not yesterday
/*
global sample a > 1000 & a != .  & age >= 25 & age <= 60 & housing_transition == 0
eststo clear 
qui eststo, title(baseline):              reg d_c       log_a if $sample
qui eststo, title(age control):           reg d_c i.age log_a if $sample
qui eststo, title(age polynomial):           reg d_c age age2 log_a if $sample
qui eststo, title(IV L.a):         ivregress 2sls d_c       (log_a = L.log_a) if $sample, first
qui eststo, title(IV L.a):         ivregress 2sls d_c       (log_a = L.log_a L.y) if $sample, first
qui eststo, title(IV a & y):         ivregress 2sls d_c i.age (log_a = L.log_a) if $sample, first
qui eststo, title(IV a & y):         ivregress 2sls d_c i.age (log_a = L.log_a L.y) if $sample, first
global esttab_opts keep(log_a _cons) ar2 label b(5) se(5) mtitles indicate(Age controls = *age*) star(* 0.10 ** 0.05 *** 0.01)
esttab , $esttab_opts title("Depvar: d_c. $sample")
*/


* It seems that the L.HtM == 0 has a lot of bite
* Or maybe L.a > 1000 has a lot of bite

* First try - maybe a bit too restrictive
* global sample a > 1000 & a < 500000 & a != . & age >= 25 & age <= 60 & housing_transition == 0 & HtM == 0  & L.HtM == 0 & L.a > 1000

* BASELINE: This is slightly better: less restrictive, gives more observations, and gives more precision to IV estimates
global sample a > 1000 & a < 500000 & a != . & age >= 25 & age <= 60 & housing_transition == 0 & L.a > 1000 

* IV results go negative when I get rid of the restriction that L.a > 1000
* BUT, IV results go positive again if I drop top/bottom 5% rather than top/bottom 1% of d_c
* global sample a > 1000 & a < 500000 & a != . & age >= 25 & age <= 60 & housing_transition == 0

* Woohoo OLS results still significant
* global sample a > 1000 & a < 500000 & a != . & age >= 25 & age <= 60 & housing_transition == 0 & L.a > 1000 & wave <= 2007

* global sample a > 1000 & a < 500000 & a != . & age >= 25 & age <= 60 & housing_transition == 0 & texas

* NOTE: It seems that the L.HtM == 0 has a lot of bite
* global sample a > 1000 & a < 500000 & a != . & age >= 25 & age <= 60 & housing_transition == 0 & HtM == 0  & L.HtM == 0 & L.a > 1000

eststo clear 
qui eststo, title(age dum):                       reg d_c i.age     log_a            if $sample
qui eststo, title(age poly):                    reg d_c age age2  log_a            if $sample
qui eststo, title(IV L.a):                 ivregress 2sls d_c age age2 (log_a = L.log_a) if $sample, first
* qui eststo, title(IV lag difs):            ivregress 2sls d_c age age2 (log_a = L.D.log_a L.D.y L.D.log_consumption) if $sample, first
qui eststo, title(IV L.cash stock):         ivregress 2sls d_c age age2 (log_a = L.(log_a log_bank_account_wealth log_stock_wealth) ) if $sample, first
qui eststo, title(IV L.y):                  ivregress 2sls d_c age age2 (log_a = L.HtM L.y) if $sample, first
qui eststo, title(IV L2.y):                 ivregress 2sls d_c age age2 (log_a = L.HtM L2.y) if $sample, first
qui eststo, title(IV L.a L.y):              ivregress 2sls d_c age age2 (log_a = L.HtM L.log_a L.y) if $sample, first
qui eststo, title(IV L.a L2.c L.y):         ivregress 2sls d_c age age2 (log_a = L.HtM L(1 2).(log_a y log_bank_account_wealth) L2.log_consumption) if $sample, first
global esttab_opts keep(log_a _cons) ar2 label b(5) se(5) mtitles indicate(Age controls = *age*) star(* 0.10 ** 0.05 *** 0.01)
esttab , $esttab_opts title("Depvar: d_c. $sample")
esttab using "$folder_output\EE_PSID.tex", $esttab_opts longtable booktabs obslast replace title("PSID Euler Equation (Baseline)") addnotes("Sample: Households with liq assets $>$ 1,000 at time t and t-1, ages 25 to 60, not moving homes that year")
esttab using "$folder_output\EE_PSID.csv", $esttab_opts csv obslast replace


eststo clear 
global control_vars i.wave D.fsize 
qui eststo, title(age dum):                           reg d_c  $control_vars i.age log_a if $sample
qui eststo, title(age poly):                          reg d_c  $control_vars age age2 log_a if $sample
qui eststo, title(IV L.a):                 ivregress 2sls d_c  $control_vars age age2 (log_a = L.log_a) if $sample, first
qui eststo, title(IV L.cash stock):        ivregress 2sls d_c  $control_vars age age2 (log_a = L.(log_a log_bank_account_wealth log_stock_wealth) ) if $sample, first
qui eststo, title(IV L.a L.y):             ivregress 2sls d_c  $control_vars age age2 (log_a = L.log_a L.y) if $sample, first
qui eststo, title(IV L.a L2.c L.y):        ivregress 2sls d_c  $control_vars age age2 (log_a = L(1 2).(log_a y log_bank_account_wealth) L2.log_consumption) if $sample, first
global esttab_opts keep(log_a _cons) ar2 label b(5) se(5) mtitles indicate("Age controls = *age*" "Year controls = *wave*" "Kids controls = *fsize*") star(* 0.10 ** 0.05 *** 0.01)
esttab , $esttab_opts title("Depvar: d_c. Kid and Year Controls. $sample")
esttab using "$folder_output\EE_PSID_Control_for_kids_and_year.tex", $esttab_opts longtable booktabs obslast replace title("PSID Euler Equation (More Controls)") addnotes("Sample: Households with liq assets $>$ 1,000 at time t and t-1, ages 25 to 60, not moving homes that year")
esttab using "$folder_output\EE_PSID_Control_for_kids_and_year.csv", $esttab_opts csv obslast replace
pause

* Looking at bank account wealth makes nicer IV results!
* IV results also work for texas!

eststo clear 
global control_vars i.wave D.fsize 
qui eststo, title(age dum):                       reg d_c i.age     log_bank_account_wealth                                                    $control_vars if $sample
qui eststo, title(age poly):                    reg d_c age age2  log_bank_account_wealth                                                    $control_vars if $sample
qui eststo, title(IV L.a):                 ivregress 2sls d_c age age2 (log_bank_account_wealth = L.log_bank_account_wealth)                       $control_vars if $sample, first
qui eststo, title(IV L.a L.y):             ivregress 2sls d_c age age2 (log_bank_account_wealth = L.log_bank_account_wealth L.y)                   $control_vars if $sample, first
qui eststo, title(IV L.a L2.c L.y):         ivregress 2sls d_c age age2 (log_bank_account_wealth = L(1 2).(log_bank_account_wealth y log_a) L2.log_consumption) $control_vars if $sample, first
global esttab_opts keep(log_bank* _cons) ar2 label b(5) se(5) mtitles indicate("Age controls = *age*" "Year controls = *wave*" "Kids controls = *fsize*") star(* 0.10 ** 0.05 *** 0.01)
esttab , $esttab_opts title("Depvar: d_c. Liquid Assets in Checking/Savings Account. $sample")
esttab using "$folder_output\EE_PSID_Bank_Account.tex", $esttab_opts longtable booktabs obslast replace title("PSID Euler Equation (Log Liquid Assets in Checking/savings accounts)") addnotes("Sample: Households with liq assets $>$ 1,000 at time t and t-1, ages 25 to 60, not moving homes that year")
esttab using "$folder_output\EE_PSID_Bank_Account.csv", $esttab_opts csv obslast replace
pause
* TODO: look at lagged assets



* TODO: use interest rate rather than year controls
* Wait... is the year control entering into the first stage for log_a? Maybe an issue
* Look at results for Texas only ...

* DONE - try age polynomial for IV - gives very similar results

* TODO: put net housing wealth into the regressions

* TODO: look at employment status & emp_status_head == 1 & L.emp_status_head == 1
* TODO: look at lagged log assets 

* PROBLEM: not real: bank_account_wealth stock_wealth
* Look at different types of liq assets in IV

/*
eststo clear 
qui eststo, title(baseline):             reg d_c       L.log_a if $sample
qui eststo, title(age control):          reg d_c i.age L.log_a if $sample
qui eststo, title(age polynomial):       reg d_c age age2 L.log_a if $sample
* qui eststo, title(ee):              reg d_c       L.log_a exp_error if $sample 
* qui eststo, title(ee):              reg d_c i.age L.log_a exp_error if $sample 
* qui eststo, title(low ee):              reg d_c       L.log_a if $sample & abs(exp_error) < 0.2
* qui eststo, title(low ee):              reg d_c i.age L.log_a if $sample & abs(exp_error) < 0.2
global esttab_opts keep(L.log_a _cons) ar2 label b(5) se(5) mtitles indicate(Age dummies = *age*)
esttab , $esttab_opts title("Lag Log Assets")
*/

* TODO: look at loq assets + net housing wealth. when allowed to refinance, both should enter into EE
* TODO: restrict to those who do not change homes!
* TODO: Look at all ages, ie dont restrict to the not old
* TODO: control for interest rates?

****************************************************************************************************
** First stage regressions
****************************************************************************************************


* missings report log_a y log_c bank_account_wealth stock_wealth
* missings report log_a y log_c log_bank_account_wealth log_stock_wealth
* gen no_bank_account_info = 

/*
reg log_a L.(log_a) age age2
reg log_a L.(log_a y) age age2
reg log_a L.(log_a y log_c) age age2
reg log_a L.(log_a y log_c log_bank_account_wealth log_stock_wealth non_pos_bank_account_wealth non_pos_stock_wealth) age age2


reg log_bank_account_wealth L.(log_bank_account_wealth log_stock_wealth y log_c) age age2 i.received_gift value_gift_1 value_gift_2 value_gift_3

* Adding gifts does basically nothing to help with fit
egen value_gifts = rowtotal(value_gift_1 value_gift_2 value_gift_3)
gen log_value_gifts = log(value_gifts + 1)
reg log_stock_wealth L.(log_bank_account_wealth log_stock_wealth y log_c) age age2
reg log_stock_wealth L.(log_bank_account_wealth log_stock_wealth y log_c) age age2 i.received_gift log_value_gifts



gen d_log_bank_account_wealth = D.log_bank_account_wealth
sum d_log_bank_account_wealth
*/


****************************************************************************************************
** Things to do
****************************************************************************************************

* look into IVs
* in the monte carlo results, interact log_a with dummies for liquid assets low/mid/high
* and make some plots that might be helpful to understand these results. both plot the simulated data and also plot the policy function
* in psid, see if results hold if i restrict to food consumption ???
* in psid, see what happens if i put in housing wealth that can be extracted
* previously i tried with net housing wealth = house price - mortgage
* maybe i should try with net housing wealth that can be extracted = max(0, houseprice * 0.9 - mortgage). in other words, if you have a 50% LTV, you can only lever up to 90%.
* aka net housing wealth that can be extracted = (0.9 - LTV) * houseprice = 0.9* houseprice - mortgage
