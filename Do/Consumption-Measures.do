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

* Pre 2005, only measure 70% of expenditure
local expenditure_total_70 foodexpenditure healthcareexpenditure utilityexpenditure ///
      transportationexpenditure educationexpenditure childcareexpenditure ///
	  housingexpenditure
	  
	  * rent_imputed propertytaxexpenditure homeinsuranceexpenditure
	  
* I exclude housingexpenditure and replace it with rent_imputed propertytaxexpenditure homeinsuranceexpenditure

* Starting in 2005, more comprehensive measure
* TODO: check that repairsexpenditure is not included in housingexpenditure. pretty sure it's not
local expenditure_total_100 `expenditure_total_70' furnishingsexpenditure ///
      clothingexpenditure tripsexpenditure recreationexpenditure repairsexpenditure

egen expenditure_total_70          = rowtotal(`expenditure_total_70')
egen expenditure_total_100         = rowtotal(`expenditure_total_100')

* WARNING: housingexpenditure includes mortgage payment. Might be better to include imputed rents for those people
* Also, Straub drops repairsexpenditure (and maybe furnishing?) cause those are savings rather than consumption



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
** Merge in CPI and make real
****************************************************************************************************


gen year = wave - 1 // note that expenditure data is for year prior to interview
merge m:1 year using "$folder\Data\Intermediate\CPI.dta"
drop if _m == 2 
drop year _m

* Convert to real terms using individual index
* WARNING: individual index might have different base year from CPI_all 
* Can see base year in xlsx file with CPI data
* (do not add/subtract real series without accounting for this)
replace gasolineexpenditure = 100 * gasolineexpenditure / CPI_gasoline
replace foodexpenditure = 100 * foodexpenditure / CPI_food
replace foodstamp = 100 * foodstamp / CPI_food
replace foodathomeexpenditure = 100 * foodathomeexpenditure / CPI_foodathome
replace foodawayfromhomeexpenditure = 100 * foodawayfromhomeexpenditure / CPI_foodawayfromhome 
replace fooddeliveredexpenditure = 100 * fooddeliveredexpenditure / CPI_food
replace transportationexpenditure = 100 * transportationexpenditure / CPI_transportation 
replace transportation_blundell = 100 * transportation_blundell / CPI_transportation
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
	expenditure_blundell_exedu expenditure_blundell_ex3 rent_imputed ///
	expenditure_hurst expenditure_hurst_nonH workexpenditure ///
	workexpenditure_post05 nonwork_nondur_expenditure housingservicesexpenditure ///
	expenditure_total_70 {
	
	* di "`var'"
	replace `var' = 100 * `var' / CPI_all
}

* NOTE: inc_fam remains nominal (though up above, expenditure categories are converted to real... not the best naming convention)
gen inc_fam_real = 100 * inc_fam / CPI_all

****************************************************************************************************
** Wealth
****************************************************************************************************

* WARNING: this is not NET
egen fam_liq_wealth = rowtotal(bank_account_wealth IRA_wealth stock_wealth)

* Convert to real
gen fam_wealth_real = 100 * fam_wealth / CPI_all
gen fam_wealth_ex_home_real = 100 * fam_wealth_ex_home / CPI_all
gen value_gifts_real = 100 * value_gifts / CPI_all
gen fam_liq_wealth_real = 100 * fam_liq_wealth / CPI_all

* TODO: perhaps down the road add expenditure_total* and inc_* 


****************************************************************************************************
** Equivalence scale
****************************************************************************************************

gen equiv = sqrt(fsize)

gen expenditure_blundell_eq        = expenditure_blundell / equiv
gen expenditure_blundell_eq_exH    = expenditure_blundell_exhous / equiv

lab var expenditure_blundell_eq "Total Expenditure (equivalence scale)"
