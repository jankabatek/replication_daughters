/* Code for Mahalanobis Distance measure as a function of covriates specified in
`1' and with a name being `2' */

local varlist `1'
local MHL `2'
local ifclause `3'


* interpreting the varlist and making the differences
local varlist1
local varlist2
local diflist

local n = 0
foreach X in `varlist' {
	local varlist1 `varlist1' `X'1
	local varlist2 `varlist2' `X'2
	local n = `n' + 1
}

cap drop dif*
forvalues i = 1/`n' {
	local v1_`i' : word `i' of `varlist1'
	local v2_`i' : word `i' of `varlist2'
	gen dif`i' =  `v1_`i'' - `v2_`i''
	label var  dif`i'  "`v1_`i''"
	local diflist `diflist' dif`i'
}
 
corr `diflist' `3' , c
mat Sdif = r(C)

mean `diflist'  
mat a = r(table)
mat mu = a[1,1...]
 
mat invS = inv(Sdif) 
cap gen `MHL' = .
 

*----------------------------------
timer clear 1
timer on 1

local N =  _N
 forvalues i = 1/`N'{ 

	if `i' == 500000 {
		di "500k MHL distances drawn in:" 
		timer off 1
		timer list 1
		timer on 1
	} 
	
	mat dif =  [ dif1[`i']-mu[1,1] ]
	forvalues j = 2/`n' {
		mat dif =  [dif, dif`j'[`i']-mu[1,`j'] ]
	}
	
	mat M = dif*invS*dif' 
	qui replace `MHL' = M[1,1] in `i' `3'
}
replace `MHL' = sqrt(`MHL')
 
timer off 1
timer list 1
