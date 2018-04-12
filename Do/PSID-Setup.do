set more off
clear all
// global folder "C:\Users\pedm\Documents\Research\Cormac\RetirementConsumptionPSID"
/*global folder "C:\Users\STUDENT\Documents\GitHub\RetirementConsumptionPSID"*/
global folder "C:\Users\pedm\Documents\GitHub\RetirementConsumptionPSID"

****************************************************************************************************
** Convert year level zip files to dta files
****************************************************************************************************

cap ssc install psidtools
cap mkdir "$folder\Data\Raw\PSID_Install"
psid install using "$folder\Data\Raw\PSID_Download", to("$folder\Data\Raw\PSID_Install")

****************************************************************************************************
** Select variables and construct panel using year-level files
****************************************************************************************************

#delimit ;
psid use
	// relationship to head
	|| rel2head
	// [68]ER30003 [69]ER30022 [70]ER30045 [71]ER30069 [72]ER30093 [73]ER30119
	// [74]ER30140 [75]ER30162 [76]ER30190 [77]ER30219 [78]ER30248 [79]ER30285
	// [80]ER30315 [81]ER30345 [82]ER30375 [83]ER30401 [84]ER30431 [85]ER30465
	// [86]ER30500 [87]ER30537 [88]ER30572 [89]ER30608 [90]ER30644 [91]ER30691
	// [92]ER30735 [93]ER30808 [94]ER33103 [95]ER33203 [96]ER33303 [97]ER33403
	[99]ER33503 [01]ER33603 [03]ER33703 [05]ER33803 [07]ER33903
	[09]ER34003 [11]ER34103 [13]ER34203 [15]ER34303

	// age of individual
	|| age
	// [68]ER30004 [69]ER30023 [70]ER30046 [71]ER30070 [72]ER30094
	// [73]ER30120 [74]ER30141 [75]ER30163 [76]ER30191 [77]ER30220
	// [78]ER30249 [79]ER30286 [80]ER30316 [81]ER30346 [82]ER30376
	// [83]ER30402 [84]ER30432 [85]ER30466 [86]ER30501 [87]ER30538
	// [88]ER30573 [89]ER30609 [90]ER30645 [91]ER30692 [92]ER30736
	// [93]ER30809 [94]ER33104 [95]ER33204 [96]ER33304 [97]ER33404
	[99]ER33504 [01]ER33604 [03]ER33704 [05]ER33804 [07]ER33904
	[09]ER34004 [11]ER34104 [13]ER34204 [15]ER34305

	// year individual born
	|| year_born
	// [83]ER30404 [84]ER30434 [85]ER30468 [86]ER30503 [87]ER30540 [88]ER30575
	// [89]ER30611 [90]ER30647 [91]ER30694 [92]ER30738 [93]ER30811 [94]ER33106
	// [95]ER33206 [96]ER33306 [97]ER33406
	[99]ER33506 [01]ER33606 [03]ER33706 [05]ER33806 [07]ER33906 [09]ER34006
	[11]ER34106 [13]ER34206 [15]ER34307

	// sex of head
	|| sex_head
	[99]ER13011 [01]ER17014 [03]ER21018 [05]ER25018 [07]ER36018 [09]ER42018
	[11]ER47318 [13]ER53018 [15]ER60018
	// note: if you want sex of the individual, use ER32000 instead

	|| sex_indiv
	[]ER32000

	|| deathyr
	[]ER32050

	// month of interview
	|| month
	[99]ER13006 [01]ER17009 [03]ER21012 [05]ER25012 [07]ER36012 [09]ER42012
	[11]ER47312 [13]ER53012 [15]ER60012


	// Family Composition Change between this wave and previous wave
	// All recontact cases, including splitoffs from recontacts, are coded 8 for this variable.
	// Codes 2-8 have priority over codes 0 and 1, and code 8 has priority over everything else
	|| fchg
	// [69]V542 [70]V1109 [71]V1809 [72]V2410 [73]V3010 [74]V3410 [75]V3810
	// [76]V4310 [77]V5210 [78]V5710 [79]V6310 [80]V6910 [81]V7510 [82]V8210
	// [83]V8810 [84]V10010 [85]V11112 [86]V12510 [87]V13710 [88]V14810
	// [89]V16310 [90]V17710 [91]V19010 [92]V20310 [93]V21608 [94]ER2005A
	// [95]ER5004A [96]ER7004A [97]ER10004A
	[99]ER13008A [01]ER17007 [03]ER21007 [05]ER25007 [07]ER36007 [09]ER42007
	[11]ER47307 [13]ER53007 [15]ER60007

	// Users often want to look at data from the "same" family in adjacent waves.
	// It is important to understand that there is no absolute definition of
	// "same" family. Families are made up of individuals who may move in or out
	// of study families from wave to wave. It is up to the user to decide what
	// he or she means by "same" family. The user may want to restrict this
	// definition to option 1) absolutely no changes in the composition of the
	// family since the previous wave. All the individuals that were in the prior
	// wave are still in the current wave - no one has moved in and no one has
	// moved out. Alternatively, the user may want define "same" family as option
	// 2) those who have the same Head in both waves.

	// In order to subset those cases which the user has defined as "same"
	// family, he or she will find the Family Composition Change variable most
	// useful. The Family Composition Change variable indicates the degree of
	// change in this family since the prior wave's data collection. For option
	// 1, the user would subset the families in the current wave where Family
	// Composition Change variable = 0. For option 2, the user would subset the
	// families in the current wave where Family Composition Change variable in
	// (0,1, 2).

	// Splitoff Indicator
	|| splitoff_indicator
	// [69]V909 [70]V1106 [71]V1806 [72]V2407 [73]V3007 [74]V3407 [75]V3807
	// [76]V4307 [77]V5207 [78]V5707 [79]V6307 [80]V6907 [81]V7507 [82]V8207
	// [83]V8807 [84]V10007 [85]V11107 [86]V12507 [87]V13707 [88]V14807
	// [89]V16307 [90]V17707 [91]V19007 [92]V20307 [93]V21606 [94]ER2005F
	// [95]ER5005F [96]ER7005F [97]ER10005F
	[99]ER13005E [01]ER17006 [03]ER21005 [05]ER25005 [07]ER36005 [09]ER42005
	[11]ER47305 [13]ER53005 [15]ER60005

	// 1	Reinterview family
	// 2	Splitoff from reinterview family
	// 3	Recontact family
	// 4	Splitoff from recontact family

	// Age of Spouse
	// This variable represents the actual age of the current Spouse or
	// Partner (cohabiting friend). 0 indicates Inap.: Head is female or
	// single male; no Spouse/Partner in FU
	|| age_spouse
	[99]ER13012 [01]ER17015 [03]ER21019 [05]ER25019 [07]ER36019 [09]ER42019
	[11]ER47319 [13]ER53019 [15]ER60019

	// Number of Children in Family Unit
	// This variable represents the actual number of persons currently in the FU
	// who are neither Head nor wife/"wife" from newborns through those 17 years
	// of age, whether or not they are actually children of the Head or Wife/"Wife."
	|| children
	[99]ER13013 [01]ER17016 [03]ER21020 [05]ER25020 [07]ER36020 [09]ER42020
	[11]ER47320 [13]ER53020 [15]ER60021

	// Marital status of the Head
	|| married
	[99]ER13021 [01]ER17024 [03]ER21023 [05]ER25023 [07]ER36023 [09]ER42023
	[11]ER47323 [13]ER53023 [15]ER60024

	// Race of head (first mention -- they record up to 3 mentions)
	|| racehead
	[99]ER15928 [01]ER19989 [03]ER23426 [05]ER27393 [07]ER40565 [09]ER46543
	[11]ER51904 [13]ER57659 [15]ER64810

	// Head's Completed Education Level (years of education, with 99 = NA)
	|| educhead
	[99]ER16516 [01]ER20457 [03]ER24148 [05]ER28047 [07]ER41037 [09]ER46981
	[11]ER52405 [13]ER58223 [15]ER65459

	// # in FU
	|| fsize
	// [68]V115 [69]V549 [70]V1238 [71]V1941 [72]V2541 [73]V3094 [74]V3507
	// [75]V3920 [76]V4435 [77]V5349 [78]V5849 [79]V6461 [80]V7066 [81]V7657
	// [82]V8351 [83]V8960 [84]V10418 [85]V11605 [86]V13010 [87]V14113
	// [88]V15129 [89]V16630 [90]V18048 [91]V19348 [92]V20650 [93]V22405
	// [94]ER2006 [95]ER5005 [96]ER7005 [97]ER10008
	[99]ER13009 [01]ER17012 [03]ER21016 [05]ER25016 [07]ER36016 [09]ER42016
	[11]ER47316 [13]ER53016 [15]ER60016

	//////////////////////////////////////////////////////////////////////////
	// EMPLOYMENT STATUS (HEAD)
	//////////////////////////////////////////////////////////////////////////

	// Head Employment Status (First Mention)
	|| emp_status_head
	// We would like to know about what (you/HEAD) (do/does) -- (are/is)
	// (you/HEAD) working now, looking for work, retired, keeping house, a
	// student, or what?--FIRST MENTION
	// [94]ER2069 [95]ER5068 [96]ER7164 [97]ER10081
	[99]ER13205 [01]ER17216 [03]ER21123 [05]ER25104 [07]ER36109 [09]ER42140
	[11]ER47448 [13]ER53148 [15]ER60163

	// Head Employment Status (Second Mention)
	|| emp_status_head_2
	// [94]ER2070 [95]ER5069 [96]ER7165 [97]ER10082
	[99]ER13206 [01]ER17217 [03]ER21124 [05]ER25105 [07]ER36110 [09]ER42141
	[11]ER47449 [13]ER53149 [15]ER60164

	// Head Employment Status (Third Mention)
	|| emp_status_head_3
	// [94]ER2071 [95]ER5070 [96]ER7166 [97]ER10083
	[99]ER13207 [01]ER17218 [03]ER21125 [05]ER25106 [07]ER36111 [09]ER42142
	[11]ER47450 [13]ER53150 [15]ER60165

	// Year Retired -- In what year did (you/HEAD) retire?
	|| ret_year
	// [78]V6003 [79]V6576 [80]V7178 [81]V7864 [82]V8524 [83]V9174 [84]V10657
	// [85]V11638 [86]V13047 [87]V14147 [88]V15155 [89]V16656 [90]V18094
	// [91]V19394 [92]V20694 [93]V22449 [94]ER2072 [95]ER5071 [96]ER7167
	// [97]ER10084
	[99]ER13208 [01]ER17219 [03]ER21126 [05]ER25107 [07]ER36112 [09]ER42143
	[11]ER47451 [13]ER53151 [15]ER60166

	// WHY LAST JOB END (Head)
	|| why_last_job_end
	// BC51. Why did you stop working for (NAME OF EMPLOYER)?--Did the company
	// go out of business, were you laid off, did you quit, or what?--MOST
	// RECENT MAIN JOB
	// [69]V651 [70]V1332 [71]V2038 [72]V2638 [73]V3155 [74]V3571 [75]V4026
	// [76]V4556 [77]V5458 [78]V5986 [79]V6559 [80]V7161 [81]V7809 [82]V8470
	// [83]V9107 [84]V10609 [85]V11764 [86]V13160 [87]V14256 [88]V15328
	// [89]V16843 [90]V18267 [91]V19567 [92]V20867 [93]V22655 [94]ER4034
	// [95]ER6874 [96]ER9125 [97]ER12102
	[99]ER13498 [01]ER17538 [03]ER21184 [05]ER25173 [07]ER36178 [09]ER42211
	[11]ER47524 [13]ER53224 [15]ER60239

	|| months_out_lab_force
	// Question in 2005 survey:
	// BC7. Was there any time in 2003 or 2004 when you did not have a job and
	// were not looking for one? How much time was that in 2004? --MONTHS
	// The values for this variable represent the actual number of reported
	// months that Head did not have a job and was not looking for one. NOTE:
	// between 0 and 12. First asked in 2003
	[03]ER21341 [05]ER25330 [07]ER36335 [09]ER42362 [11]ER47675 [13]ER53375
	[15]ER60390


	//////////////////////////////////////////////////////////////////////////
	// EMPLOYMENT STATUS (SPOUSE)
	//////////////////////////////////////////////////////////////////////////

	|| emp_status_spouse
	// [94]ER2563 [95]ER5562 [96]ER7658 [97]ER10563
	[99]ER13717 [01]ER17786 [03]ER21373 [05]ER25362 [07]ER36367 [09]ER42392
	[11]ER47705 [13]ER53411 [15]ER60426

	|| emp_status_spouse_2
	// [94]ER2564 [95]ER5563 [96]ER7659 [97]ER10564
	[99]ER13718 [01]ER17787 [03]ER21374 [05]ER25363 [07]ER36368 [09]ER42393
	[11]ER47706 [13]ER53412 [15]ER60427

	|| emp_status_spouse_3
	// [94]ER2565 [95]ER5564 [96]ER7660 [97]ER10565
	[99]ER13719 [01]ER17788 [03]ER21375 [05]ER25364 [07]ER36369 [09]ER42394
	[11]ER47707 [13]ER53413 [15]ER60428

	// Year Retired Spouse -- In what year did (you/SPOUSE/PARTNER) retire?
	|| ret_year_spouse
	// [79]V6648 [80]V7250 [81]V7941 [82]V8592 [83]V9265 [84]V10854 [85]V12001
	// [86]V13226 [87]V14322 [88]V15457 [89]V16975 [90]V18396 [91]V19696
	// [92]V20996 [93]V22802 [94]ER2566 [95]ER5565 [96]ER7661 [97]ER10566
	[99]ER13720 [01]ER17789 [03]ER21376 [05]ER25365 [07]ER36370 [09]ER42395
	[11]ER47708 [13]ER53414 [15]ER60429

	// Why Last Job End (Wife/Spouse)
	|| why_last_job_end_spouse
	// [76]V4940 [79]V6631 [80]V7233 [81]V7922 [82]V8577 [83]V9236 [84]V10809
	// [85]V12127 [86]V13328 [87]V14420 [88]V15630 [89]V17162 [90]V18569
	// [91]V19869 [92]V21169 [93]V23008 [94]ER4065 [95]ER6905 [96]ER9156
	// [97]ER12133
	[99]ER14010 [01]ER18109 [03]ER21434 [05]ER25431 [07]ER36436 [09]ER42463
	[11]ER47781 [13]ER53487 [15]ER60502


	//////////////////////////////////////////////////////////////////////////
	// INCOME
	//////////////////////////////////////////////////////////////////////////

	// Total Family Money Income
	|| inc_fam
	// The income reported here was collected in 2011 about tax year 2010. Please
	// note that this variable can contain negative values. Negative values
	// indicate a net loss, which in waves prior to 1994 were bottom-coded at $1,
	// as were zero amounts. These losses occur as a result of business or farm
	// losses. This variable is the sum of these seven variables:
	// ER52259 Head and Wife/"Wife" Taxable Income-2010
	// ER52308 Head and Wife/"Wife" Transfer Income-2010
	// ER52315 Taxable Income of Other FU Members-2010
	// ER52336 Transfer Income of OFUMS-2010
	// ER52337 Head Social Security Income-2010
	// ER52339 Wife/"Wife" Social Security Income-2010
	// ER52341 OFUM Social Security Income-2010

	// This variable is the sum of these five 2002 variables:
	// ER24100 Head and Wife/"Wife" Taxable Income
	// ER24101 Head and Wife/"Wife" Transfer Income
	// ER24102 Taxable Income of Other FU Members
	// ER24103 Transfer Income of Other FU Members
	// ER24104 Social Security Income of All FU Members

	// [68]V81 [69]V529 [70]V1514 [71]V2226 [72]V2852 [73]V3256 [74]V3676
	// [75]V4154 [76]V5029 [77]V5626 [78]V6173 [79]V6766 [80]V7412 [81]V8065
	// [82]V8689 [83]V9375 [84]V11022 [85]V12371 [86]V13623 [87]V14670 [88]V16144
	// [89]V17533 [90]V18875 [91]V20175 [92]V21481 [93]V23322 [94]ER4153
	// [95]ER6993 [96]ER9244 [97]ER12079
	[99]ER16462 [01]ER20456 [03]ER24099 [05]ER28037 [07]ER41027 [09]ER46935
	[11]ER52343 [13]ER58152 [15]ER65349


	// Head's Labor Income, Excluding Farm and Unincorporated Business Income
	|| inc_head
	// The income reported here was collected in 2009 about tax year 2008. It is
	// the sum of several labor income components from the raw data, including,
	// in addition to wages and salaries (ER46811), any separate reports of
	// bonuses (ER46813), overtime (ER46815), tips (ER46817), commissions
	// (ER46819), professional practice or trade (ER46821), market gardening
	// (ER46823), additional job income (ER46825), and miscellaneous labor income
	// (ER46827). Note that farm income (ER46806) and the labor portion of
	// business income (ER46808) are NOT included here. All missing data were
	// assigned.
	// [68]V74 [69]V514 [70]V1196 [71]V1897 [72]V2498 [73]V3051 [74]V3463
	// [75]V3863 [76]V5031 [77]V5627 [78]V6174 [79]V6767 [80]V7413 [81]V8066
	// [82]V8690 [83]V9376 [84]V11023 [85]V12372 [86]V13624 [87]V14671 [88]V16145
	// [89]V17534 [90]V18878 [91]V20178 [92]V21484 [93]V23323 [94]ER4140
	// [95]ER6980 [96]ER9231 [97]ER12080
	[99]ER16463 [01]ER20443 [03]ER24116 [05]ER27931 [07]ER40921 [09]ER46829
	[11]ER52237 [13]ER58038 [15]ER65216

	// Spouse's Labor Income, Excluding Farm and Unincorporated Business Income
	|| inc_spouse
	// [93]V21807 [94]ER4144 [95]ER6984 [96]ER9235 [97]ER12082
	[99]ER16465 [01]ER20447 [03]ER24135 [05]ER27943 [07]ER40933 [09]ER46841
	[11]ER52249 [13]ER58050 [15]ER65244

	// TODO: could look into social security. Questionnaire says: Did you
	// (HEAD) (or anyone else in the family there) receive any income in 2004
	// from Social Security? Was that disability, retirement, survivor's
	// benefits, or what? How much was it?

	// TODO: could look into retirement income:
	// Did you (HEAD) receive any income in 2004 from the Veteran's
	// Administration for a servicemen's, (widow's,) or survivor's pension,
	// service disability, or the GI bill? Did you (HEAD) receive any income
	// in 2004 from other retirement pay, pensions, or annuities?

	// Head and spouse's transfer income (except social security)
	|| inc_transfer
	// [70]V1220 [71]V1922 [72]V2523 [73]V3076 [74]V3488 [75]V3889 [76]V4404
	// [77]V5316 [78]V5815 [79]V6426 [80]V7016 [81]V7608 [82]V8301 [83]V8909
	// [84]V10305 [85]V11461 [86]V12868 [87]V13970 [88]V14985 [89]V16485
	// [90]V17901 [91]V19201 [92]V20501 [93]V22366 [94]ER4147 [95]ER6987
	// [96]ER9238 [97]ER12071
	[99]ER16454 [01]ER20450 [03]ER24101 [05]ER28002 [07]ER40992 [09]ER46900
	[11]ER52308 [13]ER58117 [15]ER65314

	// Head's Income from Social Security last year
	|| inc_ss_head
	// [86]V12832 [87]V13934 [88]V14949 [89]V16449 [90]V17865 [91]V19165
	// [92]V20465 [93]V22027
	[05]ER28031 [07]ER41021 [09]ER46929 [11]ER52337 [13]ER58146 [15]ER65343

	// Wife's Income from Social Security last year
	|| inc_ss_spouse
	// [86]V12853 [87]V13955 [88]V14970 [89]V16470 [90]V17886 [91]V19186
	// [92]V20486 [93]V22301
	[05]ER28033 [07]ER41023 [09]ER46931 [11]ER52339 [13]ER58148 [15]ER65345

	// Total Income from Social Security of All Other FU Members in FU last year --NOT PRORATED
	|| inc_ss_ofum
	// [75]V3898 [76]V4412 [77]V5324 [78]V5824 [79]V6435 [80]V7039 [81]V7631
	// [82]V8324 [83]V8932 [84]V10388 [85]V11568 [86]V12975 [87]V14077
	// [88]V15092 [89]V16592 [90]V18008 [91]V19308 [92]V20608 [93]V22380
	[05]ER28035 [07]ER41025 [09]ER46933 [11]ER52341 [13]ER58150 [15]ER65347

	// Total Family Social Security Income last year
	|| inc_ss_fam
	// This variable includes Social Security income for Heads, Wives/"Wives",
	// and OFUMs.
	// [94]ER4152 [95]ER6992 [96]ER9243 [97]ER12077
	[99]ER16460 [01]ER20455 [03]ER24104

	// NOTE: between 99 and 03, we have inc_ss_fam. between 05 and 15, sum up inc_ss_head, inc_ss_spouse, and inc_ss_ofum


	//////////////////////////////////////////////////////////////////////////
	// EXPENDITURE
	//////////////////////////////////////////////////////////////////////////

	// Expenditures are reported for the family as a whole, where a PSID
	// family is defined as a group of people living together as a family.
	// Family members are generally related by blood, marriage, or adoption,
	// but unrelated persons can be part of the same PSID family unit if they
	// permanently reside together and share both income and expenses.

	// food expenditure
	// Total Family Food Expenditure: Generated variable combining
	// expenditures for food at home, delivered, and eaten away from home.
	|| foodexpenditure
	[99]ER16515A1 [01]ER20456A1 [03]ER24138A1 [05]ER28037A1 [07]ER41027A1
	[09]ER46971A1 [11]ER52395A1 [13]ER58212A1 [15]ER65410

	|| foodathomeexpenditure
	// F18. How much do you spend on that food in an average week?
	// F22. How much do you (and everyone else in your family) spend on food
	// that you use at home in an average week?
	[99]ER16515A2 [01]ER20456A2 [03]ER24138A2 [05]ER28037A2 [07]ER41027A2
	[09]ER46971A2 [11]ER52395A2 [13]ER58212A2 [15]ER65411

	|| foodawayfromhomeexpenditure
	// F21. About how much do you spend eating out?
	// F25. About how much do you (and everyone else in your family) spend eating out?
	[99]ER16515A3 [01]ER20456A3 [03]ER24138A3 [05]ER28037A3 [07]ER41027A3
	[09]ER46971A3 [11]ER52395A3 [13]ER58212A3 [15]ER65412

	|| fooddeliveredexpenditure
	[99]ER16515A4 [01]ER20456A4 [03]ER24138A4 [05]ER28037A4 [07]ER41027A4
	[09]ER46971A4 [11]ER52395A4 [13]ER58212A4 [15]ER65413

	// F12. How much did (you/they) receive in food stamp benefits in previous year?
	// (included because food stamps is not measured in food expenditure)
	|| foodstamp
	// [93]V21713 [94]ER3060 [95]ER6059 [96]ER8156 [97]ER11050
	[99]ER14256 [01]ER18387 [03]ER21653 [05]ER25655 [07]ER36673 [09]ER42692
	[11]ER48008 [13]ER53705 [15]ER60720

	// housing expenditure
	|| housingexpenditure
	[99]ER16515A5 [01]ER20456A5 [03]ER24138A5 [05]ER28037A5 [07]ER41027A5
	[09]ER46971A5 [11]ER52395A5 [13]ER58212A5 [15]ER65414

	// mortgage expenditure
	|| mortgageexpenditure
	[99]ER16515A6 [01]ER20456A6 [03]ER24138A6 [05]ER28037A6 [07]ER41027A6
	[09]ER46971A6 [11]ER52395A6 [13]ER58212A6 [15]ER65415

	// A25. How much are your monthly mortgage payments?
	// Missing values are imputed. Imputation may result in negative values
	// due to linear regression model. These negative values are kept in order
	// to preserve population mean consistent with the estimation.

	// rent expenditure
	|| rentexpenditure
	[99]ER16515A7 [01]ER20456A7 [03]ER24138A7 [05]ER28037A7 [07]ER41027A7
	[09]ER46971A7 [11]ER52395A7 [13]ER58212A7 [15]ER65416

	|| propertytaxexpenditure
	[99]ER16515A8 [01]ER20456A8 [03]ER24138A8 [05]ER28037A8 [07]ER41027A8
	[09]ER46971A8 [11]ER52395A8 [13]ER58212A8 [15]ER65417

	|| homeinsuranceexpenditure
	[99]ER16515A9 [01]ER20456A9 [03]ER24138A9 [05]ER28037A9 [07]ER41027A9
	[09]ER46971A9 [11]ER52395A9 [13]ER58212A9 [15]ER65418

	|| utilityexpenditure
	// Generated variable combining expenditures for gas, electricity, water and sewer, and other utilities.
	[99]ER16515B1 [01]ER20456B1 [03]ER24138B1 [05]ER28037B1 [07]ER41027B1
	[09]ER46971B1 [11]ER52395B1 [13]ER58212B1 [15]ER65419

	|| transportationexpenditure
	// Total Family Transportation Expenditure: Generated variable combining
	// expenditures for vehicle loan, lease, and down payments, insurance,
	// other vehicle expenditures, repairs and maintenance, gasoline, parking
	// and car pool, bus fares and train fares, taxicabs and other
	// transportation.
	// Note: can be broken down further if needed
	[99]ER16515B6 [01]ER20456B6 [03]ER24138B6 [05]ER28037B7 [07]ER41027B7
	[09]ER46971B7 [11]ER52395B7 [13]ER58212B7 [15]ER65425

	/* subcomponents of transportation (total annual cost imputed) */

	|| vehicleloanexpenditure
	[99]ER16515B7 [01]ER20456B7 [03]ER24138B7 [05]ER28037B8 [07]ER41027B8
	[09]ER46971B8 [11]ER52395B8 [13]ER58212B8 [15]ER65426

	// vehicle down payment expenditure
	|| vehicledpexpenditure
	[99]ER16515B8 [01]ER20456B8 [03]ER24138B8 [05]ER28037B9 [07]ER41027B9
	[09]ER46971B9 [11]ER52395B9 [13]ER58212B9 [15]ER65427

	|| vehicleleaseexpenditure
	[99]ER16515B9 [01]ER20456B9 [03]ER24138B9 [05]ER28037C1 [07]ER41027C1
	[09]ER46971C1 [11]ER52395C1 [13]ER58212C1 [15]ER65428

	// auto insurance
	|| autoinsexpenditure
	[99]ER16515C1 [01]ER20456C1 [03]ER24138C1 [05]ER28037C2 [07]ER41027C2
	[09]ER46971C2 [11]ER52395C2 [13]ER58212C2 [15]ER65429

	// additional vehicle expenditure
	|| addvehicleexpenditure
	[99]ER16515C2 [01]ER20456C2 [03]ER24138C2 [05]ER28037C3 [07]ER41027C3
	[09]ER46971C3 [11]ER52395C3 [13]ER58212C3 [15]ER65430

	|| vehiclerepairexpenditure
	[99]ER16515C3 [01]ER20456C3 [03]ER24138C3 [05]ER28037C4 [07]ER41027C4
	[09]ER46971C4 [11]ER52395C4 [13]ER58212C4 [15]ER65431

	|| gasolineexpenditure
	[99]ER16515C4 [01]ER20456C4 [03]ER24138C4 [05]ER28037C5 [07]ER41027C5
	[09]ER46971C5 [11]ER52395C5 [13]ER58212C5 [15]ER65432

	|| parkingexpenditure
	// includes carpool
	[99]ER16515C5 [01]ER20456C5 [03]ER24138C5 [05]ER28037C6 [07]ER41027C6
	[09]ER46971C6 [11]ER52395C6 [13]ER58212C6 [15]ER65433

	|| bustrainexpenditure
	[99]ER16515C6 [01]ER20456C6 [03]ER24138C6 [05]ER28037C7 [07]ER41027C7
	[09]ER46971C7 [11]ER52395C7 [13]ER58212C7 [15]ER65434

	|| taxiexpenditure
	[99]ER16515C7 [01]ER20456C7 [03]ER24138C7 [05]ER28037C8 [07]ER41027C8
	[09]ER46971C8 [11]ER52395C8 [13]ER58212C8 [15]ER65435

	|| othertransexpenditure
	[99]ER16515C8 [01]ER20456C8 [03]ER24138C8 [05]ER28037C9 [07]ER41027C9
	[09]ER46971C9 [11]ER52395C9 [13]ER58212C9 [15]ER65436

	/* end of subcomponents of transportation */

	|| educationexpenditure
	[99]ER16515C9 [01]ER20456C9 [03]ER24138C9 [05]ER28037D1 [07]ER41027D1
	[09]ER46971D1 [11]ER52395D1 [13]ER58212D1 [15]ER65437

	|| childcareexpenditure
	[99]ER16515D1 [01]ER20456D1 [03]ER24138D1 [05]ER28037D2 [07]ER41027D2
	[09]ER46971D2 [11]ER52395D2 [13]ER58212D2 [15]ER65438

	|| healthcareexpenditure
	// Total Family Health Care Expenditure: Generated variable combining
	// expenditures for hospital and nursing home, doctor, prescription drugs
	// and insurance.
	[99]ER16515D2 [01]ER20456D2 [03]ER24138D2 [05]ER28037D3 [07]ER41027D3
	[09]ER46971D3 [11]ER52395D3 [13]ER58212D3 [15]ER65439

	|| healthinsuranceexpenditure
	// Note: subcomponenet of healthcareexpenditure
	[99]ER16515D6 [01]ER20456D6 [03]ER24138D6 [05]ER28037D7 [07]ER41027D7
	[09]ER46971D7 [11]ER52395D7 [13]ER58212D7 [15]ER65443


	|| telephoneexpenditure
	// also includes internet
	[05]ER28037B6 [07]ER41027B6 [09]ER46971B6 [11]ER52395B6 [13]ER58212B6
	[15]ER65424

	// Household repairs
	|| repairsexpenditure
	// How much did you (and your family living there) spend altogether in
	// 2012 on home repairs and maintenance, including materials plus any
	// costs for hiring a professional?
	[05]ER28037D8 [07]ER41027D8 [09]ER46971D8 [11]ER52395D8 [13]ER58212D8
	[15]ER65444

	// Household furnishings
	|| furnishingsexpenditure
	// F88. How much did you (and your family living there) spend altogether
	// in 2012 on household furnishings and equipment, including household
	// textiles, furniture, floor coverings, major appliances, small
	// appliances and miscellaneous housewares?
	[05]ER28037D9 [07]ER41027D9 [09]ER46971D9 [11]ER52395D9 [13]ER58212D9
	[15]ER65445

	|| clothingexpenditure
	// F89. How much did you (and your family living there) spend altogether
	// in 2012 on clothing and apparel, including footwear, outerwear, and
	// products such as watches or jewelry?
	[05]ER28037E1 [07]ER41027E1 [09]ER46971E1 [11]ER52395E1 [13]ER58212E1
	[15]ER65446

	|| tripsexpenditure
	// F90. How much did you (and your family living there) spend altogether
	// in 2012 on trips and vacations, including transportation,
	// accommodations, and recreational expenses on trips?
	[05]ER28037E2 [07]ER41027E2 [09]ER46971E2 [11]ER52395E2 [13]ER58212E2
	[15]ER65447

	|| recreationexpenditure
	// F91. How much did you (and your family living there) spend altogether
	// in 2012 on recreation and entertainment, including tickets to movies,
	// sporting events, and performing arts and hobbies including exercise,
	// bicycles, trailers, camping, photography, and reading materials? (Do
	// not include costs associated with the trips and vacations you mentioned
	// previously.)
	[05]ER28037E3 [07]ER41027E3 [09]ER46971E3 [11]ER52395E3 [13]ER58212E3
	[15]ER65448


	//////////////////////////////////////////////////////////////////////////
	// WEALTH
	// note: there's lots of other wealth information starting in 1999 (plus going back in 1984 and 1989)
	// (checking accounts, stock, home equity, inheritance, etc)
	// (can even see information on mortgages, home equity loans, etc ER60047)
	//////////////////////////////////////////////////////////////////////////

	// Total Family Wealth excluding home equity
	|| fam_wealth_ex_home
	// This variable is constructed as sum of values of six asset types (S103,
	// S105, S109, S111, S113, S115) net of debt value (S107)
	// (sometimes imputed. see accuracy codes ER58210 etc)
	// [84]S116 [89]S216 [94]S316
	[99]S416 [01]S516 [03]S616 [05]S716 [07]S816 [09]ER46968 [11]ER52392
	[13]ER58209 [15]ER65406

	// Total Family Wealth including home equity
	// also known as IMP WEALTH W/ EQUITY (WEALTH2)
	|| fam_wealth
	// In 2013: Constructed wealth variable, including equity. This imputed variable is
	// constructed as the sum of values of seven asset types (ER58155,
	// ER58161, ER58165, ER58171, ER58173, ER58177, ER58181) net of debt value
	// (ER58157, ER58167, ER58185, ER58189, ER58193, ER58197, ER58201,
	// ER58205) plus value of home equity (ER58207). All missing data were
	// assigned.
	// NOTE: this was the description for 2013. Some of these debt categories
	// were lumped together prior to 2011. For instance, in 2011 they started
	// differentiating between credit card debt and other types of debt
	// [84]S117 [89]S217 [94]S317
	[99]S417 [01]S517 [03]S617 [05]S717 [07]S817 [09]ER46970 [11]ER52394
	[13]ER58211 [15]ER65408

	// In 2001:
	// This variable is constructed as sum of values of seven asset types
	// (S503, S505, S509, S511, S513, S515, S519) net of
	// debt value (S507) plus value of home equity.
	// S503 = NET business wealth - NOT LIQUID
	// S505 = checking/savings
	// S509 = NET other real estate - NOT LIQUID -- W2.If you sold all that and paid off any debts on it, how much would you realize on it?
	// S511 = stocks
	// S513 = vehicles - NOT LIQUID
	// S515 = "other assets" - NOT LIQUID (???)
	// S519 = annuity / IRA - NOT LIQUID
	// S507 = "other debt" = W39. If you added up all these [debts/debts for all of your family], about how much would they amount to right now?
	// Plus home equity (I think thats S520 in 2001)
	// NOTE: when we define wealth, lets do everything except IRA
	// TODO: how to deal with "other real estate"... SHIT
	// NOTE: you can have loan for your IRA as well, but we can not identify that in PSID
	// NOTE: for now, define liquid wealth = fam_wealth - homeequity - IRA_wealth. It's not perfect, b/c "other real estate" is included in liquid. But there's no good way to separate out debt on other real estate, so we'll just include a footnote in the paper

	// IMP VAL CHECKING/SAVING (W28)
	|| bank_account_wealth
	// W28. If you added up all such accounts [ for all of your family living
	// here], about how much would they amount to right now? This is an
	// imputed version of a variable used in the creation of the 2013 Wealth
	// summary variables. All missing data were assigned.
	// [84]S105 [89]S205 [94]S305
	[99]S405 [01]S505 [03]S605 [05]S705 [07]S805 [09]ER46942 [11]ER52350
	[13]ER58161 [15]ER65358
	// imputed for just under 5% of people

	// IMP VALUE ANNUITY/IRA (W22)
	|| IRA_wealth
	// W22. How much would they be worth? This is an imputed version of a
	// variable used in the creation of the 2013 Wealth summary variables. All
	// missing data were assigned.
	[99]S419 [01]S519 [03]S619 [05]S719 [07]S819 [09]ER46964 [11]ER52368
	[13]ER58181 [15]ER65378

	// IMP VALUE STOCKS (W16)
	|| stock_wealth
	// W16. If you sold all that and paid off anything you owed on it, how
	// much would you have? This is an imputed version of a variable used in
	// the creation of the 2013 Wealth summary variables. All missing data
	// were assigned.
	// [84]S111 [89]S211 [94]S311
	[99]S411 [01]S511 [03]S611 [05]S711 [07]S811 [09]ER46954 [11]ER52358
	[13]ER58171 [15]ER65368

	|| business_wealth // NOTE: this is NET
	// [84]S103 [89]S203 [94]S303
	/*W11. If you sold all that and paid off any debts on it, how much would you realize on it?*/
	[99]S403 [01]S503 [03]S603 [05]S703 [07]S803 [09]ER46938 [11]ER52346

	// In 2013 onwards, they broke business_wealth into two categories: value and debt
	|| business_value
	[13]ER58155 [15]ER65352

	|| business_debt
	[13]ER58157 [15]ER65354

	// W2.If you sold all that and paid off any debts on it, how much would you realize on it?
	|| other_real_estate_wealth // NET
	// [84]S109 [89]S209 [94]S309
	[99]S409 [01]S509 [03]S609 [05]S709 [07]S809 [09]ER46950 [11]ER52354

	|| other_real_estate_value
	[13]ER58165 [15]ER65362

	|| other_real_estate_debt
	[13]ER58167 [15]ER65364


	//////////////////////////////////////////////////////////////////////////
	// HOUSING
	//////////////////////////////////////////////////////////////////////////

	|| housevalue
	// Could you tell me what the present value of (your/their)
	// (apartment/mobile home/house) is (including the value of the lot if
	// (you/they) own the lot)--I mean about how much would it bring if
	// (you/they) sold it today?
	// [68]V5 [69]V449 [70]V1122 [71]V1823 [72]V2423 [73]V3021 [74]V3417
	// [75]V3817 [76]V4318 [77]V5217 [78]V5717 [79]V6319 [80]V6917 [81]V7517
	// [82]V8217 [83]V8817 [84]V10018 [85]V11125 [86]V12524 [87]V13724
	// [88]V14824 [89]V16324 [90]V17724 [91]V19024 [92]V20324 [93]V21610
	// [94]ER2033 [95]ER5032 [96]ER7032 [97]ER10036
	[99]ER13041 [01]ER17044 [03]ER21043 [05]ER25029 [07]ER36029 [09]ER42030
	[11]ER47330 [13]ER53030 [15]ER60031

	// IMP VALUE HOME EQUITY
	|| homeequity
	// Constructed value of home equity. This imputed variable is constructed
	// as: value-of-home (A20) minus mortgage-1 (A24, first mention) minus
	// mortgage-2 (A24, second mention). All missing data were assigned.
	// [84]S120 [89]S220 [94]S320
	[99]S420 [01]S520 [03]S620 [05]S720 [07]S820 [09]ER46966 [11]ER52390
	[13]ER58207 [15]ER65404

	// Own or Rent
	|| housingstatus
	// [68]V103 [69]V593 [70]V1264 [71]V1967 [72]V2566 [73]V3108 [74]V3522
	// [75]V3939 [76]V4450 [77]V5364 [78]V5864 [79]V6479 [80]V7084 [81]V7675
	// [82]V8364 [83]V8974 [84]V10437 [85]V11618 [86]V13023 [87]V14126
	// [88]V15140 [89]V16641 [90]V18072 [91]V19372 [92]V20672 [93]V22427
	// [94]ER2032 [95]ER5031 [96]ER7031 [97]ER10035
	[99]ER13040 [01]ER17043 [03]ER21042 [05]ER25028 [07]ER36028 [09]ER42029
	[11]ER47329 [13]ER53029 [15]ER60030

	// TYPE MORTGAGE MOR 1
	|| type_mortgage1
	// A23a. Is that a mortgage, a land contract, a home equity loan, or what?
	// --FIRST MORTGAGE
	// [96]ER7036 [97]ER10040
	[99]ER13045 [01]ER17050 [03]ER21049 [05]ER25040 [07]ER36040 [09]ER42041
	[11]ER47346 [13]ER53046 [15]ER60047

	|| type_mortgage2
	// may be interesting! I notice that in 2013, 246 obs with home equity loan (2.7%)
	// and 38 obs (.4%) with line of credit loan
	// [96]ER7037 [97]ER10041
	[99]ER13054 [01]ER17061 [03]ER21060 [05]ER25051 [07]ER36052 [09]ER42060
	[11]ER47367 [13]ER53067 [15]ER60068

	// REM PRINCIPAL MOR 1
	|| mortgage1
	// A24. About how much is the remaining principal on this loan?--FIRST
	// MORTGAGE The values for this variable represent the principal currently
	// owed from all mortgages or land contracts on the home in whole dollars.
	// [69]V451 [70]V1124 [71]V1825 [72]V2425 [76]V4320 [77]V5219 [78]V5719
	// [79]V6321 [80]V6919 [81]V7519 [83]V8819 [84]V10020 [85]V11127
	// [86]V12526 [87]V13726 [88]V14826 [89]V16326 [90]V17726 [91]V19026
	// [92]V20326 [93]V21612 [94]ER2037 [95]ER5036 [96]ER7042 [97]ER10044
	[99]ER13047 [01]ER17052 [03]ER21051 [05]ER25042 [07]ER36042 [09]ER42043
	[11]ER47348 [13]ER53048 [15]ER60049

	// REM PRINCIPAL MOR 2
	|| mortgage2
	// About how much is the remaining principal on this loan?--SECOND
	// MORTGAGE. The values for this variable represent the principal
	// currently owed on the second mortgage or land contract on the home in
	// whole dollars.
	// [94]ER2038 [95]ER5037 [96]ER7043 [97]ER10045
	[99]ER13056 [01]ER17063 [03]ER21062 [05]ER25053 [07]ER36054 [09]ER42062
	[11]ER47369 [13]ER53069 [15]ER60070
	// Note: very few people have second mortgage. 4% in 2013

	// How many rooms do you have (for your family) not counting bathrooms?
	|| room_count
	// [68]V102 [69]V592 [70]V1263 [71]V1966 [72]V2565 [73]V3107 [74]V3521
	// [75]V3937 [76]V4448 [77]V5362 [78]V5862 [79]V6477 [80]V7080 [81]V7671
	// [82]V8360 [83]V8969 [84]V10432 [85]V11614 [86]V13019 [87]V14122
	// [88]V15138 [89]V16639 [90]V18070 [91]V19370 [92]V20670 [93]V22425
	// [94]ER2029 [95]ER5028 [96]ER7028 [97]ER10032
	[99]ER13037 [01]ER17040 [03]ER21039 [05]ER25027 [07]ER36027 [09]ER42028
	[11]ER47328 [13]ER53028 [15]ER60029

	// Year Moved into current house
	|| year_moved
	// What is the street address and move-in date of (your/HEAD's) current residence?
	//[93]V22443 [94]ER2064 [95]ER5063 [96]ER7157 [97]ER10074
	[99]ER13079 [01]ER17090 [03]ER21119 [05]ER25100 [07]ER36105 [09]ER42134
	[11]ER47442 [13]ER53142 [15]ER60157

	|| month_moved
	// The month coded here is that of the most recent move since the yyyy interview.
	// (Have you/Has [he/she]) lived anywhere else since January yyyy-2?
	// [75]V3942 [76]V4453 [77]V5367 [78]V5867 [79]V6485 [80]V7090 [81]V7701
	// [83]V9000 [84]V10448 [85]V11629 [86]V13038 [87]V14141 [88]V15149
	// [89]V16650 [90]V18088 [91]V19388 [92]V20688 [93]V22442 [94]ER2063
	// [95]ER5062 [96]ER7156 [97]ER10073
	[99]ER13078 [01]ER17089 [03]ER21118 [05]ER25099 [07]ER36104 [09]ER42133
	[11]ER47441 [13]ER53141 [15]ER60156

	// TODO: A50. Why did (you/HEAD) move?--FIRST MENTION ... ER60158 etc

	// TODO: A51. Do you think (you/HEAD) might move in the next couple of years? ... ER60161
	// TODO: ER60162(2015)  	"A52 LIKELIHOOD OF MOVING"
	// A52. Would you say (you/HEAD) definitely will move, probably will move, or are you more uncertain?

	|| current_state
	// Current State (FIPS Code)
	// Please refer to FIPS state codes here http://psidonline.isr.umich.edu/data/Documentation/FIPSStateCodes.pdf
	// [85]V12380 [86]V13632 [87]V14679 [88]V16153 [89]V17539 [90]V18890 [91]V20190
	// [92]V21496 [93]V23328 [94]ER4157 [95]ER6997 [96]ER9248 [97]ER10004
	[99]ER13005 [01]ER17005 [03]ER21004 [05]ER25004 [07]ER36004 [09]ER42004
	[11]ER47304 [13]ER53004 [15]ER60004

	//////////////////////////////////////////////////////////////////////////
	// INHERITANCE
	//////////////////////////////////////////////////////////////////////////

	// WTR RECD GIFT/INHERITANCE
	|| received_gift
	// 1 = yes, 5 = no
	// W123. Some people's assets come from gifts and inheritances. During the
	// last x years, have you (or anyone in your family) received any large
	// gifts or inheritances of money or property worth $10,000 or more?
	// x is infinity in 1984, 5 in 1989, 1994, and 1999. Then 2 since then
	// [84]V10937 [89]V17381 [94]ER3836
	[99]ER15115 [01]ER19311 [03]ER22706 [05]ER26687 [07]ER37705 [09]ER43696
	[11]ER49041 [13]ER54797 [15]ER61908

	// What year did you receive that?--FIRST INHERITANCE
	|| year_gift_1
	// [84]V10939 [89]V17383 [94]ER3837
	[99]ER15116 [01]ER19312 [03]ER22707 [05]ER26688 [07]ER37706 [09]ER43697
	[11]ER49042 [13]ER54798 [15]ER61910

	// W125. How much was it worth altogether, at that time?--FIRST INHERITANCE
	|| value_gift_1
	// [84]V10940 [89]V17384 [94]ER3838
	[99]ER15117 [01]ER19313 [03]ER22708 [05]ER26689 [07]ER37707 [09]ER43698
	[11]ER49043 [13]ER54799 [15]ER61913

	// W129. What year did you receive that?--SECOND INHERITANCE
	|| year_gift_2
	// [84]V10944 [89]V17386 [94]ER3842
	[99]ER15121 [01]ER19317 [03]ER22712 [05]ER26693 [07]ER37711 [09]ER43702
	[11]ER49047 [13]ER54803 [15]ER61918

	// W130. How much was it worth altogether, at that time?--SECOND INHERITANCE
	|| value_gift_2
	// [94]ER3843
	[99]ER15122 [01]ER19318 [03]ER22713 [05]ER26694 [07]ER37712 [09]ER43703
	[11]ER49048 [13]ER54804 [15]ER61921

	// W133a. What year did you receive that?--THIRD INHERITANCE
	|| year_gift_3
	// [94]ER3847
	[99]ER15126 [01]ER19322 [03]ER22717 [05]ER26698 [07]ER37716 [09]ER43707
	[11]ER49052 [13]ER54808 [15]ER61926

	// W133b. How much was it worth altogether, at that time?--THIRD INHERITANCE
	|| value_gift_3
	// [94]ER3848
	[99]ER15127 [01]ER19323 [03]ER22718 [05]ER26699 [07]ER37717 [09]ER43708
	[11]ER49053 [13]ER54809 [15]ER61929

	//////////////////////////////////////////////////////////////////////////
	// WEIGHTS
	//////////////////////////////////////////////////////////////////////////

	// Combined Core-Immigrant Sample Individual Longitudinal Weight
	// (min = .25, max = 196.44)
	// This weight variable enfolds the 1997 and 1999 Immigrant samples. Values
	// are nonzero for sample members associated with either a 2009 core or 2009
	// Immigrant response family. No weight variable exists for analysis of the
	// core or the Immigrant samples separately.
	|| indiv_longitudinal_weight
	// [97]ER33430
	[99]ER33546 [01]ER33637 [03]ER33740 [05]ER33848 [07]ER33950 [09]ER34045
	[11]ER34154 [13]ER34268 [15]ER34413

	// Core-Immigrant Individual Cross-sectional Weight
	// (integers. min = 45, max = 85,742)
	// use the command [fweight = indiv_cross_sec_weight ]
	|| indiv_cross_sec_weight
	// [97]ER33438
	[99]ER33547 [01]ER33639 [03]ER33742 [05]ER33849 [07]ER33951 [09]ER34046
	[11]ER34155 [13]ER34269 [15]ER34414


	// Core/Immigrant Family Longitudinal Weight
	// This weight variable is used for analysis of all 2015 families, including
	// the immigrant sample families that were added in 1997 and 1999 as well as
	// the PSID core families.
	// The weight is constructed by summing the individual-level weight values
	// (ER34414) for all persons associated with a given PSID response family in
	// 2015 and calculating the average.
	|| family_weight
	// [97]ER12084
	[99]ER16518 [01]ER20394 [03]ER24179 [05]ER28078 [07]ER41069 [09]ER47012
	[11]ER52436 [13]ER58257 [15]ER65492


	// Pat Note: Alt Q to wrap text
    using "$folder\Data\Raw\PSID_Install", clear design(1)
    dofile(PSID-Setup-Replication, replace);

