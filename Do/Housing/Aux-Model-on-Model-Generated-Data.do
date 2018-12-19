clear

set more off
graph close
set autotabgraphs on

global folder "C:/Users/pedm/Documents/GitHub/RetirementConsumptionPSID"
//  global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"

global results_folder "$folder/Results/Compare_Aux_Model_on_Model_Generated_Data_Nov30/"

// cd "$folder/Results/Di_Belsky_Liu_v2"
cd "C:\Users\pedm\Documents\GitHub\HousingAndCommitment\Cormac\LifeCycle_Julia\v7_temptation_and_housing"
 
* SWITCH to CHOOSE WEALTH CAT.
global analyze_liquid_wealth 1 

* Choose data source
* global data_source "standard_model"
* global data_source "temptation_model"
global data_source "psid_data"

****************************************************************************************************
** Load sim data
****************************************************************************************************
if "$data_source" == "standard_model"{
	import delimited "Simulated_Panel_Standard_Nov30.csv"
	xtset id age
}
if "$data_source" == "temptation_model"{
	import delimited "Simulated_Panel_Temptation_Nov30.csv"
	xtset id age
}
if "$data_source" == "psid_data"{
	use "$folder\Data\Intermediate\Basic-Panel-Ready-for-SUREG.dta", clear 
	xtset pid wave
}


if "$data_source" != "psid_data"{

	keep if age <= 65
	gen transition_own_to_own = h != L.h if L.h != . & L.h > 1 & h > 1
	tab transition_own_to_own
	tab transition_own_to_own if age <= 65


	gen transition_rent_to_own = h > 1 & L.h == 1 if L.h != .
	gen transition_own_to_rent = h == 1 & L.h > 1 if L.h != .


	gen owner = h > 1
	tab owner 
	tab transition_rent
	tab transition_own_to_rent
	tab transition_own_to_rent if age <= 65

	reg owner L.owner
	reg owner L.owner, nocons

	gen purchase_age_ = age if transition_rent_to_own == 1
	by id, sort: egen purchase_age = min(purchase_age_)
	gen time_owning = age - purchase_age

	gen savings_rate = (y_posttax-c)/y_posttax
	gen c_to_y = c/y_posttax

	desc 
	sum c_to_y



	/*
	preserve
		collapse (median) net_wealth m savings_rate repay c_to_y c y_posttax y_pre a (mean) owner, by(time_owning)
		tsset time
		tsline c_to_y if time <= 20 & time >= -20, name(c_to_y, replace)
		tsline net_wealth if time <= 20 & time >= -20, name(nw, replace)
		tsline m if time <= 20 & time >= -20, name(m, replace)
		tsline repay if time <= 20 & time >= -20, name(repay, replace)
		tsline owner if time <= 20 & time >= -20, name(owner, replace)
		tsline y_posttax y_pre if time <= 20 & time >= -20, name(y, replace)
		tsline c if time <= 20 & time >= -20, name(c, replace)
		tsline a if time <= 20 & time >= -20, name(a, replace)
	restore
	*/
}
else{

* PSID Data

preserve
	gen adults = 1
	gen second_adult = (age_spouse != .)
	replace adults = 2 if age_spouse != .


	gen kids = fsize - adults
	gen eq_scale_taha = (adults + 0.7*kids)^0.75
	gen eq_scale_oecd = (1 + 0.5*second_adult + 0.3*kids)
	gen eq_scale_oecd_orig = (1 + 0.7*second_adult + 0.5*kids)

	collapse fsize eq_scale*, by(age)
	tsset age
	tsline fsize eq_scale*
	list
	edit
restore

}


* preserve
* collapse owner trans*, by(age)
* tsset age
* tsline owner trans*
* tsline trans*
* restore



****************************************************************************************************
** Run regression
****************************************************************************************************


