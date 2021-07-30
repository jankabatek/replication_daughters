*------------------j.kabatek@unimelb.edu.au, 10/2020, (c)----------------------*
*                          Daughters and Divorce                               *
*                          J.Kabatek & D.C.Ribar                               *
*                                 -(J<)-                                       *
*                A MODEL ILLUSTRATION USING SYNTHETIC DATA                     *
*------------------------------------------------------------------------------*
* README:                                                                      *
* To operationalize the code, change the root MAIN_FOL macro in the first      *
* uncommented block. The paths and names/versions of raw CBS data may have     *
* changed, please make sure that they are up to date.                          *
*                                                                              *
* The folder data_sets will be populated by intermediate datasets that are used*
* within the code. No need to copy any raw data into the folder                *
*                                                                              *
* THIS IS A CODE WHICH BYPASSES THE DATA GENERATION PROCESS AND ESTIMATES THE  *
* CLOGLOG MODELS USING A DUMMY DATASET 'DUMMY_DATA.dta'                        *
*                                                                              *
* The corresponding model estimates bear no meaningful information             *
*------------------------------------------------------------------------------*

*local folders
global MAIN_FOL "C:/Users/jkabatek/GIT/STATA/replication/Daughters/STATNL_DnD"
global DOFILES 	"${MAIN_FOL}/auxiliary_scripts"
global MISC 	"${DOFILES}/misc"
global DATA  	"${MAIN_FOL}/data_sets"
global EST 		"${MAIN_FOL}/estimates"
global RES	 	"${MAIN_FOL}/results"

/*raw data
global EDU_2015 		"G:/Onderwijs/HOOGSTEOPLTAB/2015/geconverteerde data/HOOGSTEOPL2015TABV2.DTA"
global GBAHUIS_2016 	"G:/Bevolking/GBAHUISHOUDENSBUS/geconverteerde data/GBAHUISHOUDENS2016BUSV1.DTA"
global GBAVERB_2015 	"G:/Bevolking/GBAVERBINTENISPARTNERBUS/2015/geconverteerde data/GBAVERBINTENISPARTNER2015BUSV1.dta"
global GBAPERS_2016 	"G:/Bevolking/GBAPERSOONTAB/2016/geconverteerde data/GBAPERSOONTAB 2016V1.dta" 
global KINDOUDER_2015 	"G:/Bevolking/KINDOUDERTAB/2015/geconverteerde data/KINDOUDER2015TABV2"
global ADOPTIE_9512		"G:/VeiligheidRecht/ADOPTIEKINDEREN/1995-2012/geconverteerde data/140909 ADOPTIEKINDEREN 1995-2012V1.dta" 
global OPLREF  			"K:/Utilities/Code_Listings/SSBreferentiebestanden/Geconverteerde data/OPLEIDINGSNRREFV24.DTA" 
*/

clear
set more off
do "${DOFILES}/_MISC_DO.do" 


/* LOG */
cap log close
log using "${MAIN_FOL}/log_STATNL.log" , replace


/* 
 
do "${DOFILES}/EDU_DATAGEN.do"
do "${DOFILES}/KIDS_DATAGEN.do"
do "${DOFILES}/LOBS_DATAGEN.do"

*------------------------------------------------------------------------------*

/*--------------------*/ 
/*---- 1st  block ----*/
/*--------------------*/ 
 
 	use using "$GBAVERB_2016", clear
	drop XKOPPELNRVERBINTENIS RINPERSOONSVERBINTENISP RINPERSOONS 
	compress 
 
	/* COUPLE IDs */
		* preparation for generating couple ID **** 
		gen PID = real(RINPERSOON)					// personal ID
		gen SID = real(RINPERSOONVERBINTENISP)		// spousal ID
		gen long MIN = min(PID, SID)
		gen long MAX = max(PID, SID)
		drop SID PID
		rename RINPERSOON rinpersoon	
		merge m:1 rinpersoon using "$GBAPERS_2016", keep(match master) keepusing(gbageboortejaar gbageboortemaand gbageslacht gbageneratie)  

		* generate unique Couple ID (CID)
		GETCID MIN MAX AANVANGVERBINTENIS, genrin(rinpersoon gbageslacht)
		drop MIN MAX
	
		* identify first observed couple for each person:
		bys rinpersoon (AANVANGVERBINTENIS): gen CID_first1 = CID[1]
	
	/* SS (Sample Selection): drop the (partially) non-matched GBAPERS_2016 couples */
	bys CID AANVANGVERBINTENIS : egen MER = sum(_merge)
	drop if MER<6
	drop MER _merge
	
	/* COUPLE-LEVEL CHARACTERISTICS */
		bys CID AANVANGVERBINTENIS (gbageslacht rinpersoon): egen TOTF = sum(gbageslacht=="2") // 0=gays, 1=different-sex, 2 =lesbians
		by  CID AANVANGVERBINTENIS: gen byte GEN1 = real(gbageneratie[1])
		by  CID AANVANGVERBINTENIS: gen byte GEN2 = real(gbageneratie[2])
		
		by  CID AANVANGVERBINTENIS: gen BDP1 = gbageboortejaar[1] + gbageboortemaand[1]
		by  CID AANVANGVERBINTENIS: gen BDP2 = gbageboortejaar[2] + gbageboortemaand[2]
		
		*by  CID AANVANGVERBINTENIS: gen byte edu1 = lvl_gen_CMPL[1]
		*by  CID AANVANGVERBINTENIS: gen byte edu2 = lvl_gen_CMPL[2]
		
		by  CID AANVANGVERBINTENIS: gen CID_first2 = CID_first1[2]
		by  CID AANVANGVERBINTENIS: gen rinpersoon2 = rinpersoon[2]
		rename rinpersoon rinpersoon1
	
	/* SS: keep one record per couple (men's records only) */
	by  CID AANVANGVERBINTENIS: keep  if _n==1
	
	/* MARRIAGE CHARACTERISTICS */
		* marriage <-> partnership dynamics, keep one spell per record
		by CID  : gen switch_back = REDENBEEINDIGINGVERBINTENIS[_n-1]=="P"
		by CID  : gen switch_tomrg = REDENBEEINDIGINGVERBINTENIS=="H"	
		by CID  : replace EINDEVERBINTENIS = EINDEVERBINTENIS[_n+1] if switch_back[_n+1]==1
		drop if switch_back==1 //change ein_vb date to the RP sep and discard the Flash record
		
		gen AAN_UNITYPE = AANVANGVERBINTENIS //stores marriage date for switchers
		by CID  : replace AANVANGVERBINTENIS = AANVANGVERBINTENIS[_n-1] if switch_tomrg[_n-1]==1
		drop if switch_tomrg==1
		drop switch*
		
		*Divorce & flash indicators  
		gen byte PSW = 1 if REDENBEEINDIGINGVERBINTENIS =="P" 
		gen byte DIV = 1 if REDENBEEINDIGINGVERBINTENIS =="S"  
		
		* Higher-order marriage identifier
		gen HO_marriage = (CID != CID_first1) | (CID != CID_first2)
		
	/* SS: keep only the first marriages, not re-marriages of the same spouses */
	by CID : keep if _n==1

	compress  
	save "${DATA}/DIV_GEND_16" ,replace
 