label define rel2head
10 "Head"
20 "Legal Wife"
22 "'Wife'--female cohabitor" // who has lived with Head for 12 months or more
30 "Son or daughter of Head" // (includes adopted children but not stepchildren)
33 "Stepson or stepdaughter of Head" // (children of legal Wife [code 20] who are not children of Head)
35 "Son or daughter of Wife (22) but not Head" // (includes only those children of mothers whose relationship to Head is 22 but who are not children of Head)
37 "Son-in-law or daughter-in-law of Head" // (includes stepchildren-in-law)
38 "Foster son or foster daughter" // not legally adopted
40 "Brother or sister of Head" // (includes step and half sisters and brothers)
47 "Brother-in-law or sister-in-law of Head" // i.e., brother or sister of legal Wife, or spouse of Head's brother or sister
48 "Brother or sister of Head's cohabitor" // (the cohabitor is coded 22 or 88)
50 "Father or mother of Head" // (includes stepparents)
57 "Father-in-law or mother-in-law of Head" // (includes parents of legal wives [code 20] only)
58 "Father or mother of Head's cohabitor" // (the cohabitor is coded 22 or 88)
60 "Grandson or granddaughter of Head" // (includes grandchildren of legal Wife [code 20] only; those of a cohabitor are coded 97)
65 "Great-grandson or great-granddaughter" // of Head (includes great-grandchildren of legal Wife [code 20]; those of a cohabitor are coded 97)
66 "Grandfather or grandmother of Head" // (includes stepgrandparents)
67 "Grandfather or grandmother of legal Wife " // (code 20)
68 "Great-grandfather or great-grandmother" // of Head
69 "Great-grandfather or great-grandmother" // of legal Wife (code 20)
70 "Nephew or niece of Head"
71 "Nephew or niece of legal Wife (code 20)"
72 "Uncle or Aunt of Head"
73 "Uncle or Aunt of legal Wife (code 20)"
74 "Cousin of Head"
75 "Cousin of legal Wife (code 20)"
83 "Children of first-year cohabitor" // but not of Head (the parent of this child is coded 88)
88 "First-year cohabitor of Head"
90 "Legal husband of Head"
95 "Other relative of Head"
96 "Other relative of legal Wife (code 20)"
97 "Other relative of cohabitor" // (the cohabitor is code 22 or 88)
98 "Other nonrelatives" // (includes homosexual partners, friends of children of the FU, etc.)
0 "Inap."; // from Latino sample (ER30001=7001-9308); main family nonresponse by 2011 or mover-out nonresponse by 2009 (ER34102=0)
		   // TODO: we drop everyone from latino sample, cause they don't have rel2head == 10. is this the norm?

