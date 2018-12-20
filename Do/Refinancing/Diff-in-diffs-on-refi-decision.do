****************************************************************************************************
** Prep Data
****************************************************************************************************

set more off
graph close
set autotabgraphs on

global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"
use "$folder\Data\Intermediate\Basic-Panel.dta", clear

cap mkdir "$folder/Results/Aux_Model_Estimates/AuxModelLatex/"

* Switches
global allow_kids_to_leave_hh 1 // When looking for stable households, what should we do when a kid enters/leaves? 0 = break the HH, 1 = keep the HH
                                // (Note: this applies to any household member other than the head and spouse. We always break the HH when there's a change in head or spouse)

* drop if emp_status_head != 1 // only keep employed heads. Question: should I put this so early? ie to split up HH? or later?

* cap ssc install mat2txt

global aux_model_in_logs 1 // 1 = logs, 0 = levels

global drop_top_x 5 // 5 // can be 0, 1, or 5
global drop_by_income 1 // can be 1 to drop by income, 0 to drop by wealth

global estimate_reg_by_age 0 // 0 is our baseline where we estimate SUREG with everyone pooled together. 1 is alternative where we do two buckets
global cutoff_age 40

global no_age_coefs 0 // default is  0 (include age and age2). NOTE: I manually removed age and age2 from the SUR
global residualized_vars 1 // original version was 0 (no residualization) (NOTE: only works for log variables)
global house_price_by_age 0 // plot distribution of house price by age?

global compute_htm_persistence 0
global makeplots 0


cap net install xtserial.pkg

* TODO: add in mortgage debt vs house value
* TODO: drop imputed values (ex tab acc_homeequity)

****************************************************************************************************
** Sample selection
****************************************************************************************************

* Sample selection: households with same husband-wife over time
qui do "$folder\Do\Sample-Selection.do"

* Generate aggregate consumption (following Blundell et al)
qui do "$folder\Do\Consumption-Measures.do"

* TODO: make income / wealth real

* Todo: try before or after sample selection

* These people have misreported something
drop if housingstatus == 1 & housevalue == 0
drop if housingstatus == 1 & housevalue < 10000

* These people have a crazy change in wealth
* TODO: what do Aguiar and Hurst do
sort pid wave
/*gen change_wealth = (fam_wealth_real - L.fam_wealth_real) / L.fam_wealth_real
drop if change_w > 100 & change_w != . & L.fam_wealth_real > 10000

* These ppl also have a crazy change in wealth
drop if fam_wealth_real - L.fam_wealth_real > 100 * inc_fam_real & fam_wealth != . & L.fam_wealth_real != . & inc_fam_real != .*/

* To do: try with or without these guys
* drop if housingstatus == 8 // neither own nor rent

* Find first home purcahses (two alternative definitions)
qui do "$folder\Do\Housing\Find-First-Home-Purchase.do"


****************************************************************************************************
** Aux Model Versions
****************************************************************************************************

* Version 5 (Original)
* local non_log_endog_vars WHtM PHtM dummy_mort housing

* Version 5 (New - remove dummy_mort b/c in the model dummy_mort is collinear with housing)
local non_log_endog_vars WHtM PHtM housing

****************************************************************************************************
** Find housing upgrades/downgrades (owner to owner transitions)
****************************************************************************************************
* note: can see if they take out a second mortgage... interesting!
tab type_mortgage1
tab type_mortgage2
tab year_moved

* it seems they only ask year_moved if you've moved
gen dif = year_moved - wave
tab year_moved

gen owner_transition1 = (year_moved == wave | year_moved == wave-1) & homeowner == 1 & homeowner == 1  & L.homeowner == 1
gen owner_transition2 = (year_moved == wave | year_moved == wave-1 | year_moved == wave-2) & L.homeowner == 1
gen owner_transition3 = (year_moved == wave | year_moved == wave-1 | year_moved == wave-2) & year_moved != L.year_moved & L.homeowner == 1
edit pid wave housevalue year_moved current_state owner_transition* room_count mortgage1 mortgage2 if homeowner == 1
tab owner_transition2 homeowner, missing
tab owner_transition2 owner_transition3

gen owner_transition = owner_transition3 // best definition
gen owner_upgrade = owner_transition & (housevalue_real > L.housevalue_real)
gen owner_downgrade = owner_transition & (housevalue_real <= L.housevalue_real)



****************************************************************************************************
** Look into home equity loans by year
****************************************************************************************************

* TODO: count number of home owners
gen mortgage = (type_mortgage1 >= 1 & type_mortgage1 <= 7 ) | (type_mortgage2 >= 1 & type_mortgage2 <= 7 )
gen HEL   = (type_mortgage1 == 3 | type_mortgage2 == 3) 
gen HELOC = (type_mortgage1 == 5 | type_mortgage2 == 5) 
gen New_HEL   = HEL   == 1 & L.HEL   == 0
gen New_HELOC = HELOC == 1 & L.HELOC == 0

* collapse (sum) mortgage home_equity_loan HELOC, by(wave)

collapse (sum) mortgage HEL HELOC New_HEL New_HELOC (count) n = mortgage, by(wave current_state)

xtset current_state wave, delta(2)
gen D_mortgage = D.mortgage
gen D_HEL = D.HEL
gen D_HELOC = D.HELOC
gen D_New_HEL = D.New_HEL
gen D_New_HELOC = D.New_HELOC

****************************************************************************************************
* Expand forward the deregulation data -- note that it would be more rigorous to look at what happens later in time
****************************************************************************************************
preserve
use "$folder\Data\Favara and Imbs 2015\RiceStrahan2010Index_Inverse.dta", clear
xtset state_n year
forvalues v = 2005(1)2009{
	di "`v'"
	expand 2 if year == `v', gen(new)
	replace year = `v'+1 if year == `v' & new == 1
	drop new
}
sort state year
tempfile dereg_index
save `dereg_index', replace
restore

****************************************************************************************************
** Merge in banking deregulation measure
** inter_bra is larger for more deregulated states
** Note: could have done this at individual level, but for now look at state level, since we're not sure how to treat years not observed
** Note: should only keep HHs that dont move from wave to wave
****************************************************************************************************

drop if current_state == 0 | current_state == 99
gen state_n = current_state
gen year = wave
merge 1:1 year state_n using `dereg_index'
drop current_state wave
rename state_n state
xtset state year


reg mortgage  L4.inter_bra i.state i.year 
reg HELOC     L4.inter_bra i.state i.year 
reg HEL       L4.inter_bra i.state i.year
reg New_HEL   L4.inter_bra i.state i.year
reg New_HELOC L4.inter_bra i.state i.year
sdfds

reg D_mortgage  L2.inter_bra i.state i.year 
reg D_HELOC     L2.inter_bra i.state i.year 
reg D_HEL       L2.inter_bra i.state i.year
reg D_New_HEL   L2.inter_bra i.state i.year
reg D_New_HELOC L2.inter_bra i.state i.year


sdfdsf

* Look at HELOCs etc by state
gen mortgage_n = mortgage / n
gen HELOC_n = HELOC / n
gen HEL_n = HEL / n
gen New_HEL_n = New_HEL / n
gen New_HELOC_n = New_HELOC / n

reg mortgage_n L.inter_bra i.state i.year 
reg HELOC_n L.inter_bra i.state i.year 
reg HEL_n L.inter_bra i.state i.year
reg New_HEL_n  L.inter_bra i.state i.year
reg New_HELOC_n L.inter_bra i.state i.year

sum HEL_n if inter_bra == 0

* perhaps better to do at the individual level from the beginning...

