set more off
// global folder "C:\Users\pedm\Documents\Research\Cormac\RetirementConsumptionPSID"
*global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"
*global folder "C:\Users\Person\Documents\GitHub\RetirementConsumptionPSID"
global folder "/Users/bibekbasnet/Documents/GitHub/RetirementConsumptionPSID"

use "$folder/Data/Intermediate/Basic-Panel.dta", clear

global retirement_definition 0   // 0 is default (last job ended due to "Quit, Resigned, Retire" or "NA")
                                 // 1 is loose (does not ask why last job ended) and 2 is strict (last job ended due to "Quit, Resigned, Retire" only)
global allow_kids_to_leave_hh 1  // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH 
                                 // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)

global how_to_deal_with_spouse 8 // 1 Ignore the spouse () 2 Spouse never works  3.(spouse always works) 4 (spouse has same ret transition +/- 1 wave) 4. Spouse has a different transition
						
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

local inc_measures inc_fam inc_head inc_spouse inc_transfer inc_ss_fam

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
	tsline `inc_measures', title("Income based on time since head's retirement") name("income_by_ret_duration_SP$how_to_deal_with_spouse", replace) ylabel(#3)
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
	tsline `inc_measures', title("Income based on time since head's retirement") name("income_by_ret_duration_2_SP$how_to_deal_with_spouse", replace) ylabel(#3) ///
	legend(label(1 "Total Income")) legend(label(2 "Earnings of Head")) legend(label(3 "Earnings of Spouse")) legend(label(4 "No SS Transfer")) legend(label(5 "Family SS")) 
	graph export "$folder/Results/IncomeAroundRetirement/Income_with_spouse_definition_$how_to_deal_with_spouse.pdf", as(pdf) replace

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

****************************************************************************************************
* Check about the zero social security. I would hope there are very few 
* households with zero Social Security who have reached age 65?
****************************************************************************************************

/*
gen pos_inc_ss_head = inc_ss_head > 0 & inc_ss_head != .
gen pos_inc_ss_fam = inc_ss_fam > 0 & inc_ss_fam != .

keep if wave >= 2005 // in 2005 they started recording inc_ss_head
collapse *inc_ss* (count) c = inc_ss_head, by(age)
tsset age

lab var pos_inc_ss_head "% with positive inc_ss_head"
lab var pos_inc_ss_fam  "% with positive inc_ss_fam"

tsline inc_ss_head inc_ss_fam, name("inc_ss", replace)
tsline pos_inc_ss*, name("pos_inc_ss", replace)

* At age 62, 29.4% of heads have positive SS income
* At age 65, 60.7% of heads have positive SS income
* At age 70, 94.3% of heads have positive SS income
/*
Next Step as of:
Wednesday, May 30, 2018

1. Spouse retired before the head of household and after the head of the household
	DONE. Added in the defination.
 	Def-6 - Spouse retires after the head
 	Def 7 - Spouse retires before the head
 	Def 8 - Retirement of the head when the head is single

2. Drop the unsmoothed from section 8
	DONE

3. put the def 5 in the first
 	DONE. Now the category starts with 1 - Ignoring the Spouse.

4. Age Period  - multicollinearity problem. 
	DONE. Added this in both section 9 and 10. Section 9 is mean expenditure of total non durables. 
	Section 10 is - mean expenditure on each categorical variable 

7. Do the coefficients add up? For the categories to total imputed categories? 
	Added this in the section 8. We have checked the sum for defination of spouse retirement for the first three category only. 

8. Add clothing and recreation?
	Added clothing and recreation in section 10. 

QUESTIONS to THINK:
1. Retirement defination should we change. 
		When spouse retires after the head, we have very small number of observations. (4, 6, 4)


Next Step as of:
2. Friday, June 01, 2018
 
1. Demand model for 0 working, one working, 2 working

2. Life cycle modeling
		Ask Patrick to send me the information about this. 
		Every household. One in four type. 

 - High and low men and women income. 
 - We keep five groups. 
 	Every household has two different entries. 
 	- for household A:
 	 - enter in the dataset twice, consumption data same, labor supply data will be different.

 - Who are the head of household? Are they all male or female?
 - What if they are not couple? 
 		- which group of definition are they included in? 
 - Singles add a new definition on the spouse group


 Income for different definition of spouse retirement
 		This is section 7. We already have income graphs based on five definations of spouse retirement. 
 		Need to add three more in Section 3. 

 - In page 8, relabel work related expenditure graph. 

*/
Meeting June 01, 2018, Friday
- Error bands (-15, 15) in retirrement x axis
- Done. But the x-axis changes to -15 to 25. Ask Patrick about it.

