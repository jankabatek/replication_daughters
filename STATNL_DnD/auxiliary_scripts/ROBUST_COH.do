*------------------j.kabatek@unimelb.edu.au, 07/2016, (c)----------------------*
*------------------------------------------------------------------------------*
 
* First block
 
	use "${DATA}/DIV_GEND_16", clear
	gen a_yrmo = real(substr(AANVANGVERBINTENIS,1,6))
	gen t_AAN = mofd(date(AANVANGVERBINTENIS ,"YMD"))
	 
	keep if TOTF==1
	drop gbage*  
 
	gen t_BDP1 =mofd( date(BDP1,"YM") + 15)
	gen t_BDP2 =mofd( date(BDP2,"YM") + 15)
 
	tempfile CID2
	save `CID2', replace
 
* Second block
 
	use "${DATA}/CHLD_W"
	drop if TRUE1==0  
	drop if BD_kid1 ==BD_kid2 & BD_kid1!=.
  
	rename gbageslacht_kid1 gbageslacht_kid
	rename BD_kid1 BD_kid
	destring gbageslacht_kid , replace
	 
	gen unkpar =  mssng>0
	gen mis_fa = mssng==1
	gen mis_ma = mssng==2
 
	merge 1:1 CID rinpersoon1 using  `CID2' , keep(match master) nogen
	gen aan = floor(a_yrmo/100) + (a_yrmo- (100*floor(a_yrmo/100)) - 1 )/12
	gen oowed = BD_kid<aan
 	gen legitimized = BD_kid<aan & aan!=.
	
	keep if oowed ==1
	tab mssng
	keep if mssng ==0
	keep CID gbageslacht_kid BD_kid AANVANGVERBINTENIS aan  mis_fa mis_ma  rinpersoon* legitimized
	gen id =_n
	reshape long rinpersoon, i(id) j(geslacht)
	
	compress
	save "${DATA}/cohab_wkids_rin2.dta", replace
	
* Third block
	
	use "${DATA}/cohab_wkids_rin2.dta", clear
	 
	
	merge m:1 rinpersoon using "${DATA}/edu_2015_det2.dta", keepusing( lvl_gen_CMPL) nogen keep(match master)
	merge m:1 rinpersoon using "$GBAPERS_2016", keep(match master) keepusing(gbageboortejaar gbageboortemaand gbageslacht gbageneratie)
	GETBD
	gen GEN = real(gbageneratie)
	drop gba*
	drop _merge
	reshape wide rinpersoon lvl_gen_CMPL BD GEN, i(id) j(geslacht)
	for num 1/2 : gen byte EDUX = (lvl_gen_CMPLX>=0) + (lvl_gen_CMPLX>=3) + (lvl_gen_CMPLX>=5) if lvl_gen_CMPLX!=.
	for num 1/2 : replace EDUX = 99 if EDUX==.
	drop lvl_gen_*
	compress
	bys CID (AANVANGVERBINTENIS): keep if _n ==1
	save "${DATA}/CID_gend_aux", replace
	
