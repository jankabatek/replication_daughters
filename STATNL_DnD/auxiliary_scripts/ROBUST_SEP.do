*------------------j.kabatek@unimelb.edu.au, 07/2016, (c)----------------------*
*                         Son preference project
*							      -(J<)-
*------------------------------------------------------------------------------*
*INITIALIZING
do "${DOFILES}/COHAB_DATAGEN.do"
*------------------------------------------------------------------------------*
  
/* ST: LOAD */
	use "${DATA}/DIV_GEND_ST_5_16" ,clear
	set seed 3
	set matsize 1000
	local nkids =$NKIDS
	local version $VERSION
	local age_cap = 27
	
	bys CID: gen N= _N
	merge m:1 CID using  "${DATA}/div_chb_sep_CID.dta", nogen
	gen t_EIN = t_AAN+  spell
	gen t_EIN_chb = mofd(d_EIN_chb)
	replace t_EIN  = t_EIN_chb if t_EIN > t_EIN_chb & N==1
	replace spell = t_EIN - t_AAN
	drop t_EIN* N d_EIN_chb
	
	  
/* IMMIGRATION CENSORING */  
	rename rinpersoon1  rinpersoon
	merge m:1 rinpersoon using "${DATA}/HH_Last_Obs_16", keep(match master) nogen
	gen t_LOBS = mofd(date(last_obs  ,"YMD"))
	gen t_EIN = t_AAN+  spell
	bys CID: gen N= _N
	drop CID rin*
	
	*replace continuation time by time of outwardimmigration.
	replace t_EIN  = t_LOBS if t_EIN > t_LOBS & N==1 & event==0 & t_EIN<monthly("2015m12","YM")
	replace spell = t_EIN - t_AAN
	drop t_EIN* N t_LOBS
	
/* TIME-INVARIANT: PREMARITAL BIRTH */
	gen PREMAR = t_AAN>t_BD1
	 
/*  SAMPLE SELECTION (externally defined for harmonization) */	
	SP_CENSORING
	stset (spell), f(event) id(id)
	
/* ST: SPLIT */
	local transback dofm		 
	local endyear=2016			 
	local spell_freq = 12
	stsplit time, every(`spell_freq')
	
/* BASIC TIME-VARYING VARIABLES */ 	
	gen byte event2 = event
	replace event2 = 0 if event==.
	
	gen byte TM_Y = time/12		 
	gen int t_TM = t_AAN + time				// current monthly date
	gen int YR = yofd(`transback'(t_TM))	// current year
	 
/* RIGHT CENSORING - 2nd step */
	keep if YR <= `endyear' -1
	di as err "2nd step of right censoring, last year is: " `endyear' - 1
	
/* DROP ELDERLY COUPLES*/
	drop if TM_Y > 40
	for num 1/2: gen int YOBX = yofd(`transback'(t_BDPX))	//Year of birth
	for num 1/2: drop if YOBX < 1935  | YOBX > 1985
	
/* TIME-VARYING VARIABLES CTD - KIDS */
	forvalues i = 1/`nkids'{
		cap gen int AGE_K_Y`i' = floor((t_TM - t_BD`i')/12)
	}
	
	for var AGE* : replace X = 999 if X<-30	
	cap gen AGE_yngst = min(AGE_K_Y1,AGE_K_Y2,AGE_K_Y3,AGE_K_Y4,AGE_K_Y5)
	cap gen AGE_yngst = min(AGE_K_Y1,AGE_K_Y2)
	cap gen AGE_yngst = AGE_K_Y1

/* DROP COUPLES WITH ALL CHILDREN GROWNUP*/	
	drop if AGE_yngst >`age_cap' & AGE_yngst<150
	for var AGE* : replace X = 999 if X<0

	gen iOLD = 0
	replace iOLD = 1  if AGE_K_Y1>`age_cap' & AGE_K_Y1<150 
	forvalues i = 1/`nkids'{
		replace AGE_K_Y`i' = `age_cap' if AGE_K_Y`i'>`age_cap' & AGE_K_Y`i'<150 
	}

	forvalues i = 1/`nkids'{
		replace daughter`i' = 0  if daughter`i' ==. | AGE_K_Y`i'==999
	}
	
	
/* TIME-VARYING VARIABLES CTD - OTHERS */
	 
	for num 1/2: gen byte AGE_PX_Y = floor(( t_AAN - t_BDPX )/12) 	//age at the wedding in years
	gen byte RP = t_TM < t_MRG //registered partnerships, allowing for switch to MRG

	keep iOLD event2 TM_Y YR AGE_P* *AGE_K_Y* daugh* GEN* RP YOB* t_AAN t_BD* edu*  PREMAR id // *age_postsp*
	 
	*age dummies for higher-order children
	qui if `nkids' >2 {
		xi i.AGE_K_Y2 , prefix(auxi) noomit
		renvars auxi*, predrop(3)
		for num 0/`age_cap': gen byte iD_AGE_K_Y_X= iAGE_K_Y_X*daughter2
		drop *999
		
		forvalues i = 3/`nkids'{
			for num 0/`age_cap': replace iAGE_K_Y_X = iAGE_K_Y_X + 1 if AGE_K_Y`i'==X
			for num 0/`age_cap': replace iD_AGE_K_Y_X = iD_AGE_K_Y_X + 1 if AGE_K_Y`i'==X & daughter`i'==1
		}
	}
	
	compress
	
	keep event2 PREMAR TM_Y YR AGE_P* *AGE_K_Y* i* GEN* RP daughter* YOB* edu*
	for num 1/2: rename AGE_PX_Y age_aw_X   
	for num 1/2 : gen byte EDUX = (eduX>=0) + (eduX>=3) + (eduX>=5) if eduX!=.
	for num 1/2 : replace EDUX = 99 if EDUX==.

	keep if (AGE_K_Y1==999 | (AGE_K_Y1<27 & iOLD==0))	
	bys id: gen byte count = 1 if _n==1
		
 
	*	-1b- principal multivariate model
	local name separation
	cloglog event ${DURSPEC} ib(first).AGE_K_Y1 daughter1#ib(first).AGE_K_Y1  ${BG_VARS}  , eform 
		
 
 
 

		
 
