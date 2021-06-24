********************************************************************************
*                GETCID - generates couple identifiers         
********************************************************************************
* GETCID 	generates plausibly unique couple identifiers by combining parts of  
*			the spousal RIN numbers. CID is str12 variable by default. 
*			If gender + rin is included in `genrin', then the beginning of
*			CID matches the RIN of the male (or smaller RIN in same-sex couples)
*
* REQUIRES: string variable "rinpersoon"
*			 
* INPUT: 	varlist = variables that define unique couple identifiers 
* 			OPTIONAL: 	- add "gbageslacht rinpersoon" as genrin to put man first
*			 			- increase/decrease the strXX precision
* OUTPUT: 	Generate = couples identifier, by default CID
*
* FORMAT:	GETCID  huishoudnr  datumaanvanghh, genrin(gbageslacht rinpersoon) replace
*------------------j.kabatek@unimelb.edu.au, 08/2016, (c)----------------------*

capture program drop GETCID

program define GETCID
	syntax varlist(min=1), [Generate(name) precision(int 12) genrin(varlist) altrin(varname) replace] 
	
	if "`altrin'" == "" {
		local rin rinpersoon
	}
	else {
		local rin `altrin'
	}
	
	if "`generate'" == "" {
		local genvar CID
	}	
	else {
		local genvar `generate'
	}	
	
	confirm str var `rin'
	if "`replace'" == "" confirm new var `genvar'
	 
	*sort the data by variables that define unique couple identifiers
	sort `varlist' `genrin'
	 
	local pr1 = ceil(`precision'/2)
	local pr2 = floor(`precision'/2)
	 	 	
	if "`replace'" != "" drop `genvar'
	if "`generate'" == "" {
			by `varlist': gen CID = substr(rinpersoon[1],1,`pr1') + substr(rinpersoon[2],1,`pr2') 
	}	
	else {
			by `varlist': gen `generate' = substr(rinpersoon[1],1,`pr1') + substr(rinpersoon[2],1,`pr2') 
	}
	 
end 


 
