*------------------j.kabatek@unimelb.edu.au, 08/2016, (c)----------------------*
*------------------------------------------------------------------------------*
 
	use rinpersoon datumeindehh using  "$GBAHUIS_2015", clear
	rename datumeindehh last_obs
	bysort rinpersoon (last_obs): keep if _n ==_N
	save "${DATA}/HH_Last_Obs_16", replace