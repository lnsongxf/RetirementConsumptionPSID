****************************************************************************************************
** Merge in CPI
****************************************************************************************************

gen year = wave - 1 // note that expenditure data is for year prior to interview
merge m:1 year using "$folder/Data/Intermediate/CPI.dta"
drop if _m == 2
drop year _m

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
*replace healthservicesexpenditure = healthcareexpenditure - healthinsuranceexpenditure // my best guess as to how Pistaferri et al define this variable

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
gen expenditure_blundell_exedu     = expenditure_blundell - educationexpenditure
gen expenditure_blundell_ex3       = expenditure_blundell - educationexpenditure - childcareexpenditure - healthservicesexpenditure

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
** Total expenditure
** Will be useful for constructing savings rate = (Y - C) / Y
****************************************************************************************************

gen equiv = sqrt(fsize)

* Pre 2005, only measure 70% of expenditure
local expenditure_total_70 foodexpenditure healthcareexpenditure utilityexpenditure ///
      transportationexpenditure educationexpenditure childcareexpenditure ///
	  housingexpenditure

	  * rent_imputed propertytaxexpenditure homeinsuranceexpenditure
	  
local expenditure_total_pre2005 foodexpenditure healthcareexpenditure utilityexpenditure ///
      transportationexpenditure educationexpenditure childcareexpenditure ///
	  rent_imputed propertytaxexpenditure homeinsuranceexpenditure foodstamp
	  

* I exclude housingexpenditure and replace it with rent_imputed propertytaxexpenditure homeinsuranceexpenditure

