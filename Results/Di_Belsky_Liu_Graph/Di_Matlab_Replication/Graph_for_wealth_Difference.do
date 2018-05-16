clear all

global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
* global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"

import excel "$folder/Results/Di_Belsky_Liu_Graph/Di_Matlab_Replication/Matlab_Results.xlsx" ///
      , sheet("Sheet1") firstrow clear 
	  keep Duration NW_Model_B NW_Model_D
	 * drop if Duration_Dummy ==0
save "$folder/Results/Di_Belsky_Liu_Graph/Di_Matlab_Replication/NW"	, replace  
	
clear all	
import excel  using "$folder/Results/Di_Belsky_Liu_Graph/Di_Matlab_Replication/Matlab_Results.xlsx" ///
      , sheet("Sheet2") firstrow clear
	  keep Duration LW_Model_B LW_Model_D
	 * drop if Duration_Dummy ==0
save "$folder/Results/Di_Belsky_Liu_Graph/Di_Matlab_Replication/LW", replace	  	

clear all

use "$folder/Results/Di_Belsky_Liu_Graph/Di_Matlab_Replication/NW.dta"

merge 1:1 Duration using "$folder/Results/Di_Belsky_Liu_Graph/Di_Matlab_Replication/LW.dta" 
drop _merge
erase "$folder/Results/Di_Belsky_Liu_Graph/Di_Matlab_Replication/NW.dta"
erase "$folder/Results/Di_Belsky_Liu_Graph/Di_Matlab_Replication/LW.dta"

ren Duration year
tsset year

tsline NW_Model_B LW_Model_B if year <10, title("Wealth Difference between Owners and Renters") subtitle("Controlling for income ") name("Wealth_by_years_owning_modelB", replace) ytitle("Real Wealth (2015 dollars)", margin(0 4 0 0) ) graphregion(color(white)) ylabel( #3 ) ///
legend(order(1 "Net Wealth" 2 "Net Liquid Wealth")) xtitle("Duration of Homeownership") 
graph export "$folder/Results/Di_Belsky_Liu_Graph/wealth_differences_modelB.pdf", as(pdf) replace

tsline NW_Model_D LW_Model_D if year<10, title("Wealth Difference between Owners and Renters") subtitle("No control for income ") name("Wealth_by_years_owning_modelD", replace) ytitle("Real Wealth (2015 dollars)", margin(0 4 0 0) ) graphregion(color(white)) ylabel( #3 ) ///
legend(order(1 "Net Wealth" 2 "Net Liquid Wealth")) xtitle("Duration of Homeownership") 
graph export "$folder/Results/Di_Belsky_Liu_Graph/wealth_differences_modelD.pdf", as(pdf) replace
