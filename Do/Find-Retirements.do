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
gen retirement_transition        = retired_unambig == 1 & L.emp_status_head == 1 & (why_last_job_end == 4 | why_last_job_end == 0 | why_last_job_end == 9)

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
replace retirement_transition        = 0 if age < 50 | age > 70
replace retirement_transition_loose  = 0 if age < 50 | age > 70
replace retirement_transition_strict = 0 if age < 50 | age > 70

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

