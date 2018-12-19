	/**********************************************************************************************
	* Replication code for "Credit Supply and the Price of Housing", American Economic Review
	*
	* Distributed under copyright, Giovanni Favara and Jean Imbs, 2014 and the American 
	* Economic Association, 2014
	*
	* This code creates Figure 2 & 4 in the Paper
	***********************************************************************************************/ 


							**********************
							*** FIGURE 2 and 4 ***
							**********************

	** Define working directory 
	clear all
	global 		data   "$main/data"
	global 		output "$main/output"
	
	** LOAD DATA FOR AGGREGATION 
	use "$data/data_aggregation.dta", clear
	
	
	** COLLAPSE THE DATA AT THE STATE LEVEL, USING 2000 CPI INDEX TO EXPRESS CREDIT AND HOUSE PRICES IN REAL TERMS. 
	
	bysort state year: egen hpis = mean((hpi/cpi2000)*100)		// average real state-level house price index 
	bysort state year: egen crs = sum((amtoriginated_b/cpi2000)*100) 	// average real state-level credit volume by commercial banks
	replace crs = crs/1000000						// convert credit volume in billion
	bysort state year: keep if _n==1					// keep only state year obs
	
	

	** DROPS STATES THAT NEVER DEREGULATES			
	drop if yeard==. 				
	
	
							******************************************
							**** CREDIT PREDICTIONS for Figure 3  ****
							******************************************
							
	
	** GENERATE A BASE SERIES (pcrs) EQUAL TO THE ACTUAL LEVEL OF CREDIT UNTIL THE FIRST DEREGULATION OCCURS
	** AFTER DEREGULATION CREDIT INCREASES BY .028 PERCENT ON IMPACT AND STAYS AT THAT LEVEL THEREAFTER
	** THE .028 PERCENT INCREASE IS BASED ON THE ESTIMATES IN TABL2 2, COLUMN 1
	** THE BASE SERIES (pcrs) IS USED TO COMPUTE THE TWO IN-SAMPLE PREDICTIONS DISCUSSED IN THE TEXT
	
	sort state_n year
	forval x = 1996/2005 {
		gen pcrs_`x' = crs*(1+ .028)^(DLinter_bra) if year==`x' & DLinter_bra!=0 & DLinter_bra==DLinter_bra1 
		}
	egen pcrs = rowtotal(pcrs_*)	
	drop pcrs_*
	replace pcrs = crs if DLinter_bra1==0
	replace pcrs = pcrs[_n-1] if DLinter_bra1!=0 & DLinter_bra1[_n-1]!=0 & year>1996

		
	**************************
	**** CONPOUNDED METHOD ***
	**************************
	 	 
	** GENERATE A NEW SERIES (cpcrs ) STARTING WITH THE BASE SERIES (pcrs) AND IMPOSING AN 
	** ADJUSTMENT OF .02 PERCENT FOR ONE AND TWO YEARS AFTER DEREGULATION, .01 PERCENT AFTER THREE YEARS, 
	** AND 0 PERCENT THEREAFTER. THESE ADJUSTMENTS ARE BASED ON THE IRF FIGURE 1, TOP PANEL
	
	
	gen cpcrs = pcrs 
	
	gen period = 0	
	replace DLinter_bra=0 if year2==2
	sort state year
	drop yeard
	gen yeard1 =.
	replace yeard1 = year if Linter_bra>0 & Linter_bra[_n-1]==0 
	bysort state: egen yeard = mean(yeard1)
	replace yeard = 1996 if state_n==2
		
	forval x = 1996/2005	{ 				
		replace period = 1 if (DLinter_bra!=DLinter_bra1 & (`x'-yeard)<=2 & year==`x') 
		replace period = 2 if (DLinter_bra!=DLinter_bra1 & ((`x'-yeard)>2 & (`x'-yeard)<=4) & year==`x') 
		replace period = 3 if (DLinter_bra!=DLinter_bra1 & (`x'-yeard)>4  & year==`x') 
		}	
		
	tsset state_n year 
	replace cpcrs = L.cpcrs*(1+ .02)^(DLinter_bra1) if period==1
	replace cpcrs = L.cpcrs*(1+ .01)^(DLinter_bra1) if period==2
	replace cpcrs = L.cpcrs*(1+ .00)^(DLinter_bra1) if period==3
		
		
	*************************
	**** PERMANENT METHOD ***
	*************************
	 
	** GENERATE A NEW SERIES (ppcrs) STARTING WITH THE BASE SERIES (pcrs) AND IMPOSING A PERMANENT GROWTH RATE OF .028 PERCENT
	
	gen ppcrs = pcrs 
	tsset state_n year 
	replace ppcrs = L.ppcrs*(1+ .028)^(DLinter_bra1) if period==1
	replace ppcrs = L.ppcrs*(1+ .028)^(DLinter_bra1) if period==2 
	replace ppcrs = L.ppcrs*(1+ .028)^(DLinter_bra1) if period==3 
	
				
	**** GENERATE AGGREGATE ACTUAL AND PREDICTED CREDIT 

	bysort year: egen cr 	= sum(crs) 
	bysort year: egen pcr	= sum(pcrs)
	bysort year: egen pcr_c	= sum(cpcrs)
	bysort year: egen pcr_p	= sum(ppcrs)
	
	
	**** GENERATE GROWTH RATE OF EACH CREDIT MEASURE, TO BE USED BELOW TO PREDICT HOUSE PRICES
	xtset state_n year
	gen lpcrs = ln(pcrs)
	gen Dlpcrs = D.lpcrs
	replace Dlpcrs = 0 if year==1996
	gen lcpcrs = ln(cpcrs)
	gen Dlcpcrs = D.lcpcrs
	replace Dlcpcrs = 0 if year==1996
	gen lppcrs = ln(ppcrs)
	gen Dlppcrs = D.lppcrs
	replace Dlppcrs = 0 if year==1996
	
	
	
	
							***************************************************
							*** HOUSE PRICES PREDICTIONS for Figure 4  ********
							***************************************************
	
								
	
	** GENERATE A BASE VECTOR (phpis) EQUAL TO THE ACTUAL LEVEL OF HOUSE PRICES UNTIL THE FIRST DEREGULATION OCCURS
	** AFTER DEREGULATION HOUSE PRICES RESPOND TO A CHANGE IN CREDIT WITH AN ELASTICITY OF .012 (USING THE APPROXIMATE POINT ESTIMATES IN TABLE 5) 
	** AND STAY AT THAT LEVEL THEREAFTER. THE RESULTING SERIES (phpis) IS USED TO COMPUTE THE TWO IN SAMPLE PREDICTIONS DISCUSSED IN THE TEXT
	
	forval x = 1996/2005 {
		gen phpis_`x' = hpis*(1+ .12*Dlpcrs) if year==`x' & DLinter_bra!=0 & DLinter_bra==DLinter_bra1 
		}
	egen phpis = rowtotal(phpis_*)	
	drop phpis_*
	replace phpis = hpis if DLinter_bra1==0
	replace phpis = phpis[_n-1] if DLinter_bra1!=0 & DLinter_bra1[_n-1]!=0 & year>1996

	
	**************************
	**** COMPOUNDED METHOD ***
	**************************
	 
	** GENERATE NEW SERIES (cphpis) STARTING FROM THE BASE SERIES (phpis) 
	** AND ASSUMING THE ELASTICITY OF HOUSE PRICES TO A CREDIT CHANGE FOLLOWS THE POINT ESTIMATES IMPLICIT IN THE IRF OF FIGURE 3 
	** THE PREDICTED CHANGE IN CREDIT (Dlcpcrs) IS BASED ON THE COMPOUNDED METHOD DESCRIBE ABOVE
	
	gen cphpis = phpis
	gen period1 = 0	
	
	forval x = 1996/2005	{ 				
		replace period1 = 1 if (DLinter_bra!=DLinter_bra1 & (`x'-yeard)<=2 & year==`x') 
		replace period1 = 2 if (DLinter_bra!=DLinter_bra1 & ((`x'-yeard)>2 & (`x'-yeard)<=4) & year==`x') 
		replace period1 = 3 if (DLinter_bra!=DLinter_bra1 & (`x'-yeard)>4  & year==`x') 
		}
	
	tsset state_n year
	replace cphpis = L.cphpis*(1+ .20*Dlcpcrs) if period1==1
	replace cphpis = L.cphpis*(1+ .14*Dlcpcrs) if period1==2
	replace cphpis = L.cphpis*(1+ .06*Dlcpcrs) if period1==3
	
	
	*************************
	**** PERMANENT METHOD ***
	*************************
	 
	** GENERATE A NEW SERIES (pphpis) STARTING FROM THE BASE SERIES (phpis) 
	** AND ASSUMING THE ELASTICITY OF HOUSE PRICES TO A CREDIT CHANGE IS .14 (USING THE APPROXIMATE POINT ESTIMATE IN TABLE 5) 
	** THE PREDICTED CHANGE IN CREDIT (Dlppcrs) IS BASED ON THE PERMANENT METHOD DESCRIBE ABOVE
	
	gen pphpis = phpis
	tsset state_n year 
	replace pphpis = L.pphpis*(1+ .12*Dlppcrs) if period1==1
	replace pphpis = L.pphpis*(1+ .12*Dlppcrs) if period1==2
	replace pphpis = L.pphpis*(1+ .12*Dlppcrs) if period1==3 
	
	** GENERATE AGGREGATE SERIES 
	bysort year: egen hpia 		= mean(hpis) 
	bysort year: egen phpi		= mean(phpis)
	bysort year: egen phpi_c	= mean(cphpis)
	bysort year: egen phpi_p	= mean(pphpis)
	
	
	
								**********************
								**** PLOT GRAPHS   ***
								**********************
		
	** KEEP ONLY YEAR OBSERVATIONS 
	bysort year: keep if _n==1			
	
	cd $output
	twoway (line cr year, lpattern(solid)) (line pcr_p year, lpattern(dash)) (line pcr_c year, lpatter(dot)), xlabel(1996(1)2005) ylabel(#8) ///
	       title(Fig. 2 Actual and Predicted Aggregate Mortgage Volume by Commercial Banks, size(small)) ///
	       scheme(s1mono) ytitle(Billions of 2000 U.S. dollars, size(small))  ///
	       legend( label(1 "Actual Mortgage Volume") label(2 "Predicted: Permanent") label(3 "Predicted: Compounded")) ///
	       saving(Figure_2, replace)
				

	twoway (line hpia year, lpattern(solid)) (line phpi_p year, lpattern(dash)) (line phpi_c year, lpattern(dot)), xlabel(1996(1)2005) ylabel(#8) ///
		legend(size(small)) title(Fig. 4 Actual and Predicted Real House Price Index, size(small)) scheme(s1mono) /// 
		legend( label(1 "Actual House Price Index") label(2 "Predicted: Permanent") label(3 "Predicted: Compounded")) ///
		saving(Figure_4, replace) 
		       	
