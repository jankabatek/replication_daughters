 	capture program drop RESULTS_HET
	program define RESULTS_HET
		local HET `1'
		local i   `2' 
		
		local outreglist dk0012 dk1318 dk19up
		 
		mat ADD = e(Res_MC)
		local sd3 = strofreal(round(ADD[3,1], 0.01), "%04.2f") 
		local sd4 = strofreal(round(ADD[3,2], 0.01), "%04.2f")  
		local sd5 = strofreal(round(ADD[3,3], 0.01), "%04.2f")  
  
		local cnt = 101880 
		local ll = strofreal(e(ll), "%15.1gc")
		 
		local BaseB18 =  strofreal( round(ADD[1,1],0.01), "%05.2f") + "%"
		local BaseG18 =  strofreal( round(ADD[1,2],0.01), "%05.2f") + "%"
		local Diff18  =  strofreal( round(ADD[1,3],0.01), "%04.2f") + " p.p."
		
		estimates use full
		mat B = e(b)
		local Rel_12 = strofreal(round(100*(exp(B[1,1]) -1), 0.01), "%04.2f") + "%"
		local Rel_18 = strofreal(round(100*(exp(B[1,2]) -1), 0.01), "%04.2f") + "%"
		
		local sd1 = strofreal(round(100*RT[2,1], 0.01), "%04.2f")  
		local sd2 = strofreal(round(100*RT[2,2], 0.01), "%04.2f")  
 
		cap erase results/XLS/TABLE_3_${VERSION}_last_row.txt
		outreg2 using results/XLS/TABLE_3_${VERSION}_last_row, nocons keep(`outreglist') /// 
		dec(5) excel label ctitle("`HET'`i'") stats(coef se) eform ///
		addtext(Excess_hazard_0_to_12, `Rel_12', sd1, `sd1', Excess_hazard_13_to_18, `Rel_18', sd2, `sd2', ///
		Cummulative_divorce_18_boys, `BaseB18', sd3, `sd3', Cummulative_divorce_18_girls,`BaseG18', sd4, `sd4', ///
		Cummulative_divorce_difference, `Diff18', sd5, `sd5', Spells,`"`cnt'"', ll,`"`ll'"',Cohort FE, YES) ///
		addnote("Please note that the first three coefficients are not part of the TABLE3 output")
		cap erase results/XLS/TABLE_3_${VERSION}_last_row.txt
	end	
		 
	 
