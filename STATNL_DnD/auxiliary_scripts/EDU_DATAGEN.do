*------------------j.kabatek@unimelb.edu.au, 01/2016, (c)----------------------*
*------------------------------------------------------------------------------*
 
use "$OPLREF"  , clear 

rename OPLNR oplnr
 
rename SOI2006NIVEAU1 lvl_gen		// general education levels
rename SOI2006NIVEAU lvl_det		// detailed education levels 
rename ISCED97FIELD1 cat_bas  	// general education categories
rename ISCED97FIELD2 cat_gen  	// general education categories
rename ISCED97FIELD3 cat_det  	// detailed education categories 
									** (dataset contains sorting of even greater detail)
rename SOI2006RICHTING1 cat_bas_SOI  	// general education categories
rename SOI2006RICHTING2 cat_gen_SOI  	// general education categories
rename SOI2006RICHTING3 cat_det_SOI  	// detailed education categories 

keep   oplnr lvl* cat*

compress
	 
order oplnr lvl_gen lvl_det cat_bas	cat_gen	cat_det cat_bas_SOI cat_gen_SOI cat_det_SOI 
save "${DATA}/educ_ref_det2.dta",replace

 

	local year = 2015 
	scalar sc_year = `year'
	local dataset_ED = `"${edu_high`year'}"' 

	use `"${EDU_2015}"', clear
	cap gen oplnr = OPLNRHB
	cap gen oplnr = oplnrhb
	gen year = `year'

	merge m:1 oplnr using "${DATA}/educ_ref_det2.dta", keep(match master) nogen
	for var oplnr lvl_gen lvl_det cat_bas	cat_gen	cat_det: rename X X_CMPL //details for highest completed degree

	cap gen oplnr = OPLNRHG
	cap gen oplnr = oplnrhg
	
	merge m:1 oplnr using "${DATA}/educ_ref_det2.dta", keep(match master) nogen
	for var oplnr lvl_gen lvl_det cat_bas cat_gen cat_det: rename X X_FLWD 	//details for highest followed degree
	
	cap rename RINPERSOON rinpersoon
	
	cap drop RINPERSOONS GEWICHTHOOGSTEOPL OPLNRHB OPLNRHG
	cap drop rinpersoons gewichthoogsteopl oplnrhb oplnrhg
	
	*qui do Labels/label_edu
	order rinpersoon year oplnr_CMPL oplnr_FLWD
	save "${DATA}/edu_`year'_det2.dta",replace

	 

 

