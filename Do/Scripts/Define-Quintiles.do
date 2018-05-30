
****************************************************************************************************
** (1) Quintiles based on FAMILY social security income in retirement
**     (using the LAST observed social security income)
****************************************************************************************************
by pid, sort: egen max_year = max(wave)

if $quintiles_definition == 1{
	gen inc_ss_fam_last         = inc_ss_fam if wave == max_year
	xtile quintile_last         = inc_ss_fam_last if wave == max_year & retired == 1, n(5)
	by pid, sort: egen quintile = max(quintile_last)

	** Problem with this measure is that there are lots of cases where inc_ss_fam_last == 0
	** So the lowest quintile isn't made of households with the lowest permanent income
	hist inc_ss_fam_last if wave == max_year & retired == 1, name("hist", replace)
}


****************************************************************************************************
** (2) Quintiles based on FAMILY social security income in retirement
**     (using the MAX observed social security income)
** NOTE: we converted SS income to real
****************************************************************************************************

if $quintiles_definition == 2{
	* Done: rather than using inc_ss_fam_real use something similar with inc_ss_head_real
	
	by pid, sort: egen max_inc_ss_head = max(inc_ss_head_real)
	xtile quintile_last               = max_inc_ss_head if wave == max_year & retired == 1 & max_inc_ss_head != 0, n(5)
	xtile tertile_last                = max_inc_ss_head if wave == max_year & retired == 1 & max_inc_ss_head != 0, n(3)
	by pid, sort: egen quintile       = max(quintile_last)
	by pid, sort: egen tertile        = max(tertile_last)

	label define tertile 1 "Bottom" 2 "Middle" 3 "Top" 
	label val tertile tertile
	
	** Problem with this measure is that there are lots of cases where max_inc_ss_fam == 0
	** So the lowest quintile isn't made of households with the lowest permanent income
	* hist max_inc_ss_fam if wave == max_year & retired == 1, name("hist_max", replace)
	
	* Deal with people with no ss income
	replace tertile = 1 if max_inc_ss_head == 0 & educhead < 12
	replace tertile = 2 if max_inc_ss_head == 0 & educhead >= 12 & educhead < 16
	replace tertile = 3 if max_inc_ss_head == 0 & educhead >= 16

}

* Going forward, if we want to divide by max_inc_ss_fam quintiles, perhaps we drop households that retired young

* Note: when using this type of quintile, there's a very large increase in trips expenditure for the top quintile
*       food away from home also increases a bit
*       real blundell expenditure declines for quintiles 1-4, but remains flat for quintile 5
*       real blundell expenditure (in equivalence units) remains flat for the other quintiles, but goes up for quintile 5

****************************************************************************************************
** (3) Quintiles based on HEAD social security income in retirement
**     Only recorded for 2005 onwards, so when we compute stats by quintile, we exclude familes last 
**     observed before 2005
****************************************************************************************************

if $quintiles_definition == 3{
	xtile quintile_last         = inc_ss_head if wave == max_year & retired == 1 & inc_ss_head > 0, n(5)
	by pid, sort: egen quintile = max(quintile_last)

	** Problem with this measure is that there are lots of cases where inc_ss_head_last == 0
	** So the lowest quintile isn't made of households with the lowest permanent income
	* hist inc_ss_head if wave == max_year & retired == 1, name("hist_head", replace)
}

****************************************************************************************************
** (4) Quintiles based on wealth at time of retirement
****************************************************************************************************

if $quintiles_definition == 4{
	xtile quintile_last         = fam_wealth if retirement_transition == 1, n(5)
	by pid, sort: egen quintile = max(quintile_last)

	** Problem with this measure is that there are lots of cases where inc_ss_head_last == 0
	** So the lowest quintile isn't made of households with the lowest permanent income
	* hist fam_wealth if retirement_transition == 1, name("hist_wealth", replace)
}

label define quintile 1 "1 - Bottom Quintile" 2 "2" 3 "3" 4 "4" 5 "5 - Top Quintile"
label val quintile quintile
