set more off
global folder "C:\Users\pedm\Documents\Research\Cormac\RetirementConsumptionPSID"

use "$folder\Data\Intermediate\Basic-Panel.dta", clear

****************************************************************************************************
** Aggregate expenditure measure
****************************************************************************************************

* "Consumption Inequality and Family Labor Supply"
* Blundell, Pistaferri, Saporta-Eksten paper that uses PSID consumption data from 1999 to 2009
* https://www.econstor.eu/bitstream/10419/67323/1/727547445.pdf

* All components of transportation
local transportation_subcomponenets vehicleloanexpenditure vehicledpexpenditure /// 
vehicleleaseexpenditure autoinsexpenditure addvehicleexpenditure ///
vehiclerepairexpenditure gasolineexpenditure parkingexpenditure ///
bustrainexpenditure taxiexpenditure othertransexpenditure

* Subcomponents of transportation used by Blundell et al
* (aka, transportation services)
* excludes vehicle loan, down payment, lease, and additional vehicle expenditure
local transportation_blundell autoinsexpenditure vehiclerepairexpenditure ///
parkingexpenditure bustrainexpenditure taxiexpenditure othertransexpenditure

gen healthservicesexpenditure = healthcareexpenditure - healthinsuranceexpenditure // my best guess as to how Pistaferri et al define this variable

gen rent_imputed = rentexpenditure 
replace rent_imputed = 0.06 * housevalue if homeowner == 1

local expenditure_blundell foodathomeexpenditure foodstamp gasolineexpenditure foodawayfromhomeexpenditure /// 
healthinsuranceexpenditure healthservicesexpenditure utilityexpenditure ///
transportation_blundell educationexpenditure childcareexpenditure /// 
homeinsuranceexpenditure rent_imputed 

gen equiv = sqrt(fsize)

egen transportation_blundell = rowtotal(`transportation_blundell')
lab var transportation_blundell "Transportation Services (Blundell et al)"

* Blundell et al Expenditure (equivalence scale)
egen expenditure_blundell    = rowtotal(`expenditure_blundell')
gen expenditure_blundell_eq  = expenditure_blundell / fsize
lab var expenditure_blundell "Total Expenditure (Blundell et al)"
lab var expenditure_blundell_eq "Total Expenditure (equivalence scale)"


* /* Consumption */
* egen ndcons 	= 	rsum(food fstmp gasoline), missing 
* egen services 	= 	rsum(hinsurance nurse doctor prescription homeinsure electric heating water miscutils ///
* 					carins carrepair parking busfare taxifare othertrans tuition otherschool childcare rent renteq fout), missing /* note that totalhealth is not used since the sub components are used */ 
* egen totcons	= 	rsum(ndcons services), missing
* egen tempr 		= 	rsum(rent renteq)
* gen totcons_nh  =   totcons - tempr
* drop tempr



* Add food stamps to food

* The expenditure variables do not include the value of in-kind government
* transfers. For example, the value of food stamps received by family units is
* not included in estimates of food expenditures. Users who wish to include food
* stamps in calculating food expenditures or total expenditures will want to
* incorporate information contained in the food stamp variables contained in the
* family data files on the PSID website.


/* Car expenditure */
* ren ER17202 carins
* replace carins=. if carins>999997
* replace carins=. if (ER17203<5 | ER17203>6) & carins!=0
* replace carins=12*carins if ER17203==5

* ren ER17206 carrepair
* replace carrepair=. if carrepair>99997
* replace carrepair=12*carrepair

* ren ER17207 gasoline
* replace gasoline=. if gasoline>99997
* replace gasoline=12*gasoline

* ren ER17208 parking
* replace parking=. if parking>99997
* replace parking=12*parking

* ren ER17209 busfare
* replace busfare=. if busfare>99997
* replace busfare=12*busfare

* ren ER17210 taxifare
* replace taxifare=. if taxifare>99997
* replace taxifare=12*taxifare

* ren ER17211 othertrans
* replace othertrans=. if othertrans>99997
* replace othertrans=12*othertrans


	// Total Family Transportation Expenditure: 
	// vehicle loan, lease, and down payments, 
	// other vehicle expenditures
	// and car pool

	// insurance,repairs and maintenance, gasoline, parking
	// bus fares and train fares, taxicabs and other
	// transportation.
	
****************************************************************************************************
** Replicate Transportation Section of Appendix Table 4 in "Estimates of Annual Consumption Expenditures and Its Major Componenets"
****************************************************************************************************

* Make sure I know exactly what is in transportationexpenditure
* Yes -- this variable is an exact match
egen mytransportationexpenditure = rowtotal(`transportation_subcomponenets')

eststo clear
forvalues yy = 1999(2)2009{
	qui eststo: mean transportationexpenditure mytransportationexpenditure `transportation_subcomponenets' if wave == `yy'
}
esttab, nostar not label mtitles(1999 2001 2003 2005 2007 2009) title("Estimates of Annual Consumption Expenditures and Its Major Componenets, Appendix Table 4 (Transportation Only)")

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
	desc food*ma

	lab var foodexpenditure_ma "Total Food Expenditure"
	lab var foodathomeexpenditure_ma "Food at Home"
	lab var foodawayfromhomeexpenditure_ma "Food Away From Home"
	lab var fooddeliveredexpenditure_ma "Food Delivered"
	tsline food*ma if wave == 2001, name(food, replace) title("Food Expenditure in 2001")
	collapse *expenditure_ma, by(age)
	
	tsset age

	lab var housingexpenditure "Housing Expenditure"
	lab var mortgageexpenditure "Mortgage Expenditure"
	lab var rentexpenditure "Rent Expenditure"

	lab var propertytaxexpenditure "Property Tax Expenditure"
	lab var homeinsuranceexpenditure "Home Insurance Expenditure"
	lab var utilityexpenditure "Utility Expenditure"

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
	qui eststo: mean expenditure_blundell expenditure_blundell_eq `expenditure_blundell' if wave == `yy'
}
esttab, nostar not label mtitles(1999 2001 2003 2005 2007 2009) title("Table 1 Blundell et al (Working Paper)")

* transportation now looks good -- we include just transportation services (following Blundell et al code)
* imputed rent now looks good -- the issue is that housevalue had 1% of entries with an NA entry coded as a very large number
