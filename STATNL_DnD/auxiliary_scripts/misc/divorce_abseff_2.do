local version $VERSION
	local HET `1'
	
	qui foreach I in `2' {

	if "`HET'"=="main" {
		di "full set of age dummies"
	}
	else {
		estimates use "${EST}\reg_`version'_het_`HET'_`I'"
	}
	
	matrix Haz = e(haz)

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
	
	n di  "`HET' `I' kids"
	n di "baseline div rate boys: " base_b_12
	n di "absolute effect:        " base_g_12-base_b_12 
	n di "relative effect:        " base_g_12 / base_b_12

	local l 12
	local h 18
	n di  "`HET' teenage "
	n di "baseline div rate boys: " (base_b_`h'-base_b_`l')
	n di "absolute effect:        " (base_g_`h'-base_g_`l') - (base_b_`h'-base_b_`l')    
	n di "relative effect:        " (base_g_`h'-base_g_`l') / (base_b_`h'-base_b_`l')
	
	local l 18
	local h 26
	n di  "`HET' adult"
	n di "baseline div rate boys: " (base_b_`h'-base_b_`l')
	n di "absolute effect:        " (base_g_`h'-base_g_`l') - (base_b_`h'-base_b_`l')    
	n di "relative effect:        " (base_g_`h'-base_g_`l') / (base_b_`h'-base_b_`l')
	
	n di  "`HET' `I' 0-18"
	n di "baseline div rate boys: " base_b_18
	n di "absolute effect:        " base_g_18-base_b_18 
	n di "relative effect:        " base_g_18 / base_b_18
	
	n di  "`HET' `I' 0-26"
	n di "baseline div rate boys: " base_b_26
	n di "absolute effect:        " base_g_26-base_b_26 
	n di "relative effect:        " base_g_26 / base_b_26
	
	
	
}
	
 
