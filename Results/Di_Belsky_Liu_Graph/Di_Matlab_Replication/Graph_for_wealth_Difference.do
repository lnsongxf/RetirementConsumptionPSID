clear all

*global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"

import excel Duration_dummy NW_Model_B_Dummy using "$folder/Results/Di_Belsky_Liu_Graph/Di_Matlab_Replication/Matlab_Results.xlsx" ///
      , sheet("Sheet1") 
	  
import excel LW_Model_B_Dummy using "$folder/Results/Di_Belsky_Liu_Graph/Di_Matlab_Replication/Matlab_Results.xlsx" ///
      , sheet("Sheet2") 

use "$folder/Results/Di_Belsky_Liu_Graph/Di_Matlab_Replication/Wealth_Differences.dta"

ren duration_dummy year
tsset year

tsline NW_Model_B_Dummy LW_Model_B_Dummy, title("Wealth Difference between Owners and Renters") name("Wealth_by_years_owning", replace) ytitle("Real Wealth (2015 dollars)", margin(0 4 0 0) ) graphregion(color(white)) ylabel( #3 ) ///
legend(order(1 "Net Wealth" 2 "Net Liquid Wealth")) xtitle("Duration of Homeownership")

graph export "$folder/Results/Di_Belsky_Liu_Graph/wealth_differences.pdf", as(pdf) replace