label define fchg
0 "No change; no movers-in or movers-out of the family"
1 "Change in members other than Head or Spouse/Partner only"
2 "Head is the same but partner changed" // Spouse/Partner left or died; Head has new Spouse/Partner; used also when cohabiting, nonrelative female becomes Partner
3 "Spouse/Partner from last wave is now Head"
4 "Previous female Head got married--husband (usually a nonsample member) is now Head. " // Used also when cohabiting nonrelative male becomes Head
5 "Some sample individual other than previous Head or Spouse/Partner has become Head of this FU." // (Used primarily for male and unmarried female splitoffs.)
6 "Some sample female other than previous Head got married and her husband is now Head." // (Used primarily for married female splitoffs.)
7 "Female Head in last wave with husband in institution" // --husband in FU is now Head
8 "Other" // (used for recontacts and recombined families--these latter are usually Heads and spouses/partners who have parted for a wave or more, been interviewed separately, and who have reconciled at some time since the 2013 interview but prior to the 2015 interview).
9 "Underage splitoff child"; // Neither  Head nor Spouse/Partner (if there is one) is a sample member and neither of them was a Head or Spouse/Partner last year. (Used primarily for underage splitoff children.)

label define emp_status_lab
1 "Working now"
2 "Temp laid off; sick or maternity leave" // Only temporarily laid off, sick leave or maternity leave
3 "Looking for work, unemployed"
4 "Retired"
5 "Disabled" // Permanently disabled; temporarily disabled
6 "Keeping house"
7 "Student"
8 "Other" // Other; workfare; in prison or jail
99 "DK; NA; refused"
0 "NA"; // Inap. No spouse. Or no 2nd or 3rd mention