subtract health expenditure from non durable 
 	add in controls for number for kids
 	dummy for one, dummy for two, dummy for three or more
 
 June 06

 1. Side by side for expenditure with health and non health in total non durables
 	-Done
 		- side by side: one subtracting health  and one subtracting both health and education
 		 4. Keep all the conditions
2. Drawing regression table for different combinations of categories and nondurable consumptions


1. Using post 2005 data. including both recreating and clothing
	Doing. Will do in a separate tex file for convinience

2. Defination 8 - look at the outlier for driving the mean up
	Need to check this later. 

3. Interact i.retired with three different social security tertiles
	Did this for a single defination. Question about interaction presentation. 


4. Do the post 2005 data in subfigures - 3 figures a page
	Same as one. Will include clothing/ recreation and housing in all of these cases. 

Jan - 7
1. Category by category
2. Post 2005 graphs/ including clothing and recreation/ goes down by a lot unlike other two graphs in section 9. 
- Potential causes:
	-is it caused by the recession?
	-looks like the time fixed effects are not picking up the full effect of the recession
	-could use the full sample (including those who do not retire) to better estimate those time fixed effects?
	-does deaton paxon break down when the length of the sample gets too short? for instance, if we only had 2 periods, deaton paxon normalization would not work
	-if so, any way we could use the longer sample while also incorporating in recreation/trips/clothing? either as imputed consumption. or time fixed effects controlling for the increase in 2005?



.3 Check the oulier in defination 8, when the head is single using histograms. 


4. Make a table how the sample size reduces as we apply constraints
	- to track how how the numbers decrease

5. 
1. 

gen drop_bc_age = 1 or 0
gen keep_bc_retiring = 1 or 0

count
local c1 = r(N)
drop if drop_bc_age == 1
count
local c2 = r(N)
keep if keep_bc_retiring == 1
count
local c3 = r(N)


JUNE 08, 2018
1. OVERLAY
	Due to regression framework, difficult to combine so far as we use two different data sets. 
	Will Chat with Patrick tomorrow morning. 

2. DROP THE TIME COEFFICIENT
	I did in one of the regressions. Not much change.

3. DO a version without Deaton Paxson
	Did it. BAsically it is same as removing the time variable. 
(assuming time shocks are same on average across different age group)

6. For headline -IGNORING THE SPOUSE
	1. Just look at only OLS
	2. One FE
	3. no time
	4. no age
	5. no children dummy

Just for one category and see how it changes. 

Overall new and old categories

- New Time period/ post 2005
- Overall two graphs old categories new 
- old graphs new categories. 

TASKS I COMPLETED:

REGRESSION TABLE: temporary file_working file_name
1. Complete regression (3 non durable categories + 8 individual categories with fixed effect)

2. Do the table for defination 1 with different variations:
	1. Table with OLS, FE, no FE in all other interactions

3. Made tables with different combinations based on Spouse defination 1
  1. All waves- six categories
  2. Post 2005 - Six categories
  3. Post 2005 - 8 categories
  4. Post 2005 - 8/ no clothing/ no recreation

People who retire during the recession - draw another overlay graph

age cohort graph - different lines
 keep people who retired during the recession
 who retired after the recession
 Line 237 in Exp_by_souse_behaviour- follow up

 1. Xtline overlay options:/this produces three different graphs and combine
 2. Graph combine - multiple subplots
 3. Graph twoway - multiple lines

Potential tests to see what are the variables: 
1. 

TASK: WEDNESDAY
1. N TEH regression table, remove column 1 to 5. Only keep it for the retired households


2. In the expenditure/income, we want to include expenditure fall or growth as a proportion rather than numbers. 
AS a result we see higher proportion increase or decrease for people in first quartule as they have lower income. 


3. Different version for graph comparisions. No controls at all. Both pre and post 2005




