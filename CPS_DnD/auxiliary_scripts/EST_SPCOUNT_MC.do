/***************************************************************************/
/* Program to estimate boostrapped standard errors for absolute and        */
/* relative effects of firstborn child's gender on parental divorce odds   */
/***************************************************************************/

global DIRECTORY ${MAIN_FOL}

/* (0) PRE-REQUISITES */
capture program drop EST_SPCOUNT_MC 
qui do "${DIRECTORY}/auxiliary_scripts/EST_REPLACE_B.do" 

/* (1) BMC Samples Betas from the empirical distribution stored in estimates -*/
capture program drop BMC
program define BMC
	syntax , [n( integer 1000)]
	
	qui do "${DIRECTORY}/auxiliary_scripts/BMC_MATA.do"
	n di as err "Simulating " `n' " Beta vectors" 
	mata: BMC_MATA(`n') 
	n di as txt "Parameter sampling finished. Estimates stored in matrix B_MC(n,k)"
end	

	
/* (2) MAIN PROGRAM --------------------------------------------------------- */	
program define EST_SPCOUNT_MC, eclass
	syntax varlist(max=1) , [mc ITerations(integer 100) SAMple(integer 100) ext]
		
	qui do "${DIRECTORY}/auxiliary_scripts/MSD_MATA.do"
	
	cap qui sum `varlist' 
	if _rc !=0 {
		n di "Note: `varlist' not found!"
	}
	else {
		ereturn scalar cnt = r(N)
	}
	
	if "`ext'"!="" {
		local agemax = 26
	}
	else {
		local agemax = 18
	}
	local agemplus = `agemax' +1
	
	n di as err "Estimating age-specific hazard rates from age 0 to `agemax'." 
	*TIC 1
	matrix Haz = J(`agemplus',2,.)

	tempvar yhat
	tempvar YHB
	tempvar YHD
	
	cap qui predict `yhat'
	*exit clause for missing stored estimates
	if _rc !=0 {
		n di "last estimates missing, skipping the EST_SPCOUNT procedure"
	}
	else {
		qui gen `YHB' = `yhat' if fb_girl ==0
		qui gen `YHD' = `yhat' if fb_girl ==1
		
		/* BASELINE HAZARD ESTIMATES */
		
		* get the means using summarize:
		forvalues i = 0/`agemax' { 
		local j = `i' +1
			qui sum `YHB' if  fb_girl  ==0 & kid1age==`i'  
			matrix Haz[`j',1] = r(mean)
			qui sum `YHD' if fb_girl  ==1 & kid1age==`i'  
			matrix Haz[`j',2] = r(mean)
		}
		
		
		forvalues i = 0/26 { 
					local j = `i' +1
					scalar b`i' = Haz[`j',1] 
					scalar g`i' = Haz[`j',2]
		}
		
		foreach s in b g  {
			scalar base_`s' = 0
			forvalues i = 0/26 {
				scalar surv_rate_`s' = 1
				local imin1 = `i' - 1
				forvalues j = 0/`imin1' {
					scalar surv_rate_`s' = (1 - `s'`j')*surv_rate_`s'
				}
				scalar base_`s' = base_`s' + surv_rate_`s'* `s'`i'
				scalar base_`s'_`i' = base_`s'  
			}
		} 
			
		n di "Effect 0-18"
		n di "CD boys: " base_b_18
		n di "CD girls: " base_g_18
		n di "absolute effect:        " base_g_18-base_b_18 
		n di "relative effect:        " base_g_18 / base_b_18
			
		ereturn matrix haz = Haz
		matrix Res_base_18= [ base_b_18 , base_g_18 , base_g_18-base_b_18]
		if "`ext'"!="" {
			matrix Res_base_12= [ base_b_12 , base_g_12 , base_g_12-base_b_12]
			matrix Res_base_26= [ base_b_26 , base_g_26 , base_g_26-base_b_26]
		}
		*TOC 1

		/* MONTE CARLO */
			
		if "`mc'"!="" { 
			local n_MC = `iterations'
			n di " "
			n di as err "Estimating bootstrapped s.e.'s using `iterations' iterations in `sample'% sample" 
		
			matrix BETA_ORIG =e(b)
			matrix Haz_18_MC = J(`n_MC',5,.)
		
			if "`ext'"!="" {
				matrix Haz_12_MC = J(`n_MC',5,.)
				matrix Haz_26_MC = J(`n_MC',5,.) 
			}
			
			* draw betas from the sample distribution
			 BMC, n(`n_MC')
			 
			 if `sample'!=100 {
				 preserve
				 sample `sample'
			 }
			
			forvalues it = 1/`n_MC' {
				/*visual counter */
				n di "."  _continue
				if mod(`it',10) ==0 n di `it' _continue
				
				/* routine start */
				cap drop `yhat'
				cap drop `YHB' `YHD'
				
				*re-assign beta vector (b = beta_MC) and predict hazard rates
				mat B_HAT = B_MC[`it',1...]
				EST_REPLACE_B B_HAT
				
				qui predict `yhat'
				qui gen `YHB' = `yhat' if fb_girl ==0
				qui gen `YHD' = `yhat' if fb_girl ==1
				
				matrix Haz = J(`agemplus',2,.) 
				
				forvalues i = 0/`agemax' { 
					local j = `i' +1
					qui sum `YHB' if kid1age==`i'  
					matrix Haz[`j',1] = r(mean)
					qui sum `YHD' if kid1age==`i'  
					matrix Haz[`j',2] = r(mean)
				}
				
				forvalues i = 0/26 { 
					local j = `i' +1
					scalar b`i' = Haz[`j',1] 
					scalar g`i' = Haz[`j',2]
				}
				
				foreach s in b g  {
					scalar base_`s' = 0
					forvalues i = 0/26 {
						scalar surv_rate_`s' = 1
						local imin1 = `i' - 1
						forvalues j = 0/`imin1' {
							scalar surv_rate_`s' = (1 - `s'`j')*surv_rate_`s'
						}
						scalar base_`s' = base_`s' + surv_rate_`s'* `s'`i'
						scalar base_`s'_`i' = base_`s'  
					}
				}
				
				/*
				n di "Effect 0-18"
				n di "CD boys: " base_b_18
				n di "CD girls: " base_g_18
				n di "absolute effect:        " base_g_18-base_b_18 
				n di "relative effect 0 -12:  " (base_g_12) / (base_b_12)
				n di "relative effect 13-18:  " (base_g_18-base_g_12) / (base_b_18 - base_b_12)
				*/
				
				
				if "`ext'"!="" {
					matrix Haz_12_MC[`it',1] = base_b_12
					matrix Haz_12_MC[`it',2] = base_g_12
					matrix Haz_12_MC[`it',3] = base_g_12-base_b_12 
					matrix Haz_12_MC[`it',4] = base_b_0
					matrix Haz_12_MC[`it',5] = base_b_0
				}
				
				matrix Haz_18_MC[`it',1] = base_b_18
				matrix Haz_18_MC[`it',2] = base_g_18
				matrix Haz_18_MC[`it',3] = base_g_18-base_b_18 
				matrix Haz_18_MC[`it',4] = (base_g_12) / (base_b_12)
				matrix Haz_18_MC[`it',5] = (base_g_18-base_g_12) / (base_b_18 - base_b_12)
				
				if "`ext'"!="" {
					matrix Haz_26_MC[`it',1] = base_b_26
					matrix Haz_26_MC[`it',2] = base_g_26
					matrix Haz_26_MC[`it',3] = base_g_26-base_b_26 
					matrix Haz_26_MC[`it',4] = base_b_0
					matrix Haz_26_MC[`it',5] = base_b_0
				}
				*matrix Haz_aux = Haz_18_MC
				*estimates save "H:/ESTIMATES/DGH/reg_`version'_het_`HET'_`i'", replace
			
			}
			
			
			/* MC finished, now let's get mean and sd's */
		
			if "`ext'"!="" {
				matrix Res_base = Res_base_12
				mata: MSD("Haz_12_MC")
				mat rownames OUT = Beta0 mean_MC sd_MC
				mat colnames OUT = CD_b CD_g Abs_12  Rel_12 Rel_18  
				mat OUT[2,4] = J(2,2,.)
				ereturn matrix Res_MC_12 = OUT  
			}
		
			/* Principal results: */
			matrix Res_base = Res_base_18
			mata: MSD("Haz_18_MC")
			/* Results into an ereturn table */
			mat rownames OUT = Beta0 mean_MC sd_MC
			mat colnames OUT = CD_b CD_g Abs_18 Rel_12 Rel_18
			ereturn matrix Res_MC = OUT  
			
			if "`ext'"!="" {
				matrix Res_base = Res_base_26
				mata: MSD("Haz_26_MC")
				mat rownames OUT = Beta0 mean_MC sd_MC
				mat colnames OUT = CD_b CD_g Abs_26 
				mat OUT[2,4] = J(2,2,.)
				ereturn matrix Res_MC_26 = OUT  
			}
				
			if `sample'!=100 {
				 restore
			 }
			 
			/* restore original Betas */
			EST_REPLACE_B BETA_ORIG
			 

		}
	}
end
 