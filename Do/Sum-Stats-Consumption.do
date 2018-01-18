set more off
global folder "C:\Users\pedm\Documents\Research\Cormac\RetirementConsumptionPSID"

use "$folder\Data\Intermediate\Basic-Panel.dta", clear

****************************************************************************************************
** Generate aggregate consumption (following Blundell et al)
****************************************************************************************************

do "$folder\Do\Consumption-Measures.do"
	
****************************************************************************************************
** Replicate Transportation Section of Appendix Table 4 in "Estimates of Annual Consumption Expenditures and Its Major Componenets"
****************************************************************************************************

* All components of transportation
local transportation_subcomponenets vehicleloanexpenditure vehicledpexpenditure /// 
vehicleleaseexpenditure autoinsexpenditure addvehicleexpenditure ///
vehiclerepairexpenditure gasolineexpenditure parkingexpenditure ///
bustrainexpenditure taxiexpenditure othertransexpenditure

* Make sure I know exactly what is in transportationexpenditure
* Yes -- this variable is an exact match
egen mytransportationexpenditure = rowtotal(`transportation_subcomponenets')

eststo clear
forvalues yy = 1999(2)2009{
	qui eststo: mean transportationexpenditure mytransportationexpenditure `transportation_subcomponenets' if wave == `yy'
}
esttab, nostar not label mtitles(1999 2001 2003 2005 2007 2009) ///
title("Estimates of Annual Consumption Expenditures and Its Major Componenets, Appendix Table 4 (Transportation Only)")

* Total transportation expenditure is higher in my table than theirs
* This difference comes from "Other vehicle expenditure" addvehicleexpenditure
* In my table, this is 1217 to 1301 per year.
* In their table, this is 92 to 133 per year. Approximately 1/12th the value in my data
* Perhaps they forgot to convert monthly to annual?
* I have not done anything to modify this variable. The PSID converted monthly to annual (and did an imputation) for us

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


preserve
	keep if wave <= 2003
	
	* Collapse by age and wave
	collapse *expenditure* [pweight = family_weight], by(age wave)
	
	* Two sided moving average by age
	xtset wave age
	foreach var of varlist *expenditure* {
		tssmooth ma `var'_ma = `var', window(1 1 1) 
	}
	
	keep if age <= 75 & age >= 23
	desc food*ma

	lab var foodexpenditure_ma "Total Food Expenditure"
	lab var foodathomeexpenditure_ma "Food at Home"
	lab var foodawayfromhomeexpenditure_ma "Food Away From Home"
	lab var fooddeliveredexpenditure_ma "Food Delivered"
	tsline food*ma if wave == 2001, name(food, replace) title("Food Expenditure in 2001")
	collapse *expenditure_ma expenditure_blundell*ma, by(age)
	
	tsset age

	lab var housingexpenditure "Housing Expenditure"
	lab var mortgageexpenditure "Mortgage Expenditure"
	lab var rentexpenditure "Rent Expenditure"

	lab var propertytaxexpenditure "Property Tax Expenditure"
	lab var homeinsuranceexpenditure "Home Insurance Expenditure"
	lab var utilityexpenditure "Utility Expenditure"

	lab var expenditure_blundell_ma "Blundell Expenditure"
	lab var expenditure_blundell_exhealth_ma "Blundell Expenditure (ex health)"
	lab var expenditure_blundell_exhous_ma "Blundell Expenditure (ex housing)"
	lab var expenditure_blundell_eq_ma "Blundell Expenditure"
	lab var expenditure_blundell_eq_exH_ma "Blundell Expenditure (ex housing)"

	tsline housingexpenditure mortgageexpenditure rentexpenditure, name(housing, replace) title("Housing Expenditure")
	tsline propertytaxexpenditure homeinsuranceexpenditure utilityexpenditure, name(housing_cont, replace) title("Housing Expenditure Cont.")

	tsline expenditure_blundell_ma expenditure_blundell_exhealth_ma expenditure_blundell_exhous_ma, name(blundell, replace) title("Blundell Expenditure")
	tsline expenditure_blundell_eq_ma expenditure_blundell_eq_exH_ma, name(blundell_eq, replace) title("Blundell Expenditure (Equivalence Scale)")
restore


****************************************************************************************************
** Sample Selection as in Blundell et al
****************************************************************************************************

* PSID data from 1999-2009 PSID waves. PSID means are given for the main sample of estimation: married
* couples with working males aged 30 to 65. SEO sample excluded.

* Whenever there is a change in family composition we drop
* the year of the change and treat the household unit as a new family starting with
* the observation following the change. 

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

local expenditure_blundell foodathomeexpenditure foodstamp gasolineexpenditure foodawayfromhomeexpenditure /// 
healthinsuranceexpenditure healthservicesexpenditure utilityexpenditure ///
transportation_blundell educationexpenditure childcareexpenditure /// 
homeinsuranceexpenditure rent_imputed 

eststo clear
forvalues yy = 1999(2)2009{
	qui eststo: mean expenditure_blundell expenditure_blundell_eq `expenditure_blundell' if wave == `yy'
}
esttab, nostar not label mtitles(1999 2001 2003 2005 2007 2009) title("Table 1 Blundell et al (Working Paper)")

* transportation now looks good -- we include just transportation services (following Blundell et al code)
* imputed rent now looks good -- the issue is that housevalue had 1% of entries with an NA entry coded as a very large number


