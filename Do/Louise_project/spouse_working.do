clear all
set more off

*global folder "C:\Users\Person\Documents\GitHub\RetirementConsumptionPSID"
*Setting folder "C: "

global folder "/Users/bibekbasnet/Documents/GitHub/RetirementConsumptionPSID"

use "$folder/Data/Intermediate/Basic-Panel_Louise.dta", clear

global retirement_definition 0   // 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                 // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)
global allow_kids_to_leave_hh 1  // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                 // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)

global how_to_deal_with_spouse 1 // 1 Ignore the spouse () 2 Spouse never works  3.(spouse always works) 4 (spouse has same ret transition +/- 1 wave) 4. Spouse has a different transition
                        
global retirement_definition_spouse 1 //// 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                       // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)             
                    
* Sample selection: households with same husband-wife over time
do "$folder/Do/Sample-Selection.do"

* Look for retirement transitions of the head
do "$folder/Do/Find-Retirements.do"

****************************************************************************************************
** 1) Look at income based on time since retirement
** Here time since retirement is based on my generated retirement year
****************************************************************************************************
//keep if emp_status_spouse == 1 | emp_status_spouse_2 == 1 | emp_status_spouse_3 == 1


// >= 16 and no uppe limit
// lower working age
// number of women who are working from 1999 to 2015. Same people. 
// children and their age
// information about parents not so important
// household income
// sample size of the women who are working
// Start in 1994 and not in 1999
// wave 
// 



preserve

keep if wave <= 2015
//keep if married == 1
keep if sex_head == 2 // in a married couple in the PSID, the male was always the head
keep if emp_status_spouse == 1 | emp_status_spouse_2 == 1 | emp_status_spouse_3 == 1
keep if age >= 30 & age <= 65
//keep if pid <= 3000 * 1000 + 999 // drop the SEO sample, immigrant sample, and latino sample

tab emp_status_spouse if emp_status_spouse == 1
//After the restrictions: 24,380  this is total number of spouse who report working after 1999
//total observations: 69,900

tab emp_status_spouse if emp_status_spouse == 1 & wave == 1999
// 2,540  this is the total number of women who report that they are working in 1999

table wave emp_status_spouse if emp_status_spouse == 1
//note: We are using a very strict defination of employment_status of women. If the number of observations is low, 
// we can use a different defination. We are using self reported status of working. This does not include part time work. 
// We can probably people who work part time if we need higher sample size. 
// count if rep78 > 4 & weight < 3000

table wave emp_status_spouse if emp_status_spouse = 1 

//by emp_status_spouse: egen timesInc=total(emp_status_spouse = 1)

table emp_status_spouse if emp_status_spouse & wave == 1999
table emp_status_spouse if emp_status_spouse & wave == 2015



restore


//number of hours worked in a year inlude this
// 


/*
1 "Working now"
2 "Temp laid off; sick or maternity leave" // Only temporarily laid off, sick leave or maternity leave
3 "Looking for work, unemployed"
4 "Retired"
5 "Disabled" // Permanently disabled; temporarily disabled
6 "Keeping house"
7 "Student"
8 "Other" // Other; workfare; in prison or jail
99 "DK; NA; refused"
0 "NA"; // Inap. No spouse. Or no 2nd or 3rd mention

/*
preserve
    * Generate my best guess of the year that they retired (assuming some retirement_transition variable as baseline)
    * Guess is based on whether they have been out of the labor force for more than 12 months
    * WARNING: months_out_lab_force does not exist in 1999 and 2001
    gen generated_ret_year_               = wave if (month + months_out_lab_force <= 12) & retirement_transition == 1
    replace generated_ret_year_           = wave - 1 if (month + months_out_lab_force > 12) & retirement_transition == 1
    by pid, sort: egen generated_ret_year = max(generated_ret_year_)
    
    gen dif2 = generated_ret_year_ - ret_year if retirement_transition == 1 
    tab dif2

    * Generate time since retirement 
    gen ret_duration = wave - generated_ret_year
    
    collapse inc_*, by(ret_duration)
    
    tsset ret_
    label var ret_duration "Duration of Head's Retirement (ret year = first retired wave - months out)"
  //  tsline `inc_measures', title("Income based on time since head's retirement") name("income_by_ret_duration_SP$how_to_deal_with_spouse", replace) ylabel(#3)
restore

****************************************************************************************************
** 2) Look at income based on time since retirement
** Here retirement year is defined as self reported retirement year
****************************************************************************************************

preserve

    gen generated_ret_year_               = wave if retirement_transition == 1
    by pid, sort: egen generated_ret_year = max(generated_ret_year_)

    * Generate time since retirement 
    gen ret_duration = wave - generated_ret_year
    
    collapse inc_*, by(ret_duration)
    
    tsset ret_
    label var ret_duration "Duration of Head's Retirement (ret year = first retired wave)"
    tsline `inc_measures', title("Income based on time since head's retirement") name("income_by_ret_duration_2_SP$how_to_deal_with_spouse", replace) ylabel(#3)
   // graph export "$folder/Results/IncomeAroundRetirement/Income_with_spouse_definition_$how_to_deal_with_spouse.pdf", as(pdf) replace

restore

****************************************************************************************************
** 3) Look at income based on time since retirement
** Here retirement year is defined as the first survey wave where they say they are retired
** (though I exclude cases where the self reported ret_year is far from the observed transition)
****************************************************************************************************

preserve
    gen generated_ret_year_               = ret_year if retirement_transition == 1 & (wave - ret_year) <= 3
    by pid, sort: egen generated_ret_year = max(generated_ret_year_)

    * Generate time since retirement 
    gen ret_duration = wave - generated_ret_year
    
    collapse inc_*, by(ret_duration)
    
    tsset ret_
    label var ret_duration "Duration of Head's Retirement (ret year as self reported)"
    tsline `inc_measures', title("Income based on time since head's retirement") name("income_by_ret_duration_3_SP$how_to_deal_with_spouse", replace) ylabel(#3)
restore