label define sex
1 "Male"
2 "Female"
9 "NA";

label define splitoff_lab
1 "Reinterview family"
2 "Splitoff from reinterview family"
3 "Recontact family"
4 "Splitoff from recontact family";

label define married
1 "Married"
2 "Never married"
3 "Widowed"
4 "Divorced"
5 "Separated"
8 "DK"
9 "NA; refused";

label define race
1 "White"
2 "Black" // Black, African-American, or Negro
3 "Native Am." // American Indian or Alaska Native
4 "Asian"
5 "Islander" // Native Hawaiian or Pacific Islander
7 "Other"
9 "NA"; // DK; NA; refused

label define why_last_job_end
1 "Company folded" // Company folded/changed hands/moved out of town; employer died/went out of business
2 "Strike; lockout"
3 "Laid off; fired"
4 "Quit; resigned; retired" // ; pregnant; needed more money; just wanted a change
7 "Other; transfer" // ; any mention of armed services
8 "Job was completed; temp" // ; seasonal work; was a temporary job
9 "DK; NA; refused"
0 "Inap."; // : did not work for money in 2002 or has not worked for money since January 1, 2001 (ER21127=5, 8, or 9); began working for this employer in 2003 (ER21130=2003); still working for this employer

label define housingstatus
1 "Owns" // Owns or is buying home, either fully or jointly; mobile home owners who rent lots are included here
5 "Rents"
8 "Neither";

