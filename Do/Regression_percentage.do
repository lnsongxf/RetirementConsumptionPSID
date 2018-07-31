
    set more off
    graph close

    * global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"
    * global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
    global folder "/Users/bibekbasnet/Documents/GitHub/RetirementConsumptionPSID"
    // global folder_output "$folder/Results/Regression_Table"

        cap mkdir "$folder_output"
        cap ssc install outreg2

        local expenditure_cats_all total_foodexp_home_real total_foodexp_away_real total_housing_real ///
            total_education_real total_transport_real total_recreation_2005_real total_clothing_2005_real total_healthexpense_real

     // forvalues spouse_def = 1/1 {   

    use "$folder/Data/Intermediate/Basic-Panel.dta", clear

    * Switches
    global quintiles_definition 2    // Defines quintiles. Can be 1, 2, 3, or 4. My preference is 4. I think the next best option is 2
                                     // Note: if you want tertiles, must use definition 2
    global retirement_definition 0   // 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                     // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)
    global ret_duration_definition 2 // Defines retirement year. Can be 1, 2, or 3. My preference is 3 (for the sharp income drop) although 2 is perhaps better when looking at consumption data (for smoothness)
    global graphs_by_mean 0          // Graph by quintile. Can be 0 or 1
    global graphs_by_quintile 0      // Graph by quintile. Can be 0 or 1
    global graphs_by_tertile 1       // Tertiles
    global make_barplots 1
    global allow_kids_to_leave_hh 1  // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                     // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)
    global how_to_deal_with_spouse 1  // could be 1 2 3 4 5
    global retirement_definition_spouse 1 //// 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                           // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)             
                                     
    * Sample selection: households with same husband-wife over time
    //do "$folder/Do/Sample-Selection.do"

    * Look for retirement transitions of the head
    do "$folder/Do/Find-Retirements.do"
    * NOTE: could also define retirement based on whether you worked < 500 hours that year. Might be worth exploring

    * Generate aggregate consumption (following Blundell et al)
    do "$folder/Do/Consumption-Measures.do"

    do "$folder/Do/Scripts/Define-Quintiles.do"

    do "$folder/Do/Scripts/Define-Ret-Duration.do"

     gen year = wave - 1 // note that expenditure data is for year prior to interview
     merge m:1 year using "$folder/Data/Intermediate/CPI.dta"
     drop if _m == 2
     drop year _m

 
    // drop bend_point_1
    // drop bend_point_2

    /*
    gen inc_ss_head_65 = .
    replace inc_ss_head_66 = inc_ss_head if age == 65
    replace inc_ss_head_65 = inc_ss_head if age == 66 & inc_ss_head_65 == .
    replace inc_ss_head_65 = inc_ss_head if age == 64 & inc_ss_head_65 == .

    replace inc_ss_head_65 = inc_ss_head if age == 67 & inc_ss_head_65 == .
    replace inc_ss_head_65 = inc_ss_head if age == 68 & inc_ss_head_65 == .
    replace inc_ss_head_65 = inc_ss_head if age == 63 & inc_ss_head_65 == .
    replace inc_ss_head_65 = inc_ss_head if age == 62 & inc_ss_head_65 == .
    */

    // by pid, sort: generate inc_ss_head_65 = inc_ss_head if age == 65
   

/*Impute SS pre 2005 */

preserve 
gen ratio_ss_head = .
replace ratio_ss_head = inc_ss_head / inc_ss_fam if wave >=2005
collapse (mean) ratio_inc_ss_head = ratio_ss_head
local ratio = ratio_inc_ss_head in 1

restore

