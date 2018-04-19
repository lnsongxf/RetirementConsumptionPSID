clear

set more off
graph close
set autotabgraphs on

global folder "C:/Users/pedm/Documents/GitHub/RetirementConsumptionPSID"
// global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"

****************************************************************************************************
** Load sim data
****************************************************************************************************
import delimited "$folder/Results/Aux_Model_Estimates/Simulated_Data_from_Aux_Model.csv"

xtset pid age

<<<<<<< Updated upstream
=======

>>>>>>> Stashed changes
local endog_vars housing log_consumption log_liq_wealth log_housing_wealth log_income 

****************************************************************************************************
** Run regression
****************************************************************************************************

sureg (`endog_vars' = L.(`endog_vars') age age_sq)

matrix list e(b) // coefs
mat coefs = e(b)

mat sigma = e(Sigma)


mat2txt, matrix(coefs) saving("$folder/Results/Aux_Model_Estimates/coefs_onsimul.txt") replace
mat2txt, matrix(sigma) saving("$folder/Results/Aux_Model_Estimates/sigma_onsimul.txt") replace

****************************************************************************************************
** Di Belsky Liu
****************************************************************************************************

* TODO

local dep_var 

reg `dep_var' years_owning years_owning2 `cubic' log_average_income log_init_wealth total_gifts i.black i.init_HS i.init_some_college i.init_college_plus educ_improvement init_age i.married_end i.divorced_end i.region `metro_var' change_kids
qui outreg2 using "DiBelskyLiu_Reg`file_suffix'.xls", ctitle(Model A) excel replace nose noaster
qui outreg2 using "DiBelskyLiu_Means`file_suffix'.xls", ctitle(Model A) excel replace nose noaster sum

* Years owning as dummy
qui reg `dep_var' i.years_owning log_average_income log_init_wealth total_gifts i.black i.init_HS i.init_some_college i.init_college_plus educ_improvement init_age i.married_end i.divorced_end i.region `metro_var' change_kids
qui outreg2 using "DiBelskyLiu_Reg`file_suffix'.xls", ctitle(Model A Dummy) excel nose noaster
qui outreg2 using "DiBelskyLiu_Means`file_suffix'.xls", ctitle(Model A Dummy) excel nose noaster sum
