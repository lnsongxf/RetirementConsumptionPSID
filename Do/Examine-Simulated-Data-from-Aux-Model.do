clear

set more off
graph close
set autotabgraphs on

global folder "C:/Users/pedm/Documents/GitHub/RetirementConsumptionPSID"

local sumstat "mean" // can be median or mean
* local sumstat "median"

****************************************************************************************************
** Load sim data
****************************************************************************************************
import delimited "$folder/Results/Aux_Model_Estimates/Simulated_Data_from_Aux_Model.csv"

xtset pid age

* Generate variables in levels
local level_vars
foreach var of varlist log* {
  local new_var = substr("`var'", 5, .)
  gen `new_var' = exp(`var')
  local level_vars `level_vars' `new_var'
}

collapse (`sumstat') housing-log_inc `level_vars', by(age)
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

****************************************************************************************************
** Look by age
****************************************************************************************************

xtset s age

foreach var  of varlist housing-log_inc{
  xtline `var', overlay name("`sumstat'_`var'", replace) graphregion(color(white)) ylabel( #3 ) title("`sumstat' `var'")
  graph export "$folder\Results\AuxModel\plot_`sumstat'_`var'.pdf", as(pdf) replace
  di "$folder\Results\AuxModel\plot_`sumstat'_`var'
}

foreach var  of varlist `level_vars' {
  xtline `var', overlay name("`sumstat'_`var'", replace) graphregion(color(white)) ylabel( #3 ) title("`sumstat' `var'")
  graph export "$folder\Results\AuxModel\plot_`sumstat'_`var'.pdf", as(pdf) replace
  di "$folder\Results\AuxModel\plot_`sumstat'_`var'
}
