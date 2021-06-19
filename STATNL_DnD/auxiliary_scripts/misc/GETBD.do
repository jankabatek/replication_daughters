********************************************************************************
*                GETBD - program for generating float birthday variable        
********************************************************************************
* GETTIME 	generates birthday variable from year & month strings  
*
* INPUT: 	gbageboortejaar, gbageboortemaand
* OUTPUT: 	BD
* TBD: 		More automation?
*
* FORMAT:	GETBD  
*------------------j.kabatek@unimelb.edu.au, 02/2016, (c)----------------------*

capture program drop GETBD
capture program drop GETN

program define GETBD

	*args event ifclause agerange options 
	cap drop BD
	for var gbageboortejaar gbageboortemaand: cap drop X_f
	for var gbageboortejaar gbageboortemaand: gen int X_f=real(X)
	gen BD = gbageboortejaar_f + (gbageboortemaand_f-1)/12
	drop gbageboortejaar_f gbageboortemaand_f
end

program define GETN

	args `othersorts'
	cap drop N
	bys rinpersoon `othersorts' : gen N=_N
	tab N	
end

