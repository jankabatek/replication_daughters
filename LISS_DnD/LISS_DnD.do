*------------------j.kabatek@unimelb.edu.au, 11/2020, (c)----------------------*
*                          Daughters and Divorce                               *
*                          J.Kabatek & D.C.Ribar                               *
*                                 -(J<)-                                       *
*------------------------------------------------------------------------------*
* README:                                                                      *
* To operationalize the code, change the root MAIN_FOL macro in the first      *
* uncommented block.                                                           *
*                                                                              *
* the folder 'data_sets' should contain the supplied LISS data extracts:       *
*   LISS_PARENT.dta                                                            *
*   LISS_TEEN.dta                                                              *
*                                                                              *
* if you want to create the LISS data extracts from scratch, make sure to have *
* access to the raw LISS datasets (https://www.lissdata.nl/). The code can be  *
* compiled if you uncomment the first block of code. Please make sure you have *
* downloaded all relevant modules:                                             *
*   Background variables     ("z/PANEL_z.dta")                                 *
*   Family and Household     ("f/PANEL_f.dta")                                 *
*   Health                   ("h/PANEL_h.dta")                                 *
*   Income                   ("i/PANEL_i.dta")                                 *
*   Personality              ("p/PANEL_p.dta")                                 *
*   Politics and Values      ("v/PANEL_v.dta")                                 *
*   Religion and ethnicity   ("r/PANEL_r.dta")                                 *
*   Time use and consumption ("bf/PANEL_bf.dta")                               *
* Before running the code, turn the raw datasets into module-specific panels   *
* The naming convention for the panel variables is 'x001' (see the supplied    *
* data extracts).                                                              * 
*                                                                              * 
*                                                                              *
* The code with supplied datasets takes about wo minutes to execute.           * 
*------------------------------------------------------------------------------*
*local folders
global MAIN_FOL "D:/Data/LISS_DnD"
global DOFILES 	"${MAIN_FOL}/auxiliary_scripts"
global DATA  	"${MAIN_FOL}/data_sets"
global RES	 	"${MAIN_FOL}/results"
 
clear matrix
clear
set mem 2000m
set more off 
  
*------------------------------------------------------------------------------*
/*
***( CODE )*********************************************************************
 
	cd "${DATA}"	
 
/* (1) PANEL GENERATION */

	use "f/PANEL_f.dta", clear
	cap gen wave = f_m
	save, replace
	
	* Assign BG vars in the months matching each respondents' CF collection months
	use "z/PANEL_z.dta", clear
	merge m:1 nomem_encr wave using "f/PANEL_f.dta", keep(match master) 
	
	bys nomem_encr year (wave): egen MATCH = max(_merge==3)
	drop if MATCH==1 & _merge!=3
	by nomem_encr year (wave): drop if MATCH==0 & _n==2
	drop _merge MATCH

	*add extra modules (not matched on BG months)
	local modules p v bf r i h
	local N: word count `modules'
	tokenize "`modules'"
	
	forv i=1(1)`N'{
		* note: year is not an original LISS var - may be prone to errors
		merge 1:1 nomem_encr year using  "``i''/PANEL_``i''.dta" , nogen
 
	}
	
	save "${DATA}/PANEL_DGH_UPD", replace

/* (2) CHILDREN'S CF VARS ORDERED BY SENIORITY */ 
	use "${DATA}/PANEL_DGH_UPD", clear
	
	/* correct for the 2015 child coding change  	*/
	forvalues i = 1/10 { //first 10 living children put into the usual children format
		local num = `i'+36
		local num2015 = `i'+455
		replace f0`num' = f`num2015' if year >=2015
	}

	/*  RENAME CHILD-ORDERING VARIABLES (coming from CF dataset!)*/

	forvalues i = 1/15 {
		local num = `i'+36
		rename f0`num' _BYR`i'
		
		local num = `i'+52
		rename f0`num' _PASSED`i'
		
		local num = `i'+67
		rename f0`num' _GEND`i'
		
		local num = `i'+82
		rename f0`num' _ATHOME`i'
		
		
		local num = `i'+97
		cap rename f0`num' _KNDPAR`i'
		cap rename f`num' _KNDPAR`i'
		
		local num = `i'+112
		rename f`num' _CPBIO`i'
	}
		
	preserve

	*code to ensure that the child recorded as the first one is also the eldest
	keep nomem_encr year _*
	
	gen id = _n
	reshape long _BYR _GEND  _PASSED _ATHOME _KNDPAR _CPBIO , i(id) j(kidno)

	*for each year-person record, order kid observations by year of birth and kidno number for twins/closely spaced siblings
	bys nomem_encr year (_BYR kidno): gen kidno2 = _n
	drop kidno
	reshape wide _BYR _GEND _PASSED _ATHOME _KNDPAR _CPBIO, i(id) j(kidno2)
	order _BYR* _GEND* _PASSED* _ATHOME* _KNDPAR* _CPBIO*

	tempfile aux
	drop id
	save `aux'

	restore
	*drop the potentially faulty kid-ordering variables
	drop _*
	
	*---------make all variable selections here:------------
	local varlist ///
	h125 h126 h133 h134 ///
	i232 i233 i234 i235 ///
	p011 ///
	r052 r053 r057 r060 r101 ///
	v124 v129 v151 
	
	keep no* z_* *_m year `varlist' b* f*
	*-------------------------------------------------------

	*replace and rename the kid-ordering variables
	merge 1:1 nomem_encr year using `aux', nogen
	renvars _*, predrop(1)
	
	order f* v* p*, alphabetic
	order no* z_*
	
	renvars z_* , predrop(2)
	compress
	save "${DATA}/PANEL_DGH_ORD_UPD2", replace
	 
/* (3) HOW MANY PEOPLE ARE WE LOSING IN EACH STEP? */
	
	use "${DATA}/PANEL_DGH_ORD_UPD2", clear
	drop if year >2016
	order no* year
	
	/* missing children indictor */
	bys nohouse_encr nomem_encr (year): gen missing =1 if BYR1==. & BYR1[_n-1]!=.
	for num 1/8 : bys nohouse_encr nomem_encr (year): replace missing =1 if BYR1==. & BYR1[_n-X]!=.
	
	/* correct child characteristics */
	qui forvalues i=1/8 { 
		for var BYR* PASS* GEND* ATHOME* KND* CPBIO* : bys nohouse_encr nomem_encr (year): replace X =X[_n-`i'] if X==. & X[_n-`i']!=. & doetmee==1 & woonvorm==3
	}
	
	/* gender assignment in years when the gender is missing */
	bys nohouse_encr nomem_encr (year): egen f003x =max(f003)
	replace f003 = f003x if f003==.
	drop f003x
	
	replace doetmee = 1 if f_m!=. | BYR1!=. // some people have missing doetmee (not matched by the May BGvars)
	 
	/* PARENTS */
	*household heads/partners error corrections
	gen HHH = positie <4
	bys nohouse_encr year: egen NHHH = sum(HHH)
	gen aux_agedif_hhh = lftdhhh - leeftijd
	replace positie =5 if (aux_agedif_hhh>18) & (NHHH>2 & HHH==1)
	drop HHH NHHH aux_agedif_hhh
	gen HHH = positie <4
	bys nohouse_encr year: egen NHHH = sum(HHH)
	drop if NHHH>2  
	drop HHH NHHH
  
	*quantify participants
	local ifclause woonvorm ==3 & positie <4
	
	*LISS participation
	tab doetmee  if `ifclause'
	qui sum nomem_encr if `ifclause' 
	local N = r(N)
	
	qui sum doetmee if `ifclause' & doetmee ==1
	local np = r(N)
	n di as err  `np' " out of " `N' " participated (" `np'/`N'*100 "%)" 
 
	*quantify questionaire response
	gen filled_f = f_m!=.
	replace filled_f = -99 if doetmee ==0
	
	tab filled_f  if `ifclause'
	tab filled_f  if `ifclause' & doetmee
	
	qui sum filled_f if `ifclause' &  filled_f ==1
	local nr = r(N)
	n di as err  `nr' " out of " `np' " participants responded (" %05.2f `nr'/`np'*100 "%)" 
 
	* identify couples with firstborn being a biological child
	gen bio1_own = KNDPAR1==1 & CPBIO1==1 & positie <4 			//1st recorded child is bioshared w/ partner
	bys  nohouse_encr year (positie nomem_encr) : egen BIO1 = max(bio1_own ) //copy to the h'hold members
	
	* parental age
	gen aux_m = leeftijd if geslacht==1 & positie <4 
	gen aux_w = leeftijd if geslacht==2 & positie <4 
	bys  nohouse_encr year (positie nomem_encr) : egen age_m = min(aux_m)
	bys  nohouse_encr year (positie nomem_encr) : egen age_w = min(aux_w)
	drop aux_m aux_w
	
	*parental education
	replace oplcat = 99 if oplcat==.
	gen education = (oplcat >=0) + (oplcat >2) + (oplcat >4) + (oplcat >6)
	gen aux_m = education if geslacht==1 & positie <4 
	gen aux_w = education if geslacht==2 & positie <4 
	bys  nohouse_encr year (positie nomem_encr) : egen edu_m = min(aux_m)
	bys  nohouse_encr year (positie nomem_encr) : egen edu_w = min(aux_w)
	drop aux_m aux_w
	
	* number and genders of children
	for any nb ng: cap gen X = 0
	for num 1/15: replace nb = nb +1 if GENDX ==1
	for num 1/15: replace ng = ng +1 if GENDX ==2
	for any nb ng: replace X = . if positie >=4
	bys  nohouse_encr year (positie nomem_encr) : egen NB = max(nb)
	bys  nohouse_encr year (positie nomem_encr) : egen NG = max(ng)
	drop nb ng
	gen NK = NB + NG
	
	*correct spouses mistaking themselves for children:
	gen minl = -leeftijd
	sort nohouse_encr year minl nomem_encr
	by nohouse_encr year: gen fail = woonvorm ==4 & BYR1[1]==BYR1[2] & BYR1 !=.
	replace positie = 2 if fail==1
	replace woonvorm = 3 if fail==1 
	preserve
		keep if aantalki >0
		keep if positie ==5
		keep nohouse_encr nomem_encr  year aantalki minl leeftijd
		
		sort nohouse_encr  year minl
		drop minl
		by nohouse_encr year: gen n=_n
		by nohouse_encr year: gen nk_lft = _N
		drop aantalki nomem_encr
		reshape wide leeftijd ,i(nohouse_encr year) j(n)
		tempfile lft
		save `lft'
	restore
	merge m:1 nohouse_encr year using `lft', nogen
	 
	* immigration background 
	gen HERK_08_10 = 1*(r053==1) + 2*(r053==2) + 10*(r057==2 | r060==2)
	replace HERK_08_10 = . if HERK_08_10==0
	replace HERK_08_10 = 203 if HERK_08_10==11
	replace HERK_08_10 = 203 if HERK_08_10==10
	replace HERK_08_10 = 103 if HERK_08_10==12 | HERK_08_10==2
	replace HERK_08_10 = 0 if HERK_08_10==1
 
	bys nomem_enc: egen HERK = max(herkomstgroep)
	bys nomem_enc: egen HERK2 = max(HERK_08_10)
	replace herkomstgroep = HERK if HERK!=. & herkomstgroep==.
	replace herkomstgroep = HERK2 if HERK2!=. & herkomstgroep==.
	
	replace herkomstgroep = 9999 if herkomstgroep==.
	gen GEN = (herkomstgroep >=0) + (herkomstgroep >10) + (herkomstgroep >200) +( herkomstgroep>205)
	gen aux_m = GEN if geslacht==1 & positie <4 
	gen aux_w = GEN if geslacht==2 & positie <4 
	bys  nohouse_encr year (positie nomem_encr) : egen gen_m = min(aux_m)
	bys  nohouse_encr year (positie nomem_encr) : egen gen_w = min(aux_w)
	drop aux_m aux_w
	
	* correcting biological child responses 
	gen nonmisbio = KNDPAR1!=. & positie <4			   			//child records are not missing		
	bys  nohouse_encr year (positie nomem_encr) : egen NONMIS1 = max(nonmisbi)
	replace BIO1 = -99 if woonvorm ==3 & BIO1==0 & NONMIS1 ==0 	// replace h'hold BIO indicator by -99 if child records are missing for whatever reason
	 
	/* INFORMATION FOR TABLE A3 STARTS HERE: */
	* quantify respondents with bio / step children
	tab BIO1 if  woonvorm ==3 & positie <4 & filled_f==1
	qui sum  BIO1 if filled_f ==1 &   positie <4 & woonvorm ==3 & BIO1==1  
	n di as err  r(N) " individuals share bio. children"
	qui sum  BIO1 if filled_f ==1 &   positie <4 & woonvorm ==3 & BIO1==0
	n di as err  r(N) " individuals do not share bio. children"
	
	/* for people who do not report details for the oldest kid, assume that the first reported details
	correspond to the oldest chidl as well. That is, the first child is not a step child */
	gen altbio2 =  KNDPAR2==1 & CPBIO2==1 & CPBIO1==. & positie <4
	bys  nohouse_encr year (positie nomem_encr) : egen ALTBIO2 = max(altbio2)
	gen altbio3 =  KNDPAR3==1 & CPBIO3==1 &   CPBIO1==. & CPBIO2==. & positie <4
	bys  nohouse_encr year (positie nomem_encr) : egen ALTBIO3 = max(altbio3)	
	gen BIO1HOUSE =  BIO1
	replace BIO1HOUSE = 1 if ALTBIO2 ==1
	replace BIO1HOUSE = 1 if ALTBIO3 ==1
	
	/* account for families with children who passed away (var: PASSED1-X)*/
	gen psd = PASSED1 ==1	
	by  nohouse_encr (year positie nomem_encr) : egen PSD = max(psd)		
	tab  BIO1 PSD if filled_f ==1 &   positie <4 & woonvorm ==3 //second box represents people whose first child passed away prior to entering LISS.
	  
	* quantify odd cases  
	qui sum  BIO1 if filled_f ==1 &   positie <4 & woonvorm ==3 & BIO1==-99 & PSD==1 
	n di as err  r(N) " individuals with first child passed away -> no bio info"
	qui sum  BIO1 if filled_f ==1 &   positie <4 & woonvorm ==3 & BIO1==-99 & PSD==0 
	n di as err  r(N) " individuals have no information on bio. children"
 
	/* generate child age & gender indicators conditional on the family / household reference */
	qui for num 1/15:gen age_ch_X = year - BYRX
	qui for num 1/15:gen agegrX = 1*(age_ch_X>=0 & age_ch_X<13) + 2*( age_ch_X>12 & age_ch_X<19) + 3*( age_ch_X>18 & age_ch_X<89)
	qui for num 1/15:gen teenX =  ( age_ch_X>12 & age_ch_X<19)
	
	//children (up to 18yrs) in the (extended) family (incl. kids living elsewhere)
	gen C18IDF=0 
	gen NC18F=0
	qui for num 1/15:replace C18IDF = 1 if C18IDF==0 & (age_ch_X>=0 & age_ch_X<19) & PASSEDX==.
	qui for num 1/15:replace NC18F = NC18F + 1 if (age_ch_X>=0 & age_ch_X<19) & PASSEDX==.

	tab  C18IDF if filled_f ==1 &   positie <4 & woonvorm ==3 & BIO1==1
	qui sum  C18IDF if filled_f ==1 &   positie <4 & woonvorm ==3 & BIO1==1 & C18IDF==1
	n di as err  r(N) " individuals who share 0-18yr old bio. children"
	
	//children (up to 18yrs) in the household
	gen C18IDH=0 
	gen D18IDH=0 //daughters (up to 18yrs) in the household  
	gen NC18H=0	 //number of children (up to 18yrs) in the household
	gen NC18DH=0 //number of daughters (up to 18yrs) in the household  
	gen NC19H=0
	gen NC19DH=0
	qui for num 1/15:replace C18IDH = 1 if C18IDH==0 & (age_ch_X>=0 & age_ch_X<19) & PASSEDX==.  & ATHOMEX==1
	qui for num 1/15:replace D18IDH = 1 if D18IDH==0 & (age_ch_X>=0 & age_ch_X<19) & PASSEDX==.  & ATHOMEX==1 & GENDX ==2

	qui for num 1/15:replace NC18H = NC18H + 1 if (age_ch_X>=0 & age_ch_X<19) & PASSEDX==.  & ATHOMEX==1
	qui for num 1/15:replace NC18DH = NC18DH + 1 if (age_ch_X>=0 & age_ch_X<19) & PASSEDX==.  & ATHOMEX==1  & GENDX ==2
	
	qui for num 1/15:replace NC19H = NC19H + 1 if (age_ch_X>=0 & age_ch_X<20) & PASSEDX==.  & ATHOMEX==1
	qui for num 1/15:replace NC19DH = NC19DH + 1 if (age_ch_X>=0 & age_ch_X<20) & PASSEDX==.  & ATHOMEX==1  & GENDX ==2
	
	gen NC19=0
	gen NC19D=0
	qui for num 1/15:replace NC19 = NC19 + 1 if (age_ch_X>=0 & age_ch_X<20) & PASSEDX==.  
	qui for num 1/15:replace NC19D = NC19D + 1 if (age_ch_X>=0 & age_ch_X<20) & PASSEDX==.  & GENDX ==2
	
	//teens in the family (incl. kids living elsewhere)
	gen TIDF=0 
	gen NTF = 0
	qui for num 1/15:replace TIDF = teenX if TIDF==0 & teenX==1 & PASSEDX==.
	qui for num 1/15:replace NTF = NTF + teenX if PASSEDX==.  
		
	tab  TIDF if filled_f ==1 &   positie <4 & woonvorm ==3 & BIO1==1
	qui sum  TIDF if filled_f ==1 &   positie <4 & woonvorm ==3 & BIO1==1 & TIDF==1
	n di as err  r(N) " individuals share bio. teenage children"
	
	//teens in the household
	gen TIDH=0 
	gen TDIDH=0
	gen NTH=0
	gen NTDH=0
	
	qui for num 1/15:replace TIDH = teenX if TIDH==0 & teenX==1 & PASSEDX==. & ATHOMEX==1
	qui for num 1/15:replace TDIDH = teenX if TDIDH==0 & teenX==1 & PASSEDX==. & ATHOMEX==1 & GENDX ==2
	qui for num 1/15:replace NTH = NTH + teenX if PASSEDX==. & ATHOMEX==1
	qui for num 1/15:replace NTDH = NTDH + teenX if PASSEDX==. & ATHOMEX==1 & GENDX ==2
	
	qui sum  TIDH if filled_f ==1 &   positie <4 & woonvorm ==3 & BIO1==1 & TIDH==1
	n di as err  r(N) " individuals live w/ bio. teenage children"

	* drop parents with missing education
	drop if edu_m==4
	drop if edu_w==4
	
	/* FAMILY INDICATORS */ 
	gen BIOFBC = filled_f ==1 &   positie <4 & woonvorm ==3 & PASSED1 ==. & BIO1==1 	
	gen BIOFBT = filled_f ==1 &   positie <4 & woonvorm ==3 & PASSED1 ==. & BIO1==1 & teen1==1
	gen BIOFBTH = filled_f ==1 &   positie <4 & woonvorm ==3 & PASSED1 ==. & BIO1==1 & teen1==1 & ATHOME1==1
	qui sum BIOFBTH if BIOFBTH==1
	n di as err  r(N) " individuals living w/ 1st born bio. teenager"
	
	gen BIOFBTH_MAR = BIOFBTH==1 &  f030==1
	qui sum BIOFBTH_MAR if BIOFBTH_MAR==1
	n di as err  r(N) " married individuals living w/ 1st born bio. teenager"
 
	gen BIOFBC18 = filled_f ==1 &   positie <4 & woonvorm ==3 & PASSED1 ==. & BIO1==1 & (age_ch_1>=0 & age_ch_1<19) 
	gen BIOFBC18H = filled_f ==1 &   positie <4 & woonvorm ==3 & PASSED1 ==. & BIO1==1 & (age_ch_1>=0 & age_ch_1<19) & ATHOME1==1
	gen BIOFBC18H_MAR = BIOFBC18H &  f030==1
	
	qui sum BIOFBC18 if BIOFBC18==1
	n di as err  r(N) "  individuals who have w/ 1st born bio. child less than 18"
	qui sum BIOFBC18H if BIOFBC18H==1
	n di as err  r(N) "  individuals living w/ 1st born bio. child less than 18"
 	qui sum BIOFBC18H_MAR if BIOFBC18H_MAR==1
	n di as err  r(N) " married individuals living w/ 1st born bio. child less than 18"

	/* PRODUCE AN AUXILIARY DATASET FOR TABLE A3 */
	preserve 
		keep if woonvorm ==3 & positie <4
		keep nomem_encr doetmee filled_f BIO1 C18IDF BIOFBC18H BIOFBC18H_MAR BIOFBTH_MAR
		label variable nomem_encr 		"id" 
		label variable doetmee 			"individuals participated"
		label variable filled_f			"individuals filled in the family module"
		label variable BIO1				"individuals share bio. children"
		label variable C18IDF			"individuals share 0-18yr old bio. children"
		label variable BIOFBC18H		"individuals living w/ 1st born bio. child less than 18"
		label variable BIOFBC18H_MAR	"married individuals living w/ 1st born bio. child less than 18"
		label variable BIOFBTH_MAR 		"married individuals living w/ 1st born bio. teenager"
		save "${DATA}/LISS_FREQUENCIES", replace   
	restore
	
	/* PRODUCE THE TEEN DATASET (16-19 yrs) */
	gen BIOFBC19 = filled_f ==1 &   positie <4 & woonvorm ==3 & PASSED1 ==. & BIO1==1 & (age_ch_1>=0 & age_ch_1<20) 
	gen BIOFBC19H = filled_f ==1 &   positie <4 & woonvorm ==3 & PASSED1 ==. & BIO1==1 & (age_ch_1>=0 & age_ch_1<20) & ATHOME1==1
	gen BIOFBC19H_MAR = BIOFBC19H &  f030==1	
	bys  nohouse_encr  (positie nomem_encr) : egen TH = max(BIOFBC19H)
	
	preserve
		* regression variables declaration
		bys nohouse_encr year (positie nomem_encr): egen AC1 =max(age_ch_1)
		bys nohouse_encr year (positie nomem_encr): egen BY1 =min(BYR1)
		bys nohouse_encr year (positie nomem_encr): egen BY2 =min(BYR2)
		bys nohouse_encr year (positie nomem_encr): egen NK_ALT =sum( pos==5)
		bys nohouse_encr year (positie nomem_encr): egen ND_ALT =sum( geslacht==2 & pos==5)	
		bys nohouse_encr year (positie nomem_encr): egen BIO =max(BIOFBC19H_MAR)
 
		gen NSIB018H = NK_ALT - ( pos==5)
		gen NSIB018DH = ND_ALT  - ( geslacht ==2 & pos==5)	
		gen FB = gebjaar == BY1
		gen girl = f003==2
		
		* sample selections
		keep if pos==5
		keep if leeftijd <19
		keep if TH==1
		
		* immigration variables adjustment (to prevent the regression dropping any observations)
		for var gen* : replace X = 1 if X==4 & herkomstgroep ==0
		for var gen* : replace X = 2 if X==4 & herkomstgroep ==101
		for var gen* : replace X = 2 if X==4 & herkomstgroep ==102
		for var gen* : replace X = 2 if X==4 & herkomstgroep ==201
		for var gen* : replace X = 2 if X==4 & herkomstgroep ==202
		replace gen_m = 4 if gen_w ==4
		replace gen_w = 4 if gen_m ==4
		replace gen_w = 4 if gen_m ==2 & gen_w ==3
		replace gen_m = 4 if gen_m ==2 & gen_w ==4
		
		*use reported age of parents
		replace age_m = year - f005 if f005 <2000
		replace age_w = year - f009 if f009 <2000
		
		drop if leeftijd < 15
		keep f161 f162 h125 h126 h133 h134 f024 ///
			 girl FB age_m age_w edu_* gen_* year NSIB018H NSIB018DH

		save "${DATA}/LISS_TEEN", replace
	restore
	
	/* PRODUCE THE PARENT DATASET */
	* regression variables  
	gen mom = f003 ==2
	gen daughter_1 = GEND1 ==2
	gen _CHLD = (BIOFBTH==1) + (BIOFBC18H==1) //1 for kids, 2 for teens	
	gen DGH012 = daughter_1*(_CHLD==1)
	gen PUB = _CHLD==2
	gen DPUB = daughter_1*PUB
	
	* number of children & daughters
	bys nohouse_encr year (positie nomem_encr): egen NSIB018H =sum( pos==5)
	bys nohouse_encr year (positie nomem_encr): egen NSIB018DH =sum( geslacht==2 & pos==5)
	replace NSIB018H = NSIB018H-1 if NSIB018H > 0
	replace NSIB018DH = NSIB018DH-1 if NSIB018DH > 0 & daughter_1==1
	
	* immigration variables adjustment (to prevent the regression dropping any observations)
	replace gen_m = 4 if gen_w==4
	replace gen_w = 4 if gen_m==4

	* outcome variable transformations
	for var f225-f236: recode X (1=3) (3=1) //recode behavioral questions (listed in descending order)
	  
	/*local lv_f180 ""
	local lv_f181 ""
	local lv_f182 "Can you indicate whether you and your partner had any differences of opinion regarding money expenditure over the past year?"
	local lv_f183 "Can you indicate whether you and your partner had any differences of opinion regarding raising the children over the past year?"
	local lv_f427 "All in all... caring for my child is not such a burden."
	local lv_f430 "Caring for my child costs so much energy that others sometimes get too little attention."
	local lv_f431 "My child is very easy to care for."	 
	local lv_v129 "A divorce is generally the best solution if a married couple cannot solve their marital problems"
 
	 foreach x in f180 f181 v151 v124 f432 p011{
		local lv_`x': variable label  `x'
	 }
	 
	 local text = ""
	 local xlab = "Dependent variables:  `lab'"
	 foreach x in f180 f181 f182 f183 v151 v129 v124 f432 f427 p011 {
		 local xlab = "`xlab' , `x': `lv_`x''"	 
	 } */
	 

	* sample selection  
	keep if BIOFBC18H_MAR ==1   & age_ch_1<19
	keep 	f180 f182 f183 v151 v129 v124 f432 f427 p011	///
			age_m age_w DGH012 PUB DPUB mom edu_* gen_* year NSIB018H NSIB018DH b013 b014 b114 b135
	
	compress
	save "${DATA}/LISS_PARENT", replace
	*/
	
