****************************************************************************************************
** Construct household with same husband-wife over time
****************************************************************************************************

* Choose when to break the household
if $allow_kids_to_leave_hh == 1{
	* Blundell et al use fchg>1 to break the HH when there's a change in the head or spouse
	local fchg_cutoff 1

	* Note: by selecting fchg>1, we select all cases other than these:
	* 0 "No change; no movers-in or movers-out of the family"
	* 1 "Change in members other than Head or Spouse/Partner only"
	* (fchg>1 indicates that there has been some change in either the head or the spouse)
	* (there are only two exceptions: "other" and "underage splitoff child")

}
else{

	* If we want a more restrictive definition, we can break the HH when there's a change in any member:
	local fchg_cutoff 0 
}


* Drop cases where there's a change in family composition
sort pid wave
egen miny 		= min(wave), by(pid)
gen break_d 	= (fchg > `fchg_cutoff') // Blundell et al use (fchg>1) to break the HH when there's a change in the head or spouse
replace break_d	= 0 if wave==miny & break_d==1
tab break_d
drop if break_d == 1

gen change_other_than_spouse_or_head = (fchg == 1) if wave != miny
drop miny break_d

/*  Account for intermittent "headship" 
    (or missing from the panel from other reasons) 
    for the year after the change, bring back the family with new id */

sort pid wave
qby pid: gen dyear   = wave-wave[_n-1] // how many years in between
qby pid: gen break_d = (dyear>2 & dyear!=.) // break if more than 2 in between
qby pid: gen b_year  = wave if break_d == 1 // identify the break year
egen break_year      = min(b_year), by(pid) // identify the first break year
tab b_year

gen long_sample=0 			/* long_sample is equal to one for families which were broken and than put back in to the sample */ 
local ind=1
while `ind'>0 {
	sum pid
	local max_id        =	r(max) // find the largest currently existing pid
	count if wave       == break_year   /* for tracking */
	di r(N)						/* for tracking */ 
	replace pid         = pid + `max_id' if wave>=break_year // if wave is after a break, give it a new id
	replace long_sample = 1 if wave>break_year
	drop dyear break_d b_year break_year

	* Just like before, identify break years
	* Only difference is that now pid has changed
	* We're just doing this again because there might be 2+ breaks in the same family
	sort pid wave
	qby pid: gen dyear   = wave-wave[_n-1]
	qby pid: gen break_d = (dyear>2 & dyear!=.)
	qby pid: gen b_year  = wave if break_d == 1
	egen break_year      = min(b_year), by(pid)
	
	* Count how many breaks we've identified - if it's more than 0, we will continue
	count if break_d == 1
	local ind=r(N)
	di `ind'					/* for tracking */
}

/*  Drop observations with total net worth higher than 20M$ */ 
drop if fam_wealth >= 20000000 & fam_wealth!=.
xtset pid wave, delta(2) // specify that we have data every other year

drop if age >= 100
