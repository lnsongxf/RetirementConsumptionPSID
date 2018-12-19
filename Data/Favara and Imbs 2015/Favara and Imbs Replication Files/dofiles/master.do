	/**********************************************************************************************
	* Replication code for "Credit Supply and the Price of Housing", American Economic Review
	*
	* Distributed under copyright, Giovanni Favara and Jean Imbs, 2014 and the American 
	* Economic Association, 2014
	*
	* This code creates Tables 1-6 and Figure 1-4 in the Paper, as well as Tables A1-A4 
	* in the Paper Appendix, and Tables OA2-OA8 in the on line web Appendix
	***********************************************************************************************/ 
	
	
	** Define working directory 
	clear all
	global 		main    "/cm/giovanni/Final_AER2"
	global 		data    "$main/data"
	global 		dofiles "$main/dofiles"
	global 		output  "$main/output"

	
	***********************************************************************************************
	*      TABLE 1            								     **
	***********************************************************************************************

	do "$dofiles/tab_1.do"  


	***********************************************************************************************
	*      TABLE 2 & 3       								     **
	***********************************************************************************************
	
	** load data 
	 
	use "$data/hmda.dta", clear
	merge 1:1 county year using "$data/hp_dereg_controls.dta", nogen keep(1 3)
	merge 1:1 county year using "$data/call.dta", nogen keep(1 3)
	
	** define controls 
	global D_control       "Dl_inc LDl_inc Dl_pop LDl_pop Dl_hpi LDl_hpi Dl_her_v LDl_her_v"
	global D_control_hp    "Dl_inc LDl_inc Dl_pop LDl_pop Dl_her_v LDl_her_v"
	global B_control        " etoa_b liatoa_b totltoa_b "
	
		
	** TABLE 2
	** PANEL A -- BANKS 
	foreach var in Dl_nloans_b Dl_vloans_b Dl_nden_b Dl_lir_b  Dl_nsold_b {
	xtreg `var' Linter_bra $D_control L`var' yr*, fe cl(state_n)
	est store `var'
	}
	estout Dl_nloans_b Dl_vloans_b Dl_nden_b Dl_lir_b  Dl_nsold_b using "$output/Tab2_A.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl* ) legend  posthead("")  starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed) 
	** PANEL B -- Placebo TFCU & IMC 
	foreach var in Dl_nloans_pl Dl_vloans_pl Dl_nden_pl Dl_lir_pl  Dl_nsold_pl {
	xtreg `var' Linter_bra $D_control L`var' yr*, fe cl(state_n)
	est store `var'
	}
	estout Dl_nloans_pl Dl_vloans_pl Dl_nden_pl Dl_lir_pl  Dl_nsold_pl using "$output/Tab2_B.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl*) legend  posthead("")  starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed) 


	** TABLE 3 
	** PANEL A -- Out-of-state banks with local branches 
	foreach var in Dl_nloans_b_oos_lb Dl_vloans_b_oos_lb Dl_nden_b_oos_lb Dl_lir_b_oos_lb  Dl_nsold_b_oos_lb Dl_nbra_oos_lb {
	xtreg `var' Linter_bra $D_control L`var' yr*, fe cl(state_n)
	est store `var'
	}
	estout Dl_nloans_b_oos_lb Dl_vloans_b_oos_lb Dl_nden_b_oos_lb Dl_lir_b_oos_lb  Dl_nsold_b_oos_lb Dl_nbra_oos_lb using "$output/Tab3_A.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl* ) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed) 
	** PANEL B -- Out of state banks with no local branches 
	foreach var in Dl_nloans_b_oos Dl_vloans_b_oos Dl_nden_b_oos Dl_lir_b_oos  Dl_nsold_b_oos {
	xtreg `var' Linter_bra $D_control L`var' yr*, fe cl(state_n)
	est store `var'
	}
	estout Dl_nloans_b_oos Dl_vloans_b_oos Dl_nden_b_oos Dl_lir_b_oos  Dl_nsold_b_oos using "$output/Tab3_B.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl*) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed)  
	** PANEL C -- In-state banks 
	foreach var in Dl_nloans_b_is Dl_vloans_b_is Dl_nden_b_is Dl_lir_b_is  Dl_nsold_b_is Dl_nbra_is {
	xtreg `var' Linter_bra $D_control L`var' yr*, fe cl(state_n)
	est store `var'
	}
	estout Dl_nloans_b_is Dl_vloans_b_is Dl_nden_b_is Dl_lir_b_is  Dl_nsold_b_is Dl_nbra_is using "$output/Tab3_C.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl*) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed)   
	 
	

	***********************************************************************************************
	**       TABLE 4 & 5         								     **
	***********************************************************************************************
	
	** TABLE 4  
	xtreg Dl_hpi Linter_bra yr* [aw=w1] , fe cl(state_n) 
	est store hpi1
	xtreg Dl_hpi Linter_bra Linter_ela yr* [aw=w1] , fe cl(state_n) 
	est store hpi2
	xtreg Dl_hpi Linter_bra Linter_ela LDl_hpi $D_control_hp yr* [aw=w1] , fe cl(state_n) 
	est store hpi3
	xtreg Dl_hsosf Linter_bra Linter_inela yr* [aw=w1] , fe cl(state_n) 
	est store hs1
	xtreg Dl_hsosf Linter_bra Linter_inela LDl_hsosf $D_control_hp yr* [aw=w1] , fe cl(state_n) 
	est store hs2
	estout hpi1 hpi2 hpi3 hs1 hs2 using "$output/Tab4.txt", replace ///
		cells(b(star fmt(%9.5f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Counties N-Clust Cluster R2)) ///
		drop(yr* o.yr* _cons) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) varwidth(16) ///
		modelwidth(12) delimiter("") style(fixed) 
	
	** TABLE 5  
	xtivreg2 Dl_hpi (Dl_nloans_b = Linter_bra) LDl_hpi  $D_control_hp yr* [aw=w1], fe r bw(3) partial(yr*)  
	est store Dl_nloans_b
	xtivreg2 Dl_hpi (Dl_vloans_b = Linter_bra) LDl_hpi  $D_control_hp yr* [aw=w1], fe r bw(3) partial(yr*)  
	est store Dl_vloans_b
	xtivreg2 Dl_hpi (Dl_lir_b  = Linter_bra) LDl_hpi  $D_control_hp yr* [aw=w1], fe r bw(3) partial(yr*)  
	est store Dl_lir_b 
	estout Dl_nloans_b Dl_vloans_b  Dl_lir_b  using "$output/Tab5.txt", replace ///
		cells(b(star fmt(%9.5f)) se(par)) stats(N N_g N_clust clustvar idp widstat archi2p, fmt(%9.0f %9.0g) labels(Obs N-Counties N-Clust Cluster Upvl F Cpvl )) ///
		drop() legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) varwidth(16) ///
		modelwidth(12) delimiter("") style(fixed) 



	***********************************************************************************************
	**     TABLE 6         									     **
	***********************************************************************************************
	
	** TABLE 6
	** PANEL A 
	xtreg ifireltomtg_b Linter_bra $B_control $D_control yr*, fe cl(state_n)
	est store ifireltomtg_b
	xtreg roa_b Linter_bra $B_control $D_control yr* , fe cl(state_n)
	est store roa_b
	xtreg iodtototd_b Linter_bra $B_control $D_control yr*, fe cl(state_n)
	est store iodtototd_b
	xtreg nplrel_b Linter_bra $B_control $D_control yr*, fe cl(state_n)
	est store nplrel_b
	xtreg Dl_totd_b Linter_bra $B_control $D_control yr* LDl_totd_b, fe cl(state_n)
	est store Dl_totd_b
	estout ifireltomtg_b roa_b iodtototd_b nplrel_b Dl_totd_b using "$output/Tab6_A.txt", replace ///
		cells(b(star fmt(%9.5f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Counties N-Clust Cluster R2-W )) ///
		drop(_cons yr* o.yr* LDl* Dl_inc Dl_pop Dl_hpi Dl_her_v tot* lia* etoa*) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) varwidth(16) ///
		modelwidth(12) delimiter("") style(fixed)  
	** PANEL B
	xtreg ifireltomtg_b Linter_bra $B_control $D_control yr* if border==1, fe cl(state_n)
	est store ifireltomtg_b
	xtreg roa_b Linter_bra $B_control $D_control yr*  if border==1, fe cl(state_n)
	est store roa_b
	xtreg iodtototd_b Linter_bra $B_control $D_control yr*  if border==1, fe cl(state_n)
	est store iodtototd_b
	xtreg nplrel_b Linter_bra $B_control $D_control yr*  if border==1, fe cl(state_n)
	est store nplrel_b
	xtreg Dl_totd_b Linter_bra $B_control $D_control yr* LDl_totd_b  if border==1, fe cl(state_n)
	est store Dl_totd_b
		estout ifireltomtg_b roa_b iodtototd_b nplrel_b Dl_totd_b using "$output/Tab6_B.txt", replace ///
		cells(b(star fmt(%9.5f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Counties N-Clust Cluster R2-W )) ///
		drop(_cons yr* o.yr* LDl* Dl_inc Dl_pop Dl_hpi Dl_her_v tot* lia* etoa*) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) varwidth(16) ///
		modelwidth(12) delimiter("") style(fixed) 




	***********************************************************************************************
	**     FIGURE 1 AND 3          								     **
	***********************************************************************************************

	do "$dofiles/irf_fig_1&3.do"
    

	***********************************************************************************************
	**     FIGURE 2 AND 4          								     **
	***********************************************************************************************

	do "$dofiles/aggregation_fig_2&4.do"
    
    





	***********************************************************************************************
	** 							     				     **
	** 					PAPER APPENDIX 		             		     **
	**							     				     **
	***********************************************************************************************

	
	***********************************************************************************************
	**     TABLE A1 & A2       								     **
	***********************************************************************************************

	use "$data/hmda.dta", clear
	merge 1:1 county year using "$data/hp_dereg_controls.dta", nogen keep(1 3)
	merge 1:1 county year using "$data/call.dta", nogen keep(1 3)
	
	** define controls 
	global D_control       "Dl_inc LDl_inc Dl_pop LDl_pop Dl_hpi LDl_hpi Dl_her_v LDl_her_v"
	global D_control_hp    "Dl_inc LDl_inc Dl_pop LDl_pop Dl_her_v LDl_her_v"
	global B_control        " etoa_b liatoa_b totltoa_b " 
	
	** TABLE A1 
	** PANEL A -- Commercial Banks 
	foreach var in Dl_nloans_b Dl_vloans_b Dl_nden_b Dl_lir_b  Dl_nsold_b {
	xtreg `var' Linter_bra $D_control L`var' yr* if border==1 , fe cl(state_n)
	est store `var'
	}
	estout Dl_nloans_b Dl_vloans_b Dl_nden_b Dl_lir_b  Dl_nsold_b using "$output/TabA1_A.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2, fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl* ) legend  posthead("")  starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed) 
	** PANEL B -- Placebo TFCU & IMC 
	foreach var in Dl_nloans_pl Dl_vloans_pl Dl_nden_pl Dl_lir_pl  Dl_nsold_pl {
	xtreg `var' Linter_bra $D_control L`var' yr* if border==1, fe cl(state_n)
	est store `var'
	}
	estout Dl_nloans_pl Dl_vloans_pl Dl_nden_pl Dl_lir_pl  Dl_nsold_pl using "$output/TabA1_B.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl*) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed) 


	** TABLE A2 
	** PANEL A -- Out-of-state banks with local branches 
	foreach var in Dl_nloans_b_oos_lb Dl_vloans_b_oos_lb Dl_nden_b_oos_lb Dl_lir_b_oos_lb  Dl_nsold_b_oos_lb Dl_nbra_oos_lb {
	xtreg `var' Linter_bra $D_control L`var' yr* if border==1, fe cl(state_n)
	est store `var'
	}
	estout Dl_nloans_b_oos_lb Dl_vloans_b_oos_lb Dl_nden_b_oos_lb Dl_lir_b_oos_lb  Dl_nsold_b_oos_lb Dl_nbra_oos_lb using "$output/TabA2_A.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl* ) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed) 
	** PANEL B -- Out-of-state banks with no local branches 
	foreach var in Dl_nloans_b_oos Dl_vloans_b_oos Dl_nden_b_oos Dl_lir_b_oos  Dl_nsold_b_oos {
	xtreg `var' Linter_bra $D_control L`var' yr* if border==1, fe cl(state_n)
	est store `var'
	}
	estout Dl_nloans_b_oos Dl_vloans_b_oos Dl_nden_b_oos Dl_lir_b_oos  Dl_nsold_b_oos using "$output/TabA2_B.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl*) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed) 
	** PANEL C -- In-state banks 
	foreach var in Dl_nloans_b_is Dl_vloans_b_is Dl_nden_b_is Dl_lir_b_is  Dl_nsold_b_is Dl_nbra_is {
	xtreg `var' Linter_bra $D_control L`var' yr* if border==1, fe cl(state_n)
	est store `var'
	}
	estout Dl_nloans_b_is Dl_vloans_b_is Dl_nden_b_is Dl_lir_b_is  Dl_nsold_b_is Dl_nbra_is using "$output/TabA2_C.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl*) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed)   
	
	
	***********************************************************************************************
	**     TABLE A3 & A4       								     **
	***********************************************************************************************

	** TABLE A3 
	xtreg Dl_hpi Linter_bra yr* [aw=w1] if border==1, fe cl(state_n) 
	est store hpi1
	xtreg Dl_hpi Linter_bra Linter_ela yr* [aw=w1] if border==1, fe cl(state_n) 
	est store hpi2
	xtreg Dl_hpi Linter_bra Linter_ela LDl_hpi $D_control_hp yr* [aw=w1] if border==1, fe cl(state_n) 
	est store hpi3
	xtreg Dl_hsosf Linter_bra Linter_inela yr* [aw=w1] if border==1, fe cl(state_n) 
	est store hs1
	xtreg Dl_hsosf Linter_bra Linter_inela LDl_hsosf $D_control_hp yr* [aw=w1] if border==1, fe cl(state_n) 
	est store hs2
	estout hpi1 hpi2 hpi3 hs1 hs2 using "$output/TabA3.txt", replace ///
   	 cells(b(star fmt(%9.5f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Counties N-Clust Cluster R2)) ///
	 drop(yr* o.yr* _cons) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) varwidth(16) ///
	 modelwidth(12) delimiter("") style(fixed) 
	 
	** TABLE A4 	
	xtivreg2 Dl_hpi (Dl_nloans_b = Linter_bra) LDl_hpi  $D_control_hp yr* [aw=w1] if border==1, fe r bw(3) partial(yr*)  
	est store Dl_nloans_b
	xtivreg2 Dl_hpi (Dl_vloans_b = Linter_bra) LDl_hpi  $D_control_hp yr* [aw=w1] if border==1, fe r bw(3) partial(yr*)  
	est store Dl_vloans_b
	xtivreg2 Dl_hpi (Dl_lir_b  = Linter_bra) LDl_hpi  $D_control_hp yr* [aw=w1] if border==1, fe r bw(3) partial(yr*)  
	est store Dl_lir_b 
	estout Dl_nloans_b Dl_vloans_b Dl_lir_b  using "$output/TabA4.txt", replace ///
	  cells(b(star fmt(%9.5f)) se(par)) stats(N N_g N_clust clustvar idp widstat cstatp , fmt(%9.0f %9.0g) labels(Obs N-Counties N-Clust Cluster Upvl F Cpvl )) ///
	  drop() legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) varwidth(16) ///
	  modelwidth(12) delimiter("") style(fixed)    

	
	
	
	
	
	***********************************************************************************************
	** 							     			             **
	** 			ONLINE APPENDIX 	             				     **
	**							     				     **
	***********************************************************************************************
	
	
	***********************************************************************************************
	**     TABLE OA2           								     **
	***********************************************************************************************
		
	** TABLE OA2
	** FULL SAMPLE 
	** DEFINE ESTIMATION SAMPLE
	xtreg Dl_nloans_b Linter_bra yr* $D_control LDl_nloans_b, fe cl(state_n) 
	gen fullsample = e(sample)

	** Banks 
	tabstat Dl_nloans_b Dl_vloans_b Dl_nden_b Dl_lir_b  Dl_nsold_b if fullsample==1, stats(mean sd p10 p90 n)  col(stat)
	** Placebo Lenders (TFCU and CU)
	tabstat Dl_nloans_pl Dl_vloans_pl Dl_nden_pl Dl_lir_pl  Dl_nsold_pl if fullsample==1, stats(mean sd p10 p90 n)  col(stat) 
	** Out-of-state banks with local branches 
	tabstat Dl_nloans_b_oos_lb Dl_vloans_b_oos_lb Dl_nden_b_oos_lb Dl_lir_b_oos_lb  Dl_nsold_b_oos_lb if fullsample==1, stats(mean sd p10 p90 n)  c(s) 
	** Out-of-state banks with no branches
	tabstat Dl_nloans_b_oos Dl_vloans_b_oos Dl_nden_b_oos Dl_lir_b_oos  Dl_nsold_b_oos if fullsample==1, stats(mean sd p10 p90 n)  c(s) 
	** In-state banks 
	tabstat Dl_nloans_b_is Dl_vloans_b_is Dl_nden_b_is Dl_lir_b_is  Dl_nsold_b_is if fullsample==1, stats(mean sd p10 p90 n)  c(s) 
	** Herfindhal index and call report variable 
	tabstat Dl_her_v ifireltomtg_b  roa_b nplrel_b iodtototd_b Dl_totd_b if fullsample==1, stats(mean sd p10 p90 n)  c(s) 
	** Other variables 
	tabstat Dl_hpi Dl_hsosf Dl_inc Dl_pop Linter_bra elast if fullsample ==1, stats(mean sd p10 p90 n) columns(statistics)
	
	** SAMPLE OF CONTIGUOUS COUNTIES 
	** define estimation sample 
	xtreg Dl_nloans_b Linter_bra yr* $D_control LDl_nloans_b if border==1, fe cl(state_n) 
	gen bordersample = e(sample)
	
	** Banks 
	tabstat Dl_nloans_b Dl_vloans_b Dl_nden_b Dl_lir_b  Dl_nsold_b if bordersample==1, stats(mean sd p10 p90 n)  col(stat)
	** Placebo lenders 
	tabstat Dl_nloans_pl Dl_vloans_pl Dl_nden_pl Dl_lir_pl  Dl_nsold_pl if bordersample==1, stats(mean sd p10 p90 n)  col(stat) 
	** Out-of-state banks with local branches 
	tabstat Dl_nloans_b_oos_lb Dl_vloans_b_oos_lb Dl_nden_b_oos_lb Dl_lir_b_oos_lb  Dl_nsold_b_oos_lb if bordersample==1, stats(mean sd p10 p90 n)  c(s) 
	** Out-of-state banks with no branches
	tabstat Dl_nloans_b_oos Dl_vloans_b_oos Dl_nden_b_oos Dl_lir_b_oos  Dl_nsold_b_oos if bordersample==1, stats(mean sd p10 p90 n)  c(s) 
	** In-state banks  
	tabstat Dl_nloans_b_is Dl_vloans_b_is Dl_nden_b_is Dl_lir_b_is  Dl_nsold_b_is if bordersample==1, stats(mean sd p10 p90 n)  c(s) 
	** Herfindhal and call report variable 
	tabstat Dl_her_v ifireltomtg_b  roa_b nplrel_b iodtototd_b Dl_totd_b if bordersample==1, stats(mean sd p10 p90 n)  c(s) 
	** Other variables 
	tabstat Dl_hpi Dl_hsosf Dl_inc Dl_pop Linter_bra elast if bordersample ==1, stats(mean sd p10 p90 n) columns(statistics)


	
	***********************************************************************************************
	**     TABLE OA3 & OA6     								     **
	***********************************************************************************************
	
        do "$dofiles/3yr_avg_tab_OA3&OA6.do" 

	
	***********************************************************************************************
	**     TABLE OA4         								     **
	***********************************************************************************************

	** TABLE OA4 ***
	use "$data/hmda.dta", clear
	merge 1:1 county year using "$data/hp_dereg_controls.dta", nogen keep(1 3)
	merge 1:1 county year using "$data/call.dta", nogen keep(1 3)
		
	xi, prefix(yr) i.yeard 
	forvalues y =1997/2004 {
	gen deregXyear_`y' = Linter_bra*yryeard_`y'
	}
	xi: xtreg Dl_nloans_b i.year deregXyear_* , fe cl(state_n)
	est store orig
	xi: xtreg Dl_vloans_b i.year deregXyear_* , fe cl(state_n)
	est store vol
	xi: xtreg Dl_lir_b  i.year deregXyear_* , fe cl(state_n)
	est store lir
	xi: xtreg Dl_nloans_b i.year deregXyear_* if border==1 , fe cl(state_n)
	est store orig_bor
	xi: xtreg Dl_vloans_b i.year deregXyear_* if border==1 , fe cl(state_n)
	est store vol_bor
	xi: xtreg Dl_lir_b  i.year deregXyear_* if border==1 , fe cl(state_n)
	est store lir_bor
	estout orig vol lir orig_bor vol_bor lir_bor using "$output/TabOA4.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_Iyear* _cons) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed)      


	
	***********************************************************************************************
	**     TABLE OA5 & OA7     								     **
	***********************************************************************************************

	do "$dofiles/placebo_tab_OA5&OA7.do"
	
	
	***********************************************************************************************
	**     TABLE OA8         								     **
	***********************************************************************************************

	use "$data/data_distance.dta", clear
	global D_control       "Dl_inc LDl_inc Dl_pop LDl_pop Dl_hpi LDl_hpi Dl_her_v LDl_her_v"
	global D_control_hp    "Dl_inc LDl_inc Dl_pop LDl_pop Dl_her_v LDl_her_v"
	
	** TABLE OA8 
	** Panel A -- distance less than 20 miles
	xtreg Dl_nloans_b Linter_bra $D_control LDl_nloans_b yr* if distance<=20, fe cl(state_n) 
	est store num_less20
	xtreg Dl_vloans_b Linter_bra $D_control LDl_vloans_b yr* if distance<=20, fe cl(state_n)
	est store vol_less20
	xtreg Dl_hpi Linter_bra $D_control_hp LDl_hpi yr* [aw=w1] if distance<=20, fe cl(state_n) 
	est store hpi_less20
	xtreg Dl_nloans_b Linter_bra $D_control LDl_nloans_b yr* if distance>20, fe cl(state_n) 
	est store num_plus20
	xtreg Dl_vloans_b Linter_bra $D_control LDl_vloans_b yr* if distance>20, fe cl(state_n)
	est store vol_plus20
	xtreg Dl_hpi Linter_bra $D_control_hp LDl_hpi  yr* [aw=w1] if distance>20, fe cl(state_n) 
	est store hpi_plus20
	estout num_less20 vol_less20 hpi_less20 num_plus20 vol_plus20 hpi_plus20 using "$output/TabOA8_A.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2 , fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl*) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed)  
	** Panel B -- 15-30 miles distance 
	xtreg Dl_nloans_b Linter_bra $D_control LDl_nloans_b yr* if distance<=15, fe cl(state_n) 
	est store num_less15
	xtreg Dl_vloans_b Linter_bra $D_control LDl_vloans_b yr* if distance<=15, fe cl(state_n)
	est store vol_less15
	xtreg Dl_hpi Linter_bra $D_control_hp LDl_hpi yr* [aw=w1] if distance<=15, fe cl(state_n) 
	est store hpi_less15
	xtreg Dl_nloans_b Linter_bra $D_control LDl_nloans_b yr* if distance>15 & distance<30, fe cl(state_n) 
	est store num_1530
	xtreg Dl_vloans_b Linter_bra $D_control LDl_vloans_b yr* if distance>15 & distance<30, fe cl(state_n)
	est store vol_1530
	xtreg Dl_hpi Linter_bra $D_control_hp LDl_hpi yr* [aw=w1] if distance>15 & distance<30, fe cl(state_n) 
	est store hpi_1530
	xtreg Dl_nloans_b Linter_bra $D_control LDl_nloans_b yr* if distance>=30, fe cl(state_n) 
	est store num_plus30
	xtreg Dl_vloans_b Linter_bra $D_control LDl_vloans_b yr* if distance>=30, fe cl(state_n)
	est store vol_plus30
	xtreg Dl_hpi Linter_bra $D_control_hp LDl_hpi yr* [aw=w1]  if distance>=30, fe cl(state_n) 
	est store hpi_plus30
	estout num_less15 vol_less15 hpi_less15 num_1530 vol_1530 hpi_1530 num_plus30 vol_plus30 hpi_plus30 using "$output/TabOA8_B.txt", replace ///
	 cells(b(star fmt(%9.3f)) se(par)) stats(N N_g N_clust clustvar r2, fmt(%9.0f %9.0g) labels(Obs N-Groups N-Clust Cluster R2-W )) ///
	 drop(_cons yr* o.yr* Dl* LDl*) legend  posthead("") starl(* 0.1 ** 0.05 *** 0.01) ///
	 varwidth(16) modelwidth(12) delimiter("") style(fixed) 


    
     