label define type_mortgage
1 "Mortgage"
2 "Land contract, loan from seller"
3 "Home equity"
4 "Home improvement"
5 "Line of credit loan"
7 "Other"
8 "DK"
9 "NA; refused"
0 "Inap.";

#delimit cr

psid long

* Add up social security income
* Between 99 and 03 we have inc_ss_fam
* Between 05 and 15 we have inc_ss_head, inc_ss_spouse, and inc_ss_ofum
* For comparison, let's use inc_ss_fam
replace inc_ss_fam = inc_ss_head + inc_ss_spouse + inc_ss_ofum if wave >= 2005

* addvaluelabel does not work
* psid vardoc rel2head, addvaluelabel(rel2head)
* psid vardoc fchg, addvaluelabel(fam_change)

label values rel2head rel2head
label values fchg fchg
label values emp_status_head emp_status_lab
label values emp_status_head_2 emp_status_lab
label values emp_status_head_3 emp_status_lab
label values emp_status_spouse emp_status_lab
label values emp_status_spouse_2 emp_status_lab
label values emp_status_spouse_3 emp_status_lab
label values sex_head sex
label values sex_indiv sex
label values splitoff_indicator splitoff_lab
label values married married
label values racehead race
label values why_last_job_end why_last_job_end
label values why_last_job_end_spouse why_last_job_end
label values housingstatus housingstatus
label values type_mortgage1 type_mortgage
label values type_mortgage2 type_mortgage

