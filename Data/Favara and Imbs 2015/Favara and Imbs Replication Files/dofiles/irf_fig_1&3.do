	/**********************************************************************************************
	* Replication code for "Credit Supply and the Price of Housing", American Economic Review
	*
	* Distributed under copyright, Giovanni Favara and Jean Imbs, 2014 and the American 
	* Economic Association, 2014
	*
	* This code creates Figure 1 & 3 in the Paper
	***********************************************************************************************/ 
	
					********************************************* 
					***** IRF -- PROJECTION METHODS CREDIT ******
					*********************************************
	
	** define working directory  
	clear all
	global 		data    "$main/data"
	global 		dofiles "$main/do_files"
	global 		output  "$main/output"

	** load data
	use "$data/hmda.dta", clear
	merge 1:1 county year using "$data/hp_dereg_controls.dta", nogen keep(1 3)
	merge 1:1 county year using "$data/call.dta", nogen keep(1 3)
	
	** define controls 
	global D_control       "Dl_inc LDl_inc Dl_pop LDl_pop Dl_hpi LDl_hpi Dl_her_v LDl_her_v"
	global D_control_hp    "Dl_inc LDl_inc Dl_pop LDl_pop Dl_her_v LDl_her_v"
		

	tsset county year 
	
	** Figure 1
	foreach var in Dl_nloans_b Dl_vloans_b Dl_lir_b  {
		xtreg `var' L`var' $D_control  yr* Linter_bra, fe cluster(state_n) 
		gen _b`var'0= _b[Linter_bra]
		gen _se`var'0 = _se[Linter_bra]
		forvalues y = 1/8 {
		xtreg F`y'.`var' L.`var' $D_control  yr* Linter_bra, fe cluster(state_n) 
		gen _b`var'`y'= _b[Linter_bra]
		gen _se`var'`y' = _se[Linter_bra]
		}
	}

	keep year _b* _se* 
	collapse _b* _se* , by(year) 
	keep if _n==1
	reshape long _bDl_nloans_b _seDl_nloans_b _bDl_vloans_b _seDl_vloans_b _bDl_lir_b _seDl_lir_b , i(year) j(period)

	gen ciu_nloans = _bDl_nloans_b + 1.64*_seDl_nloans_b
	gen cil_nloans = _bDl_nloans_b - 1.64*_seDl_nloans_b
	gen ciu_vloans = _bDl_vloans_b + 1.64*_seDl_vloans_b
	gen cil_vloans = _bDl_vloans_b - 1.64*_seDl_vloans_b
	gen ciu_lir = _bDl_lir_b  + 1.64*_seDl_lir_b 
	gen cil_lir = _bDl_lir_b  - 1.64*_seDl_lir_b  

	ren period years
	tsset years

	cd $output 

	twoway (line _bDl_nloans_b years) (line ciu_nloans years,  lpattern(dash)) (line cil_nloans years,  lpattern(dash)), xlabel(0(1)8) legend(off) ///
		title(Panel A. Number of loans in response to deregulation shock, size(medium)) scheme(s1mono) saving(IRFnloans_L, replace)
	twoway (line _bDl_vloans_b years) (line ciu_vloans years,  lpattern(dash)) (line cil_vloans years,  lpattern(dash)), xlabel(0(1)8) legend(off) ///
		title(Panel B. Volume of loans in response to deregulation shock, size(medium)) scheme(s1mono) saving(IRFvloans_L, replace)
	twoway (line _bDl_lir_b  years) (line ciu_lir years,  lpattern(dash)) (line cil_lir years,  lpattern(dash)), xlabel(0(1)8) legend(off) ///
		title(Panel C. Loan to income ratio in response to deregulation shock, size(medium)) scheme(s1mono) saving(IRFlir_L, replace)
	graph combine IRFnloans_L.gph IRFvloans_L.gph IRFlir_L.gph, cols(1) graphregion(fcolor(white) lwidth(none)) plotregion(fcolor(white) ///
		lwidth(none)) scheme(s1mono) altshrink title("Figure 1. Mortgage Credit by Commercial Banks: Impulse Responses to Branching Deregulation Shock", size(small)) ///
		subtitle("(dashed lines are 90 percent confidence bands)", size(small)) ///
		saving(Figure_1, replace)  	

	erase IRFnloans_L.gph 
	erase IRFvloans_L.gph 
	erase IRFlir_L.gph

					********************************************* 
					***** IRF -- PROJECTION METHODS HP     ******
					*********************************************

	** Figure 3
	clear all
	global 		data    "$main/data"
	global 		dofiles "$main/dofiles"
	global 		output  "$main/output"

	** load data 
	use "$data/hmda.dta", clear
	merge 1:1 county year using "$data/hp_dereg_controls.dta", nogen keep(1 3)
	merge 1:1 county year using "$data/call.dta", nogen keep(1 3)
	
	** define controls 
	global D_control_hp    "Dl_inc LDl_inc Dl_pop LDl_pop Dl_her_v LDl_her_v"

	tsset county year 
	g credit_v = Dl_vloans_b 
	g credit_n = Dl_nloans_b 
	g credit_lir = Dl_lir_b 
	
	foreach var in credit_v credit_n credit_lir {
	xtivreg2 Dl_hpi LDl_hpi $D_control_hp  yr* (`var' = Linter_bra) [aw=w1], fe r partial(yr*)
	gen _b`var'0	= _b[`var']
	gen _se`var'0	= _se[`var']
		forvalues y = 1/8 {
		xtivreg2 F`y'.Dl_hpi L.Dl_hpi $D_control_hp  yr* (`var' = Linter_bra) [aw=w1], fe r partial(yr*)
		gen _b`var'`y'	= _b[`var']
		gen _se`var'`y'= _se[`var']
		}
	}
	
	keep year _b* _se* 
	collapse _b* _se*, by(year) 
	keep if _n==1
	reshape long _bcredit_v _secredit_v _bcredit_n _secredit_n _bcredit_lir _secredit_lir, i(year) j(period)

	gen ciu_credit_v = _bcredit_v + 1.64*_secredit_v
	gen cil_credit_v = _bcredit_v - 1.64*_secredit_v
	gen ciu_credit_n = _bcredit_n + 1.64*_secredit_n
	gen cil_credit_n = _bcredit_n - 1.64*_secredit_n
	gen ciu_credit_lir = _bcredit_lir + 1.64*_secredit_lir
	gen cil_credit_lir = _bcredit_lir - 1.64*_secredit_lir

	ren period years
	tsset years
	cd $output 

	twoway (line _bcredit_n years) (line ciu_credit_n years,  lpattern(dash)) (line cil_credit_n years,  lpattern(dash)), xlabel(0(1)8) legend(off) ///
		title(Panel A. House price in response to instrumented Number of Originations , size(medium)) scheme(s1mono) saving(IRF_HPcredit_n, replace)
	twoway (line _bcredit_v years) (line ciu_credit_v years,  lpattern(dash)) (line cil_credit_v years,  lpattern(dash)), xlabel(0(1)8) legend(off) ///
		title(Panel B. House price in response to instrumented volume of loans, size(medium)) scheme(s1mono) saving(IRF_HPcredit_v, replace)
	twoway (line _bcredit_lir years) (line ciu_credit_lir years,  lpattern(dash)) (line cil_credit_lir years,  lpattern(dash)), xlabel(0(1)8) legend(off) ///
		title(Panel C. House price in response to instrumented loan to income ratio, size(medium)) scheme(s1mono) saving(IRF_HPcredit_lir, replace)
	graph combine IRF_HPcredit_n.gph IRF_HPcredit_v.gph IRF_HPcredit_lir.gph, cols(1) graphregion(fcolor(white) lwidth(none)) plotregion(fcolor(white) ///
		lwidth(none)) scheme(s1mono) altshrink title("Figure 3. House Prices: Impulse Responses to Instrumented Credit Shock", size(small)) ///
		subtitle("(dashed lines are 90 percent confidence bands)", size(small)) ///
		saving(Figure_3, replace) 
	erase IRF_HPcredit_v.gph 
	erase IRF_HPcredit_n.gph 
	erase IRF_HPcredit_lir.gph


