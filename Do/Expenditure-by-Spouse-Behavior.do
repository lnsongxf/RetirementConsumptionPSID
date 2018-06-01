set more off
graph close
*set autotabgraphs on

*global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"
* global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
global folder "/Users/bibekbasnet/Documents/GitHub/RetirementConsumptionPSID"

cap mkdir "$folder/Results/ConsumptionPostRetirement_by_SpouseDef"

 forvalues spouse_def = 1/8{

	//local spouse_def 1
	//display "Spouse def = `spouse_def'"

	* Switches
	global quintiles_definition 2    // Defines quintiles. Can be 1, 2, 3, or 4. My preference is 4. I think the next best option is 2
                                 // Note: if you want tertiles, must use definition 2
	global retirement_definition 0   // 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                 // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)
	global ret_duration_definition 2 // Defines retirement year. Can be 1, 2, or 3. My preference is 3 (for the sharp income drop) although 2 is perhaps better when looking at consumption data (for smoothness)
	global graphs_by_mean 0          // Graph by quintile. Can be 0 or 1
	global graphs_by_quintile 0      // Graph by quintile. Can be 0 or 1
	global graphs_by_tertile 1       // Tertiles
	global allow_kids_to_leave_hh 1  // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                 // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)
	global how_to_deal_with_spouse `spouse_def'  // could be 1 2 3 4 5
	global retirement_definition_spouse 1 //// 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                       // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)			 							 
						
	** LOAD AND PREPARE DATA
	use "$folder/Data/Intermediate/Basic-Panel.dta", clear
					 
	* Sample selection: households with same husband-wife over time
	quietly do "$folder/Do/Sample-Selection.do"

	* Look for retirement transitions of the head
	quietly do "$folder/Do/Find-Retirements.do"
	* NOTE: could also define retirement based on whether you worked < 500 hours that year. Might be worth exploring

	* Generate aggregate consumption (following Blundell et al)
	quietly do "$folder/Do/Consumption-Measures.do"
	
	quietly do "$folder/Do/Scripts/Define-Quintiles.do"

	quietly do "$folder/Do/Scripts/Define-Ret-Duration.do"

		
	local expenditure_cats_all total_foodexp_home_real total_foodexp_away_real total_housing_real ///
	total_education_real total_healthexpense_real total_transport_real 
	egen nondurable_expenditure_real = rowtotal( `expenditure_cats_all' )
	label variable nondurable_expenditure_real "Real Nondurable Expenditure"
	
	lab var ret_duration "Duration of Head's Retirement"
	lab var transportation_blundell "Transportation Services"
	lab var gasolineexpenditure "Gasoline Expenditure"
	lab var healthcareexpenditure "Health care"
	lab var healthinsuranceexpenditure "Health insurance"
	lab var healthservicesexpenditure "Health services"
	lab var tripsexpenditure "Trips"
	lab var recreationexpenditure "Recreation"
	lab var clothingexpenditure "Clothing"
	lab var foodathomeexpenditure "Food at home"
	lab var foodawayfromhomeexpenditure "Food away from home"
	lab var expenditure_blundell_eq "Nondurable Consumption (Equivalence Scale)"
	lab var workexpenditure "Work Related Expenditure" // excludes clothing

	* lab var expenditure_cats_2005 "Expenditure Categories"
	lab var total_foodexp_home_real "Food Expenditure at Home"
	lab var total_foodexp_away_real "Food away from Home"
	lab var	total_education_real "Education Expenditure"
	lab var	total_healthexpense_real "Health Expenditure"
	lab var	total_transport_real "Non Durables Transportation Expenditure"
	lab var	transport_durables "Transportation Durables Expenditure"
	lab var	total_housing_2005_real "Housing Expenditure"
	lab var	total_recreation_2005_real "Recreation Expenditure"
	lab var total_clothing_2005_real  "Clothing Expenditure"

	local expenditure_cats nondurable_expenditure_real

	// local lab: variable label `var'

		***********************************************************************************
		** APC
		***********************************************************************************

		* Create normalized year dummies, where year dummies are normalized so that Ed_year=0 and Cov(d_year,trend)=0
		* Deaton-Paxson Normalization to solve multicollinearity in the age-period-cohort model
		* See for instance Aguiar and Hurst 2013
		* if using data from 1999 to 2015, use 3/9 (because there are 9 waves)
		* if using data from 2005 to 2015, use 3/6 (because there are 6 waves)
		quietly tab wave, gen(year_cat)
		foreach num of numlist 3/9 { 
			gen d_year_`num'=year_cat`num'+(1-`num')*year_cat2+(`num'-2)*year_cat1
		}

		* xtreg .... d_year*

	***********************************************************************************
	** New Version: regression
	***********************************************************************************

	* Categorical variables cannot contain negatives
	replace ret_duration = ret_duration + 100

	tempfile results	
	qui xtreg nondurable_expenditure_real ibn.ret_duration d_year* if tertile == 1, fe 
	regsave using `results', addlabel(tertile, "Bottom Tertile") replace
	qui xtreg nondurable_expenditure_real ibn.ret_duration d_year* if tertile == 2, fe
	regsave using `results', addlabel(tertile, "Middle Tertile") append
	xtreg nondurable_expenditure_real ibn.ret_duration d_year* if tertile == 3, fe
	regsave using `results', addlabel(tertile, "Top Tertile") append


	* xtreg nondurable_expenditure_real ibn.ret_duration if tertile == 3, fe

	* xtset pid ret_duration, delta(2)
	* test ( F.ret_duration + ret_duration + L.ret_duration)

	count if tertile == 1 & ret_duration == 100
	local count1 `r(N)'

	count if tertile == 2 & ret_duration == 100
	local count2 `r(N)'

	count if tertile == 3 & ret_duration == 100
	local count3 `r(N)'

	***********************************************************************************
	** Produce regression results using saved coefs
	** NOTE: we do not smooth SEs correctly in this version
	***********************************************************************************
	/*
	preserve
		* Find coefs by age
		use `results', clear
		destring var, replace ignore(".ret_duration" "bn.ret_duration")
		rename var ret_duration
		replace ret_duration = ret_duration - 100

		* Plot results
		encode tertile, gen(tertile_i)
		xtset tertile_i ret_duration, delta(2)
		lab var ret_duration "Retirement Duration"
		lab var coef "Mean Expenditure"

		gen ub = coef + stderr
		gen lb = coef - stderr

		gen coef_ma = ( F.coef + coef + L.coef ) / 3
		* NOTE: this is not correct, will want to ask cormac about how to use "test" with L. and F.
		gen lb_ma = ( F.lb + lb + L.lb ) / 3
		gen ub_ma = ( F.ub + ub + L.ub ) / 3

		lab var coef_ma "Mean Expenditure"

		keep if ret_duration >= -10 & ret_duration <= 10

		* Not smoothed
		xtline coef, name("Fig1", replace)  ytitle(, margin(0 2 0 0)) ///
			byopts(title("Nondurable Expenditure by Tertile (Spouse Def = `spouse_def')") note("# Households in Tertile 1 = `count1'; Households in Tertile 2 = `count2'; Households in Tertile 3 = `count3'") rows(1) ) ylabel(#3) ///
			addplot( rarea ub lb ret_duration, below)
		     graph export "$folder/Results/ConsumptionPostRetirement_by_SpouseDef/UnSmoothed/spouse_def_`spouse_def'.pdf", as(pdf) replace

		* TODO: make the plot stop where the data stops
		* This is smoothed
		xtline coef_ma, name("Fig1_ma", replace)  ytitle(, margin(0 2 0 0)) ///
			byopts(title("Nondurable Expenditure by Tertile (Spouse Def = `spouse_def')") note("# Households in Tertile 1 = `count1'; Households in Tertile 2 = `count2'; Households in Tertile 3 = `count3'") rows(1) ) ylabel(#3) ///
			addplot( rarea ub_ma lb_ma ret_duration, below )
			graph export "$folder/Results/ConsumptionPostRetirement_by_SpouseDef/Smoothed/spouse_def_`spouse_def'.pdf", as(pdf) replace

	restore
	*/

	***********************************************************************************
	** Produced smoothed regression results using lincom command
	***********************************************************************************

	* Create empty variables where we can store reg results
	gen reg_coef = .
	gen reg_se = .
	gen reg_coef_ma = .
	gen reg_se_ma = .
	gen reg_ret_duration = .
	gen reg_tertile = .
	local counter 1
	
	* loop over tertiles
	forvalues n_tertile = 1/3{
		* Step 1: run the regression
		qui xtreg nondurable_expenditure_real ibn.ret_duration d_year* if tertile == `n_tertile', fe 

		* loop over ret_duration: 80 to 120
		forvalues n = 80(2)120{
			local nPlus = `n' + 2
			local nMinus = `n' - 2

			* Step 2: save the raw coef and se
			capture lincom _cons + i`n'.ret_duration
			* if lincom did not throw an error, then save the results
			if _rc == 0 {
				qui replace reg_coef = r(estimate) in `counter'
				qui replace reg_se = r(se) in `counter'
				qui replace reg_ret_duration = `n' in `counter'
				qui replace reg_tertile = `n_tertile' in `counter'
			}			

			* Step 3: save the moving average coef and se
			* lincom will compute moving average based on coefs
			* capture will hide error msg (for instance if we're looking for coefs that dont exist)
			capture lincom _cons + (i`nMinus'.ret_duration + i`n'.ret_duration + i`nPlus'.ret_duration) / 3

			* if lincom did not throw an error, then save the results
			if _rc == 0 {
				qui replace reg_coef_ma = r(estimate) in `counter'
				qui replace reg_se_ma = r(se) in `counter'
			}

			local counter = `counter' + 1
		}
	}

	** New Version : error bands computed correctly
	 preserve

		replace reg_ret_duration = reg_ret_duration - 100

		lab var reg_coef_ma "Smoothed Mean Expenditure"
		lab var reg_coef "UnSmoothed Mean Expenditure"


		keep if reg_ret_duration >= -10 & reg_ret_duration <= 10

		keep reg_coef reg_se reg_ret_duration reg_tertile reg_coef_ma reg_se_ma
		* keep if reg_ret_duration != .
		
		xtset reg_tertile reg_ret_duration
		/*
		xtline reg_coef reg_coef_ma, name("tertile", replace) ytitle(, margin(0 2 0 0)) ///
		byopts(title("Nondurable expenditure by Tertile(Spouse Def = `spouse_def')") rows(1)) ///
		legend(label(1 "UnSmoothed Expenditure")) legend(label(2 "Smoothed Expenditure"))
		graph export "$folder/Results/ConsumptionPostRetirement_by_SpouseDef/Comparision/SmoothedvsUnsmoothed_`spouse_def'.pdf", as(pdf) replace
		*/
		* Smoothed version
		gen se_ub_ma = reg_coef_ma + reg_se_ma
		gen se_lb_ma = reg_coef_ma - reg_se_ma

		xtline reg_coef_ma, name("Fig1_ma", replace)  ytitle(, margin(0 2 0 0)) ///
		byopts(title("Nondurable Expenditure by Tertile (Spouse Def = `spouse_def')") note("# Households in Tertile 1 = `count1'; Households in Tertile 2 = `count2'; Households in Tertile 3 = `count3'") rows(1) ) ylabel(#3) ///
 		addplot( rarea se_ub_ma se_lb_ma reg_ret_duration, below )
		graph export "$folder/Results/ConsumptionPostRetirement_by_SpouseDef/Smoothed/spouse_def_`spouse_def'.pdf", as(pdf) replace

		* Unsmoothed version
		*Dropp this part
		
				gen se_ub = reg_coef + reg_se
				gen se_lb = reg_coef - reg_se

				xtline reg_coef, name("Fig2", replace)  ytitle(, margin(0 2 0 0)) ///
				byopts(title("Nondurable Expenditure by Tertile (Spouse Def = `spouse_def')") note("# Households in Tertile 1 = `count1'; Households in Tertile 2 = `count2'; Households in Tertile 3 = `count3'") rows(1) ) ylabel(#3) ///
				addplot( rarea se_ub se_lb reg_ret_duration, below)
				graph export "$folder/Results/ConsumptionPostRetirement_by_SpouseDef/UnSmoothed/spouse_def_`spouse_def'.pdf", as(pdf) replace
		
	 restore
}


