	set more off
	graph close
	*set autotabgraphs on
	*set trace on

	* global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"
	* global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
	global folder "/Users/bibekbasnet/Documents/GitHub/RetirementConsumptionPSID"
	global folder_output "$folder/Results/Regression_Table"

	cap mkdir "$folder_output"
	cap ssc install outreg2

	local expenditure_cats_all total_foodexp_home_real total_foodexp_away_real total_housing_real ///
		total_education_real total_transport_real total_recreation_2005_real total_clothing_2005_real total_healthexpense_real

	 forvalues spouse_def = 1/3 {
		 	
		 *	foreach var in `expenditure_cats_all' {
		 	* local var total_foodexp_home_real

		 	 //LOAD AND PREPARE DATA
			 use "$folder/Data/Intermediate/Basic-Panel.dta", clear
			
			// local spouse_def 1
		// display "Spouse def = `spouse_def'"

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
		/*total_healthexpense_real total_education_real */ total_transport_real 
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

		gen dummy_children = .
		replace dummy_children = 0 if children == 0
		replace dummy_children = 1 if children == 1
		replace dummy_children = 2 if children == 2
		replace dummy_children = 3 if children >= 3

		by pid, sort: egen do_they_ever_retire = max(retired)


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

		* local lab: variable label `var'

	 	****************************************************************************************
		* SECTION 1: 
		* Part A: Creates 3 regression tables for 3 definations of total non durable consuptions
		*	Defination 1: expendtiure_categories_1 - All six non durable categories
		*	Defination 2: expendtiure_categories_2 - Non durable categories without health expenses
		*	Defination 3: expendtiure_categories_3 - Non durable categories without health and education expenses

		* Part B: By changing the spouse defination, we can create 3 more regression tables
		****************************************************************************************
			

		local expenditure_categories_1 total_foodexp_home_real total_foodexp_away_real total_housing_real ///
		total_healthexpense_real total_education_real total_transport_real 

		local expenditure_categories_2 total_foodexp_home_real total_foodexp_away_real total_housing_real ///
		total_education_real total_transport_real 

		local expenditure_categories_3 total_foodexp_home_real total_foodexp_away_real total_housing_real ///
		total_transport_real 

			egen nond_expenditure_categories_1 = rowtotal( `expenditure_categories_1' )
			label variable nond_expenditure_categories_1 "Real Nondurable Expenditure"

			egen nond_expenditure_categories_2 = rowtotal( `expenditure_categories_2' )
			label variable nond_expenditure_categories_2 "Real Nondurable Expenditure less Health"

			egen nond_expenditure_categories_3 = rowtotal( `expenditure_categories_3' )
			label variable nond_expenditure_categories_3 "Real Nondurable Expenditure less Health & Education"

	local expenditure_categories_all nond_expenditure_categories_1 nond_expenditure_categories_2 nond_expenditure_categories_3

	* by pid, sort: egen do_they_ever_retire = max(retired)
	* edit pid wave retired do_they_ever_retire if do_they_ever_retire == 1 & pid == 11003

	foreach var in `expenditure_categories_all' {
		
		qui reg `var' i.retired
		outreg2 using "$folder_output/Def_`spouse_def'/test_`var'.tex", ctitle("OLS") tex(frag) replace addtext(HH FE, No, Age Dummies, No, Dummy Children, No, Time, No) keep(i.retired) nocons // keep() addtext() ///

		qui xtreg `var' i.retired, fe
		outreg2 using "$folder_output/Def_`spouse_def'/test_`var'.tex", ctitle("test 2") tex(frag) addtext(HH FE, Yes, Age Dummies, No, Dummy Children, No, Time, No) keep(i.retired) nocons

		qui xtreg `var' i.age i.retired, fe
		outreg2 using "$folder_output/Def_`spouse_def'/test_`var'.tex", ctitle("test 3") tex(frag) addtext(HH FE, Yes, Age Dummies, Yes, Dummy Children, No, Time, No) keep(i.retired) nocons

		qui xtreg `var' i.age i.retired i.dummy_children, fe
		outreg2 using "$folder_output/Def_`spouse_def'/test_`var'.tex", ctitle("test 4") tex(frag) addtext(HH FE, Yes, Age Dummies, Yes, Dummy Children, Yes, Time, No) keep(i.retired) nocons

		qui xtreg `var' i.age i.retired i.dummy_children d_year*, fe
		outreg2 using "$folder_output/Def_`spouse_def'/test_`var'.tex", ctitle("test 5") tex(frag) addtext(HH FE, Yes, Age Dummies, Yes, Dummy Children, Yes, Time, Yes)  keep(i.retired) nocons

	* edit pid wave retired do_they_ever_retire if do_they_ever_retire == 1 & pid == 11003

		local conditions "if do_they_ever_retire == 1"

		qui reg `var' i.retired `conditions'
		outreg2 using "$folder_output/Def_`spouse_def'/test_`var'.tex", ctitle("test 6") tex(frag) addtext(HH FE, No, Age Dummies, No, Dummy Children, No, Time, No) keep(i.retired) nocons // keep() addtext() ///

		qui xtreg `var' i.retired `conditions', fe
		outreg2 using "$folder_output/Def_`spouse_def'/test_`var'.tex", ctitle("test 7") tex(frag) addtext(HH FE, Yes, Age Dummies, No, Dummy Children, No, Time, No) keep(i.retired) nocons

		qui xtreg `var' i.age i.retired `conditions', fe
		outreg2 using "$folder_output/Def_`spouse_def'/test_`var'.tex", ctitle("test 8") tex(frag) addtext(HH FE, Yes, Age Dummies, Yes, Dummy Children, No, Time, No) keep(i.retired) nocons

		qui xtreg `var' i.age i.retired i.dummy_children `conditions', fe
		outreg2 using "$folder_output/Def_`spouse_def'/test_`var'.tex", ctitle("test 9") tex(frag) addtext(HH FE, Yes, Age Dummies, Yes, Dummy Children, Yes, Time, No) keep(i.retired) nocons

		qui xtreg `var' i.age i.retired i.dummy_children d_year* `conditions', fe
		outreg2 using "$folder_output/Def_`spouse_def'/test_`var'.tex", ctitle("test 10") tex(frag) addtext(HH FE, Yes, Age Dummies, Yes, Dummy Children, Yes, Time, Yes)  keep(i.retired) nocons


}
	
*/
/*
	****************************************************************************************
	* SECTION 2: 
	* Part A: Creates 8 regression tables for 8 different conpumption category based on a defination of spouse retirement
	* Part B: By changing the spouse defination and keeping this part same, we can create 8 more regression tables
	****************************************************************************************

		if "`var'" == "total_clothing_2005_real" | "`var'" == "total_recreation_2005_real"{
				keep if wave >= 2005

				quietly tab wave, gen(year_cat)
				foreach num of numlist 3/6 { 
					gen d_year_`num'=year_cat`num'+(1-`num')*year_cat2+(`num'-2)*year_cat1
				}		
			}
			else{ 

				quietly tab wave, gen(year_cat)
				foreach num of numlist 3/9 { 
					gen d_year_`num'=year_cat`num'+(1-`num')*year_cat2+(`num'-2)*year_cat1
				}
			 }

		qui reg `var' i.retired
		outreg2 using "$folder_output/Def_`spouse_def'/`spouse_def'_test_`var'.tex", ctitle("OLS") tex(frag) replace addtext(HH FE, No, Age Dummies, No, Dummy Children, No, Time, No) keep(i.retired) nocons // keep() addtext() ///

		qui xtreg `var' i.retired, fe
		outreg2 using "$folder_output/Def_`spouse_def'/`spouse_def'_test_`var'.tex", ctitle("test 2") tex(frag) addtext(HH FE, Yes, Age Dummies, No, Dummy Children, No, Time, No) keep(i.retired) nocons

		qui xtreg `var' i.age i.retired, fe
		outreg2 using "$folder_output/Def_`spouse_def'/`spouse_def'_test_`var'.tex", ctitle("test 3") tex(frag) addtext(HH FE, Yes, Age Dummies, Yes, Dummy Children, No, Time, No) keep(i.retired) nocons

		qui xtreg `var' i.age i.retired i.dummy_children, fe
		outreg2 using "$folder_output/Def_`spouse_def'/`spouse_def'_test_`var'.tex", ctitle("test 4") tex(frag) addtext(HH FE, Yes, Age Dummies, Yes, Dummy Children, Yes, Time, No) keep(i.retired) nocons

		qui xtreg `var' i.age i.retired i.dummy_children d_year*, fe
		outreg2 using "$folder_output/Def_`spouse_def'/`spouse_def'_test_`var'.tex", ctitle("test 5") tex(frag) addtext(HH FE, Yes, Age Dummies, Yes, Dummy Children, Yes, Time, Yes) keep(i.retired) nocons


		local conditions "if do_they_ever_retire == 1"
		
		qui reg `var' i.retired `conditions'
		outreg2 using "$folder_output/Def_`spouse_def'/`spouse_def'_test_`var'.tex", ctitle("test 6") tex(frag) addtext(HH FE, No, Age Dummies, No, Dummy Children, No, Time, No) keep(i.retired) nocons // keep() addtext() ///

		qui xtreg `var' i.retired `conditions', fe
		outreg2 using "$folder_output/Def_`spouse_def'/`spouse_def'_test_`var'.tex", ctitle("test 7") tex(frag) addtext(HH FE, Yes, Age Dummies, No, Dummy Children, No, Time, No) keep(i.retired) nocons

		qui xtreg `var' i.age i.retired `conditions', fe
		outreg2 using "$folder_output/Def_`spouse_def'/`spouse_def'_test_`var'.tex", ctitle("test 8") tex(frag) addtext(HH FE, Yes, Age Dummies, Yes, Dummy Children, No, Time, No) keep(i.retired) nocons

		qui xtreg `var' i.age i.retired i.dummy_children `conditions', fe
		outreg2 using "$folder_output/Def_`spouse_def'/`spouse_def'_test_`var'.tex", ctitle("test 9") tex(frag) addtext(HH FE, Yes, Age Dummies, Yes, Dummy Children, Yes, Time, No) keep(i.retired) nocons

		qui xtreg `var' i.age i.retired i.dummy_children d_year* `conditions', fe
		outreg2 using "$folder_output/Def_`spouse_def'/`spouse_def'_test_`var'.tex", ctitle("test 10") tex(frag) addtext(HH FE, Yes, Age Dummies, Yes, Dummy Children, Yes, Time, Yes)  keep(i.retired) nocons

	}
	*/
}
