clear

set more off
graph close
set autotabgraphs on

*global folder "C:/Users/pedm/Documents/GitHub/RetirementConsumptionPSID"
global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"

****************************************************************************************************
** Load sim data
****************************************************************************************************
import delimited "$folder/Results/Aux_Model_Estimates/Simulated_Data_from_Aux_Model.csv"

xtset pid age


local endog_vars log_consumption log_liq_wealth log_housing_wealth log_income housing

****************************************************************************************************
** Run regression
****************************************************************************************************

sureg (`endog_vars' = L.(`endog_vars') age age_sq)

matrix list e(b) // coefs
mat coefs = e(b)

mat sigma = e(Sigma)


mat2txt, matrix(coefs) saving("$folder/Results/Aux_Model_Estimates/coefs_onsimul.txt") replace
mat2txt, matrix(sigma) saving("$folder/Results/Aux_Model_Estimates/sigma_onsimul.txt") replace
