clear

set more off
graph close
set autotabgraphs on

global folder "C:/Users/pedm/Documents/GitHub/RetirementConsumptionPSID"
/*global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"*/

* local sumstat "mean" // can be median or mean
local sumstat "mean"

global aux_model_in_logs 1 // 1 = logs, 0 = levels

// local title "(aux model v1)"
local title "(residualized aux model)"

set scheme s2mono

****************************************************************************************************
** Load sim data
****************************************************************************************************
import delimited "$folder/Results/Aux_Model_Estimates/Simulated_Data_from_Aux_Model.csv"

keep if age <= 65
// xtset pid age

* Generate variables in levels
if $aux_model_in_logs == 1{
  local level_vars
  foreach var of varlist log* {
    local new_var = substr("`var'", 5, .)
    gen `new_var' = exp(`var')
    local level_vars `level_vars' `new_var'
  }

  gen log_housing_wealth_if_owner = log_housing_wealth if housing == 1
  local log_vars housing-log_inc log_housing_wealth_if_own
}
else if $aux_model_in_logs == 0 {
  local level_vars housing-income
  local log_vars
}



preserve
  gen HtM = liq_wealth <= (income / 24)
  gen WHtM = HtM & housing_wealth > 1 // we've gone from logs to levels. And in logs, minimum housing_wealth == log(0) == 1
//   gen HtM_homeowners = HtM & housing > 0
  gen PHtM = HtM & housing_wealth <= 1
  collapse (mean) *HtM*, by(age)
  tsset age
  list
  lab var WHtM "Share of Wealthy HtM"
  lab var PHtM "Share of Poor HtM"
  tsline WHtM PHtM,  title("Hand to Mouth Households") subtitle("in the aux model") name("WHTM1", replace) graphregion(color(white))
  graph export "$folder\Results\AuxModel\AuxModel_HtM.pdf", as(pdf) replace
restore



collapse (`sumstat') `log_vars' `level_vars', by(age)
tsset age


* tempfile sim_data
* save `sim_data', replace

gen source = "aux model"

****************************************************************************************************
** Load PSID data
****************************************************************************************************
append using "$folder/Results/Aux_Model_Estimates/PSID_by_age_`sumstat'.csv"
replace source = "PSID" if source == ""
encode source, gen(s)

rename log_housing_wealth_if_owner log_housing_wealth_if_own
****************************************************************************************************
** Look by age
****************************************************************************************************

xtset s age

if $aux_model_in_logs == 1{
  foreach var  of varlist `log_vars' {
    xtline `var', overlay name("`sumstat'_`var'", replace) graphregion(color(white)) ylabel( #3 ) title("`sumstat' `var' `title'")
    graph export "$folder\Results\AuxModel\plot_`sumstat'_`var'.pdf", as(pdf) replace
    di "$folder\Results\AuxModel\plot_`sumstat'_`var'
  }
}

foreach var  of varlist `level_vars' {
  xtline `var', overlay name("`sumstat'_`var'", replace) graphregion(color(white)) ylabel( #3 ) title("`sumstat' `var' `title'")
  graph export "$folder\Results\AuxModel\plot_`sumstat'_`var'.pdf", as(pdf) replace
  di "$folder\Results\AuxModel\plot_`sumstat'_`var'
}