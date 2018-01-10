set more off
global folder "C:\Users\pedm\Documents\Research\Cormac\RetirementConsumptionPSID"

use "$folder\Data\Intermediate\Basic-Panel.dta", clear

****************************************************************************************************
** Aggregate expenditure measure
****************************************************************************************************

* "Consumption Inequality and Family Labor Supply"
* Blundell, Pistaferri, Saporta-Eksten paper that uses PSID consumption data from 1999 to 2009
* https://www.econstor.eu/bitstream/10419/67323/1/727547445.pdf

gen healthservicesexpenditure = healthcareexpenditure - healthinsuranceexpenditure // my best guess as to how Pistaferri et al define this variable
gen transportationexgasexpenditure = transportationexpenditure - gasolineexpenditure

gen rent_imputed = rentexpenditure 
replace rent_imputed = 0.06 * housevalue if homeowner == 1

local expenditure_list foodathomeexpenditure gasolineexpenditure foodawayfromhomeexpenditure /// 
healthinsuranceexpenditure healthservicesexpenditure utilityexpenditure ///
transportationexgasexpenditure educationexpenditure childcareexpenditure /// 
homeinsuranceexpenditure rent_imputed 

egen expenditure_blundell = rowtotal(`expenditure_list')
lab var expenditure_blundell "Total Expenditure (Blundell et al)"

****************************************************************************************************
** Replicate Figures in "Studying Consumption with the PSID"
****************************************************************************************************


* The figures plot, for each data source, expenditures for each major category
* and for overall total expenditures by the age of the family head. The three-
* age group moving average for each single year of age (e.g., 25-27 years old,
* 26-28 years old, 27-29 years old, etc.) is calculated for each year (1999,
* 2001, and 2003), and then averaged across the years. We do not control here
* for any household characteristics (e.g. gender of head, family size, etc.), so
* the profiles represent how, at a point in time, consumption differs at
* different points in the life cycle, and thus reflect changes over the
* lifecycle in household size, composition, and all other factors. Sample
* weights are used in these figures

* Question: are there suspiciously many entries with food expenditure = 0?

/*
preserve
	keep if wave <= 2003
	
	* Collapse by age and wave
	collapse *expenditure [pweight = family_weight], by(age wave)
	
	* Two sided moving average by age
	xtset wave age
	foreach var of varlist *expenditure {
		tssmooth ma `var'_ma = `var', window(1 1 1) 
	}
	
	keep if age <= 75 & age >= 23
	tsline food*ma if wave == 2001, name(food, replace) title("Food Expenditure in 2001")
	collapse *expenditure_ma, by(age)
	
	tsset age
	tsline housingexpenditure mortgageexpenditure rentexpenditure, name(housing, replace) title("Housing Expenditure")
	tsline propertytaxexpenditure homeinsuranceexpenditure utilityexpenditure, name(housing_cont, replace) title("Housing Expenditure Cont.")
restore
*/


****************************************************************************************************
** Sample Selection as in Blundell et al
****************************************************************************************************

* PSID data from 1999-2009 PSID waves. PSID means are given for the main sample of estimation: married
* couples with working males aged 30 to 65. SEO sample excluded.

keep if wave <= 2009
keep if married == 1
keep if sex_head == 1 // in a married couple in the PSID, the male was always the head
keep if emp_status_head == 1 | emp_status_head_2 == 1 | emp_status_head_3 == 1
* keep if inc_head > 0 
keep if age >= 30 & age <= 65
keep if pid <= 3000 * 1000 + 999 // drop the SEO sample, immigrant sample, and latino sample

****************************************************************************************************
** Look at componenets of consumption and services across years
** Replicate Table 1 in Blundell et al (working paper version)
****************************************************************************************************

eststo clear
forvalues yy = 1999(2)2009{
	qui eststo: mean expenditure_blundell `expenditure_list' rentexpenditure if wave == `yy'
}
esttab, nostar not label mtitles(1999 2001 2003 2005 2007 2009)

* transportation way to high
* rent too high


* mean *expenditure if wave == 2009


