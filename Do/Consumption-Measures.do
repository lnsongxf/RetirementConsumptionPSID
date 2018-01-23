****************************************************************************************************
** Generate aggregate consumption (following Blundell et al)
****************************************************************************************************

* "Consumption Inequality and Family Labor Supply"
* Blundell, Pistaferri, Saporta-Eksten paper that uses PSID consumption data from 1999 to 2009
* https://www.econstor.eu/bitstream/10419/67323/1/727547445.pdf

* Subcomponents of transportation used by Blundell et al
* (aka, transportation services)
* excludes vehicle loan, down payment, lease, and additional vehicle expenditure
local transportation_blundell autoinsexpenditure vehiclerepairexpenditure ///
parkingexpenditure bustrainexpenditure taxiexpenditure othertransexpenditure

gen healthservicesexpenditure = healthcareexpenditure - healthinsuranceexpenditure // my best guess as to how Pistaferri et al define this variable

gen rent_imputed = rentexpenditure 
replace rent_imputed = 0.06 * housevalue if housingstatus == 1

local expenditure_blundell foodathomeexpenditure foodstamp gasolineexpenditure foodawayfromhomeexpenditure /// 
healthinsuranceexpenditure healthservicesexpenditure utilityexpenditure ///
transportation_blundell educationexpenditure childcareexpenditure /// 
homeinsuranceexpenditure rent_imputed 

egen transportation_blundell = rowtotal(`transportation_blundell')
lab var transportation_blundell "Transportation Services (Blundell et al)"

* Blundell et al Expenditure (equivalence scale)
egen expenditure_blundell          = rowtotal(`expenditure_blundell')
gen expenditure_blundell_exhealth  = expenditure_blundell - healthservicesexpenditure - healthinsuranceexpenditure
gen expenditure_blundell_exhous    = expenditure_blundell - rent_imputed - homeinsuranceexpenditure
gen expenditure_blundell_ex3 = expenditure_blundell - educationexpenditure - childcareexpenditure - healthservicesexpenditure

lab var expenditure_blundell_ex3 "Blundell Ex - Edu, Child Care, Health"
lab var expenditure_blundell "Total Expenditure (Blundell et al)"


* /* Consumption */
* egen ndcons 	= 	rsum(food fstmp gasoline), missing 
* egen services 	= 	rsum(hinsurance nurse doctor prescription homeinsure electric heating water miscutils ///
* 					carins carrepair parking busfare taxifare othertrans tuition otherschool childcare rent renteq fout), missing /* note that totalhealth is not used since the sub components are used */ 
* egen totcons	= 	rsum(ndcons services), missing
* egen tempr 		= 	rsum(rent renteq)
* gen totcons_nh  =   totcons - tempr
* drop tempr

* Blundell et al include food stamps in food. 
* (The expenditure variables do not include the value of in-kind government
* transfers. For example, the value of food stamps received by family units is
* not included in estimates of food expenditures.)

* Blundell et al exclude durable transportation expenditures: vehicle loan,
* lease, and down payments, other vehicle expenditures

* Blundell et al include transportation services: insurance,repairs and
* maintenance, gasoline, parking bus fares and train fares, taxicabs and
* other transportation.


****************************************************************************************************
** Merge in CPI
****************************************************************************************************

gen year = wave - 1 // note that expenditure data is for year prior to interview
merge m:1 year using "$folder\Data\Intermediate\CPI.dta"
drop if _m == 2 
drop year _m

* Convert to real terms using individual index
* Note: individual index might have different base year from CPI_all 
* Can see base year in xlsx file with CPI data
* (do not add/subtract real series without accounting for this)
replace gasolineexpenditure = 100 * gasolineexpenditure / CPI_gasoline
replace foodexpenditure = 100 * foodexpenditure / CPI_food
replace foodathomeexpenditure = 100 * foodathomeexpenditure / CPI_foodathome
replace foodawayfromhomeexpenditure = 100 * foodawayfromhomeexpenditure / CPI_foodawayfromhome 
replace fooddeliveredexpenditure = 100 * fooddeliveredexpenditure / CPI_food
replace transportationexpenditure = 100 * transportationexpenditure / CPI_transportation 
replace healthcareexpenditure = 100 * healthcareexpenditure / CPI_health
replace healthinsuranceexpenditure = 100 * healthinsuranceexpenditure / CPI_health
replace healthservicesexpenditure = 100 * healthservicesexpenditure / CPI_health
replace clothingexpenditure = 100 * clothingexpenditure / CPI_apparel
replace recreationexpenditure = 100 * recreationexpenditure / CPI_recreation

* Convert to real terms using CPI_all
foreach var of varlist housingexpenditure mortgageexpenditure rentexpenditure ///
	propertytaxexpenditure homeinsuranceexpenditure utilityexpenditure ///
	vehicleloanexpenditure vehicledpexpenditure vehicleleaseexpenditure ///
	autoinsexpenditure addvehicleexpenditure vehiclerepairexpenditure ///
	parkingexpenditure bustrainexpenditure taxiexpenditure othertransexpenditure ///
	educationexpenditure childcareexpenditure telephoneexpenditure ///
	repairsexpenditure furnishingsexpenditure tripsexpenditure ///
	expenditure_blundell expenditure_blundell_exhealth expenditure_blundell_exhous ///
	expenditure_blundell_ex3 {
	
	* di "`var'"
	replace `var' = 100 * `var' / CPI_all
}

****************************************************************************************************
** Equivalence scale
****************************************************************************************************

gen equiv = sqrt(fsize)

gen expenditure_blundell_eq        = expenditure_blundell / fsize
gen expenditure_blundell_eq_exH    = expenditure_blundell_exhous / fsize

lab var expenditure_blundell_eq "Total Expenditure (equivalence scale)"