/* ESTIMATION & OUTPUT ------------------------------------------------------ */ 	

/* OUTPUTS FOR TABLE A3*/
	use "${DATA}/LISS_FREQUENCIES", clear  
	 
	gen var1 = ""
	gen var2 = .
	local i = 1
	
	qui sum nomem_encr  
		local N = r(N)
		replace var1 = "individuals in the LISS households" if _n ==`i'
		replace var2 = r(N) if _n ==`i'
		local i = `i' + 1
	qui sum doetmee if  doetmee ==1
		local N = r(N)
		replace var1 = "individuals participated" if _n ==`i'
		replace var2 = r(N) if _n ==`i'
		local i = `i' + 1  
	qui sum  BIO1 if filled_f ==1  
		local N = r(N)
		replace var1 = "individuals filled in the family module" if _n ==`i'
		replace var2 = r(N) if _n ==`i'
		local i = `i' + 1
	qui sum  BIO1 if filled_f ==1 & BIO1==1  
		local N = r(N)
		replace var1 = "individuals share bio. children" if _n ==`i'
		replace var2 = r(N) if _n ==`i'
		local i = `i' + 1
	qui sum  C18IDF if filled_f ==1 & BIO1==1 & C18IDF==1
		local N = r(N)
		replace var1 = "individuals individuals share 0-18yr old bio. children" if _n ==`i'
		replace var2 = r(N) if _n ==`i'
		local i = `i' + 1
	qui sum BIOFBC18H if BIOFBC18H==1
		local N = r(N)
		replace var1 = "individuals living w/ 1st born bio. child less than 18" if _n ==`i'
		replace var2 = r(N) if _n ==`i'
		local i = `i' + 1
	qui sum BIOFBC18H_MAR if BIOFBC18H_MAR==1
		local N = r(N)
		replace var1 = "married individuals living w/ 1st born bio. child less than 18" if _n ==`i'
		replace var2 = r(N) if _n ==`i'
		local i = `i' + 1
	qui sum BIOFBTH_MAR if BIOFBTH_MAR==1
		local N = r(N)
		replace var1 = "married individuals living w/ 1st born bio. teenager" if _n ==`i'
		replace var2 = r(N) if _n ==`i'
		local i = `i' + 1
		keep var1 var2
		keep if var2 !=.
		export excel using "${RES}/XLS/TABLE_A3__Liss_frequencies", replace