/*--------------------*/ 
/*---- 2nd  block ----*/
/*--------------------*/ 
 	 
	use "${DATA}/DIV_GEND_16", clear
	set seed 2
	local nkids = 5
	
	/* TIMESTAMPS FOR THE CURRENT MARRIAGE */
		gen d_AAN = date(AANVANGVERBINTENIS ,"YMD")
		gen d_EIN = date(EINDEVERBINTENIS ,"YMD")
		gen d_MRG = date(AAN_UNITYPE ,"YMD")
		replace d_MRG = date("20990101" ,"YMD") if TYPEVERBINTENIS=="P"	//recoded for RPs that don't switch
		
		*left censoring (not used anymore)
			local startyear=1995
			local d_left_cens = date("`startyear'0101","YMD")  
			di as err "Left-censoring time is: " %td  `d_left_cens'
			
		*right censoring, since the most recent year or two is usualy not reliable
			local endyear=2016
			local d_right_cens = date("`endyear'1231","YMD")
			di as err "Right-censoring time is: " %td  `d_right_cens'
			
		*unilateral divorce law cutoff date
			local d_left_cutoff = date("19711001","YMD")
			di as err "Unilateral divorce law was adopted by: " %td  `d_left_cutoff'
			
	/* STATS: sample selection frequencies */ 
		cap qui sum TOTF 
		set dp period
		di as err "starting with " %12.2gc r(N) " couples married/rp'd (with both [!] spouses surviving till 1995) " 
		
		cap qui sum TOTF if d_AAN >= `d_left_cutoff'
		di as err  %12.2gc r(N) " couples married/rp'd () with wedding past 1970" 

		cap qui sum TOTF if  d_AAN >= `d_left_cens'
		di as err  %12.2gc r(N) " couples married/rp'd () past 1 Jan 1995"

		sum TOTF if  d_AAN< `d_left_cens'& d_EIN >= `d_left_cens'
		di as err  %12.2gc r(N) " marriages were on-going on  1 Jan 1995"
		
		/* SS: drop same-sex couples (s-s RP available as of 1998)*/
		cap qui sum TOTF if TOTF!=1 & d_AAN >= `d_left_cens'
		di as err "dropping  " %12.2gc r(N) " same-sex couples married/rp'd past 1970" 
		keep if TOTF==1
		drop TOTF

	/* CHILDREN DATA */ 	
		cap drop _merge
		merge m:1 CID rinpersoon1 using  "${DATA}/CHLD_W.dta" , keep(match master) 
		
		*updated blended families with no shared children 
		rename rinpersoon1 rinpersoon
		merge m:1 rinpersoon  using  "${DATA}/RINFBDATA_NEW.dta" , nogen keep(match master) 
		rename rinpersoon rinpersoon1
		
		gen fbch_problem = (CID != CID_yngst) & (CID_yngst!="") & t_BD_yngst< mofd(d_AAN)
		drop CID_yngst t_BD_yngst
		
		rename rinpersoon2 rinpersoon
		merge m:1 rinpersoon  using  "${DATA}/RINFBDATA_NEW.dta" , nogen keep(match master) 
		rename rinpersoon rinpersoon2
		
		replace fbch_problem = 1 if (CID != CID_yngst) & (CID_yngst!="") & t_BD_yngst< mofd(d_AAN)
		drop CID_yngst t_BD_yngst mssng
	

	/* DECLARE BIRTHDAYS AND OTHER CHARACTERISTICS */ 	 
		*child birthdays & genders
		cap rename BD_kid BD_kid1
		cap rename gbageslacht_kid gbageslacht_kid1
		forvalues i = 1/`nkids'{
			gen BD`i' = string(floor(BD_kid`i')) +  string(round(12*(BD_kid`i' - floor(BD_kid`i'))+1), "%02.0f")
			gen d_BD`i' = date(BD`i',"YM") + 15 //mid-month date?
			replace d_BD`i' = date("205005","YM") if BD_kid`i' ==. // Childless families -> asssign BD in far future 
			destring gbageslacht_kid`i', gen(daughter`i')
			replace daughter`i' = daughter`i' -1
		}
	 
		*parental birthdays
		gen d_BDP1 = date(BDP1,"YM") + 15
		gen d_BDP2 = date(BDP2,"YM") + 15
		format d_* %td
		
	/* FAILURE DECLARATION */ 
		gen event = DIV==1 | PSW==1  // PSW needs to be added since it is the DIV indicator for flashed couples. 
									 // The RP separation date for PSWers is correctly assigned.
	
	/* SS: RIGHT CENSORING - 1st step */  
		cap qui sum d_AAN if d_AAN > `d_right_cens'
		di as err "dropping  " %12.2gc r(N) " couples who got married past right-censoring threshold (`endyear'1231)" 

		drop if d_AAN > `d_right_cens'
		replace event = 0 if d_EIN > `d_right_cens' | EINDEVERBINTENIS =="88888888"
		replace d_EIN = `d_right_cens' if d_EIN > `d_right_cens' | EINDEVERBINTENIS =="88888888" 
		
	/* LEFT CENSORING */
		*first observation after `d_right_cens'
		gen d_AAN_CEN = max(`d_left_cens',d_AAN) 
		*alternatively, for yearly frequency, picking up at the anniversary
		gen d_AAN_CEN2 = max(`d_left_cens' + doy(d_AAN) , d_AAN) 
		
	/* UNITS */
		* defined in months
		local trans mofd
		local transback dofm
		local format %tm
		* translate daily timestamps into monthly timestamps
		for any _BDP1 _BDP2 _EIN _MRG _AAN _AAN_CEN _AAN_CEN2: gen tX = `trans'(dX)
		for num 1/`nkids': gen t_BDX = `trans'(d_BDX)	
		for var t_*: format X `format'
		
	/* SPELL DECLARATION */ 
		gen spell  = t_EIN - t_AAN
		gen ctime  = t_AAN_CEN2 - t_AAN
		
	/* HOUSEKEEPING */
		order CID rin*
		keep CID GEN* event  spell ctime t_AAN t_MRG t_BD* daughter* rin* fbch_problem TRUE1 HO* 
		gen id = _n
		compress
		
	/* IMPORT EDUCATION */  
		rename rinpersoon1 rinpersoon
		merge m:1 rinpersoon using   "${DATA}/edu_2015_det2.dta", keep(match master) keepusing(lvl_gen_CMPL) nogen
		rename lvl_gen_CMPL lvl_gen1
		rename rinpersoon  rinpersoon1
		rename rinpersoon2 rinpersoon
		merge m:1 rinpersoon using   "${DATA}/edu_2015_det2.dta", keep(match master) keepusing(lvl_gen_CMPL) nogen
		rename lvl_gen_CMPL lvl_gen2
		rename rinpersoon rinpersoon2
		for num 1/2 : rename lvl_genX eduX
		
	/* ST: SET & SAVE */ 	 
		stset (spell), f(event) id(id) enter(ctime)	
		save "${DATA}/DIV_GEND_ST_5_16_ALL" ,replace

		drop if TRUE1 ==0 //drop couples who do not legaly share their FB child (stepchild-stepparent relationships)
		drop if fbch_problem==1 //drop couples where spouse(s) re-married after having kids with other people and did not have any further children
		drop fbch_problem TRUE1
		save "${DATA}/DIV_GEND_ST_5_16" ,replace
		
	/* SUMMARY STATISTICS */
		do "${DOFILES}/SUMSTAT.do" 
	 
 }
 	 
	/*--------------------*/ 
	/*--- 3rd block ------> 'MACROS' SECTION BELOW CONTAINS PARAMETERS THAT CAN BE ADJUSTED TO MAKE THE CODE RUN FASTER (SMALLER SAMPLE / LESS MC ITERATIONS / ETC) */
	/*--------------------*/ 
	 
	/* ST: LOAD */
 		use "${DATA}/DIV_GEND_ST_5_16" ,clear

	/* PARAMETERS */	
		set seed 3
		set matsize 1000
		*number of modelled children capped at 5	
			local nkids =5
		*censoring criteria
			local age_cap = 27
			local dur_cap = 40
			local yob_low = 1935
			local yob_hig = 1985
		*monte carlo macros
			local MC_onoff          = "mc"
			local MC_sample         = 100
			local MC_iterations		= 200 
		*global macros
			global NKIDS 			= `nkids'
			global SAMPLE   		= 100 //sampling criterion
			global MC_ONOFF 	 	 `MC_onoff'
			global MC_SAMPLE 		= `MC_sample'
			global MC_ITERATIONS	= `MC_iterations'
		*dynamic version counter
			local mm_dd = strofreal(month(date("$S_DATE", "DMY")),"%02.0f") + "_" + strofreal(day(date("$S_DATE", "DMY")),"%02.0f")
			local version `mm_dd'
			global VERSION `version'
 
	/* LOG */
		cap log close
		log using "${EST}/log_${VERSION}" , replace
		
	/* MORE DATA GENERATION */	
		*additional child-specific variables
		gen byte i_anybro =0
		for num 2/5: replace i_anybro = 1 if daughterX==0
		gen byte i_nobro = 1 if (t_BD2 ==1084 | daughter2==1)
		for num 3/5: replace i_nobro = 0 if daughterX==0
		gen i_noch = t_BD1 ==1084 
		replace i_anybro = runiform()<=0.5 if i_noch == 1
		replace i_nobro = runiform()<=0.5 if i_noch == 1
		drop i_noch
		compress

		destring edu1, replace
		destring edu2, replace
		
	/* IMMIGRATION CENSORING */  
		rename rinpersoon1  rinpersoon
		merge m:1 rinpersoon using "${DATA}/HH_Last_Obs_16", keep(match master) nogen 	
		rename rinpersoon rinpersoon1
		gen t_LOBS = mofd(date(last_obs  ,"YMD"))
		gen t_EIN = t_AAN+  spell
		bys CID: gen N= _N

		*replace continuation time by time of outward immigration.
		replace t_EIN  = t_LOBS if t_EIN > t_LOBS & N==1 & event==0 // & t_EIN<monthly("2015m12","YM")
		replace spell = t_EIN - t_AAN
		drop t_EIN* N t_LOBS
		
	/* TIME-INVARIANT: EDUCATION LEVELS */	
		for num 1/2 : gen byte EDUX = (eduX>=0) + (eduX>=3) + (eduX>=5) if eduX!=.
		for num 1/2 : replace EDUX = 99 if EDUX==.	
		
	/* TIME-INVARIANT: PREMARITAL BIRTH */
		gen PREMAR = t_AAN>t_BD1			
		
	/* MAHALANOBIS DISTANCE METRIC */
		for num 1/2 : gen byte aux_GENX = (GENX==0)*1 + (GENX==2)*2 + (GENX==1)*3
		
		forvalues i = 1/2 { 
			gen byte aux_EDU`i' = edu`i' //if edu`i' != 99
			sum aux_EDU`i'
			replace aux_EDU`i' = r(mean) if aux_EDU`i' ==.
		}
		do "${DOFILES}/misc/MAHALANOBIS4_MU0" " aux_GEN aux_EDU t_BDP " "MHLdist" "if EDU1!=99 & EDU2 !=99"
		drop aux_*
		drop last_obs

	/*-- LAST BATCH OF GLOBAL TIME-INVARIANT SPELL SELECTIONS (bundled into a parsable program --*/
		SP_CENSORING
		 
	/* ST: SPLIT */
		stset (spell), f(event) id(id) 			// enter(ctime)
		local transback dofm					// careful - reassigning timeops!
		local endyear=2016						// careful - reassigning endyear!
		local spell_freq = 12
		stsplit time, every(`spell_freq')
		
	/* BASIC TIME-VARYING VARIABLES */ 	
		gen byte event2 = event
		replace event2 = 0 if event==.
		
		gen byte TM_Y = time/12					// provided that the time is counted in months, spell_freq' does not matter here.
		gen int t_TM = t_AAN + time				// current monthly date
		gen int YR = yofd(`transback'(t_TM))	// current year
		 
	/* SS: RIGHT CENSORING - 2nd step */
		keep if YR <= `endyear' -1
		di as err "2nd step of right censoring, last year is: " `endyear' - 1
		
	/* SS: DROP ELDERLY COUPLES, YOUNG COUPLES, AND SPELL PARTS PAST 40YRS*/
		drop if TM_Y > `dur_cap'
		for num 1/2: gen int YOBX = yofd(`transback'(t_BDPX))	//Year of birth
		for num 1/2: drop if YOBX < `yob_low'  | YOBX > `yob_hig'
		
	/* TIME-VARYING VARIABLES CTD - AGE KIDS */
		forvalues i = 1/`nkids'{
			cap gen int AGE_K_Y`i' = floor((t_TM - t_BD`i')/12)
		}
		for var AGE* : replace X = 999 if X<-30	
		
	/* SS: DROP SPELL PARTS WITH ALL CHILDREN GROWNUP */	
		gen AGE_yngst = . 
		for num 1/`nkids': replace AGE_yngst = AGE_K_YX if AGE_K_YX< AGE_yngst & AGE_K_YX!=.
		drop if AGE_yngst >`age_cap' & AGE_yngst<150
		drop AGE_yngst
		 
	/* FINALIZING KIDS' AGE & GENDER VARS */
		for var AGE* : replace X = 999 if X<0
		gen iOLD = (AGE_K_Y1>`age_cap' & AGE_K_Y1<150 ) 
		forvalues i = 1/`nkids'{
			replace AGE_K_Y`i' = `age_cap' if AGE_K_Y`i'>`age_cap' & AGE_K_Y`i'<150 
		}
		gen byte iFB = (AGE_K_Y1!=999) 
		forvalues i = 1/`nkids'{
			replace daughter`i' = 0  if daughter`i' ==. | AGE_K_Y`i'==999 //true daughter indicators assigned only post-birth
		}
		
		*age counts for higher-order children 
		qui if `nkids' >2 {
			xi i.AGE_K_Y2 , prefix(auxi) noomit
			renvars auxi*, predrop(3)
			for num 0/`age_cap': gen byte iD_AGE_K_Y_X= iAGE_K_Y_X*daughter2
			drop *999
			*drop iAGE_K_Y_0
			
			gen byte iKIDS = (AGE_K_Y1!=999) + (AGE_K_Y2!=999)
			
			forvalues i = 3/`nkids'{
				replace iKIDS = iKIDS+1 if AGE_K_Y`i' !=999
				for num 0/`age_cap': replace iAGE_K_Y_X = iAGE_K_Y_X + 1 if AGE_K_Y`i'==X
				for num 0/`age_cap': replace iD_AGE_K_Y_X = iD_AGE_K_Y_X + 1 if AGE_K_Y`i'==X & daughter`i'==1
			}
		}
		
		*quicker model variant only counting the first higher-parity child
		if `nkids' ==2 {
			xi i.AGE_K_Y2 , prefix(auxi) noomit
			renvars auxi*, predrop(3)
			for num 0/`age_cap': gen byte iD_AGE_K_Y_X= iAGE_K_Y_X*daughter2
			drop *999
			gen byte iKIDS = (AGE_K_Y1!=999) + (AGE_K_Y2!=999)
			
		}	
		
	/* TIME-VARYING VARIABLES CTD - OTHERS */
		for num 1/2: gen byte AGE_PX_Y = floor(( t_AAN - t_BDPX )/12) 	//age at the wedding in years
		gen byte RP = t_TM < t_MRG  			//registered partnerships, allowing for switch to MRG
		compress 
		
	/* MISC */
		for num 1/2: rename AGE_PX_Y age_aw_X 
		
	/* Employment histories generation:
		preserve
			do "${MISC}/divorce_empty_29_emp_aux.do"
		restore
		merge 1:1 rinpersoon1 rinpersoon2 YR using "${DATA}/DIV_pops_inc.dta" , keep(match master)
		bys CID (TM_Y) : gen DEMP2 = EMP2 - EMP2[_n-1]
		bys CID (TM_Y) : gen DEMP1 = EMP1 - EMP1[_n-1]
		
	 */
	
	/* KEEP ONLY THE NECESSARY VARIABLES. EXPAND IF NEED BE */
		keep event2 PREMAR TM_Y YR age_aw_* *AGE_K_Y* i* GEN* RP daughter* YOB* EDU* CID MHLdist rin*  // EMP* DEMP*
	  
	/* SS: keep spells of childless families and spell parts with firstborn younger than 27 */
	keep if (AGE_K_Y1==999 | AGE_K_Y1<27)
	gen byte NOCHX = AGE_K_Y1!=999
	bys id: gen byte count = 1 if _n==_N
