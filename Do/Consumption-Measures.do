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

* Blundell et al include food stamps in food. 
* (The expenditure variables do not include the value of in-kind government
* transfers. For example, the value of food stamps received by family units is
* not included in estimates of food expenditures.)

* Blundell et al exclude durable transportation expenditures: vehicle loan,
* lease, and down payments, other vehicle expenditures

* Blundell et al include transportation services: insurance,repairs and
* maintenance, gasoline, parking bus fares and train fares, taxicabs and
* other transportation.

