****************************************************************************************************
** Look for well defined retirement transitions
** (Here I just look at the head's retirement)
****************************************************************************************************
xtset pid wave, delta(2) // specify that we have data every other year

* Look for those who are unambiguously retired this year
* Necessary because lots of people are retired but also working now, looking for work, or disabled
* tab emp_status_head_2 if emp_status_head  == 4
gen retired_unambig = emp_status_head == 4 & (emp_status_head_2 != 1 & emp_status_head_2 != 2 & emp_status_head_2 != 3 & emp_status_head_2 != 5) ///
										   & (emp_status_head_3 != 1 & emp_status_head_3 != 2 & emp_status_head_3 != 3 & emp_status_head_3 != 5)

* Currently retired and previously employed
gen retirement_transition_loose  = retired_unambig == 1 & L.emp_status_head == 1

* Currently retired, previously employed, and last job ended due to "Quit, Resigned, Retire" or "Inap." or "NA"
gen retirement_transition        = retired_unambig == 1 & L.emp_status_head == 1 & (why_last_job_end == 4 | why_last_job_end == 0 | why_last_job_end == 9 | why_last_job_end == 7)

* Currently retired, previously employed, and quit last job due to "Quit, Resigned, Retire"
* WARNING: lots of people just have "Inap." for why_last_job_end
gen retirement_transition_strict = retired_unambig == 1 & L.emp_status_head == 1 & why_last_job_end == 4 

* Look for people who go back to work after having a year of retirement
gen back_to_work_                = emp_status_head == 1 & L.emp_status_head == 4
by pid, sort: egen back_to_work  = max(back_to_work_)
drop back_to_work_

* Replace all retirement transitions with zero if they go back to work
replace retirement_transition        = 0 if back_to_work == 1
replace retirement_transition_loose  = 0 if back_to_work == 1
replace retirement_transition_strict = 0 if back_to_work == 1

* Replace all retirement transitions with zero if outside of 50 - 70 age range (following Hurd and Rohwedder)
* Pat Note: I expanded to age 80, just in case it gives us more observations
replace retirement_transition        = 0 if age < 50 | age > 80
replace retirement_transition_loose  = 0 if age < 50 | age > 80
replace retirement_transition_strict = 0 if age < 50 | age > 80

****************************************************************************************************
** Choose an alternative measure of retirement
****************************************************************************************************

* Loose
if $retirement_definition == 1{
	drop retirement_transition
	rename retirement_transition_loose retirement_transition
}

* Strict
if $retirement_definition == 2{
	drop retirement_transition
	rename retirement_transition_strict retirement_transition
}

****************************************************************************************************
** Look into the difference between observed retirement and reported retirement
****************************************************************************************************

* gen ret_year_computed = wave if retirement_transition == 1 
* tab ret_year ret_year_computed

* Look at difference in self reported retirement year and the wave that they are first observed retired 
* NOTE: any value < -2 is suspicious!
replace ret_year = wave if retirement_transition == 1 & ret_year >= 9997
gen dif          = ret_year - wave if retirement_transition == 1 
* It's worrisome that some people have a ret_year so much earlier than the year they are listed as retiring
* tab dif
* TODO: try dropping families for which dif <= -3

****************************************************************************************************
** Show retirement
****************************************************************************************************

* Flag anyone after a retirement transition
gen retired = 1 if retirement_transition == 1
replace retired = 1 if L.retired == 1
replace retired = 0 if retired == .

* by pid, sort: egen max_retired = max(retired)
* edit pid wave retirement_transition retired inc_ss_fam inc_ss_head if max_r == 1


** PART B
****************************************************************************************************
* RETIREMENT TRANSITIONS FOR SPOUSES 
****************************************************************************************************
xtset pid wave, delta(2) // specify that we have data every other year

* Looking for those who are unambiguously retired this year
* Necessary because lots of people are retired but also working now, looking for work, or disabled
* tab emp_status_head_2 if emp_status_head  == 4
gen retired_unambig_spouse = emp_status_spouse == 4 & (emp_status_spouse_2 != 1 & emp_status_spouse_2 != 2 & emp_status_spouse_2 != 3 & emp_status_spouse_2 != 5) ///
										   & (emp_status_spouse_3 != 1 & emp_status_spouse_3 != 2 & emp_status_spouse_3 != 3 & emp_status_spouse_3 != 5)

* Currently retired and previously employed
gen retirement_transition_loose_s  = retired_unambig_spouse == 1 & L.emp_status_spouse == 1

* Currently retired, previously employed, and last job ended due to "Quit, Resigned, Retire" or "Inap." or "NA"
gen retirement_transition_spouse       = retired_unambig_spouse == 1 & L.emp_status_spouse == 1 & (why_last_job_end_spouse == 4 | why_last_job_end_spouse == 0 | why_last_job_end_spouse == 9 | why_last_job_end_spouse == 7)

* Currently retired, previously employed, and quit last job due to "Quit, Resigned, Retire"
* WARNING: lots of people just have "Inap." for why_last_job_end
gen retirement_transition_strict_s = retired_unambig_spouse == 1 & L.emp_status_spouse == 1 & why_last_job_end_spouse == 4 

* Look for people who go back to work after having a year of retirement
gen back_to_work_sp              = emp_status_spouse == 1 & L.emp_status_spouse == 4
by pid, sort: egen back_to_work_spouse  = max(back_to_work_sp)
drop back_to_work_sp

* Replace all retirement transitions with zero if they go back to work
replace retirement_transition_spouse        = 0 if back_to_work_spouse == 1
replace retirement_transition_loose_s  = 0 if back_to_work_spouse == 1
replace retirement_transition_strict_s = 0 if back_to_work_spouse == 1

* Replace all retirement transitions with zero if outside of 50 - 70 age range (following Hurd and Rohwedder)
* Pat Note: I expanded to age 80, just in case it gives us more observations
replace retirement_transition_spouse        = 0 //if age < 50 | age > 80
replace retirement_transition_loose_s  = 0 //if age < 50 | age > 80
replace retirement_transition_strict_s = 0 //if age < 50 | age > 80

****************************************************************************************************
** Choose an alternative measure of retirement
****************************************************************************************************

* Loose
if $retirement_definition_spouse == 1 {
	drop retirement_transition_spouse
	rename retirement_transition_loose_s retirement_transition_spouse
}

* Strict
if $retirement_definition_spouse == 2{
	drop retirement_transition_spouse
	rename retirement_transition_strict_s retirement_transition_spouse
}

****************************************************************************************************
** Look into the difference between observed retirement and reported retirement
****************************************************************************************************

* gen ret_year_computed = wave if retirement_transition == 1 
* tab ret_year ret_year_computed

* Look at difference in self reported retirement year and the wave that they are first observed retired 
* NOTE: any value < -2 is suspicious!
replace ret_year_spouse = wave if retirement_transition_spouse == 1 & ret_year >= 9997
gen diff          = ret_year_spouse - wave if retirement_transition_spouse == 1 
* It's worrisome that some people have a ret_year so much earlier than the year they are listed as retiring
* tab dif
* TODO: try dropping families for which dif <= -3

****************************************************************************************************
** Show retirement
** Is retired only for head and not for spouse
****************************************************************************************************

* Flag anyone after a retirement transition
gen retired_spouse = 1 if retirement_transition_spouse == 1
replace retired_spouse = 1 if L.retired_spouse == 1
replace retired_spouse = 0 if retired == .

* by pid, sort: egen max_retired = max(retired)
* edit pid wave retirement_transition retired inc_ss_fam inc_ss_head if max_r == 1

****************************************************************************************************
** Partners retirement status
****************************************************************************************************

	* find hhs where spouse never works
	* only keep the retirement transitions for those people
	* aka set retirement_transition == .

if $how_to_deal_with_spouse == 1{
	** 	option 1: Spouse never works during observed sample period
	gen not_working_spouse = ( emp_status_spouse != 1 & emp_status_spouse_2 != 1 & emp_status_spouse_3 != 1 ) 
	by pid, sort: egen never_work_spouse = min(not_working_spouse)
	
	replace retirement_transition = retirement_transition * never_work_spouse //

 * todo: change def of never works 
 * by pid, sort: egen ... 
 
 ** So, the above defination, a person never works if:
 ** the person never retired, is not working now, person is not on temporary leave or maternity leave, is not looking for work and the person is not disabled.)	
}