*/

	****************************************************************************
	* ESTIMATION ***************************************************************
	****************************************************************************
	
	/* DOWNLOAD THE PSEUDO DATASET (if not already in the folder) */
	
	capture confirm file "${DATA}/DUMMY_DATA.dta"
	if _rc != 0 {
		webuse set https://www.jankabatek.com/datasets/
		webuse daughters_pseudo_data
		save "${DATA}/DUMMY_DATA.dta", replace
	}
	
	use "${DATA}/DUMMY_DATA.dta", clear
	 
	/* PARAMETERS SECTION - KEY PARAMETERS COPIED FROM THE 3rd BLOCK */	
		set seed 123
		set matsize 1000
		*monte carlo macros
			local MC_onoff          = "mc"
			local MC_sample         = 100
			local MC_iterations		= 5 
		*global macros
			global MC_ONOFF 	 	 `MC_onoff'
			global MC_SAMPLE 		= `MC_sample'
			global MC_ITERATIONS	= `MC_iterations'
			global ROBUST_EXT 	    = 1
		*dynamic version counter
			local mm_dd = strofreal(month(date("$S_DATE", "DMY")),"%02.0f") + "_" + strofreal(day(date("$S_DATE", "DMY")),"%02.0f")
			local version `mm_dd'
			global VERSION `version'
 
	/* VARLISTS */
		global BG_VARS `BG_vars' i.YR RP GEN1#GEN2 age_aw_1 c.age_aw_1#(c.age_aw_1 c.age_aw_1#c.age_aw_1)       age_aw_2 c.age_aw_2#(c.age_aw_2 c.age_aw_2#c.age_aw_2) i.EDU1 i.EDU2
		global DURSPEC `durspec' i.TM_Y   i.YOB1 i.YOB2

	tempfile baseline
	save `baseline', replace
	
	/* -1a- descriptive model ----------------------------------------------- */

		cloglog event ib(first).AGE_K_Y1  daughter1#ib(first).AGE_K_Y1, eform robust
			EST_SPCOUNT_MC count, ${MC_ONOFF} it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) ext
			estimates save "${EST}/reg_${VERSION}_main_1'", replace
 
	/* -1b- principal multivariate model ------------------------------------ */
	
		cloglog event ib(first).AGE_K_Y1 daughter1#ib(first).AGE_K_Y1 ${DURSPEC} ${BG_VARS} PREMAR , eform  robust
			EST_SPCOUNT_MC count, ${MC_ONOFF} it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) ext
			estimates save "${EST}/reg_${VERSION}_main_2'", replace
	
	/* -2- multivariate model + higher-order births ------------------------- */
	
		* first, generate the 24+ dummy for adult HO children
		replace iAGE_K_Y_24 = iAGE_K_Y_24 + iAGE_K_Y_25 + iAGE_K_Y_26 + iAGE_K_Y_27
		replace iD_AGE_K_Y_24 = iD_AGE_K_Y_24 + iD_AGE_K_Y_25 + iD_AGE_K_Y_26 + iD_AGE_K_Y_27
		drop iAGE_K_Y_25 iAGE_K_Y_26 iAGE_K_Y_27 iD_AGE_K_Y_25 iD_AGE_K_Y_26 iD_AGE_K_Y_27
		* generate child count and make the group k_HO==0 the reference group
		gen byte NRHO = (AGE_K_Y1!=999) + (AGE_K_Y2!=999) + (AGE_K_Y3!=999) + (AGE_K_Y4!=999) + (AGE_K_Y5!=999 )
		drop iAGE_K_Y_0
		
		cap cloglog event i.NRHO ib(first).AGE_K_Y1 daughter1#ib(first).AGE_K_Y1 ${DURSPEC} ${BG_VARS} PREMAR iA* iD* , eform robust 
			EST_SPCOUNT_MC count, ${MC_ONOFF} it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) ext
			estimates save "${EST}/reg_${VERSION}_main_3'", replace
 
	/* CREATE AN AUXILIARY DATASET FOR OUTPUT GENERATION */ 
		preserve
			sample 1 
			save "${DATA}/DIV_GEND_outreg_OUTPUT_AUX", replace
		restore
	 
	/* -3- Subgroup analyses ------------------------------------------------ */
	* ESTIMATES FOR TABLES 3, A2 & B1
		** first, create three age group dummies
		cap drop iD* iA*
		
		** first, create three age group dummies
		for any N_KID N_PUB N_ADU: gen byte X = 0
		for var N_KID N_PUB N_ADU: gen byte X_D = 0
		forvalues i = 1/1{
			replace N_KID  		= N_KID +  1 if AGE_K_Y`i'>=0 & AGE_K_Y`i'<13
			replace N_KID_D  	= N_KID_D +  1 if AGE_K_Y`i'>=0 & AGE_K_Y`i'<13 & daughter`i'
			replace N_PUB  		= N_PUB +  1 if AGE_K_Y`i'>=13 & AGE_K_Y`i'<19
			replace N_PUB_D  	= N_PUB_D +  1 if AGE_K_Y`i'>=13 & AGE_K_Y`i'<19 & daughter`i'
			replace N_ADU  		= N_ADU +  1 if AGE_K_Y`i'>=19 & AGE_K_Y`i'<100
			replace N_ADU_D  	= N_ADU_D +  1 if AGE_K_Y`i'>=19 & AGE_K_Y`i'<100 & daughter`i'
		}  	
	
		** create additional subgroup covariates 
			gen byte IMB = 1*(GEN1==GEN2 & GEN1==1) + 2*(GEN1!=GEN2 & GEN1==1) + 3*(GEN1!=GEN2 & GEN2==1) 
			gen byte IMBALT = 1*(GEN1==GEN2 & GEN1==1) + 2*(GEN1!=GEN2 & GEN1==1) + 2*(GEN1!=GEN2 & GEN2==1) 

			cap drop COH1
			gen byte COH1 = .
			replace COH1 = 1 if YOB1<1955
			replace COH1 = 2 if YOB1>=1955 & YOB1<1965
			replace COH1 = 3 if YOB1>=1965 & YOB1!=.
			
			cap drop COH2
			gen byte COH2 = .
			replace COH2 = 1 if YOB2<1955
			replace COH2 = 2 if YOB2>=1955 & YOB2<1965
			replace COH2 = 3 if YOB2>=1965 & YOB2!=.
		
		** define covariate lists
			local hetvarlist ${DURSPEC} ${BG_VARS}  PREMAR  i.AGE_K_Y1  c.N_KID_D c.N_PUB_D c.N_ADU_D 
			global HETVARLIST ${DURSPEC} ${BG_VARS}  PREMAR  i.AGE_K_Y1  c.N_KID_D c.N_PUB_D c.N_ADU_D 
	 
		** estimate subgroup models and save results
			preserve
			local HET BASE
			local i 1
			cap cloglog event2 ${HETVARLIST} ,eform robust
			EST_SPCOUNT_MC count, mc it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) auxkeep
			drop _all
			cap estimates save "${EST}/reg_${VERSION}_het_`HET'_`i'", replace
			restore, preserve
			 
			cap preserve
			local HET IMB
			foreach i in 0 1 2 3 {
				keep if `HET'==`i'
				cloglog event2 ${HETVARLIST} ,eform robust
				EST_SPCOUNT_MC count, ${MC_ONOFF} it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) auxkeep
				drop _all
				cap estimates save "${EST}/reg_${VERSION}_het_`HET'_`i'", replace	
				restore, preserve
			}
			
			cap preserve
			local HET IMBALT
			foreach i in 2 {
				keep if `HET'==`i'
				cloglog event2 ${HETVARLIST} ,eform robust
				EST_SPCOUNT_MC count, ${MC_ONOFF} it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) auxkeep
				drop _all
				cap estimates save "${EST}/reg_${VERSION}_het_`HET'_`i'", replace	
				restore, preserve
			}
			
			cap preserve			
			local HET EDU1
			foreach i in 1 2 3 99 {
				keep if `HET'==`i'
				cap cloglog event2 ${HETVARLIST} ,eform robust
				EST_SPCOUNT_MC count, ${MC_ONOFF} it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) auxkeep
				drop _all
				cap estimates save "${EST}/reg_${VERSION}_het_`HET'_`i'", replace	
				restore, preserve
			}
			
			cap preserve	
			local HET EDU2
			foreach i in 1 2 3 99 {
				keep if `HET'==`i'
				cap cloglog event2 ${HETVARLIST} ,eform robust
				EST_SPCOUNT_MC count, ${MC_ONOFF} it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) auxkeep
				drop _all
				cap estimates save "${EST}/reg_${VERSION}_het_`HET'_`i'", replace	
				restore, preserve
			}
			
			cap preserve
			local HET EDU_DIF
			foreach i in 0 1 {
				gen byte EDU_DIF = EDU1 != EDU2
				keep if `HET'==`i'
				keep if EDU1 != 99 & EDU2 !=99
				cloglog event2 ${HETVARLIST} ,eform robust
				EST_SPCOUNT_MC count, ${MC_ONOFF} it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) auxkeep
				drop _all
				cap estimates save "${EST}/reg_${VERSION}_het_`HET'_`i'", replace	
				restore, preserve
			}

			cap preserve 
			local HET COH1
			foreach i in 1 2 3 {
				keep if `HET'==`i'
				local durspec i.TM_Y  i.YOB1  
				local BG_vars  i.YR RP GEN1#GEN2 age_aw_1 c.age_aw_1#(c.age_aw_1 c.age_aw_1#c.age_aw_1)       age_aw_2 c.age_aw_2#(c.age_aw_2 c.age_aw_2#c.age_aw_2) i.EDU1 i.EDU2
				local hetvarlist `durspec' `BG_vars'  PREMAR i.AGE_K_Y1  c.N_KID_D c.N_PUB_D c.N_ADU_D
					
				cap cloglog event2 `hetvarlist' ,eform robust
				EST_SPCOUNT_MC count, ${MC_ONOFF} it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) auxkeep
				drop _all
				cap estimates save "${EST}/reg_${VERSION}_het_`HET'_`i'", replace	
				restore, preserve
			}
			
			cap preserve 
			local HET COH2
			foreach i in 1 2 3 {
				keep if `HET'==`i'
				local durspec i.TM_Y  i.YOB2 
				local BG_vars  i.YR RP GEN1#GEN2 age_aw_1 c.age_aw_1#(c.age_aw_1 c.age_aw_1#c.age_aw_1)       age_aw_2 c.age_aw_2#(c.age_aw_2 c.age_aw_2#c.age_aw_2) i.EDU1 i.EDU2
				local hetvarlist `durspec' `BG_vars'  PREMAR i.AGE_K_Y1  c.N_KID_D c.N_PUB_D c.N_ADU_D
					
				cap cloglog event2 `hetvarlist' ,eform robust
				EST_SPCOUNT_MC count, ${MC_ONOFF} it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) auxkeep
				drop _all
				cap estimates save "${EST}/reg_${VERSION}_het_`HET'_`i'", replace	
				restore, preserve
			}
		
			cap preserve	
			local HET MD
			foreach i in 1 2 3 {
				keep if MHLdist != .
				cap gen CID = rinpersoon1
				bys MHLdist CID: replace MHLdist =. if _n!=1
				gen byte First = MHLdist != .
				
				gen byte MD_aux = .
				forvalues ii = 1/3 {
					bys First (MHLdist): replace MD_aux = `ii' if _n>(`ii'*_N/3 - _N/3) & _n<=(`ii'*_N/3) & First ==1
				}
				tab MD_aux
				bys CID: egen byte MD = max(MD_aux)
				
				keep if `HET'==`i'
				cap cloglog event2 ${HETVARLIST} ,eform robust
				EST_SPCOUNT_MC count, ${MC_ONOFF} it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) auxkeep
				drop _all
				cap estimates save "${EST}/reg_${VERSION}_het_`HET'_`i'", replace	
				restore, preserve
			}
			
			*maternal siblings
			cap preserve 
				drop if GEN2==1
				keep if YOB2 >= 1966
				replace YOB1 = 1950 if YOB1<1950

				rename rinpersoon2 rinpersoon
				cap merge m:1 rinpersoon   using  "${DATA}/GENDKIDRIN12MAX.dta" , keep(match) nogen
				gen byte SIS = girl_sib>0
				gen byte BRO = boy_sib>0	
				
				tempfile aux
				save `aux', replace
				foreach HET in BRO SIS{
					foreach i in 0 1 {
						keep if `HET'==`i'
						cap cloglog event2 ${HETVARLIST} ,eform robust
						EST_SPCOUNT_MC count, ${MC_ONOFF} it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) auxkeep
						drop _all
						cap estimates save "${EST}/reg_${VERSION}_het_`HET'MA_`i'", replace	
						use `aux', clear
					}
				}
			restore, preserve
			
			*paternal siblings
			cap preserve 
				drop if GEN1==1
				keep if YOB1 >= 1966
				replace YOB2 = 1950 if YOB2<1950

				rename rinpersoon2 rinpersoon
				cap merge m:1 rinpersoon   using  "${DATA}/GENDKIDRIN12MAX.dta" , keep(match) nogen
				gen byte SIS = girl_sib>0
				gen byte BRO = boy_sib>0	
				
				tempfile aux
				save `aux', replace
				foreach HET in BRO SIS {
					foreach i in 0 1 {
						keep if `HET'==`i'
						cap cloglog event2 ${HETVARLIST} ,eform robust
						EST_SPCOUNT_MC count, ${MC_ONOFF} it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) auxkeep
						drop _all
						cap estimates save "${EST}/reg_${VERSION}_het_`HET'FA_`i'", replace	
						use `aux', clear
					}
				}
			restore, preserve
 
	/* CREATE AN AUXILIARY DATASET FOR OUTPUT GENERATION */ 
		sample 1 
		save "${DATA}/DIV_GEND_outreg_OUTPUT_AUX_het", replace
		restore, preserve 
  
/*------------------------------ ROBUSTNESS - EXTENDED -----------------------*/
 
 
 if ${ROBUST_EXT} == 1 {

	/* OUTPUT FOR FIGURE 3 */
	*Specification charts - require the dataset to be loaded  
		do "${MISC}/SPEC_CURVE.do"
		graph combine Graph_1 Graph_2, rows(2)
		graph export "${RES}/XLS/FIGURE_3_${VERSION}_specs.png", as(png) replace
		cap restore, preserve
	
	*robustness - cohabiting couples
	*(TABLE B1c, Last column)
		cap do "${DOFILES}/ROBUST_COH.do"
		if _rc !=0 cloglog event2 ${HETVARLIST}, eform robust // dummy model for syntetic code		
		EST_SPCOUNT_MC count, it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) ext
		estimates save "${EST}/reg_${VERSION}_het_COHAB", replace

	 
	*robustness - residential separation
	*(TABLE B2, Col. 1)
		use `baseline', clear
		cap do "${DOFILES}/ROBUST_SEP.do"
		if _rc !=0 cloglog event ib(first).AGE_K_Y1 daughter1#ib(first).AGE_K_Y1 ${DURSPEC} ${BG_VARS} PREMAR if _n < 0.9*_N , eform  robust // dummy model for syntetic code
		EST_SPCOUNT_MC count, it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) ext
		estimates save "${EST}/reg_${VERSION}_robu_1", replace
  
	*robustness - stepchildren 
	*(TABLE B2, Col. 2)
		use `baseline', clear
		cap do "${DOFILES}/ROBUST_EXPAND.do"
		if _rc !=0 cloglog event ib(first).AGE_K_Y1 daughter1#ib(first).AGE_K_Y1 ${DURSPEC} ${BG_VARS} PREMAR if _n < 0.8*_N , eform robust // dummy model for syntetic code
		EST_SPCOUNT_MC count, it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) ext
		estimates save "${EST}/reg_${VERSION}_robu_2", replace

	*robustness - income 
	*(TABLE B2, Col. 3)
		use `baseline', clear
		cap keep if t_BD1 >= monthly("1995m01","YM") & TM_Y<37
		cap cloglog event ib(first).AGE_K_Y1 daughter1#ib(first).AGE_K_Y1 ${DURSPEC} ${BG_VARS} , eform robust
		EST_SPCOUNT_MC count, it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) ext
		estimates save "${EST}/reg_${VERSION}_robu_3", replace

	*robustness - gender 
	*(TABLE B2, Col. 4 & 5)
		use `baseline', clear
		replace AGE_K_Y1 = 3 if AGE_K_Y1<3 & AGE_K_Y1>=0				
		cap cloglog event ib(first).AGE_K_Y1 daughter1#ib(first).AGE_K_Y1 ${DURSPEC} ${BG_VARS} PREMAR if i_nobro ==1, eform  robust
		cap estimates save "${EST}/reg_${VERSION}_robu_4", replace
		cloglog event ib(first).AGE_K_Y1 daughter1#ib(first).AGE_K_Y1 ${DURSPEC} ${BG_VARS} PREMAR if i_anybro ==1 , eform  robust
		estimates save "${EST}/reg_${VERSION}_robu_5", replace 
	
	*robustness - income 
	*(TABLE B2, Col. 6)
		use `baseline', clear
		cap forvalues aux = 1/1 {
			*retrieve incomes and employment prior to the year of outcome
			gen year = YR-1
			drop if year<1999
			preserve
				keep CID rinpersoon* year
				gen id = _n
				cap rename rinpersoon rinpersoon1
				reshape long rinpersoon, i(id ) j(Geslacht  )		
				tempfile auxi_inc 
				save `auxi_inc', replace
				
				do "${DOFILES}/INC_DATAGEN.do" " `auxi_inc'"
				drop rinpersoon
				reshape wide INC_yr, i(id ) j(Geslacht  )
				keep CID year INC*
				*tempfile emphist
				save "${DATA}/INCEMP" , replace
			restore
			merge m:1 CID year using "${DATA}/INCEMP", nogen
			for num 1/2 : gen emplagX = INC_yrX>0 & INC_yrX!=.
			for num 1/2 : replace INC_yrX= log(INC_yrX/10000+1)
			for num 1/2 : replace INC_yrX=0 if INC_yrX==.	
		}
		for num 1/2: cap gen empX = floor(0.7 + runiform())
		for num 1/2: cap gen INCX = 60*(runiform())
		cap cloglog event ib(first).AGE_K_Y1 daughter1#ib(first).AGE_K_Y1 ${DURSPEC} ${BG_VARS} PREMAR emp* INC* , eform  robust
		EST_SPCOUNT_MC count, it(${MC_ITERATIONS}) sample(${MC_SAMPLE}) ext
		estimates save "${EST}/reg_${VERSION}_robu_6", replace
}	
  
   
*------------------------------------------------------------------------------*
*------------------- OUTPUT ---------------------------------------------------*
*------------------------------------------------------------------------------*

	/* OUTPUT FOR FIGURES 1 & 2, TABLE A1 - MAIN RESULTS */
		use "${DATA}/DIV_GEND_outreg_OUTPUT_AUX"	, clear		 

		cd "${RES}"
		cap mkdir XLS
		cap erase XLS/TABLE_A1_${VERSION}_main.txt	
		cap erase XLS/TABLE_3_${VERSION}_het.txt
		cap erase XLS/TABLE_B1_${VERSION}_het.txt
		cap erase XLS/TABLE_B2_${VERSION}_robust.txt
				
		estimates use "${EST}/reg_${VERSION}_main_1'"
			RESULTS_BASE
			
		estimates use "${EST}/reg_${VERSION}_main_2'"
			RESULTS_BASE
		
		estimates use "${EST}/reg_${VERSION}_main_3'" 
			RESULTS_BASE
			
		
	/* OUTPUT FOR TABLE B2 - ROBUSTNESS */ 
		use "${DATA}/DIV_GEND_outreg_OUTPUT_AUX"	, clear		
				
			local durspec i.TM_Y i.YOB1 i.YOB2 
			local BG_vars RP GEN1#GEN2 age_aw_1 c.age_aw_1#c.age_aw_1 c.age_aw_1#c.age_aw_1#c.age_aw_1       age_aw_2 c.age_aw_2#c.age_aw_2 c.age_aw_2#c.age_aw_2#c.age_aw_2 i.EDU1 i.EDU2 i.YR
			global BG_VARS `BG_vars' 
			local outreglist i.AGE_K_Y1 daughter1#i.AGE_K_Y1 i.TM_Y  ${BG_VARS} PREMAR iA* iD*

			forvalues i = 1/5 {		
				estimates use "${EST}/reg_${VERSION}_robu_`i'"
				outreg2 using XLS/TABLE_B2_${VERSION}_robust,  keep(`outreglist' ) side dec(3) ///
				noparen excel  ctitle("`i'")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") /// 
				stats(coef se) eform /// 
				addtext(spells,`"`cnt'"', ll,`"`ll'"',Cohort FE, YES)
			}

			for num 1/2: cap gen empX = floor(0.7 + runiform())
			for num 1/2: cap gen INCX = 60*(runiform())
			forvalues i = 6/6 {		
				estimates use "${EST}/reg_${VERSION}_robu_`i'"
				outreg2 using XLS/TABLE_B2_${VERSION}_robust,  keep(`outreglist' emp* INC*) side dec(3) ///
				noparen excel  ctitle("`i'")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") /// 
				stats(coef se) eform /// 
				addtext(spells,`"`cnt'"', ll,`"`ll'"',Cohort FE, YES)
			}

	/* OUTPUT FOR TABLE B1 - HETEROGENEITY*/ 
		use "${DATA}/DIV_GEND_outreg_OUTPUT_AUX_het",clear		 

			local HET BASE
			local i 1
				RESULTS_HET `HET' `i'  
				
			local HET IMB
			foreach i in 0 1 {
				RESULTS_HET `HET' `i'  
			}			
			local HET IMB
			foreach i in 2 3 {
				RESULTS_HET `HET' `i' "long"
			}
			local HET IMBALT
			foreach i in 2 {
				RESULTS_HET `HET' `i' "short"
			}
			
			local HET EDU1
			foreach i in 1 2 3 99 {
				RESULTS_HET `HET' `i'
			}
			local HET EDU2
			foreach i in 1 2 3 99 {
				RESULTS_HET `HET' `i' "long"
			} 
			local HET EDU_DIF
			foreach i in 0 1 {
				RESULTS_HET `HET' `i' "long"
			}
			
			local HET COH1
			foreach i in 1 2 3 {
				RESULTS_HET `HET' `i'
			}
			local HET COH2
			foreach i in 1 2 3 {
				RESULTS_HET `HET' `i' "long"
			}
			
			local HET MD
			foreach i in 1 2 3 {
				RESULTS_HET `HET' `i'
			}
			
			local HET SISFA
			foreach i in 0 1  {
				RESULTS_HET `HET' `i'
			}
			local HET BROMA
			foreach i in 0 1  {
				RESULTS_HET `HET' `i'
			}

	/* OUTPUT FOR TABLE B1 - COHABITATION */
		local outreglist N_KID_D c.N_PUB_D c.N_ADU_D  i.AGE_K_Y1  i.TM_Y  age_aw_1 age_aw_1 c.age_aw_1#c.age_aw_1 c.age_aw_1#c.age_aw_1#c.age_aw_1       age_aw_2 c.age_aw_2#c.age_aw_2 c.age_aw_2#c.age_aw_2#c.age_aw_2
			
		local HET COHAB
		estimates use "${EST}/reg_${VERSION}_het_`HET'"
		local cnt = strofreal(e(cnt), "%15.1gc")
		local ll = strofreal(e(ll), "%15.1gc")
		outreg2 using XLS/TABLE_B1_${VERSION}_het, keep(`outreglist' ) dec(3) noparen excel label ctitle("`HET'`i'")   stats(coef se) eform addtext(spells,`cnt', ll,`ll',Cohort FE, YES)
	
	/* CLOSE LOG */
		cap log close
	
	/* OUTPUT FOR TABLE 2, PRODUCED IN THE DESIGNATED LOG FILE */
		use "${DATA}/DUMMY_DATA.dta", clear
		keep if AGE_K_Y1 == 0
		
		log using "${RES}/XLS/TABLE_2_${VERSION}_sumstat.log" , replace
		do "${DOFILES}/SUMSTAT.do"
		cap log close
	
		cap erase XLS/TABLE_A1_${VERSION}_main.txt	
		cap erase XLS/TABLE_3_${VERSION}_het.txt
		cap erase XLS/TABLE_B1_${VERSION}_het.txt
		cap erase XLS/TABLE_B2_${VERSION}_robust.txt