rename xsqnr sequence
rename x11101ll pid
label var pid "Person identification number (1968 Interview Number * 1000 + Person Number)"
rename x11102 family_id

* Note on sequence variable
* 1 - 20	Individuals in the family at the time of the yy interview
* 51 - 59	Individuals in institutions at the time of the yy interview
* 71 - 80	Individuals who moved out of the FU or out of institutions and established their own households between the yy-2 and yy interviews
* 81 - 89	Individuals who were living in y but died by the time of the 1999 interview
* 0	Inap.: born or moved in after the 1999 interview; from Latino sample (ER30001=7001-9308); main family nonresponse by yy or mover-out nonresponse by yy-2 (ER33501=0)


* Note on personal indentification number
* gen long x11101ll = ER30001*1000 + ER30002
* lab var x11101ll "Person identification number"
* ER30001 = 1968 INTERVIEW NUMBER
* This variable is the 1968 family ID number. The combination of this variable
* and Person Number (ER30002) provides unique identification for each individual
* on the data file. Individuals associated with families from the Latino and
* Immigrant samples, added to the PSID in 1990/1992 and 1997/1999, respectively,
* were assigned 1968 IDs so that they, too, have unique identifiers compatible
* with the PSID structure for the core (SRC and Census) sample.
* ER30002 = Person Number

