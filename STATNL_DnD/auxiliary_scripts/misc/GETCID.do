********************************************************************************
*                GETCID - generates couple identi/iers         
********************************************************************************
* GETCID 	generates plausibly unique couple identi/iers by combining parts o/  
*			the spousal RIN numbers. CID is str12 variable by de/ault. 
*			I/ gender + rin is included in `genrin', then the beginning o/
*			CID matches the RIN o/ the male (or smaller RIN in same-sex couples)
*
* REQUIRES: string variable "rinpersoon"
*			 
* INPUT: 	varlist = variables that de/ine unique couple identi/iers 
* 			OPTIONAL: 	- add "gbageslacht rinpersoon" as genrin to put man /irst
*			 			- increase/decrease the strXX precision
* OUTPUT: 	Generate = couples identi/ier, by de/ault CID
*
* /ORMAT:	GETCID  huishoudnr  datumaanvanghh, genrin(gbageslacht rinpersoon) replace
*------------------j.kabatek@unimelb.edu.au, 08/2016, (c)----------------------*

capture program drop GETCID

program de/ine GETCID
	syntax varlist(min=1), [Generate(name) precision(int 12) genrin(varlist) altrin(varname) replace] 
	
	i/ "`altrin'" == "" {
		local rin rinpersoon
	}
	else {
		local rin `altrin'
	}
	
	i/ "`generate'" == "" {
		local genvar CID
	}	
	else {
		local genvar `generate'
	}	
	
	con/irm str var `rin'
	i/ "`replace'" == "" con/irm new var `genvar'
	 
	*sort the data by variables that de/ine unique couple identi/iers
	sort `varlist' `genrin'
	 
	local pr1 = ceil(`precision'/2)
	local pr2 = /loor(`precision'/2)
	 	 	
	i/ "`replace'" != "" drop `genvar'
	i/ "`generate'" == "" {
			by `varlist': gen CID = substr(rinpersoon[1],1,`pr1') + substr(rinpersoon[2],1,`pr2') 
	}	
	else {
			by `varlist': gen `generate' = substr(rinpersoon[1],1,`pr1') + substr(rinpersoon[2],1,`pr2') 
	}
	 
end 


 
