********************************************************************************
*                GETTIME - program for decoding CBS time stamps        
********************************************************************************
* GETTIME 	decodes CBS time stamps which use "19901231" string formatting 
*
* INPUT: 	varlist = time stamp
* 			OPTIONAL: 	base = base year from which the time starts
* 						cntd = generate continuation indicator variable
* OUTPUT: 	generate = time (coded as a float, unit = 1 year, 
* 			accounts for monthly day frequencies
* TBD: 		Leap years + day unit switch
*
* FORMAT:	GETTIME  datumaanvangbaanid, gen(dabid) base(2000) cntd
*------------------j.kabatek@unimelb.edu.au, 02/2016, (c)----------------------*

capture program drop GETTIME

program define GETTIME
	syntax varlist(min=1 max=1), Generate(name) [base(real 0) cntd]
	confirm new var `generate'
	confirm str var `varlist'
	
	tempname yr_s mo_s da_s yr mo da cd_dum
	
	gen `yr_s' = substr(`varlist',1,4)
	gen `mo_s' = substr(`varlist',5,2)
	gen `da_s' = substr(`varlist',7,2)
	
	*gen `yr' = substr(`varlist',1,4)
	*gen `mo' = substr(`varlist',5,2)
	*gen `da' = substr(`varlist',7,2)
	*destring `yr' `mo' `da', replace
	
	gen int `yr' = real(`yr_s')
	gen byte `mo' = real(`mo_s')
	gen byte `da' = real(`da_s')
	
	* cummulative number of days preceding 1st day of each month:
	scalar sc_cumd1 = 0
	scalar sc_cumd2 = 31
	scalar sc_cumd3 = 59
	scalar sc_cumd4 = 90
	scalar sc_cumd5 = 120
	scalar sc_cumd6 = 151
	scalar sc_cumd7 = 181
	scalar sc_cumd8 = 212
	scalar sc_cumd9 = 243
	scalar sc_cumd10= 273
	scalar sc_cumd11 = 304
	scalar sc_cumd12 = 334
	
	* adjustment for continuing spells indicators (labeled as "88888888") ******
	gen `cd_dum' =  `yr' == 8888
	replace `mo' = 12 if  `cd_dum'
	replace `da' = 31 if  `cd_dum'
	qui sum `yr' if `yr' != 8888
	replace `yr' = r(max) if  `cd_dum'
	****************************************************************************
	
	gen `generate' = `yr' - `base'
	forvalues i = 1/12{ 
		replace `generate' = `generate' + (sc_cumd`i' + `da' - 1)/365 if `mo' ==`i'
	}
	
	* continuation  dummy
	if "`cntd'" != "" {
		gen byte  CNTD_`generate' = `cd_dum'
	}

end

 












