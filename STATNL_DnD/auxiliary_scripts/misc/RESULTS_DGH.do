
	capture program drop RESULTS_BASE
	program define RESULTS_BASE
		local durspec i.TM_Y i.YOB1 i.YOB2 
		local BG_vars RP GEN1#GEN2 age_aw_1 c.age_aw_1#c.age_aw_1 c.age_aw_1#c.age_aw_1#c.age_aw_1       age_aw_2 c.age_aw_2#c.age_aw_2 c.age_aw_2#c.age_aw_2#c.age_aw_2 i.EDU1 i.EDU2 i.YR
		local outreglist i.AGE_K_Y1 daughter1#i.AGE_K_Y1 i.TM_Y  `BG_vars' PREMAR i.NRHO iA* iD*
	
	
		*estimates use "${EST}/reg_${version}_het_`HET'_`i'"
		qui do "${MISC}/divorce_abseff_2.do" main 1
		
		local cnt = strofreal(e(cnt), "%15.1gc")
		local ll = strofreal(e(ll), "%15.1gc")
		
		foreach cap in 12 18 26 {
			local BaseB`cap' =  strofreal( round(base_b_`cap'*100,0.01), "%05.2f") + "%"
			local BaseG`cap' =  strofreal( round(base_g_`cap'*100,0.01), "%05.2f") + "%"
			local Diff`cap'  =  strofreal( round((base_g_`cap' - base_b_`cap')*100,0.01), "%04.2f") + "%"
		}
		outreg2 using XLS/TABLE_A1_${VERSION}_main,  keep(`outreglist' ) side dec(3) ///
		noparen excel  ctitle("1")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") /// 
		stats(coef se) eform /// 
		addtext(CD12_b, `BaseB12', CD12_g,`BaseG12', ABS12, `Diff18',CD18_b, `BaseB18', CD18_g,`BaseG18', ABS18, `Diff18',CD18_b, `BaseB26', CD26_g,`BaseG26', ABS26, `Diff26', spells,`"`cnt'"', ll,`"`ll'"',Cohort FE, YES)
	end	

	capture program drop RESULTS_HET
	program define RESULTS_HET
		local HET `1'
		local i   `2' 
		
		local durspec i.TM_Y i.YOB1 i.YOB2 
		local BG_vars i.YR RP GEN1#GEN2 age_aw_1 c.age_aw_1#c.age_aw_1 c.age_aw_1#c.age_aw_1#c.age_aw_1       age_aw_2 c.age_aw_2#c.age_aw_2 c.age_aw_2#c.age_aw_2#c.age_aw_2  i.EDU1 i.EDU2
		local outreglist N_KID_D N_PUB_D N_ADU_D  i.AGE_K_Y1  i.TM_Y  `BG_vars' PREMAR  

		estimates use "${EST}/reg_${VERSION}_het_`HET'_`i'"
		mat ADD = e(Res_MC)
		local sd1 = strofreal(round(ADD[3,4], 0.01), "%04.2f")  
		local sd2 = strofreal(round(ADD[3,5], 0.01), "%04.2f")  
		local sd3 = strofreal(round(ADD[3,1], 0.01), "%04.2f") 
		local sd4 = strofreal(round(ADD[3,2], 0.01), "%04.2f")  
		local sd5 = strofreal(round(ADD[3,3], 0.01), "%04.2f")  
		
		qui do "${MISC}/divorce_abseff_2.do" `HET' `i'
		
		local cnt = strofreal(e(cnt), "%15.1gc")
		local ll = strofreal(e(ll), "%15.1gc")
		
		mat B = e(b)
		local Rel_12 = strofreal(round(100*(exp(B[1,e(k)-3]) -1), 0.01), "%04.2f") + "%"
		local Rel_18 = strofreal(round(100*(exp(B[1,e(k)-2]) -1), 0.01), "%04.2f") + "%"
		
		local BaseB18 =  strofreal( round(base_b_18*100,0.01), "%05.2f") + "%"
		local BaseG18 =  strofreal( round(base_g_18*100,0.01), "%05.2f") + "%"
		local Diff18  =  strofreal( round((base_g_18 - base_b_18)*100,0.01), "%04.2f") + " p.p."
		if ("`3'"=="long" | "`3'"=="") outreg2 using XLS/TABLE_B1_${VERSION}_het, keep(`outreglist' ) dec(3) noparen excel label ctitle("`HET'`i'")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") stats(coef se) eform addtext(Spells,`"`cnt'"', ll,`"`ll'"',Cohort FE, YES) 
		if ("`3'"=="short"| "`3'"=="") outreg2 using XLS/TABLE_3_${VERSION}_het, nocons keep(N_KID_D N_PUB_D N_ADU_D) /// 
		dec(5) excel label ctitle("`HET'`i'") stats(coef se) eform ///
		addtext(Excess_hazard_0_to_12, `Rel_12', sd1, `sd1', Excess_hazard_13_to_18, `Rel_18', sd2, `sd2', ///
		Cummulative_divorce_18_boys, `BaseB18', sd3, `sd3', Cummulative_divorce_18_girls,`BaseG18', sd4, `sd4', ///
		Cummulative_divorce_difference, `Diff18', sd5, `sd5', Spells,`"`cnt'"', ll,`"`ll'"',Cohort FE, YES) ///
		addnote("Please note that the first three coefficients are not part of the TABLE3 output")
	end	
		 
	capture program drop RESULTS_HET_BASE
	program define RESULTS_HET_BASE
		local HET BASE
		local i   1
		
		local durspec i.TM_Y i.YOB1 i.YOB2 
		local BG_vars i.YR RP GEN1#GEN2 age_aw_1 c.age_aw_1#c.age_aw_1 c.age_aw_1#c.age_aw_1#c.age_aw_1       age_aw_2 c.age_aw_2#c.age_aw_2 c.age_aw_2#c.age_aw_2#c.age_aw_2  i.EDU1 i.EDU2
		local outreglist N_KID_D c.N_PUB_D c.N_ADU_D  i.AGE_K_Y1  i.TM_Y  `BG_vars' PREMAR  

		estimates use "${EST}/reg_${VERSION}_het_`HET'_`i'"
		qui do "${MISC}/divorce_abseff_2.do" `HET' `i'
		
		local cnt = strofreal(e(cnt), "%15.1gc")
		local ll = strofreal(e(ll), "%15.1gc")
		
		mat B = e(b)
		local Rel_12 = strofreal(round(100*(exp(B[1,e(k)-3]) -1), 0.01), "%04.2f") + "%"
		local Rel_18 = strofreal(round(100*(exp(B[1,e(k)-2]) -1), 0.01), "%04.2f") + "%"
		local Rel_26 = strofreal(round(100*(exp(B[1,e(k)-1]) -1), 0.01), "%04.2f") + "%"
		
		foreach cap in 12 18 26 {
			local BaseB`cap' =  strofreal( round(base_b_`cap'*100,0.01), "%05.2f") + "%"
			local BaseG`cap' =  strofreal( round(base_g_`cap'*100,0.01), "%05.2f") + "%"
			local Diff`cap'  =  strofreal( round((base_g_`cap' - base_b_`cap')*100,0.01), "%04.2f") + " p.p."
		}
		
		outreg2 using XLS/TABLE_B2_${VERSION}_base_short, nocons keep(N_KID_D N_PUB_D N_ADU_D ) /// 
		side dec(3) excel label ctitle("`HET'`i'") stats(coef se) eform ///
		addtext(Rel_12, `Rel_12', Rel_18, `Rel_18', Rel_26, `Rel_26', CD12_b, `BaseB12', CD12_g,`BaseG12', ABS12, `Diff12',CD18_b, `BaseB18', CD18_g,`BaseG18', ABS18, `Diff18',CD18_b, `BaseB26', CD26_g,`BaseG26', ABS26, `Diff26', Spells,`"`cnt'"', ll,`"`ll'"',Cohort FE, YES)
	end	
	
	 
