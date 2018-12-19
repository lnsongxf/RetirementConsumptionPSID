	/**********************************************************************************************
	* Replication code for "Credit Supply and the Price of Housing", American Economic Review
	*
	* Distributed under copyright, Giovanni Favara and Jean Imbs, 2014 and the American 
	* Economic Association, 2014
	*
	* This code creates Tables OA3 & OA6 in the Paper Appendix
	***********************************************************************************************/ 
	
	
	** define working directory 
	clear all
	global 		data    "$main/data"
	global 		dofiles "$main/dofiles"
	global 		output  "$main/output"

	** load data 
	use "$data/hmda.dta", clear
	merge 1:1 county year using "$data/hp_dereg_controls.dta", nogen keep(1 3)
	merge 1:1 county year using "$data/call.dta", nogen keep(1 3)


	*** compute 3 year average 
	foreach var in Dl_nloans_b Dl_vloans_b  Dl_nden_b Dl_lir_b  Dl_nsold_b  ///
			Dl_nloans_pl Dl_vloans_pl Dl_nden_pl Dl_lir_pl  Dl_nsold_pl  ///
			Linter_bra Linter_ela Dl_hpi Dl_inc Dl_pop Dl_her_v {
			
			bysort county: egen avg_`var'1 = mean(`var') if year >1993 & year<1997
			bysort county: egen avg_`var'2 = mean(`var') if year >1996 & year<2000
			bysort county: egen avg_`var'3 = mean(`var') if year >1999 & year<2003
			bysort county: egen avg_`var'4 = mean(`var') if year >2002
			egen avg_`var' = rowtotal(avg_`var'*)
			drop avg_`var'?
			}


	** label var 
	label var avg_Dl_nloans_b "3-year avg. log change number of mortgage loans by commercial banks"
	label var avg_Dl_vloans_b "3-year avg. log change volume of mortgage loans by commercial banks"
	label var avg_Dl_nden_b "3-year avg. log change number of mortgages denied by commercial banks"
	label var avg_Dl_lir_b  "3-year avg. log change mortgage amount by commercial banks over IRS income"
	label var avg_Dl_nsold_b "3-year avg. log change number of mortgages sold by commercial banks"

	label var avg_Dl_nloans_pl "3-year avg. log change number of mortgage loans by commercial banks"
	label var avg_Dl_vloans_pl "3-year avg. log change volume of mortgage loans by commercial banks"
	label var avg_Dl_nden_pl "3-year avg. log change number of mortgages denied by commercial banks"
	label var avg_Dl_lir_pl  "3-year avg. log change mortgage amount by commercial banks over IRS income"
	label var avg_Dl_nsold_pl "3-year avg. log change number of mortgages sold by commercial banks"

	label var avg_Dl_her_v "3-year avg. log change HHI based on volume of mortgages originated"

	label var avg_Linter_bra "3-year avg. lagged Rice & Strahan deregulation index (4-)"
	label var avg_Linter_ela "3-year avg. interaction avg_Linter_bra & Saiz (2010) elasticity" 
	label var avg_Dl_hpi "3-year avg. log change house price index"
	label var avg_Dl_pop "3-year avg. log change population"
	label var avg_Dl_inc "3-year avg. log change income per capita"


	** indicator variable for a sample containing the same number of counties as in the yearly regressions
	gen sample = (Dl_hpi!=.) 	

	keep if year==1994 | year==1997 | year==2000 | year==2003 

	** define control variables
	global D_control_avg "avg_Dl_hpi avg_Dl_inc avg_Dl_pop avg_Dl_her_v" 
	global D_control_avg_hp "avg_Dl_inc avg_Dl_pop avg_Dl_her_v" 


	tsset county year
	gen period = 1 if year < 1997
	replace period =2 if year > 1996 
	replace period = 3 if year > 1999
	replace period = 4 if year > 2002
	tab period, g(pr)



	*** TAB OA3
	*** PANEL A -- Commercial Banks
	xtreg avg_Dl_nloans_b  Linter_bra  $D_control_avg pr*  if sample==1, fe cl(state_n)  
	est store norig
	xtreg avg_Dl_vloans_b  Linter_bra  $D_control_avg pr*  if sample==1, fe cl(state_n)  
	est store vol
	xtreg avg_Dl_nden_b  Linter_bra  $D_control_avg pr*  if sample==1, fe cl(state_n)  
	est store nden
	xtreg avg_Dl_lir_b  Linter_bra  $D_control_avg pr*  if sample==1, fe cl(state_n)  
	est store lir
	xtreg avg_Dl_nsold_b  Linter_bra  $D_control_avg pr*  if sample==1, fe cl(state_n)  
	est store nsold
	estout norig vol nden lir nsold using "$output/TabOA3_A.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-groups N-Clust Cluster R2-W )) ///
	 drop( _cons pr* o.pr* avg_Dl*) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed)   
	*** PANEL B -- Placebo
	xtreg avg_Dl_nloans_pl Linter_bra  $D_control_avg pr*  if sample==1, fe cl(state_n)  
	est store norig
	xtreg avg_Dl_vloans_pl  Linter_bra  $D_control_avg pr*  if sample==1, fe cl(state_n)  
	est store vol
	xtreg avg_Dl_nden_pl Linter_bra  $D_control_avg pr*  if sample==1, fe cl(state_n)  
	est store nden
	xtreg avg_Dl_lir_pl   Linter_bra  $D_control_avg pr*  if sample==1, fe cl(state_n)  
	est store lir
	xtreg avg_Dl_nsold_pl  Linter_bra  $D_control_avg pr* if sample==1, fe cl(state_n)  
	est store nsold
	estout norig vol nden lir nsold using "$output/TabOA3_B.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-proups N-Clust Cluster R2-W )) ///
	 drop(_cons pr* o.pr* avg_Dl*)  legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed)   

	*** TAB OA6
	xtreg avg_Dl_hpi Linter_bra pr*  if sample==1 [aw=w1], fe cl(state_n)  
	est store hpi1
	xtreg avg_Dl_hpi Linter_bra Linter_ela pr*  if sample==1 [aw=w1], fe cl(state_n)  
	est store hpi2
	xtreg avg_Dl_hpi Linter_bra Linter_ela $D_control_avg_hp pr*  if sample==1 [aw=w1], fe cl(state_n)  
	est store hpi3
	estout hpi1 hpi2 hpi3 using "$output/TabOA6.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-proups N-Clust Cluster R2-W )) ///
	 drop(_cons avg_* pr* o.pr*)  legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed)   





