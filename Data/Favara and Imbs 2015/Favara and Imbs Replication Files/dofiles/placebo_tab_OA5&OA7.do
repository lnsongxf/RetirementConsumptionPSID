	/**********************************************************************************************
	* Replication code for "Credit Supply and the Price of Housing", American Economic Review
	*
	* Distributed under copyright, Giovanni Favara and Jean Imbs, 2014 and the American 
	* Economic Association, 2014
	*
	* This code creates Tables OA5 & OA7 in the Paper
	***********************************************************************************************/ 
	
	** Define working directory 
	clear all 
	global 		data    "$main/data"
	global 		dofiles "$main/dofiles"
	global 		output  "$main/output"

	** load hmda data and other data for 1990-1994 period 
	use "$data/data_placebo_1990_1994.dta", clear
	
	** define control sets
	global D_control       "Dl_inc LDl_inc Dl_pop LDl_pop Dl_hpi LDl_hpi Dl_her_v LDl_her_v"
	global D_control_hp    "Dl_inc LDl_inc Dl_pop LDl_pop Dl_her_v LDl_her_v"


							********************************
							***        TABLE OA5 & OA7   ***
							********************************


	*** TAB 0A5
	*** PANEL A -- Commercial Banks
	foreach var in Dl_nloans_b Dl_vloans_b Dl_nden_b Dl_lir_b Dl_nsold_b {
	xtreg `var' Linter_bra $D_control L`var' yr*, fe cl(state_n)
	est store `var'
	}
	estout Dl_nloans_b Dl_vloans_b Dl_nden_b Dl_lir_b Dl_nsold_b using "$output/TabOA5_A.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl* ) legend  posthead("")  starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed) 
	*** PANEL B -- Placebo TFCU & IMC 
	foreach var in Dl_nloans_pl Dl_vloans_pl Dl_nden_pl Dl_lir_pl Dl_nsold_pl {
	xtreg `var' Linter_bra $D_control L`var' yr*, fe cl(state_n)
	est store `var'
	}
	estout Dl_nloans_pl Dl_vloans_pl Dl_nden_pl Dl_lir_pl Dl_nsold_pl using "$output/TabOA5_B.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl*) legend  posthead("")  starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed) 
	
	*** TAB OA7
	xtreg Dl_hpi Linter_bra yr* [aw=w1], fe cl(state_n) 
	est store hpi1
	xtreg Dl_hpi Linter_bra Linter_ela yr* [aw=w1], fe cl(state_n)
	est store hpi2
	xtreg Dl_hpi Linter_bra Linter_ela $D_control_hp  yr* [aw=w1], fe cl(state_n)
	est store hpi3
	estout hpi1 hpi2 hpi3 using "$output/TabOA7.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl*) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed)   
 

