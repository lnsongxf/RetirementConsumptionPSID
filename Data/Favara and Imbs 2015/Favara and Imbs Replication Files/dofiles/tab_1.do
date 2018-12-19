	/**********************************************************************************************
	* Replication code for "Credit Supply and the Price of Housing", American Economic Review
	*
	* Distributed under copyright, Giovanni Favara and Jean Imbs, 2014 and the American 
	* Economic Association, 2014
	*
	* This code creates Tables 1 in the Paper
	***********************************************************************************************/ 
	
	
	** Define working directory 
	global 		data    "$main/data"
	global 		dofiles "$main/dofiles"
	global 		output  "$main/output"


	** load data for Table 1
	use "$data/data_tab1.dta", clear
	

	** define variables of interest
	g nar_b 	= nrequested_b 
	g nlo_b 	= noriginated_b 
	g amto_b	= amtoriginated_b/noriginated_b 
	g inco_b 	= incomeoriginated_b/noriginated_b

	g nar_imc 	= nrequested_imc 
	g nlo_imc 	= noriginated_imc 
	g amto_imc	= amtoriginated_imc/noriginated_imc 
	g inco_imc 	= incomeoriginated_imc/noriginated_imc

	g nar_tfcu 	= nrequested_tfcu 
	g nlo_tfcu 	= noriginated_tfcu 
	g amto_tfcu	= amtoriginated_tfcu/noriginated_tfcu 
	g inco_tfcu 	= incomeoriginated_tfcu/noriginated_tfcu
	
	
	** label var of interest
	label var nar_b "number mortgage applications received by commercial banks"
	label var nlo_b "number mortgage loans originated by commercial banks"
	label var amto_b "average loan originated (thousand dollars) by commercial banks"
	label var inco_b "average applicant's income (thousand dollars) by commercial banks"

	label var nar_imc "number mortgage applications received by mortgage companies"
	label var nlo_imc "number mortgage loans originated by mortgage companies"
	label var amto_imc "average loan originated (thousand dollars) by mortgage companies"
	label var inco_imc "average applicant's income (thousand dollars) by mortgage companies"
	
	label var nar_tfcu "number mortgage applications received by thrifts and credit unions "
	label var nlo_tfcu "number mortgage loans originated by thrifts and credit unions "
	label var amto_tfcu "average loan originated (thousand dollars) by thrifts and credit unions "
	label var inco_tfcu "average applicant's income (thousand dollars) by thrifts and credit unions "


	** display mean for each var of interest
	**COL 1
	tabstat nar_b nar_imc nar_tfcu nlo_b nlo_imc nlo_tfcu amto_b amto_imc amto_tfcu  inco_b inco_imc inco_tfcu, stat(mean) long col(stat) 
	**COL 2 -- year 1995
	tabstat  nar_b nar_imc nar_tfcu nlo_b nlo_imc nlo_tfcu amto_b amto_imc amto_tfcu  inco_b inco_imc inco_tfcu if year==1995, stat(mean) long col(stat) 
	**COL 3 -- year 2000
	tabstat  nar_b nar_imc nar_tfcu nlo_b nlo_imc nlo_tfcu amto_b amto_imc amto_tfcu  inco_b inco_imc inco_tfcu if year==2000, stat(mean) long col(stat) 
	**COL 4 -- year 2005
	tabstat  nar_b nar_imc nar_tfcu nlo_b nlo_imc nlo_tfcu amto_b amto_imc amto_tfcu  inco_b inco_imc inco_tfcu if year==2005, stat(mean) long col(stat) 
	
	
	
	
