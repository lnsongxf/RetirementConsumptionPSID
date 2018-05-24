
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
	by pid, sort: egen max_inc_ss_fam = max(inc_ss_fam_real)
	xtile quintile_last               = max_inc_ss_fam if wave == max_year & retired == 1, n(5)
	xtile tertile_last                = max_inc_ss_fam if wave == max_year & retired == 1, n(3)
	by pid, sort: egen quintile       = max(quintile_last)
	by pid, sort: egen tertile        = max(tertile_last)

	label define tertile 1 "Bottom" 2 "Middle" 3 "Top" 
	label val tertile tertile
	
	** Problem with this measure is that there are lots of cases where max_inc_ss_fam == 0
	** So the lowest quintile isn't made of households with the lowest permanent income
	* hist max_inc_ss_fam if wave == max_year & retired == 1, name("hist_max", replace)
	
	* TEMPORARY FIX
	* TODO: do something better with these people
	drop if max_inc_ss_fam == 0
	
	* by pid, sort: egen max_retired = max(retired)
	* sort pid wave
	* edit pid wave age sex_head retired inc_ss_fam inc_ss_head if max_retired == 1 & quintile == 1
	
	* Look into the people with 0 inc_ss_fam
	by pid, sort: egen max_age = max(age)
	sort pid wave
	tab max_age if retired == 1 & L.retired == 0 & max_inc_ss_fam == 0
	tab max_age if retired == 1 & L.retired == 0 & max_inc_ss_fam > 0
	
	* I think we're catching the young households in quintile 1
	* For instance, 65% of individuals with max_inc_ss_fam == 0 are last observed at age <= 62
	
	* The average person in quintile 1 retired at age 60
	* The average person in quintile 2-5 retired at age 63-64
	reg age i.quintile  if retired == 1 & L.retired == 0
	
	* The average person in quintile 1 is last observed at age 62
	* The average person in quintile 2-5 is last observed between 68-70
	reg max_age i.quintile  if retired == 1 & L.retired == 0

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
