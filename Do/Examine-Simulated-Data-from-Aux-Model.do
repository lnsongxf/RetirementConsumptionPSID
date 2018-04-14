clear

set more off
graph close
set autotabgraphs on

global folder "C:/Users/pedm/Documents/GitHub/RetirementConsumptionPSID"

****************************************************************************************************
** Load sim data
****************************************************************************************************
import delimited "$folder/Results/Aux_Model_Estimates/Simulated_Data_from_Aux_Model.csv"

xtset pid age

collapse (mean) housing-log_inc, by(age)
tsset age

* tempfile sim_data
* save `sim_data', replace

gen source = "aux model"

****************************************************************************************************
** Load PSID data
****************************************************************************************************
append using "$folder/Results/Aux_Model_Estimates/PSID_by_age_mean.csv"
replace source = "PSID" if source == ""
encode source, gen(s)

****************************************************************************************************
** Look by age
****************************************************************************************************

xtset s age

foreach var  of varlist housing-log_inc{
  xtline `var', overlay name("`var'", replace)

}
