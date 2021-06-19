*------------------j.kabatek@unimelb.edu.au, 09/2016, (c)----------------------*
 

	use "$KINDOUDER_2015" , clear
	renvars, lower
	bys rinpersoon: keep if _n==_N

	rename rinpersoon RINPERSOON
	merge m:1 RINPERSOON using "$ADOPTIE_9512", keep(match master) nogen keepusing(JrGK)
	rename RINPERSOON rinpersoon
	gen byte adopted = JrGK!=.  
	drop JrGK
	

*get kid's details
	merge 1:1 rinpersoon using "$GBAPERS_2016", keep(match) nogen keepusing(gbageboortejaar gbageboortemaand gbageslacht)  
	GETBD
	
	gen t_BD = monthly( gbageboortejaar + "y" + gbageboortemaand, "YM" )
	format %tm t_*
	for var BD gbageslacht rinpersoon t_BD: rename X X_kid

	drop rinpersoons rinpersoonspa rinpersoonsma xkoppelnummer gbageboortejaar gbageboortemaand 

	
*consistent couple identifiers ************************
	* reshape first
	rename rinpersoonpa rinpersoon1
	rename rinpersoonma rinpersoon2
	reshape long rinpersoon , i(rinpersoon_kid) j(Geslacht)
	cap drop n
	GETCID  rinpersoon_kid, genrin(rinpersoon Geslacht) // precision(int 18) Generate(CIDFULL)
	
	* individual lifetime fertility ordering
	sort rinpersoon BD_kid rinpersoon_kid
	by rinpersoon:  gen ord_kid_legal = _n if rinpersoon!="---------"
	reshape wide rinpersoon ord_kid_legal, i(rinpersoon_kid) j(Geslacht)
******************************************************

	/* Wide instead of Long sorting */
	*missing parental records:
	gen mssng_1 =  rinpersoon1=="---------"
	gen mssng_2 =  rinpersoon2 =="---------"
	
	replace CID = "SM_" + rinpersoon2 if mssng_1
	replace CID = "SF_" + rinpersoon1 if mssng_2
	replace CID = "X_" + string(_n) if mssng_2 & mssng_1
	sort CID rinpersoon1 rinpersoon2 BD_kid rinpersoon_kid
	
	* children with earlier CID partners? -> Supremum of the child parity
	gen ord_kid_legal_tsup = max(ord_kid_legal1, ord_kid_legal2)
	
	* supremum of spousal fertility up to the point of CID separation/death
	*sort CID BD_kid rinpersoon_kid
	by CID rinpersoon1 rinpersoon2 (BD_kid rinpersoon_kid):  gen ord_kid_legal_max = ord_kid_legal_tsup[_N]
	
	* order of children with parenthood claimed by both spouses in CID 
	by CID rinpersoon1 rinpersoon2 (BD_kid rinpersoon_kid): gen ord_kid_SharedInCID = _n
	
	compress
	gen TRUE = ord_kid_SharedInCID == ord_kid_legal_tsup
	gen mssng = mssng_1 + 2* mssng_2
	
	/* adopted adjustment */
	tab ord_kid_SharedInCID  adopted if  BD_kid >=1995 & BD_kid <2013 & TRUE==1, row
	// 7,196 adopted "first-borns" '95-'12 that would have been regarded as TRUE bio
	replace TRUE = 0 if adopted ==1
	//15,938 adopted children in total with the same coding issue	  
	  
	keep CID mssng ord_kid_SharedInCID BD_kid t_* gbageslacht_kid TRUE rinpersoon_kid rinpersoon1 rinpersoon2

	by CID rinpersoon1 rinpersoon2 (BD_kid rinpersoon_kid): gen aux = (_n==1)
	gen id = sum(aux)
	drop aux
	
	
	/* save wide dataset with children records */
	compress
	preserve
		drop rinpersoon_kid t_BD_kid
		keep if ord_kid_SharedInCID<=5
		reshape wide BD_kid gbageslacht_kid TRUE , i( id ) j( ord_kid_SharedInCID )
		drop id
		save "${DATA}/CHLD_W.dta",replace	
	restore, preserve
	
	/* save sibling dataset for the robustness section */
		gen int nboys = 1000
		gen int ngirls = 1000
		
		gen rin_sib_match = rinpersoon2
		replace rin_sib_match = rinpersoon1  if mssng==2
		replace rin_sib_match = rinpersoon_kid  if mssng==3
		
		gen boy_sib = 0
		for num -4/-1 : bys rin_sib_match (BD_kid): replace boy_sib = boy_sib+1 if (BD_kid[_n + X] > (BD_kid - 5)) & (BD_kid[_n + X] < (BD_kid + 5)) & gbageslacht_kid[_n + X] =="1"
		for num  1/4  : by rin_sib_match (BD_kid): replace boy_sib = boy_sib+1 if (BD_kid[_n + X] > (BD_kid - 5)) & (BD_kid[_n + X] < (BD_kid + 5)) & gbageslacht_kid[_n + X] =="1"
		gen girl_sib = 0
		for num -4/-1 : by rin_sib_match (BD_kid): replace girl_sib = girl_sib+1 if (BD_kid[_n + X] > (BD_kid - 5)) & (BD_kid[_n + X] < (BD_kid + 5)) & gbageslacht_kid[_n + X] =="2"
		for num  1/4  : by rin_sib_match (BD_kid): replace girl_sib = girl_sib+1 if (BD_kid[_n + X] > (BD_kid - 5)) & (BD_kid[_n + X] < (BD_kid + 5)) & gbageslacht_kid[_n + X] =="2"
		
		keep rinpersoon_kid  gbageslacht_kid  nboys  ngirls *sib
		rename  rinpersoon_kid rinpersoon
		compress
		save "${DATA}/GENDKIDRIN12MAX.dta",replace
	restore, preserve
	
	/*save first child dataset */
		keep rinpersoon1 rinpersoon2 t_BD_kid CID
		gen id = _n
		reshape long rinpersoon , i(id) j(Geslacht)
		bys rinpersoon ( t_BD_kid ) : keep if _n==1
		rename CID CID_yngst
		rename t_BD_kid t_BD_yngst
		keep rinpersoon CID_yngst t_BD_yngst
		compress
		save "${DATA}/RINFBDATA_NEW.dta",replace
	
	
	

	
 
	
	
	
