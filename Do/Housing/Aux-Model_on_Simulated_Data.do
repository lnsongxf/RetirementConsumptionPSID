clear

set more off
graph close
set autotabgraphs on

global folder "C:/Users/pedm/Documents/GitHub/RetirementConsumptionPSID"
//  global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"

cd "$folder/Results/Di_Belsky_Liu_v2"
 
* SWITCH to CHOOSE WEALTH CAT.
global analyze_liquid_wealth 1 

****************************************************************************************************
** Load sim data
****************************************************************************************************
import delimited "$folder/Results/Aux_Model_Estimates/Simulated_Data_from_Aux_Model.csv"

xtset pid age, delta(2)

local endog_vars housing log_consumption log_liq_wealth log_housing_wealth log_income 


preserve
	gen L_housing = L.housing
	gen L_log_consumption = L.log_consumption
	gen L_log_liq_wealth = L.log_liq_wealth
	gen L_log_housing_wealth = L.log_housing_wealth
	gen L_log_income = L.log_income
	
	drop if L_log_income ==  . | L_housing == . | L_log_consumption == .
	describe
	export delimited using "$folder/Results/Aux_Model_Estimates/Simulated_Data_from_Aux_Model_with_lags.csv", replace
restore


****************************************************************************************************
** Run regression
****************************************************************************************************

sureg (`endog_vars' = L.(`endog_vars') age age_sq)

matrix list e(b) // coefs
mat coefs = e(b)

mat  list e(Sigma)
mat sigma = e(Sigma)


mat2txt, matrix(coefs) saving("$folder/Results/Aux_Model_Estimates/coefs_onsimul.txt") replace
mat2txt, matrix(sigma) saving("$folder/Results/Aux_Model_Estimates/sigma_onsimul.txt") replace 

****************************************************************************************************
** Di Belsky Liu
****************************************************************************************************

* TODO

* DEFINING TOTAL WEALTH and INITIAL WEALTH AND INITIAL AGE and AVG ANNUAL INCOME
gen liq_wealth = exp(log_liq_wealth)
gen housing_wealth = exp(log_housing_wealth)

gen total_wealth = liq_wealth + housing_wealth
gen log_total_wealth = log(total_wealth)
bys pid: gen observation_pid = _n

gen initial_wealth = log_total_wealth if  observation_pid==1
bys pid: egen log_initial_wealth = max(initial_wealth)

gen initial_age_ = age if observation_pid==1
bys pid: egen  initial_age = max(initial_age_)

bys pid: egen log_avg_income = mean(log_income)

* Generate quartiles (must do after selecting the sample)
egen init_wealth_quant = xtile(log_initial_wealth), n(4)

* DEFINING DEPENDENT VARIABLE and SUFFIX

 local dep_var 
 local file_suffix 
if $analyze_liquid_wealth == 0{
 local dep_var log_total_wealth
 local file_suffix on_simulated_model_NW
}
else if $analyze_liquid_wealth == 1{
  local dep_var log_liq_wealth
  local file_suffix on_simulated_model_LW
}

* Keep people renting in initial observation 
bys pid: egen min_housing = min(housing)
drop if min_housing!=0

* DEFINING PERIOD OF OWNERSHIP and ITS SQUARE
bys pid: gen years_owning = sum(housing)  /* should it be -1 ?*/
bys pid: gen years_owning2= years_owning^2

* cut those who own more than 15 years
drop if years_owning>15


reg `dep_var' years_owning years_owning2 log_avg_income log_initial_wealth initial_age 

qui outreg2 using "DiBelskyLiu_Reg`file_suffix'.xls", ctitle(Model A) excel replace nose noaster
qui outreg2 using "DiBelskyLiu_Means`file_suffix'.xls", ctitle(Model A) excel replace nose noaster sum

reg `dep_var' years_owning years_owning2 log_avg_income  i.init_wealth_quant initial_age 
qui outreg2 using "DiBelskyLiu_Reg`file_suffix'.xls", ctitle(Model B) excel nose noaster
qui outreg2 using "DiBelskyLiu_Means`file_suffix'.xls", ctitle(Model B) excel nose noaster sum

/* Years owning as dummy
qui reg `dep_var' i.years_owning log_average_income log_init_wealth total_gifts i.black i.init_HS i.init_some_college i.init_college_plus educ_improvement init_age i.married_end i.divorced_end i.region `metro_var' change_kids
qui outreg2 using "DiBelskyLiu_Reg`file_suffix'.xls", ctitle(Model A Dummy) excel nose noaster
qui outreg2 using "DiBelskyLiu_Means`file_suffix'.xls", ctitle(Model A Dummy) excel nose noaster sum
