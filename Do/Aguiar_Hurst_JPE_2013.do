set more off
graph close
set autotabgraphs on

global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
use "$folder\Data\Intermediate\Basic-Panel.dta", clear

* Switches							 
global cohort_graphs 0           // plot graphs by age and cohort (1) or by age controlling for cohort and year (0) 

* Generate aggregate consumption (following Blundell et al)
qui do "$folder\Do\Consumption-Measures.do"

****************************************************************************************************
** Aguiar and Hurst prep
****************************************************************************************************

cap ssc install regsave

keep if age >= 25 & age <= 75

* Aguiar and Hurst:
* We also restrict the sample to households that record a nonzero annual 
* expenditure on six key sub-omponents of the consumption basket: food, 
* entertainment, transportation, clothing and personal care, utilities, and housing/rent.

* In the PSID, they impute missing values
* TODO: find the values thare are imputed
egen missings = rowmiss(foodexpenditure transportationexp utilityexpenditure rent_imputed)
tab missings

* Follow Aguiar and Hurst: bottom-code the expenditure data at $1 and then take logs (for smaller consumption categories)
qui replace childcareexpenditure = 1 if childcareexpenditure < 1
qui replace clothingexpenditure = 1 if clothingexpenditure < 1
qui replace tripsexpenditure = 1 if tripsexpenditure < 1
qui replace recreationexpenditure = 1 if recreationexpenditure < 1

* Convert to logs
local collapse_vars 
foreach var of varlist expenditure_hurst expenditure_hurst_nonH ///
	foodathomeexpenditure workexpenditure nonwork_nondur_expenditure ///
	clothingexpenditure workexpenditure_post05 utilityexpenditure ///
	housingservicesexpenditure childcareexpenditure ///
	tripsexpenditure recreationexpenditure ///
	transportationexpenditure foodawayfromhomeexpenditure {
	
	qui gen log_`var' = log(`var')
	local collapse_vars `collapse_vars' log_`var'
}

xtset pid wave, delta(2)

