set more off
*global folder "/Users/agneskaa/Documents/RetirementConsumptionPSID"
global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"


clear
import excel "$folder/Data/Raw/CPI.xlsx", sheet("Sheet1") firstrow
rename A year
keep year AllitemsinUScityaverage AllitemslessfoodinUScity Allitemslessfoodandenergyi Apparel EducationinUScityaverage Food Foodathome Medicalcare RecreationinUScityaverage TransportationservicesinUS Foodawayfromhome RentofprimaryresidenceinUS Gasolinealltypes
drop in 1
drop in 35

* Rename series
rename AllitemsinUScityaverage CPI_all
rename AllitemslessfoodinUScity CPI_all_ex_food
rename Allitemslessfoodandenergyi CPI_all_ex_food_energy
rename Apparel CPI_apparel
rename EducationinUScityaverage CPI_educ
rename Food CPI_food
rename Foodathome CPI_foodathome
rename Medicalcare CPI_health
rename RecreationinUScityaverage CPI_recreation
rename TransportationservicesinUS CPI_transportation
rename Foodawayfromhome CPI_foodawayfromhome
rename RentofprimaryresidenceinUS CPI_rent
rename Gasolinealltypes CPI_gasoline

destring *, replace

save "$folder/Data/Intermediate/CPI.dta", replace

* Import CPI all with base = 2015
clear
import excel "$folder/Data/Raw/CPI_2015.xls", sheet("Sheet1")  firstrow
rename Year year
drop CPI_all_base_1982
drop ratio
tempfile newcpi
save `newcpi', replace

* Merge in CPI all with base = 2015
use  "$folder/Data/Intermediate/CPI.dta", clear
merge 1:1 year using `newcpi'
drop _merge
* gen ratio = CPI_all_base_2015 / CPI_all
* tsset year
* tsline ratio
save "$folder/Data/Intermediate/CPI.dta", replace
