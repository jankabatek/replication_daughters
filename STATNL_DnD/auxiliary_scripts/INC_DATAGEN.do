*------------------j.kabatek@unimelb.edu.au, 07/2016, (c)----------------------* 
*							      -(J<)-
*------------------------------------------------------------------------------*
global data_sommen1999 "G:/Arbeid/BAANSOMMENTAB/1999/geconverteerde data/140930 BAANSOMMENTAB 1999V3.dta"
global data_sommen2000 "G:/Arbeid/BAANSOMMENTAB/2000/geconverteerde data/140930 BAANSOMMENTAB 2000V3.dta" 
global data_sommen2001 "G:/Arbeid/BAANSOMMENTAB/2001/geconverteerde data/140930 BAANSOMMENTAB 2001V3.dta"
global data_sommen2002 "G:/Arbeid/BAANSOMMENTAB/2002/geconverteerde data/140930 BAANSOMMENTAB 2002V3.dta"
global data_sommen2003 "G:/Arbeid/BAANSOMMENTAB/2003/geconverteerde data/140930 BAANSOMMENTAB 2003V3.dta"
global data_sommen2004 "G:/Arbeid/BAANSOMMENTAB/2004/geconverteerde data/140930 BAANSOMMENTAB 2004V3.dta"
global data_sommen2005 "G:/Arbeid/BAANSOMMENTAB/2005/geconverteerde data/140930 BAANSOMMENTAB 2005V3.dta"
global data_sommen2006 "G:/Arbeid/BAANSOMMENTAB/2006/geconverteerde data/140930 BAANSOMMENTAB 2006V2.dta"
global data_sommen2007 "G:/Arbeid/BAANSOMMENTAB/2007/geconverteerde data/140930 BAANSOMMENTAB 2007V2.dta"
global data_sommen2008 "G:/Arbeid/BAANSOMMENTAB/2008/geconverteerde data/140930 BAANSOMMENTAB 2008V2.dta"
global data_sommen2009 "G:/Arbeid/BAANSOMMENTAB/2009/geconverteerde data/140930 BAANSOMMENTAB 2009V2.dta"
global data_sommen2010 "G:/Arbeid/BAANSOMMENTAB/2010/geconverteerde data/140930 BAANSOMMENTAB 2010V2.dta"
global data_sommen2011 "G:/Arbeid/BAANSOMMENTAB/2011/geconverteerde data/140930 BAANSOMMENTAB 2011V2.dta"
global data_sommen2012 "G:/Arbeid/BAANSOMMENTAB/2012/geconverteerde data/140930 BAANSOMMENTAB 2012V2.DTA"
global data_sommen2013 "G:/Arbeid/BAANSOMMENTAB/2013/geconverteerde data/BAANSOMMENTAB 2013V1.DTA"
global data_sommen2014 "G:/Arbeid/BAANSOMMENTAB/2014/geconverteerde data/BAANSOMMEN2014TABV1.DTA"
/*------------------- AUXILIARY EMPLOYMENT DATA GENERATION -------------------*/
local startyear=1999
local endyear=2014
*------------------------------------------------------------------------------*

local rinyear_data `1'
forvalues year = `startyear'/`endyear'{  
	n di `year'
	use `rinyear_data' ,clear
	keep if year == `year'

	local dataset_BS = `"${data_sommen`year'}"'	
	joinby rinpersoon using "`dataset_BS'"
	keep fiscloon rinpersoon CID Geslacht id year
	compress
	tempfile base`year'
	save `base`year''
	 
}

local endyless =  `endyear' - 1
forvalues year = `startyear'/`endyless'{
	append using `base`year''
}	
 
bys rinpersoon year CID: egen INC_yr = sum(fiscloon)
 

by rinpersoon year CID: keep if _n==1
drop fiscloon 
 