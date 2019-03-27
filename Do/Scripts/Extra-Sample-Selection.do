* Follow some of the extra sample selection criteria in Blundell, Pistaferri, Saporta-Eksten AER 2012

* Following C:\Users\pedm\Documents\PhD\Blundell Pistaferri Saporta-Ekstein AER 2012 Replication Files\AER_2012_1549_data\prepare_bootstrap.do

* When calculating the relevant consumption, hourly wage, and earnings moments,
* we do not use data displaying extreme “jumps” from one year to the next (most
* likely due to measurement error). A “jump” is defined as an extremely positive
* (negative) change from  t − 2  to  t  , followed by an extreme negative
* (positive) change from  t   to  t + 2 . Formally, for each variable (say  x),
* we construct the biennial log difference   Δ2 log(x t), and drop the
* relevant variables for observation in the bottom 0.25 percent of the product
* Δ2 log(xt) * Δ2 log(xt−2). 

* Furthermore, we do not use earnings and wage
* data when the implied hourly wage is below one-half of the state minimum wage.
* https://pubs.aeaweb.org/doi/pdfplus/10.1257/aer.20121549


/* Replace the extreme jumps with missing values */ 
global pec_drop     = 0.25		 
* global pec_drop     = 1

tsset pid wave
local npec = 100/${pec_drop}
di `npec'

/* 	Generate the first difference for logs and the interaction between first difference and lagged first difference (which would be large in absolute value 
	for large values of transitory shocks or for measurement error */ 

* We want to do this for consumption, hourly wage, and earnings
* local varlist_where_to_remove_jumps log_* // Original in Blundell et al

* We do this for log_consumption and log_income
local varlist_where_to_remove_jumps log_consumption log_income

foreach var of varlist `varlist_where_to_remove_jumps' {
	gen d_`var' = `var' - l2.`var'
	gen d_`var'_lag = d_`var'*l2.d_`var'
}

sum d_log_consumption d_log_income, det

/* Generate percentiles of the interacted difference by year */ 
foreach var of varlist d_*_lag {
	di "Look for jumps in `var'"
	egen pec_`var'=  xtile(`var'), by(wave) n(`npec') 
}

/* Assign missing values for the variable with the potential measurement error  */ 
foreach var of varlist `varlist_where_to_remove_jumps'  {
	replace `var'=. if f2.pec_d_`var'_lag==1 	/* 	assigning missing values to the year with the jump */ 
}

/* Check the new distribution of the interacted lag */ 
foreach var of varlist `varlist_where_to_remove_jumps' {
	gen d_`var'_trunc = `var' - l2.`var'
	gen d_`var'_trunc_lag = d_`var'_trunc*l2.d_`var'_trunc
}
su d_*_lag
drop d_* pec_*

foreach var of varlist `varlist_where_to_remove_jumps' {
	gen d_`var' = `var' - l2.`var'
	gen d_`var'_lag = d_`var'*l2.d_`var'
}
sum d_log_consumption d_log_income, det
drop d_*

* replace log_w = . if log_y==. 
* replace log_y = . if log_w==. 

* replace log_ww = . if log_yw==. 
* replace log_yw = . if log_ww==. 

sum `varlist_where_to_remove_jumps', det

tsset pid wave, delta(2)
