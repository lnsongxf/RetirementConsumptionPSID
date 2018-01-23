set more off
* global folder "C:\Users\pedm\Documents\Research\Cormac\RetirementConsumptionPSID"
global folder "F:\Cormac Project January 18 2018 Backup\RetirementConsumptionPSID"


clear
import excel "$folder\Data\Raw\CPI.xlsx", sheet("Sheet1") firstrow
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

save "$folder\Data\Intermediate\CPI.dta", replace