* SRC sample families have 1968 ID values less than 3000.
* Immigrant sample families have 1968 ID values greater than 3000 and less than 5000.
* SEO sample families have 1968 ID values greater than 5000 and less than 7000.
* Latino sample families have values greater than 7000 and less than 9309.

* x11102 = family ID number in that year
* 1999 FAMILY INTERVIEW (ID) NUMBER
* The values for this variable represent the 1999 interview number. The case
* count for 1999 is 6997, with 6927 core and 1997 Immigrant families, and 70
* Immigrant recontact families. Values for this variable may not be contiguous.
* [68]V3 [69]V442 [70]V1102 [71]V1802 [72]V2402 [73]V3002 [74]V3402 [75]V3802
* [76]V4302 [77]V5202 [78]V5702 [79]V6302 [80]V6902 [81]V7502 [82]V8202
* [83]V8802 [84]V10002 [85]V11102 [86]V12502 [87]V13702 [88]V14802 [89]V16302
* [90]V17702 [91]V19002 [92]V20302 [93]V21602 [94]ER2002 [95]ER5002 [96]ER7002
* [97]ER10002 [99]ER13002 [01]ER17002 [03]ER21002 [05]ER25002 [07]ER36002
* [09]ER42002 [11]ER47302 [13]ER53002 [15]ER60002