/* ESTIMATES AND OUTPUTS FOR TABLES 4 & B3, PARENT SECTION */
	use "${DATA}/LISS_PARENT", clear
	 
	cap erase "${RES}/XLS/TABLES_4_AND_B3__parent.txt" 
	
	/* estimation macros */
	
	local mainvars 	DGH012 PUB DPUB 
	
	local varlist   c.age_m c.age_m#c.age_m c.age_m#c.age_m#c.age_m c.age_w c.age_w#c.age_w c.age_w#c.age_w#c.age_w i.edu_m i.edu_w i.gen_m#i.gen_w  i.year
	local ctrlist   c.NSIB018H c.NSIB018DH  
	
	local ctrlvars  `ctrlist' `varlist' mom
	local fullist   `mainvars' `ctrlvars'  
	
	local keeplist  DGH012 DPUB
	local options   , robust
	 
	local ifclause1 if mom ==0
	local ifclause2 if mom ==1
	local fullist   `mainvars' `ctrlvars'  
	 
	qui forvalues i = 1/1 {
	 
		 local x f180
		 ologit `x' `mainvars' `ctrlvars' `ifclause1' & `x'!=999
		 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'") e(ll) stats(coef se) addnote(`xlab')
		 ologit `x' `mainvars' `ctrlvars' `ifclause2' & `x'!=999
		 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'_2") e(ll) stats(coef se) addnote(`xlab')
		
		 local x f182
		 ologit `x' `mainvars' `ctrlvars' `ifclause1' & `x'!=4
		 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'") e(ll) stats(coef se) 
		 ologit `x' `mainvars' `ctrlvars' `ifclause2' & `x'!=4
		 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'_2") e(ll) stats(coef se) addnote(`xlab')
		  
		 local x f183
		 ologit `x' `mainvars' `ctrlvars' `ifclause1' & `x'!=4
		 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'") e(ll) stats(coef se) 
		 ologit `x' `mainvars' `ctrlvars' `ifclause2' & `x'!=4
		 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'_2") e(ll) stats(coef se) addnote(`xlab')
		  		 
		 local x p011
		 ologit `x' `mainvars' `ctrlvars' `ifclause1' & `x'!=999
		 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'") e(ll) stats(coef se) 
		 ologit `x' `mainvars' `ctrlvars' `ifclause2' & `x'!=999
		 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'_2") e(ll) stats(coef se) addnote(`xlab')
		 
		 foreach x in v151 v129 v124 f427{
			 ologit `x' `mainvars' `ctrlvars' `ifclause1'
			 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'") e(ll) stats(coef se) 
			 ologit `x' `mainvars' `ctrlvars' `ifclause2' 
			 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'_2") e(ll) stats(coef se) addnote(`xlab')
		 }
		 
		 gen maux = gen_m
		 gen waux = gen_w
	
		 foreach x in f432 {
			 ologit `x' `mainvars' `ctrlvars' `ifclause1'
			 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'") e(ll) stats(coef se) 
			 replace gen_w = 4 if gen_m ==3 & gen_w ==2
			 replace gen_m = 4 if gen_w ==4
			 
			 ologit `x' `mainvars' `ctrlvars' `ifclause2' 
			 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'_2") e(ll) stats(coef se) addnote(`xlab')
		 }
	 }
 
	* time-use and expenditures variables 
	gen time_use = (b013 + b014/60) if b013!=. & b014!=.
	replace time_use = b013 if b013!=. & b014==.
	replace time_use = b014/60 if b013==. & b014!=.
	replace time_use =84 if time_use >84 & time_use !=.
	 	  
	gen exp_H = b114
	replace exp_H = b135 if exp_H ==.
	gen log_exp_H = log( 1 + exp_H )
	
	reg log_exp_H  `mainvars' `ctrlvars' `ifclause1' 
				 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'") e(ll) stats(coef se) 
	reg log_exp_H  `mainvars' `ctrlvars' `ifclause2' 
				 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'_2") e(ll) stats(coef se) addnote(`xlab')
	reg time_use  `mainvars' `ctrlvars' `ifclause1' 
				 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'") e(ll) stats(coef se) 
	reg time_use  `mainvars' `ctrlvars' `ifclause2' 
				 outreg2 using "${RES}/XLS/TABLES_4_AND_B3__parent.xml" , excel  dec(3)  noas  label  ctitle("`x'_2") e(ll) stats(coef se) addnote(`xlab')

/* ESTIMATION - TEENAGER'S MODELS */
/* ESTIMATES AND OUTPUTS FOR TABLES 4 & B3, TEENAGER SECTION */

	use "${DATA}/LISS_TEEN", clear
	 
	cap erase "${RES}/XLS/TABLES_4_AND_B3__teen.txt" 
	
	local varlist   c.age_m c.age_m#c.age_m c.age_m#c.age_m#c.age_m c.age_w c.age_w#c.age_w c.age_w#c.age_w#c.age_w i.edu_m i.edu_w i.gen_m#i.gen_w  i.year
	local ctrlist c.NSIB018H c.NSIB018DH  

	ologit f161 girl  `ctrlist' `varlist'  if FB==1
	outreg2 using "${RES}/XLS/TABLES_4_AND_B3__teen.xml" , excel  dec(3)  noas  label   ctitle("relship w mom, FB") e(ll) stats(coef se) 
	
	ologit f161 girl   `ctrlist' `varlist'
	outreg2 using "${RES}/XLS/TABLES_4_AND_B3__teen.xml" , excel  dec(3)  noas  label   ctitle("relship w mom ") e(ll) stats(coef se) 
	
	ologit f162 girl  `ctrlist' `varlist'  if FB==1
	outreg2 using "${RES}/XLS/TABLES_4_AND_B3__teen.xml" , excel  dec(3)  noas  label   ctitle("relship w pop, FB") e(ll) stats(coef se)
	
	ologit f162 girl  `ctrlist' `varlist'
	outreg2 using "${RES}/XLS/TABLES_4_AND_B3__teen.xml" , excel  dec(3)  noas  label   ctitle("relship w pop ") e(ll) stats(coef se) 
 
	replace h133 = 9 - h133
	replace h134 = 2 - h134
	replace h126 = 2 if h125==2
	replace h126 = 2 - h126
	replace h125 = 2 - h125	
	replace f024 = 2 - f024
	
	logit h125 girl   `ctrlist' `varlist' if FB==1
	outreg2 using "${RES}/XLS/TABLES_4_AND_B3__teen.xml" , excel  dec(3)  noas  label   ctitle("ever smk, FB") e(ll) stats(coef se) 
	
	logit h125 girl   `ctrlist' `varlist'
	outreg2 using "${RES}/XLS/TABLES_4_AND_B3__teen.xml" , excel  dec(3)  noas  label   ctitle("ever smk") e(ll) stats(coef se) 

	logit h126 girl   `ctrlist' `varlist' if FB==1
	outreg2 using "${RES}/XLS/TABLES_4_AND_B3__teen.xml" , excel  dec(3)  noas  label   ctitle("smk now, FB") e(ll) stats(coef se) 
	
	logit h126 girl   `ctrlist' `varlist'
	outreg2 using "${RES}/XLS/TABLES_4_AND_B3__teen.xml" , excel  dec(3)  noas  label   ctitle("smk now") e(ll) stats(coef se) 
	
	ologit h133 girl   `ctrlist' `varlist' if FB==1
	outreg2 using "${RES}/XLS/TABLES_4_AND_B3__teen.xml" , excel  dec(3)  noas  label   ctitle("drink scale, FB") e(ll) stats(coef se) 
	
	ologit h133 girl   `ctrlist' `varlist'
	outreg2 using "${RES}/XLS/TABLES_4_AND_B3__teen.xml" , excel  dec(3)  noas  label   ctitle("drink scale") e(ll) stats(coef se) 
	
	logit h134 girl   `ctrlist' `varlist' if FB==1
	outreg2 using "${RES}/XLS/TABLES_4_AND_B3__teen.xml" , excel  dec(3)  noas  label   ctitle("any drink 1w, FB") e(ll) stats(coef se) 
	
	logit h134 girl   `ctrlist' `varlist'
	outreg2 using "${RES}/XLS/TABLES_4_AND_B3__teen.xml" , excel  dec(3)  noas  label   ctitle("any drink 1w") e(ll) stats(coef se) 
	
	logit f024 girl   `ctrlist' `varlist' if FB==1
	outreg2 using "${RES}/XLS/TABLES_4_AND_B3__teen.xml" , excel  dec(3)  noas  label   ctitle("partner, FB") e(ll) stats(coef se) 
	
	logit f024 girl   `ctrlist' `varlist'
	outreg2 using "${RES}/XLS/TABLES_4_AND_B3__teen.xml" , excel  dec(3)  noas  label   ctitle("partner") e(ll) stats(coef se) 
	
	cap erase "${RES}/XLS/TABLES_4_AND_B3__parent.txt"
	cap erase "${RES}/XLS/TABLES_4_AND_B3__teen.txt" 
	 