* Starting in 2005, more comprehensive measure
* TODO: check that repairsexpenditure is not included in housingexpenditure. pretty sure it's not
local expenditure_total_100 `expenditure_total_70' furnishingsexpenditure ///
      clothingexpenditure tripsexpenditure recreationexpenditure repairsexpenditure

egen expenditure_total_70          = rowtotal(`expenditure_total_70')
egen expenditure_total_100         = rowtotal(`expenditure_total_100')
egen expenditure_total_pre2005     = rowtotal(`expenditure_total_pre2005')

* TODO: expenditure_total_post2005
local expenditure_total_post2005 `expenditure_total_pre2005' furnishingsexpenditure ///
      clothingexpenditure tripsexpenditure recreationexpenditure repairsexpenditure telephoneexpenditure

* WARNING: housingexpenditure includes mortgage payment. Might be better to include imputed rents for those people
* Also, Straub drops repairsexpenditure (and maybe furnishing?) cause those are savings rather than consumption


egen expenditure_total_post2005       = rowtotal(`expenditure_total_post2005') if wave >= 2005
gen expenditure_total_post2005_real    = (100 * expenditure_total_post2005 / CPI_all_base_2015) / equiv

// gen expenditure_total_100_real = 100 * expenditure_total_100 / CPI_all_base_2015
// replace expenditure_total_100_real =  expenditure_total_100_real / equiv


****************************************************************************************************
** Consumption Categories //
****************************************************************************************************
*Category 1 | Food at Home | From 1999 to 2015

local total_foodexp_home foodathomeexpenditure fooddeliveredexpenditure foodstamp
egen total_foodexp_home        = rowtotal(`total_foodexp_home')
*Converting the nominal value to real value of food expenditure at home
gen total_foodexp_home_real    = 100 * total_foodexp_home / CPI_all_base_2015


* Category 2 | Food expenditure away from home
* this category is already created in the document
egen total_foodexp_away = rowtotal(foodawayfromhomeexpenditure)

* Converting the nomial value to real value
gen total_foodexp_away_real = 100 * total_foodexp_away / CPI_all_base_2015


*Category 3 | Housing without repairs expenses. Repairs were added only from 2005 data
local total_housing rent_imputed utilityexpenditure homeinsuranceexpenditure propertytaxexpenditure

egen total_housing = rowtotal(`total_housing')
*Converting from nominal value to real value
gen total_housing_real    = 100 * total_housing / CPI_all_base_2015

*    	- Utilities
* 		- Home insurance
* 		- Imputed Rent
* 		- *Repairs

*CATEGORY 4 | Housing expenditure from 2005 onwards
*Note:Data on Repairs and telephone/internet expenditure was collected from 2005 onwards only. So we need two different equations on this. 
local total_housing_2005 rent_imputed utilityexpenditure homeinsuranceexpenditure propertytaxexpenditure repairsexpenditure telephoneexpenditure
egen total_housing_2005       = rowtotal(`total_housing_2005') if wave >= 2005
gen total_housing_2005_real    = 100 * total_housing_2005  / CPI_all_base_2015


*CATEGORY 5 | Health expenses (Generated variable combining
	// expenditures for hospital and nursing home, doctor, prescription drugs
	// and insurance.)
local total_healthexpense healthcareexpenditure 
egen total_healthexpense = rowtotal(`total_healthexpense')

gen total_healthexpense_real    = 100 * total_healthexpense / CPI_all_base_2015


*CATEGORY 6 | Education expenses
local total_education educationexpenditure
*childcareexpenditure
egen total_education = rowtotal(`total_education')
gen total_education_real =  100 * total_education / CPI_all_base_2015


*CATEGORY 7 | nondurable tranportation expenses
local total_transportexpense gasolineexpenditure transportation_blundell
egen total_transportexpense = rowtotal(`total_transportexpense')
gen total_transport_real = 100 * total_transportexpense / CPI_all_base_2015


* CATEGORY 8 | Recreation expenses **
* The data on recreation was added from 2005 survey
local total_recreation_2005 recreationexpenditure tripsexpenditure
egen total_recreation_2005   = rowtotal(`total_recreation_2005') if wave >= 2005

gen total_recreation_2005_real  = 100 * total_recreation_2005 / CPI_all_base_2015


*CATEGORY 9 | Clothing expenses | This category was also added from 2005 onwards

egen total_clothing_2005 = rowtotal(clothingexpenditure) if wave >= 2005
gen total_clothing_2005_real = 100 * total_clothing_2005 / CPI_all_base_2015


gen expenditure_total_pre2005_real = 100 * expenditure_total_pre2005 / CPI_all_base_2015



* dividing all by equiv 
foreach var of varlist  total_foodexp_home_real total_foodexp_away_real total_housing_real ///
total_housing_2005_real total_education_real total_healthexpense_real total_transport_real  ///
total_recreation_2005_real total_clothing_2005_real expenditure_total_pre2005_real {
replace `var' =  `var'/ equiv
}

*********************************************
//ADDING MISSING DURABLES TO PLOT BAR GRAPHS
*********************************************
// local missing_food_exp fooddeliveredexpenditure 
// egen missing_food_exp = rowtotal(`missing_food_exp')
// gen missing_food_exp_real =  100 * missing_food_exp / CPI_all_base_2015
// replace missing_food_exp_real =  missing_food_exp_real/ equiv


local transport_durables vehicleloanexpenditure vehicledpexpenditure vehicleleaseexpenditure ///
	  addvehicleexpenditure
egen transport_durables = rowtotal(`transport_durables')
gen transport_durables_real =  100 * transport_durables / CPI_all_base_2015
replace transport_durables_real =  transport_durables_real/ equiv

gen transportationexp_real2015 = 100 * (transportationexpenditure / CPI_all_base_2015) / equiv
* excludes vehicle loan, down payment, lease, and additional vehicle expenditure
* additonal vehicle expenditure (intially excluded from the data)
// local transportation_blundell autoinsexpenditure vehiclerepairexpenditure ///
// parkingexpenditure bustrainexpenditure taxiexpenditure othertransexpenditure// gasoline (



* 1) add them
* egen x = rowtotal(var1 var2)
* 2) convert to real values using (where x is the variable of interest)
* gen x_real = 100 * x / CPI_all_base_2015
* 3) divide each category equiv (replace x = x / equiv )

****************************************************************************************************
** Aguiar and Hurst Additions
****************************************************************************************************

// When examining the life cycle profile of mean
// expenditures and cross-sectional dispersion, we limit our analysis to nondurables
// excluding health and education expenditures. Our measure of
// nondurables consists of expenditure on food (both home and away), alcohol,
// tobacco, clothing and personal care, utilities, domestic services,
// nondurable transportation, airfare, nondurable entertainment, net gambling
// receipts, business services, and charitable giving.7We also examine a
// broader measure of nondurables that includes housing services, where
// housing services are calculated as either rent paid (for renters) or the selfreported
// rental equivalent of the respondent’s house (for homeowners).

* PSID: we do same as AH but do not have tobacco, clothing and personal care,
* domestic services, airfare, nondurale entertainemtn, net gambling, business services, charitable giving

local expenditure_hurst_nonH foodathomeexpenditure foodstamp foodawayfromhomeexpenditure ///
		fooddeliveredexpenditure gasolineexpenditure  utilityexpenditure ///
		transportation_blundell childcareexpenditure

local expenditure_hurst `expenditure_hurst_nonH' propertytaxexpenditure homeinsuranceexpenditure rent_imputed

egen expenditure_hurst      = rowtotal( `expenditure_hurst' )
egen expenditure_hurst_nonH = rowtotal( `expenditure_hurst_nonH' )

// Figure 2
// The categories are food at home;
// work-related expenses which include transportation, food away from home, and clothing/personal care;
// and core nondurables which include all other categories of total nondurable
// expenditure, including housing services but excluding alcohol and tobacco.
// NOTE: I exclude clothingexpenditure since it only begins in 2005

egen workexpenditure               = rowtotal(transportation_blundell gasolineexpenditure foodawayfromhomeexpenditure ) // if wave >= 2005 // clothingexpenditure begins in 2005
egen workexpenditure_post05        = rowtotal(transportation_blundell gasolineexpenditure foodawayfromhomeexpenditure clothingexpenditure ) // NOTE: only use 2005 onward
egen nonwork_nondur_expenditure    = rowtotal( /* healthinsuranceexpenditure healthservicesexpenditure educationexpenditure*/ ///
											utilityexpenditure childcareexpenditure homeinsuranceexpenditure ///
											propertytaxexpenditure rent_imputed )


egen housingservicesexpenditure = rowtotal(rent_imputed homeinsuranceexpenditure propertytaxexpenditure)


****************************************************************************************************
** Compare imputed variables to underlying data
** slightly weird: transportationexpenditure == transportationexpenditure_TEST
** but we cannot replicate this assertion using the real-equiv-scale data
****************************************************************************************************

/*
graph bar total_transport_real transport_durables, over(age) stack name("fig1", replace)
graph bar transportationexp_real2015, over(age) stack name("fig2", replace)

preserve
collapse total_transport_real transport_durables transportationexp_real2015, by(age)
gen transportation_NEW = total_transport_real + transport_durables
tsset age
tsline transportationexp_real2015 transportation_NEW
restore
*/

/*

gen dif_trans = transportationexp_real2015 - total_transport_real - transport_durables


* Assert that these components of transportation all add up to transportationexpenditure
egen transportationexpenditure_TEST = rowtotal(vehicleloanexpenditure vehicledpexpenditure vehicleleaseexpenditure autoinsexpenditure addvehicleexpenditure ///
	vehiclerepairexpenditure gasolineexpenditure parkingexpenditure bustrainexpenditure taxiexpenditure othertransexpenditure)
assert transportationexpenditure_TEST <= transportationexpenditure + 0.03 & ///
		transportationexpenditure_TEST >= transportationexpenditure - 0.03



sum dif_trans 
hist dif_trans 
tab wave if dif_trans > 0.1 | dif_trans < -0.1

edit pid wave transportationexpenditure vehicleloanexpenditure vehicledpexpenditure vehicleleaseexpenditure autoinsexpenditure addvehicleexpenditure ///
	vehiclerepairexpenditure gasolineexpenditure parkingexpenditure bustrainexpenditure taxiexpenditure othertransexpenditure ///
	dif_trans transportationexp_real2015 total_transport_real transport_durables	if dif_trans > 0.1 | dif_trans < -0.1
*/
	
	

****************************************************************************************************
** Merge in CPI and make real
****************************************************************************************************


* Convert to real terms using individual index
* WARNING: individual index might have different base year from CPI_all
* Can see base year in xlsx file with CPI data
* (do not add/subtract real series without accounting for this)
replace gasolineexpenditure         = 100 * gasolineexpenditure / CPI_gasoline
replace foodexpenditure             = 100 * foodexpenditure / CPI_food
replace foodstamp                   = 100 * foodstamp / CPI_food
replace foodathomeexpenditure       = 100 * foodathomeexpenditure / CPI_foodathome
replace foodawayfromhomeexpenditure = 100 * foodawayfromhomeexpenditure / CPI_foodawayfromhome
replace fooddeliveredexpenditure    = 100 * fooddeliveredexpenditure / CPI_food
replace transportationexpenditure   = 100 * transportationexpenditure / CPI_transportation
replace transportation_blundell     = 100 * transportation_blundell / CPI_transportation
replace healthcareexpenditure       = 100 * healthcareexpenditure / CPI_health
replace healthinsuranceexpenditure  = 100 * healthinsuranceexpenditure / CPI_health
replace healthservicesexpenditure   = 100 * healthservicesexpenditure / CPI_health
replace clothingexpenditure         = 100 * clothingexpenditure / CPI_apparel
replace recreationexpenditure       = 100 * recreationexpenditure / CPI_recreation

* Convert to 2015 real dollars
gen expenditure_exH_real_2015       = 100 * expenditure_blundell_exhous / CPI_all_base_2015

* Convert to real terms using CPI_all
foreach var of varlist housingexpenditure mortgageexpenditure rentexpenditure ///
	propertytaxexpenditure homeinsuranceexpenditure utilityexpenditure ///
	vehicleloanexpenditure vehicledpexpenditure vehicleleaseexpenditure ///
	autoinsexpenditure addvehicleexpenditure vehiclerepairexpenditure ///
	parkingexpenditure bustrainexpenditure taxiexpenditure othertransexpenditure ///
	educationexpenditure childcareexpenditure telephoneexpenditure ///
	repairsexpenditure furnishingsexpenditure tripsexpenditure ///
	expenditure_blundell expenditure_blundell_exhealth expenditure_blundell_exhous ///
	expenditure_blundell_exedu expenditure_blundell_ex3 rent_imputed ///
	expenditure_hurst expenditure_hurst_nonH workexpenditure ///
	workexpenditure_post05 nonwork_nondur_expenditure housingservicesexpenditure ///
	expenditure_total_70 {

	* di "`var'"
	replace `var' = 100 * `var' / CPI_all
}

* NOTE: inc_fam remains nominal (though up above, expenditure categories are converted to real... not the best naming convention)
gen inc_fam_real      = 100 * inc_fam / CPI_all
gen inc_fam_real_2015 = 100 * inc_fam / CPI_all_base_2015

gen inc_ss_fam_real   = 100 * inc_ss_fam / CPI_all_base_2015

****************************************************************************************************
** Wealth
****************************************************************************************************

egen fam_liq_wealth              = rowtotal(bank_account_wealth stock_wealth) // NOTE: Limitation: this is not net
egen fam_liq_plus_housing_wealth = rowtotal(fam_liq_wealth homeequity other_real_estate_wealth)
egen fam_liq_housing_IRA         = rowtotal(fam_liq_wealth homeequity other_real_estate_wealth IRA_wealth)
egen fam_liq_housing_IRA_bus     = rowtotal(fam_liq_wealth homeequity other_real_estate_wealth IRA_wealth business_wealth)
gen  fam_wealth_ex_bus           = fam_wealth - business_wealth // business_wealth is net
gen  fam_wealth_ex_bus_ira       = fam_wealth - business_wealth - IRA_wealth // business_wealth is net
egen mortgage_debt               = rowtotal( mortgage1 mortgage2 )

* NOTE: I took out IRA wealth
* TODO: say that mortgage debt is in housing, and all other debt is in liquid

* Convert to real with base = 2015
gen fam_wealth_real              = 100 * fam_wealth / CPI_all_base_2015
gen fam_wealth_ex_home_real      = 100 * fam_wealth_ex_home / CPI_all_base_2015
gen value_gifts_real             = 100 * value_gifts / CPI_all_base_2015
gen fam_liq_wealth_real          = 100 * fam_liq_wealth / CPI_all_base_2015
gen homeequity_real              = 100 * homeequity / CPI_all_base_2015
gen fam_LiqAndH_wealth_real      = 100 * fam_liq_plus_housing_wealth / CPI_all_base_2015 // liquid and housing wealth only
gen fam_wealth_ex_bus_real       = 100 * fam_wealth_ex_bus / CPI_all_base_2015
gen fam_wealth_ex_bus_ira_real   = 100 * fam_wealth_ex_bus_ira / CPI_all_base_2015
gen fam_liq_housing_IRA_real     = 100 * fam_liq_housing_IRA / CPI_all_base_2015
gen fam_liq_housing_IRA_bus_real = 100 * fam_liq_housing_IRA_bus / CPI_all_base_2015
gen housevalue_real              = 100 * housevalue / CPI_all_base_2015
gen mortgage_debt_real           = 100 * mortgage_debt / CPI_all_base_2015

* TODO: perhaps down the road add expenditure_total* and inc_*

* NOTE: wealth is now in 2015 dollars whereas most other categories are 1982 -- WARNING!!!
* TODO: convert others to 2015 dollars

****************************************************************************************************
** Equivalence scale
****************************************************************************************************

gen expenditure_blundell_eq        = expenditure_blundell / equiv
gen expenditure_blundell_eq_exH    = expenditure_blundell_exhous / equiv

lab var expenditure_blundell_eq "Total Expenditure (equivalence scale)"