* Fourth block
	
	use rinpersoon typhh plhh datumaanvanghh datumeindehh huishoudnr aantalkindhh  using  "$GBAHUIS_2015", clear
	local enddate 20151231 

	drop if typhh=="8"
	drop if typhh=="7"

	joinby rinpersoon using "${DATA}/cohab_wkids_rin2.dta"
	  
	if "${SAMPLE}"!="" {
		sample $SAMPLE
		}
	 
	DESTRING   plhh typhh
	  
	sort CID datumeindehh huishoudnr plhh 
	by CID datumeindehh huishoudnr  : gen N = _N 
	 
	by CID: gen start = 1 if N==2 & N[_n-1]!=2
	by CID: gen start_cens = 1 if start==1 & datumaanvanghh =="19941001"

	by CID: gen staux = sum(start )
	gen aan_chb = datumaanvanghh  if  start==staux

	by CID: gen end = 1 if ( N==2 & N[_n+1]==1) | (N==2 & datumeindehh =="`enddate'")
	by CID: gen endaux = sum(end)
	by CID: egen endmax = max(endaux )

	gen ein_chb =  datumeindehh  if  endaux ==endmax & N==2
	qui GETTIME ein_chb , gen(GT_ein_chb)
	 
	merge m:1 rinpersoon using "${DATA}/HH_Last_Obs_16", keep(match) nogen  
	qui GETTIME last_obs , gen(GT_last_obs)
	bys CID: egen minlast = min(GT_last_obs)
	gen sep =  (datumeindehh!="`enddate'")*(GT_ein_chb < GT_last_obs)   if  endaux ==endmax & N==2

	sort CID aan_chb
	by CID: gen AAN = aan_chb[_N]
	 
	keep if sep!=.

	gen d_AAN = date(AAN  ,"YMD")
	gen d_EIN = date(ein_chb  ,"YMD")
	gen  d_AAN2 = date(string(floor(BD_kid)),"Y") + (BD_kid-floor(BD_kid))*365
	local d_left_cens = date("19950101","YMD")
	gen d_AAN_CEN = max(`d_left_cens',d_AAN2)
	gen ctime  = d_AAN_CEN - d_AAN2
	gen d_EIN2 = date(AANVANGVERBINTENIS  ,"YMD")
	replace d_EIN =d_EIN2  if d_EIN2<=d_EIN  & legitimized ==1
	replace sep=0 if legitimized ==1
	format %td d_*

	by CID: drop if end==. & _n!=_N

	gen spell  = d_EIN - d_AAN2
	replace id =_n
	stset (spell), f(sep) id(id) enter(ctime)
	
	local dlabel 0 "0" 365 "1" 730 "2" 1095 "3" 1460 "4" 1825  "5" 2190 "6" 2555 "7" 2920 "8" 3285 "9" 3650 "10" 4015 "11" 4380 "12" 4745 "13" 5110 "14" 5475 "15" 5840 "16" 6205 "17" 6570 "18" 6935 "19" 7300 "20" 7665 "21" 8030 "22" 8395 "23" 8760 "24" 9125 "25" 9490 "26"
	local dlabel 0 "0"  730 "2"  1460 "4"  2190 "6"  2920 "8" 3650 "10"  4380 "12"  5110 "14"  5840 "16"  6570 "18"  7300 "20"  8030 "22"  8760 "24" 9490 "26"
	sts graph  if _t<15000 , hazard tmax(9500) xtitle(Age of the first-born)  ci  by( gbageslacht_kid ) xlabel(`dlabel')

	stsplit time, every(365)

	gen byte event2 = sep
	replace event2 = 0 if event==.
	gen byte TM_Y = time/365
	gen int d_TM = d_AAN2 + time
	gen int YR = yofd(d_TM)
	drop if TM_Y > 27

	gen AGE_K_Y1 = TM_Y

	for any N_KID N_PUB N_ADU: gen byte X = 0
	for var N_KID N_PUB N_ADU: gen byte X_D = 0

	gen daughter1 = gbageslacht_kid==2

	forvalues i = 1/1{
		replace N_KID  = N_KID +  1 if AGE_K_Y`i'>=0 & AGE_K_Y`i'<13
		replace N_KID_D  = N_KID_D +  1 if AGE_K_Y`i'>=0 & AGE_K_Y`i'<13 & daughter`i'
		replace N_PUB  = N_PUB +  1 if AGE_K_Y`i'>=13 & AGE_K_Y`i'<19
		replace N_PUB_D  = N_PUB_D +  1 if AGE_K_Y`i'>=13 & AGE_K_Y`i'<19 & daughter`i'
		replace N_ADU  = N_ADU +  1 if AGE_K_Y`i'>=19 & AGE_K_Y`i'<100
		replace N_ADU_D  = N_ADU_D +  1 if AGE_K_Y`i'>=19 & AGE_K_Y`i'<100 & daughter`i'
	}
 
	merge m:1 CID using "${DATA}/CID_gend_aux" , keep(match master) nogen
	 
	for num 1/2 :gen AABX = BD_kid - BDX
	for num 1/2 : drop if AABX<12
	drop if AAB2 <16 | AAB2 >45

	for num 1/2 : gen YOBX = floor(BDX)
	for var YOB1 YOB2: drop if X<1935 | X>1985

	rename AAB1  age_aw_1 
	rename AAB2  age_aw_2

	local durspec   i.YOB1   i.YOB2  
	local BG_vars  i.YR GEN1#GEN2 age_aw_1 c.age_aw_1#(c.age_aw_1 c.age_aw_1#c.age_aw_1)       age_aw_2 c.age_aw_2#(c.age_aw_2 c.age_aw_2#c.age_aw_2) i.EDU1 i.EDU2
	local hetvarlist `durspec' `BG_vars'   i.AGE_K_Y1  c.N_KID_D c.N_PUB_D c.N_ADU_D

	local name COHAB
	bys id: gen byte count = 1 if _n==1

	keep if YR <= 2013		 
	cloglog event2  (`hetvarlist') ,eform 