gen inc_ss_head_imputed = .
replace inc_ss_head_imputed = inc_ss_fam * `ratio' if wave < 2005
replace inc_ss_head_imputed = inc_ss_head if wave >= 2005

/*Generate nominal version of inc_ss_head */
* This is in nominal version
*If this was real, we we have something like inc_ss_head_real

/*Find the year they claimed social security - maybe a question, otherwise use when it arrives in the data*/
* The PSID does not ask when they first claim social security

gen year_ss_claims = .
replace year_ss_claims = wave if inc_ss_head != . & inc_ss_head != 0 & wave >= 2005
replace year_ss_claims = wave if inc_ss_fam != . & inc_ss_fam != 0 & wave < 2005
by pid, sort: egen year_ss_claim = min(year_ss_claims)


* social security the wave after they claim (where possible)
by pid, sort: egen last_wave = max(wave)
gen tempSS = inc_ss_head * (wave == year_ss_claim + 2) if last_wave >= year_ss_claim + 2
replace tempSS = inc_ss_head * (wave == year_ss_claim) if last_wave < year_ss_claim + 2
by pid, sort: egen referenceSS = max(tempSS)

gen tempPriceNum = CPI_all * (wave == year_ss_claim + 2)
by pid, sort: egen priceNum = max(tempPriceNum)
gen tempPriceDenom = CPI_all * (wave == year_ss_claim)
by pid, sort: egen priceDenom = max(tempPriceDenom)
gen pieTwoYearsAfterClaim = priceNum / priceDenom
gen referenceSS_InClaimYear = referenceSS/pieTwoYearsAfterClaim


**NOTE: CHECK THE MISSINGs in REFERENCESS COLUMN. 

*by pid, sort: egen inc_ss_max = max(inc_ss_head_imputed)
*Drop the people who we do not observe atleast one wave after they claim social security


//bring the social security back to the year they claim social security
// confused over this step
 // gen ss_onyear_claimed = .
 // replace ss_onyear_claimed = inc_ss_head_imputed & year_ss_claim

//keep if year_ss_claim == wave
// keep pid year_ss_claim inc_ss_head_imputed age


// bend points have to be merged for the year they claim social security
    gen year = year_ss_claim - 1 // note that expenditure data is for year prior to interview
    merge m:1 year using "$folder/Data/Raw/bead.dta"
    drop if _m == 2
    drop year _m

    destring bend_point_1, gen(bend_1)
    destring bend_point_2, gen(bend_2) ignore(",")
    replace bend_1 = bend_1 * 12
    replace bend_2 = bend_2 * 12

/*
// Then apply the bend points formuala
 gen ea_head = . 

    replace ea_head  = referenceSS_InClaimYear / 0.9 if referenceSS_InClaimYear <  bend_1*0.9

    replace ea_head  = bend_1 + (referenceSS_InClaimYear - bend_1*0.9)/0.32 if referenceSS_InClaimYear > bend_1*0.9 & referenceSS_InClaimYear < (bend_1*0.9 + (bend_2-bend_1)*0.32)

    gen ssAtbend_2 = bend_1/0.9 + (bend_2 - bend_1)*0.32
    replace ea_head  = bend_2 + (referenceSS_InClaimYear- ssAtbend_2)/0.15 if referenceSS_InClaimYear > bend_1*0.9 + (bend_2-bend_1)*0.32

    by pid, sort: egen they_ever_retire = max(retired)
    keep if they_ever_retire == 1

    drop bend_point_1
    drop bend_point_2

*/

gen ss_at_bend_1 = bend_1*0.9
    gen ss_at_bend_2 = bend_1*0.9 + (bend_2 - bend_1) * 0.32
    
    
    gen ea_head = . 

    replace ea_head  = referenceSS_InClaimYear / 0.9 if referenceSS_InClaimYear < ss_at_bend_1
    replace ea_head  = bend_1 + (referenceSS_InClaimYear - ss_at_bend_1)/0.32 if referenceSS_InClaimYear >ss_at_bend_1 & referenceSS_InClaimYear < ss_at_bend_2 
    replace ea_head  = bend_2 + (referenceSS_InClaimYear- ss_at_bend_2)/0.15 if referenceSS_InClaimYear > ss_at_bend_2 

    sort ea_head
    line referenceSS_InClaimYear ea_head if year_ss_claim == 2005
    graph export "$folder/Results/ImputedEarnings/year_ss_claim_2005.pdf", as(pdf) replace




// social security income should be monthly


// 1) first find the age they they first took the social security
// 2) discount at 7% per year


//  people who claim social security early- get it at a discount
* what is the discount rate? 



// people who claim before 65, they get at discount
// find the discount and find what it would be if they had claimed at 65


    // 1. social security income for people when they are closest to 65. 
    // 2. Most of the observations in the table do not have a social security income because they have not retired, 
    // 3. I see the social security as in 2004 dollar. Need to change that. 
    ///4. How do we use the 


    /*
    90% of the first $896
    32% of the amount greater than $896, but less than $5,399
    15% of the amount greater than $5,399
    Source: 2018 US conversation statistics
    */

            local expenditure_cats_all total_foodexp_home_real total_foodexp_away_real total_housing_real ///
            total_healthexpense_real total_education_real total_transport_real
            egen nondurable_expenditure_real = rowtotal(`expenditure_cats_all' )
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
            lab var total_education_real "Education Expenditure"
            lab var total_healthexpense_real "Health Expenditure"
            lab var total_transport_real "Non Durables Transportation Expenditure"
            lab var transport_durables "Transportation Durables Expenditure"
            lab var total_housing_2005_real "Housing Expenditure"
            lab var total_recreation_2005_real "Recreation Expenditure"
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
            *   Defination 1: expendtiure_categories_1 - All six non durable categories
            *   Defination 2: expendtiure_categories_2 - Non durable categories without health expenses
            *   Defination 3: expendtiure_categories_3 - Non durable categories without health and education expenses

            * Part B: By changing the spouse defination, we can create 3 more regression tables
            **************************************************************************************** 
            local expenditure_categories_1 total_foodexp_home_real total_foodexp_away_real total_housing_real ///
            total_healthexpense_real total_education_real total_transport_real 

            local expenditure_categories_2 total_foodexp_home_real total_foodexp_away_real total_housing_real ///
            total_education_real total_transport_real 

            local expenditure_categories_3 total_foodexp_home_real total_foodexp_away_real total_housing_real ///
            total_transport_real 
    /*
                egen nond_expenditure_categories_1 = rowtotal( `expenditure_categories_1' )
                label variable nond_expenditure_categories_1 "Real Nondurable Expenditure"
                replace nond_expenditure_categories_1 = nond_expenditure_categories_1/average_earning_head

                egen nond_expenditure_categories_2 = rowtotal( `expenditure_categories_2' )
                label variable nond_expenditure_categories_2 "Real Nondurable Expenditure less Health"
                replace nond_expenditure_categories_2 = nond_expenditure_categories_2/average_earning_head


                egen nond_expenditure_categories_3 = rowtotal( `expenditure_categories_3' )
                label variable nond_expenditure_categories_3 "Real Nondurable Expenditure less Health & Education"
                replace nond_expenditure_categories_3 = nond_expenditure_categories_3/average_earning_head
    */
        local expenditure_categories_all nond_expenditure_categories_1 nond_expenditure_categories_2 nond_expenditure_categories_3

        * by pid, sort: egen do_they_ever_retire = max(retired)
        * edit pid wave retired do_they_ever_retire if do_they_ever_retire == 1 & pid == 11003
    /*
        foreach var in `expenditure_categories_all' {
        
            qui reg `var' i.tertile i.retired#i.tertile
            outreg2 using "$folder_output/NO_FE/Defff_`spouse_def'/test_`var'.tex", ctitle("OLS") tex(frag) replace addtext(HH FE, No, Age Dummies, No, Dummy Children, No, Time, No) nocons keep(1.retired#1b.tertile 1.retired#2.tertile 1.retired#3.tertile 2.tertile 3.tertile) // keep() addtext() ///
            * esttab / estout / eststo
            * ssc install esttab

            qui xtreg `var' i.tertile i.retired#i.tertile, fe
            outreg2 using "$folder_output/NO_FE/Defff_`spouse_def'/test_`var'.tex", ctitle("test 2") tex(frag) addtext(HH FE, Yes, Age Dummies, No, Dummy Children, No, Time, No) nocons keep(1.retired#1b.tertile 1.retired#2.tertile 1.retired#3.tertile 2.tertile 3.tertile)

            qui xtreg `var' i.age i.tertile i.retired#i.tertile
            outreg2 using "$folder_output/NO_FE/Defff_`spouse_def'/test_`var'.tex", ctitle("test 3") tex(frag) addtext(HH FE, No, Age Dummies, Yes, Dummy Children, No, Time, No) nocons keep(1.retired#1b.tertile 1.retired#2.tertile 1.retired#3.tertile 2.tertile 3.tertile)

            qui xtreg `var' i.age i.tertile i.retired#i.tertile
            outreg2 using "$folder_output/NO_FE/Defff_`spouse_def'/test_`var'.tex", ctitle("test 4") tex(frag) addtext(HH FE, No, Age Dummies, Yes, Dummy Children, Yes, Time, No) nocons keep(1.retired#1b.tertile 1.retired#2.tertile 1.retired#3.tertile 2.tertile 3.tertile)

            qui xtreg `var' i.age i.tertile i.retired#i.tertile i.dummy_children d_year*
            outreg2 using "$folder_output/NO_FE/Defff_`spouse_def'/test_`var'.tex", ctitle("test 5") tex(frag) addtext(HH FE, No, Age Dummies, Yes, Dummy Children, Yes, Time, Yes) nocons keep(1.retired#1b.tertile 1.retired#2.tertile 1.retired#3.tertile 2.tertile 3.tertile)

        * edit pid wave retired do_they_ever_retire if do_they_ever_retire == 1 & pid == 11003
            local conditions "if do_they_ever_retire == 1"

            qui reg `var' i.tertile i.retired#i.tertile `conditions'
            outreg2 using "$folder_output/NO_FE/Defff_`spouse_def'/test_`var'.tex", ctitle("OLS") tex(frag) replace addtext(HH FE, No, Age Dummies, No, Dummy Children, No, Time, No) nocons keep(1.retired#1b.tertile 1.retired#2.tertile 1.retired#3.tertile 2.tertile 3.tertile)

            qui xtreg `var' i.tertile i.retired#i.tertile `conditions', fe
            outreg2 using "$folder_output/NO_FE/Defff_`spouse_def'/test_`var'.tex", ctitle("test 7") tex(frag) addtext(HH FE, Yes, Age Dummies, No, Dummy Children, No, Time, No) nocons keep(1.retired#1b.tertile 1.retired#2.tertile 1.retired#3.tertile 2.tertile 3.tertile)

            qui xtreg `var' i.age i.tertile i.retired#i.tertile `conditions'
            outreg2 using "$folder_output/NO_FE/Defff_`spouse_def'/test_`var'.tex", ctitle("test 8") tex(frag) addtext(HH FE, No, Age Dummies, Yes, Dummy Children, No, Time, No) nocons keep(1.retired#1b.tertile 1.retired#2.tertile 1.retired#3.tertile 2.tertile 3.tertile)

            qui xtreg `var' i.age i.tertile i.retired#i.tertile i.dummy_children `conditions'
            outreg2 using "$folder_output/NO_FE/Defff_`spouse_def'/test_`var'.tex", ctitle("test 9") tex(frag) addtext(HH FE, No, Age Dummies, Yes, Dummy Children, Yes, Time, No) nocons keep(1.retired#1b.tertile 1.retired#2.tertile 1.retired#3.tertile 2.tertile 3.tertile)

            qui xtreg `var' i.age i.tertile i.retired#i.tertile i.dummy_children d_year* `conditions'
            outreg2 using "$folder_output/NO_FE/Defff_`spouse_def'/test_`var'.tex", ctitle("test 10") tex(frag) addtext(HH FE, No, Age Dummies, Yes, Dummy Children, Yes, Time, Yes)  nocons  keep(1.retired#1b.tertile 1.retired#2.tertile 1.retired#3.tertile 2.tertile 3.tertile)
    */
    // }

        