* For each family, the family ID number will most certainly vary from year to
* year. Yearly IDs are assigned based on the order in which interviews are
* received--the first interview in from field is numbered 1, the second, 2, and
* so on. This means it's very unlikely that a family with the Family ID Number
* 1234 in one year will get the same Family ID Number the next year, or any
* other year.

* Each family unit in a specific wave is assigned a unique "Family Interview
* (ID) Number" valid for that wave only. In addition, each family also has a
* "1968 Family Identifier", also known as the "1968 ID". This is the Family
* Interview (ID) Number that was assigned to the original family in the 1968
* interviewing wave. When sample members in any family move out and establish
* their own household, we interview them (these families are called "splitoffs",
* in the first year they are formed). These new "splitoff" families have the
* same 1968 ID as the family they moved out of, and keep that same 1968 ID each
* year. All families with the same 1968 ID contain at least one of the original
* members from the 1968 family or their lineal descendents born after 1968.

* Deal with DK or NA codings
replace foodstamp       = 0 if foodstamp >= 999998
lab var foodstamp       "Food stamps value last year"
lab var age             "Age"
replace housevalue      = 0 if housevalue >= 9999998
replace age_spouse      = . if age_spouse == 999
replace educhead        = . if educhead == 99
replace ret_year        = . if ret_year >= 9998
replace ret_year_spouse = . if ret_year_spouse >= 9998
replace mortgage1       = . if mortgage1 >= 9999998
replace mortgage2       = . if mortgage2 >= 9999998
replace year_born       = . if year_born == 9999

* Compute net business wealth for 2013 and 2015
replace business_wealth = business_value - business_debt if wave >= 2013
drop business_value business_debt

* Compute net "other real estate wealth" for 2013 and 2015
replace other_real_estate_wealth = other_real_estate_value - other_real_estate_debt if wave >= 2013
drop other_real_estate_value other_real_estate_debt

* Clean up the year_moved variable (coding is different in 1999 and 2001)
replace year_moved = 1997 if year_moved == 1 & wave == 1999
replace year_moved = 1998 if year_moved == 2 & wave == 1999
replace year_moved = 1999 if year_moved == 3 & wave == 1999
replace year_moved = 1999 if year_moved == 1 & wave == 2001
replace year_moved = 2000 if year_moved == 2 & wave == 2001
replace year_moved = 2001 if year_moved == 3 & wave == 2001

* Clean up month_moved (had some winter/spring/summer/fall options in 1999 and 2001)
replace month_moved = 1  if month_moved == 21
replace month_moved = 4  if month_moved == 22
replace month_moved = 7  if month_moved == 23
replace month_moved = 10 if month_moved == 24

* Clean up missings
replace month_moved     = . if month_moved == 0 | month_moved > 24 // should this be 12 or 24??
replace year_moved      = . if year_moved < 10 | year_moved > 2100

* Note fam_wealth is topcoded, but I just leave that as is for now

* Clean up inheritance/gift data
replace received_gift = . if received_gift > 5
forvalues i = 1/3{
	replace year_gift_`i' = .    if year_gift_`i' >= 9997 | year_gift_`i' == 0
	replace year_gift_`i' = 2013 if year_gift_`i' == 1 & wave == 2015
	replace year_gift_`i' = 2014 if year_gift_`i' == 2 & wave == 2015
	replace year_gift_`i' = 2015 if year_gift_`i' == 3 & wave == 2015
	replace year_gift_`i' = 2015 if year_gift_`i' == 7 & wave == 2015
	replace year_gift_`i' = .    if year_gift_`i' == 8 & wave == 2015
	replace year_gift_`i' = .    if year_gift_`i' == 1988 & wave == 1999
	replace year_gift_`i' = .    if year_gift_`i' == 1992 & wave == 1999
	replace value_gift_`i' = 0   if value_gift_`i' >= 999999998
	replace value_gift_`i' = 0   if ( value_gift_`i' == 9999998 | value_gift_`i' == 9999999 ) & wave >= 2013
}
egen value_gifts = rowtotal(value_gift_1 value_gift_2 value_gift_3)
lab var value_gifts "Value of inheritance/gifts since last wave"

* Look for other variables with error codes
summ *

****************************************************************************************************
** Count kids by age in each household (needed for Aguiar and Hurst regressions)
****************************************************************************************************

tempvar kid counted_children kid0_17 kid0_2 kid3_5 kid6_13 kid14_17m kid18_21m kid14_17f kid18_21f
gen `kid' = (rel2head != 10) & (rel2head != 20) & (rel2head != 22) & sequence > 0 & sequence <= 20

gen `kid0_17'  = `kid' & age <= 17 // this matches the PSID definition of children = all persons <= 17 who are not head/wife/"wife"
gen `kid0_2'   = `kid' & age >= 0  & age <= 2
gen `kid3_5'   = `kid' & age >= 3  & age <= 5
gen `kid6_13'  = `kid' & age >= 6  & age <= 13
gen `kid14_17m' = `kid' & age >= 14 & age <= 17 & sex_indiv == 1
gen `kid14_17f' = `kid' & age >= 14 & age <= 17 & sex_indiv == 2
gen `kid18_21m' = `kid' & age >= 18 & age <= 21 & sex_indiv == 1
gen `kid18_21f' = `kid' & age >= 18 & age <= 21 & sex_indiv == 2

by family_id wave, sort: egen `counted_children' = total(`kid0_17')
by family_id wave: egen children0_2   = total(`kid0_2')
by family_id wave: egen children3_5   = total(`kid3_5')
by family_id wave: egen children6_13  = total(`kid6_13')
by family_id wave: egen children14_17m = total(`kid14_17m')
by family_id wave: egen children14_17f = total(`kid14_17f')
by family_id wave: egen children18_21m = total(`kid18_21m')
by family_id wave: egen children18_21f = total(`kid18_21f')

* Apparently tempvars get saved in the dta file down below... that's annoying
drop `kid' `counted_children' `kid0_17' `kid0_2' `kid3_5' `kid6_13' `kid14_17m' `kid18_21m' `kid14_17f' `kid18_21f'

// gen DIF = `counted_children' - children
// tab DIF // this gets a 99.87% match

// sort family_id wave pid
// edit family_id wave pid age rel2head children counted_children kid sequence if DIF != 0

****************************************************************************************************
** Keep only heads of household
****************************************************************************************************

keep if family_id != .

* Keep only heads (as done in "Studying Consumption with the PSID")
keep if rel2head == 10
format %8.0g rel2head

* Replicate Table 2 in "Studying Consumption with the PSID"
preserve
	keep if age <= 100
	mean *expenditure [pweight = family_weight] if wave == 2005
restore

save "$folder\Data\Intermediate\Basic-Panel.dta", replace

* TODO: add in code from psid_sample.do


* TODO: why are there cases where sex_head changes?
by pid, sort: egen max_sex = max(sex_head)
by pid, sort: egen min_sex = min(sex_head)
gen dif = max_sex - min_sex
tab dif

* edit pid wave sex_head sex_indiv rel2head if dif == 1