if $how_to_deal_with_spouse == 2{
**  option: 2 Spouse always works
	gen spouse_working = ( emp_status_spouse == 1 | emp_status_spouse_2 == 1 | emp_status_spouse_3 == 1 ) // by wave and HH
	by pid, sort: egen always_work_spouse = min(spouse_working) // by HH (if they have a single wave not working, this var will be zero)
	
	*							& (emp_status_spouse_2 != 2 & emp_status_spouse_2 != 3 & emp_status_spouse_2 != 4 & emp_status_spouse_2 != 5) ///
	*							& (emp_status_spouse_3 != 2 & emp_status_spouse_3 != 3 & emp_status_spouse_3 != 4 & emp_status_spouse_3 != 5)	
	
	* Modify our definition of retirement_transition
	* Will now be zero if spouse does not always work
	replace retirement_transition = retirement_transition * always_work_spouse // if single period not working, make retirement transition 0
	}
	
if $how_to_deal_with_spouse == 3{
*		option 3: Spouse has same* retirement transition *for +/- one wave

		* will use retirement_transition_spouse
		rename retirement_transition retirement_transition_head
		gen retirement_transition = retirement_transition_head if ( L.retirement_transition_spouse == 1 | retirement_transition_spouse == 1 | F.retirement_transition_spouse == 1 )
		replace retirement_transition = 0 if retirement_transition == .
		* produce retirement transition for the household
		
		tab retirement_transition retirement_transition_head

		}
	
if $how_to_deal_with_spouse == 4{
*		option 4: Spouse has a different retirement transition
		// replace ret_year_spouse = wave if retirement_transition_spouse == 1 & ret_year >= 9997
		// gen diff = ret_year_spouse - wave if retirement_transition_spouse == 1 
		rename retirement_transition retirement_transition_head
		gen retirement_transition = retirement_transition_head if ( L.retirement_transition_spouse != 1 & retirement_transition_spouse != 1 & F.retirement_transition_spouse != 1 )
		replace retirement_transition = 0 if retirement_transition == .
		
		tab retirement_transition retirement_transition_head
		}
	
		
if $how_to_deal_with_spouse == 5{
*		5 option: ignore the spouse (keep doing what we currently do)
		* no need to modify retirement_transition b/c we already defined it for the head
}
*	- Five versions:
*		- Spouse never works (currently)
*		- Spouse always works
*		- Spouse has same* retirement transition *for +/- one wave
*		- Spouse has a different retirement transition
*		- 5 option: ignore the spouse (keep doing what we currently do)

/* Total expenditure for each each tertile
* total expenditure by social security income - 3 tertiles