****************************************************************************************************
** Create cohorts and collapse
****************************************************************************************************
if $cohort_graphs == 1{

egen cohort = cut(year_born), at( 1940(10)1990 ) icodes label
tab cohort, missing
drop if cohort == .

// Panel A plots mean log expenditure
// by age conditional on cohort, normalized year, and family status controls. Each point
// represents the coefficient on the corresponding age dummy from the estimation of equation 4, 
// with age 25 being the omitted group.

collapse  `collapse_vars' (count) c = log_expenditure_hurst (count) c_2005 = workexpenditure ///
		 [pweight = family_weight], by(age cohort)
		 
keep if c >= 5000
xtset cohort age

****************************************************************************************************
** Figure 1a - by cohorts
****************************************************************************************************

xtline  log_expenditure_hurst, overlay name("Fig1a", replace) ///
		title("Fig 1a. Life cycle profiles of nondurable expenditures") 
		
xtline  log_expenditure_hurst_nonH, overlay name("Fig1a_exH", replace) ///
		title("Fig 1a. Life cycle profiles of nondurable expenditures") subtitle("Excluding housing") 

****************************************************************************************************
** Figure 2a - by cohorts
****************************************************************************************************

// The categories are food at home;
// work-related expenses which include transportation, food away from home, and clothing/personal care;
// and core nondurables which include all other categories of total nondurable
// expenditure, including housing services but excluding alcohol and tobacco.

xtline  log_foodathomeexpenditure, overlay name("Fig2a_food", replace) ///
		title("Fig 2a. Food at Home Expenditure") 

xtline  log_workexpenditure /* if c_2005 >= 5000 */, overlay name("Fig2a_work", replace) ///
		title("Fig 2a. Work Related Expenditure") 
		
xtline  log_nonwork_nondur_expenditure, overlay name("Fig2a_nonwork", replace) ///
		title("Fig 2a. Non Work Non Durable Expenditure") 

xtline  log_clothingexpenditure, overlay name("Fig2a_clothing", replace) ///
		title("Fig 2a. Clothing Expenditure") 
}
****************************************************************************************************
** Aguiar and Hurst Version: Life cycle conditional on cohort and normalized years
****************************************************************************************************
else{

* Aguiar Hurst restrict cohorts to those that have at least 10 years in the sample
* Aka age 65 in 1980 (birth year >= 1915) and age 35 in 2003 (birth year <= 1968)
* Should I also trim off the tails? 
* Aka age 65 in 1999 (birth year >= 1934) and age 35 in 2015 (birth year <= 1980)
keep if year_born >= 1934 & year_born <= 1980

* Create year dummies, where year dummies are normalized so that Ed_year=0 and Cov(d_year,trend)=0
quietly tab wave, gen(year_cat)
foreach num of numlist 3/9 {
	gen d_year_`num'=year_cat`num'+(1-`num')*year_cat2+(`num'-2)*year_cat1
}

gen married_dummy = married == 1 // just look at married or not (rather than divorced, never married, widowed, separated, etc)
local family_controls i.married_dummy i.fsize i.children i.children0_2 i.children3_5 i.children6_13 i.children14_17m i.children14_17f i.children18_21m i.children18_21f 
local reg_controls i.age i.year_born d_year* `family_controls' 

* Question: is it right to use family weights rather than cross sectional? [pweight = family_weight]

* Small technicality:
* numchild in AH includes all children, whereas I just include those under 17 in the children variable

* TODO: weights
* TODO: add fixed effects?

// quietly reg ln_nondurable  hhsize_cat* numchild_cat* child12_cat* child35_cat* child613_cat* 
// child1417m_cat* child1417f_cat* child1821m_cat* child1821f_cat* [aw=adjwt];

****************************************************************************************************
** Figure 1a - Nondurables w and w/out housing
****************************************************************************************************

tempfile results

reg log_expenditure_hurst `reg_controls'
regsave using `results', addlabel(lab, "Nondurables") replace

qui reg log_expenditure_hurst_nonH `reg_controls' 
regsave using `results', addlabel(lab, "Nondurables w/out Housing") append

preserve
* Find coefs by age
use `results', clear
gen is_age = strpos(var, "age")
keep if is_age > 0
drop is_age
destring var, replace ignore("b.age")
rename var age

* Plot results
encode lab, gen(labels)
xtset labels age
lab var age "Age"
lab var coef "Log Expenditure Relative to Age 25"
xtline coef, overlay name("Fig1", replace) note("Nondurables in PSID include food, gasoline, utilities, transportation services, and child care." "It does not include other components used in Aguiar Hurst, such as tobacco, clothing,""personal care, domestic services, airfare, nondurable entertainment, gambling, business" "services, and chartiable giving") title("Life Cycle Consumption") ytitle(, margin(0 2 0 0))
restore

****************************************************************************************************
** Figure 2a - Work vs Non Work
****************************************************************************************************

preserve

tempfile results
reg log_foodathomeexpenditure `reg_controls'
regsave using `results', addlabel(lab, "Food at Home") replace

* NOTE: workexpenditure_post05 looks closer to A-H, but only starts in 2005
qui reg log_workexpenditure `reg_controls'
regsave using `results', addlabel(lab, "Work Related") append

qui reg log_nonwork_nondur_expenditure `reg_controls'
regsave using `results', addlabel(lab, "Non Work Related") append

// keep if wave >= 2005
// keep if year_born >= 1940 // aka maximum of age 65 in 2005
// reg clothingexpenditure `reg_controls'
// regsave using `results', addlabel(lab, "Clothing") append
//// TODO: will need normalized year controls that are normalized starting in 2005

* Find coefs by age
use `results', clear
gen is_age = strpos(var, "age")
keep if is_age > 0
drop is_age
destring var, replace ignore("b.age")
rename var age

* Plot results
encode lab, gen(labels)
xtset labels age
lab var age "Age"
lab var coef "Log Expenditure Relative to Age 25"
xtline coef, overlay name("Fig2", replace) title("Life Cycle Consumption: Work vs Non Work") ytitle(, margin(0 2 0 0))
restore

****************************************************************************************************
** Figure 3a - Smaller categories starting in 1999
** They use entertainemnt, utilities, housing services, other ND, domestic services
****************************************************************************************************

preserve
tempfile results
qui reg log_utilityexpenditure `reg_controls'
regsave using `results', addlabel(lab, "Utilities") replace

qui reg log_housingservicesexpenditure `reg_controls' // includes rent, imputed rent (for owners), prop tax, and home insurance 
regsave using `results', addlabel(lab, "Housing Services") append

qui reg log_childcareexpenditure `reg_controls'
regsave using `results', addlabel(lab, "Child Care Expenditure") append

* Find coefs by age
use `results', clear
gen is_age = strpos(var, "age")
keep if is_age > 0
drop is_age
destring var, replace ignore("b.age")
rename var age

* Plot results
encode lab, gen(labels)
xtset labels age
lab var age "Age"
lab var coef "Log Expenditure Relative to Age 25"
xtline coef, overlay name("Fig3a", replace) title("Life Cycle Consumption: Increasing Components") ytitle(, margin(0 2 0 0))
restore

****************************************************************************************************
** Figure 3b - Smaller categories starting in 1999
** Transportation, food at home, food away from home
****************************************************************************************************

preserve
tempfile results
qui reg log_transportationexpenditure `reg_controls'
regsave using `results', addlabel(lab, "Transportation") replace

qui reg log_foodathomeexpenditure `reg_controls' 
regsave using `results', addlabel(lab, "Food at home") append

qui reg log_foodawayfromhomeexpenditure `reg_controls'
regsave using `results', addlabel(lab, "Food away from home") append

* Find coefs by age
use `results', clear
gen is_age = strpos(var, "age")
keep if is_age > 0
drop is_age
destring var, replace ignore("b.age")
rename var age

* Plot results
encode lab, gen(labels)
xtset labels age
lab var age "Age"
lab var coef "Log Expenditure Relative to Age 25"
xtline coef, overlay name("Fig3b", replace)  title("Life Cycle Consumption: Decreasing Components") ytitle(, margin(0 2 0 0))
restore

****************************************************************************************************
** Fig 3 extension - Post 2005 Expenditure Categories
****************************************************************************************************

preserve

* Select smaller sample
keep if wave >= 2005
// keep if year_born >= 1940 // aka maximum of age 65 in 2005

* New year dummies, starting in 2005
* where year dummies are normalized so that Ed_year=0 and Cov(d_year,trend)=0
drop year_cat* d_year_*
quietly tab wave, gen(year_cat)
foreach num of numlist 3/6 {
	gen d_year_`num'=year_cat`num'+(1-`num')*year_cat2+(`num'-2)*year_cat1
}

tempfile results
qui reg log_workexpenditure_post05 `reg_controls'
regsave using `results', addlabel(lab, "Work Related (incl clothing)") replace

qui reg log_clothingexpenditure `reg_controls' // includes rent, imputed rent (for owners), prop tax, and home insurance 
regsave using `results', addlabel(lab, "Clothing") append

qui reg log_tripsexpenditure `reg_controls'
regsave using `results', addlabel(lab, "Trips") append

qui reg log_recreationexpenditure `reg_controls'
regsave using `results', addlabel(lab, "Recreation") append

* Find coefs by age
use `results', clear
gen is_age = strpos(var, "age")
keep if is_age > 0
drop is_age
destring var, replace ignore("b.age")
rename var age

* Plot results
encode lab, gen(labels)
xtset labels age
lab var age "Age"
lab var coef "Log Expenditure Relative to Age 25"
xtline coef, overlay name("Fig3_alt", replace)  title("Life Cycle Consumption: New PSID Measures") ytitle(, margin(0 2 0 0))
restore

****************************************************************************************************
** Fig 3b extension - Post 2005 Expenditure Categories
****************************************************************************************************

preserve

* Select smaller sample
keep if wave >= 2005
// keep if year_born >= 1940 // aka maximum of age 65 in 2005

* New year dummies, starting in 2005
* where year dummies are normalized so that Ed_year=0 and Cov(d_year,trend)=0
drop year_cat* d_year_*
quietly tab wave, gen(year_cat)
foreach num of numlist 3/6 {
	gen d_year_`num'=year_cat`num'+(1-`num')*year_cat2+(`num'-2)*year_cat1
}


tempfile results
qui reg log_workexpenditure_post05 `reg_controls'
regsave using `results', addlabel(lab, "Work Related (incl clothing)") replace

qui reg log_clothingexpenditure `reg_controls' // includes rent, imputed rent (for owners), prop tax, and home insurance 
regsave using `results', addlabel(lab, "Clothing") append

qui reg log_tripsexpenditure `reg_controls'
regsave using `results', addlabel(lab, "Trips") append

qui reg log_recreationexpenditure `reg_controls'
regsave using `results', addlabel(lab, "Recreation") append

* Find coefs by age
use `results', clear
gen is_age = strpos(var, "age")
keep if is_age > 0
drop is_age
destring var, replace ignore("b.age")
rename var age

* Plot results
encode lab, gen(labels)
xtset labels age
lab var age "Age"
lab var coef "Log Expenditure Relative to Age 25"
xtline coef, overlay name("Fig3_alt2005", replace) title("Life Cycle Consumption: New PSID Measures") ytitle(, margin(0 2 0 0))
restore

}
