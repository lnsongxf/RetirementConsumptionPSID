****************************************************************************************************
** Define ret_duration
****************************************************************************************************

if $ret_duration_definition == 1{
	** Here retirement year is defined based on whether they have been out of the labor force for more than 12 months
	gen generated_ret_year_               = wave if (month + months_out_lab_force <= 12) & retirement_transition == 1
	replace generated_ret_year_           = wave - 1 if (month + months_out_lab_force > 12) & retirement_transition == 1
	by pid, sort: egen generated_ret_year = max(generated_ret_year_)
	gen ret_duration                      = wave - generated_ret_year
}

if $ret_duration_definition == 2{
	** Here retirement year is defined as self reported retirement year
	gen generated_ret_year_               = wave if retirement_transition == 1
	by pid, sort: egen generated_ret_year = max(generated_ret_year_)
	gen ret_duration                      = wave - generated_ret_year
}

if $ret_duration_definition == 3{
	** Here retirement year is defined as the first survey wave where they say they are retired
	** (though I exclude cases where the self reported ret_year is far from the observed transition)
	gen generated_ret_year_               = ret_year if retirement_transition == 1 & (wave - ret_year) <= 3
	by pid, sort: egen generated_ret_year = max(generated_ret_year_)
	gen ret_duration                      = wave - generated_ret_year
}
