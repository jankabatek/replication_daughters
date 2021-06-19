*------------------j.kabatek@unimelb.edu.au, 10/2020, (c)----------------------*
*                          Daughters and Divorce                               * 
*							      -(J<)-                                       *     
*------------------------------------------------------------------------------* 
   
	/* ST: LOAD */
		use "${DATA}/DIV_GEND_ST_5_16_ALL" ,clear
		drop if fbch_problem==1 //drop couples where spouse(s) re-married after having kids with other people and did not have any further children

	/* PREAMBLE */	
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
			local MC_iterations		= 2 
 
 
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
		SP_CENSORING, keepho
		 
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
	
	/* KEEP ONLY THE NECESSARY VARIABLES. EXPAND IF NEED BE */
		keep event2 PREMAR TM_Y YR age_aw_* *AGE_K_Y* i* GEN* RP daughter* YOB* EDU* CID MHLdist rin* t_BD1 // EMP* DEMP*
	  
	/* SS: keep spells of childless families and spell parts with firstborn younger than 27 */
	keep if (AGE_K_Y1==999 | AGE_K_Y1<27)
	gen byte NOCHX = AGE_K_Y1!=999
	bys id: gen byte count = 1 if _n==_N
 
	****************************************************************************
	* ESTIMATION ***************************************************************
	****************************************************************************
 
	cloglog event ib(first).AGE_K_Y1 daughter1#ib(first).AGE_K_Y1 ${DURSPEC} ${BG_VARS} PREMAR , eform 
			 

 
 
	
 

				
 