if "$data_source" == "standard_model" | "$data_source" == "temptation_model" {
	* Model:
	keep if age <= 65
	gen housing = owner
	gen log_consumption = log(c)
	gen log_liq_wealth = log(a+1)
	gen log_housing_wealth = log(net_wealth - a + 1)
	gen log_income = log(y_pretax)
	cap drop c_to_y
	gen c_to_y = c / y_pretax
	gen log_mortgage = log(m+1)
	gen mort = m > 0
	gen bought = owner == 1 & L.owner == 0
	gen age2 = age^2
	gen age3 = age^3
}
else{
	* Data:
	* local endog_vars housing log_consumption log_liq_wealth log_housing_wealth log_income WHtM PHtM
	rename PHtM phtm 
	rename WHtM whtm 
	rename dummy_mort mort 
	gen c_to_y = exp(log_consumption) / exp(log_income)

	* Keep only those who are always employed!! Makes persistence in logY more similar to model
	keep if emp_status_head == 1 | emp_status_head_2 == 1 | emp_status_head_3 == 1 
	
	* Compute homeownership rates by income quartile
	* cap ssc install astile
	by age, sort: astile quartile = income, nquantiles(4) // note: results look different if using log_income, since log_income has been residualized

	* TODO: put this earlier, before "residualizing"
	sum income, det
	drop if income < 100 // important!!! about 100 people. many with negative income!

	preserve
		collapse (mean) income housing (max) max_income = income (min) min_income = income, by(age quartile)
		xtset quartile age
		xtline income, overlay name(inc_quartile, replace)
		xtline min_income, overlay name(min_income, replace)
		xtline max_income, overlay name(max_income, replace)
		lab var housing "Homeownership Rate"
		xtline housing, overlay name(own_quartile, replace) title("Homeownership by Quartile (PSID)")
	restore

	* Look at variance by age
	preserve
		collapse (mean) log_consumption log_income (sd) sd_c = log_consumption sd_y = log_income, by(age)
		tsset age
		tsline log_*, name(logs, replace)
		gen var_consumption = sd_c^2
		gen var_income = sd_y^2
		tsline var_*, name(vars, replace)
	restore
}

rename log_consumption logC
rename log_housing_wealth logHW
rename log_income logY
rename log_liq_wealth logLW
rename log_mortgage logM
* cap rename dummy_mort mort
cap rename housing H
rename bought just_bought



gen H_phtm = phtm * H
gen H_whtm = whtm * H
gen H_mort = mort * H
gen H_logC = logC * H
gen H_logHW = logHW * H
gen H_logY = logY * H
gen H_logLW = logLW * H
gen H_logM = logM * H

* v1
sort pid wave
local endog_vars H phtm whtm mort logC logHW logY logLW logM 
sureg (`endog_vars' =  L2.(`endog_vars') just_bought age age2 age3)

* v2
* local endog_vars phtm whtm mort logC logHW logY logLW logM 
* sureg (H c_to_y `endog_vars' = L2.H L2.(`endog_vars' H_*) just_bought age age2 age3)

****************************************************************************************************
** Save results in tex files
****************************************************************************************************

di e(ll)
matrix list e(b) // coefs
mat coefs = e(b)

mat  list e(Sigma)
mat sigma = e(Sigma)

cap mkdir "$results_folder/"
mat2txt, matrix(coefs) saving("$results_folder/coefs_$data_source.txt") replace
mat2txt, matrix(sigma) saving("$results_folder/sigma_$data_source.txt") replace 

	// export coefs to latex (transposed)
	preserve
		matrix c = e(b)'
		xsvmat c, norestore roweqname(xvar)
		split xvar, parse(":")
		drop xvar
		replace xvar2 = subinstr(xvar2, ".", "_", .)
// 		reshape wide c1, i(xvar1) j(xvar2) string
		reshape wide c1, i(xvar2) j(xvar1) string

// 		rename c1_cons c1constant
		foreach var of varlist c1* {
			local newname = substr("`var'", 3, .)
			rename `var' `newname'
		}
		rename xvar Y
				
		* list
		desc 
		desc H-whtm 

		drop if Y == "oL2_H_logHW" 
		drop if Y == "oL2_H_logM"
		drop if Y == "oL2_H_mort"
		drop if Y == "oL2_H_phtm"
		drop if Y == "oL2_H_whtm"


		* dataout, save("$folder/Results/Aux_Model_Estimates/AuxModelLatex/coefs") tex replace auto(3)
// 		mkmat L* cons age*, matrix(newcoefs) rownames(Y)
		mkmat H-whtm , matrix(newcoefs) rownames(Y)
		outtable using "$results_folder/coefs_transposed_$data_source", nobox mat(newcoefs) replace f(%9.3f)  caption("Coefficients (transposed)")
		mat2txt, matrix(newcoefs) saving("$results_folder/coefs_transposed_$data_source.txt") replace
	restore
	
	// export var covar to latex
	outtable using "$results_folder/sigma_$data_source", ///
		nobox mat(sigma) replace f(%9.3f) caption("Variance Covariance Matrix")
		
