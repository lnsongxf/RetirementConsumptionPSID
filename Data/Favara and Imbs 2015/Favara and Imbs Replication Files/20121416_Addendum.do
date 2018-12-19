
	clear all
	global 		main    "../"
	global 		data    "$main/data"
		
	use "$data/hmda.dta", clear
	merge 1:1 county year using "$data/hp_dereg_controls.dta", nogen keep(1 3)


	gen y1 = Dl_nloans_b
	gen y2 = Dl_vloans_b
	gen y3 = Dl_lir_b
	gen y4 = Dl_nden_b 
	gen y5 = Dl_nsold_b

	gen y1p = Dl_nloans_pl
	gen y2p = Dl_vloans_pl
	gen y3p = Dl_lir_pl

	gen x1 = Dl_inc
	gen x2 = Dl_pop
	gen x3 = Dl_hpi
	gen x4 = Dl_her
	
	foreach var in y1 y2 y3 y1p y2p y3p x1 x2 x3 x4 {
	gen L`var' = L.`var'
	} 
	gen d = Linter_bra

	set matafavor speed, perm
	set more off,perm
	tsset county year
	xtdes

	*********************************
	**** TAB 1 (number of loans) ****
	********************************(
		
		**** PANEL A -- commercial banks ****
		* AB GMM 
		xtabond2 y1 yr* L(0/1).(x1 x2 x3 x4) L.y1 d, gmm(L.y1 x1 x2 x3 x4, lag(1 .)) iv(yr* d) nolevel small cl(state_n) h(2) or  
		* BB GMM
		xtabond2 y1 yr* L(0/1).(x1 x2 x3 x4) L.y1 d, gmm(L.y1 x1 x2 x3 x4, lag(1 .)) iv(yr*) iv(d, e(d)) cl(state_n) h(2) or 
		* AB GMM 2 lags 
		xtabond2 y1 yr* L(0/1).(x1 x2 x3 x4) L.y1 d, gmm(L.y1 x1 x2 x3 x4, lag(1 2)) iv(yr* d) nolevel small cl(state_n) h(2) or  
		* BB GMM 2 lags 
		xtabond2 y1 yr* L(0/1).(x1 x2 x3 x4) L.y1 d, gmm(L.y1 x1 x2 x3 x4, lag(1 2)) iv(yr*) iv(d, e(d)) cl(state_n) h(2) or 
		* Kiviet 	
		xtlsdvc y1 x1 x2 x3 x4 Lx1 Lx2 Lx3 Lx4 yr* d, i(ab) bias(3) vcov(500)
		
		
		**** PANEL B -- placebo lenders ****
		* AB GMM 
		xtabond2 y1p yr* L(0/1).(x1 x2 x3 x4) L.y1p d, gmm(L2.y1p x1 x2 x3 x4, lag(1 .)) iv(yr* d) nolevel small cl(state_n) h(2) or 
		* BB GMM 
		xtabond2 y1p yr* L(0/1).(x1 x2 x3 x4) L.y1p d, gmm(L2.y1p x1 x2 x3 x4, lag(1 .)) iv(yr*) iv(d, e(d)) cl(state_n) h(2) or 
		* AB GMM 2 lags 
		xtabond2 y1p yr* L(0/1).(x1 x2 x3 x4) L.y1p d, gmm(L2.y1p x1 x2 x3 x4, lag(1 2)) iv(yr* d) nolevel small cl(state_n) h(2) or  
		* BB GMM 2 lags 
		xtabond2 y1p yr* L(0/1).(x1 x2 x3 x4) L.y1p d, gmm(L2.y1p x1 x2 x3 x4, lag(1 2)) iv(yr*) iv(d, e(d)) cl(state_n) h(2) or 
		* Kiviet 	
		xtlsdvc y1p x1 x2 x3 x4 Lx1 Lx2 Lx3 Lx4 yr* d, i(ab) bias(3) vcov(500)
	
	
	*********************************
	**** TAB 2 (loan volume)     ****
	*********************************
		
		**** PANEL A -- commercial banks ****
		* AB GMM 
		xtabond2 y2 yr* L(0/1).(x1 x2 x3 x4) L.y2 d, gmm(L.y2 x1 x2 x3 x4, lag(1 .)) iv(yr* d) nolevel small cl(state_n) h(2) or  
		* BB GMM
		xtabond2 y2 yr* L(0/1).(x1 x2 x3 x4) L.y2 d, gmm(L.y2 x1 x2 x3 x4, lag(1 .)) iv(yr*) iv(d, e(d)) cl(state_n) h(2) or 
		* AB GMM 2 lags 
		xtabond2 y2 yr* L(0/1).(x1 x2 x3 x4) L.y2 d, gmm(L.y2 x1 x2 x3 x4, lag(1 2)) iv(yr* d) nolevel small cl(state_n) h(2) or  
		* BB GMM 2 lags 
		xtabond2 y2 yr* L(0/1).(x1 x2 x3 x4) L.y2 d, gmm(L.y2 x1 x2 x3 x4, lag(1 2)) iv(yr*) iv(d, e(d)) cl(state_n) h(2) or 
		* Kiviet 	
		xtlsdvc y2 x1 x2 x3 x4 Lx1 Lx2 Lx3 Lx4 yr* d, i(ab) bias(3) vcov(500)
		
		
		**** PANEL B -- placebo lenders ****
		* AB GMM 
		xtabond2 y2p yr* L(0/1).(x1 x2 x3 x4) L.y2p d, gmm(L2.y2p x1 x2 x3 x4, lag(1 .)) iv(yr* d) nolevel small cl(state_n) h(2) or 
		* BB GMM 
		xtabond2 y2p yr* L(0/1).(x1 x2 x3 x4) L.y2p d, gmm(L2.y2p x1 x2 x3 x4, lag(1 .)) iv(yr*) iv(d, e(d)) cl(state_n) h(2) or 
		* AB GMM 2 lags 
		xtabond2 y2p yr* L(0/1).(x1 x2 x3 x4) L.y2p d, gmm(L2.y2p x1 x2 x3 x4, lag(1 2)) iv(yr* d) nolevel small cl(state_n) h(2) or  
		* BB GMM 2 lags 
		xtabond2 y2p yr* L(0/1).(x1 x2 x3 x4) L.y2p d, gmm(L2.y2p x1 x2 x3 x4, lag(1 2)) iv(yr*) iv(d, e(d)) cl(state_n) h(2) or 
		* Kiviet 	
		xtlsdvc y2p x1 x2 x3 x4 Lx1 Lx2 Lx3 Lx4 yr* d, i(ab) bias(3) vcov(500)


	*********************************
	**** TAB 3 (loan to income)  ****
	*********************************
		
		**** PANEL A -- commercial banks ****
		* AB GMM 
		xtabond2 y3 yr* L(0/1).(x1 x2 x3 x4) L.y3 d, gmm(L.y3 x1 x2 x3 x4, lag(1 .)) iv(yr* d) nolevel small cl(state_n) h(2) or  
		* BB GMM
		xtabond2 y3 yr* L(0/1).(x1 x2 x3 x4) L.y3 d, gmm(L.y3 x1 x2 x3 x4, lag(1 .)) iv(yr*) iv(d, e(d)) cl(state_n) h(2) or 
		* AB GMM 2 lags 
		xtabond2 y3 yr* L(0/1).(x1 x2 x3 x4) L.y3 d, gmm(L.y3 x1 x2 x3 x4, lag(1 2)) iv(yr* d) nolevel small cl(state_n) h(2) or  
		* BB GMM 2 lags 
		xtabond2 y3 yr* L(0/1).(x1 x2 x3 x4) L.y3 d, gmm(L.y3 x1 x2 x3 x4, lag(1 2)) iv(yr*) iv(d, e(d)) cl(state_n) h(2) or 
		* Kiviet 	
		xtlsdvc y3 x1 x2 x3 x4 Lx1 Lx2 Lx3 Lx4 yr* d, i(ab) bias(3) vcov(500)
		
		
		**** PANEL B -- placebo lenders ****
		* AB GMM 
		xtabond2 y3p yr* L(0/1).(x1 x2 x3 x4) L.y3p d, gmm(L2.y3p x1 x2 x3 x4, lag(1 .)) iv(yr* d) nolevel small cl(state_n) h(2) or 
		* BB GMM 
		xtabond2 y3p yr* L(0/1).(x1 x2 x3 x4) L.y3p d, gmm(L2.y3p x1 x2 x3 x4, lag(1 .)) iv(yr*) iv(d, e(d)) cl(state_n) h(2) or 
		* AB GMM 2 lags 
		xtabond2 y3p yr* L(0/1).(x1 x2 x3 x4) L.y3p d, gmm(L2.y3p x1 x2 x3 x4, lag(1 2)) iv(yr* d) nolevel small cl(state_n) h(2) or  
		* BB GMM 2 lags 
		xtabond2 y3p yr* L(0/1).(x1 x2 x3 x4) L.y3p d, gmm(L2.y3p x1 x2 x3 x4, lag(1 2)) iv(yr*) iv(d, e(d)) cl(state_n) h(2) or 
		* Kiviet 	
		xtlsdvc y3p x1 x2 x3 x4 Lx1 Lx2 Lx3 Lx4 yr* d, i(ab) bias(3) vcov(500)

