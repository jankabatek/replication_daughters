*------------------j.kabatek@unimelb.edu.au, 07/2016, (c)----------------------* 
*							      -(J<)-
*------------------------------------------------------------------------------*

use "${DATA}/DIV_GEND_ST_5_16" ,clear
keep rinpersoon* CID
gen id = _n 
reshape long rinpersoon, i(id) j(order)

tempfile div_rin
save `div_rin', replace

use rinpersoon typhh plhh datum* huishoudnr aantalkindhh using  "$GBAHUIS_2015", clear
renvars, lower

drop if typhh=="8"
drop if typhh=="7"
 
joinby rinpersoon using `div_rin'

DESTRING   plhh typhh

sort CID datumeindehh huishoudnr rinpersoon 
by CID datumeindehh huishoudnr rinpersoon: keep if _n ==1   
by CID datumeindehh huishoudnr  : gen N = _N 

by CID: gen start = 1 if N==2 & N[_n-1]!=2
by CID: gen start_cens = 1 if start==1 & datumaanvanghh =="19941001"
by CID: gen staux = sum(start )
gen aan_chb = datumaanvanghh  if  start==staux

by CID: gen end = 1 if ( N==2 & N[_n+1]==1) | (N==2 & datumeindehh =="20151231")
by CID: gen endaux = sum(end)
by CID: egen endmax = max(endaux )
gen ein_chb =  datumeindehh  if  endaux ==endmax & endaux!=0 & N==2

qui GETTIME ein_chb , gen(GT_ein_chb)

merge m:1 rinpersoon using "${DATA}/HH_Last_Obs_16", keep(match) nogen  
qui GETTIME last_obs , gen(GT_last_obs)
bys CID: egen minlast = min(GT_last_obs)

gen sep =  (datumeindehh!="20151231")*(GT_ein_chb < GT_last_obs)   if  endaux ==endmax & N==2

sort CID aan_chb
by CID: gen AAN = aan_chb[_N]
keep if sep!=.

gen d_EIN_chb = date(ein_chb  ,"YMD")

bys CID: keep if _n==1  
keep CID d_EIN_chb
save "${DATA}/div_chb_sep_CID.dta", replace
