 qui forvalues aux = 1/1 {
	* auxiliary data generation for the syntehtic code
	cap gen t_BDP1 = mofd(dofy(YOB1))
	cap gen t_BDP2 = mofd(dofy(YOB2))
	cap gen t_AAN  = mofd(dofy(YR-TM_Y))
	cap gen t_BD1  = mofd(dofy(YR-TM_Y + floor(-2 + 10*(runiform())) ))
	cap gen t_BD2  = t_BD1 + floor(10*(runiform()))
	for num 1/2: cap gen EMPX = floor(0.7 + runiform())
	for num 1/2: cap gen INCX = 60*(runiform())
	
	cap drop if HO==1  
	keep if daughter1 !=.
	
	for var t_BDP*: keep if ( X>=monthly("1935m01","YM")) & ( X<monthly("1986m01","YM"))
	keep if t_AAN >= monthly("1971m10","YM")
	drop if t_AAN > monthly("2015m12","YM")
	
	gen BALLT=1
	gen DAUT =daughter1
	gen oowed = t_BD1 < t_AAN

	gen B1 = year(dofm(t_BDP1)) + (month(dofm(t_BDP1))-1)/12
	gen B2 = year(dofm(t_BDP2)) + (month(dofm(t_BDP2))-1)/12
	gen BD_kid = year(dofm(t_BD1)) + (month(dofm(t_BD1))-1)/12

	gen YOW = yofd(dofm(t_AAN))

	for num 1/2 : cap gen byte EDUX = (eduX>=0) + (eduX>=3) + (eduX>=5) if eduX!=.
	for num 1/2 : replace EDUX = 99 if EDUX==.	

	for num 1/2 : gen primX =  EDUX==1
	for num 1/2 : gen secX =  EDUX==2
	for num 1/2 : gen terX =  EDUX==3
	for num 1/2 : gen misX =  EDUX==99

	cap gen nosib = (daughter2!=.)
	for num 3/5: cap replace nosib = nosib + (daughterX!=.)

	* auxiliary data generation for the syntehtic code
	cap gen nosib = floor(runiform()*5)

	gen Bspac2chld = t_BD2  - t_BD1 if t_BD1!=t_BD2 &  t_BD2!=1084

	gen WED = year(dofm( t_AAN)) + (month(dofm(t_AAN ))-1)/12
	for num 1/2: gen AGEWX = WED - BX
	for num 1/2: gen AGEPX = BD_kid - BX
	gen dur = AGEP1 - AGEW1 if AGEP1>=AGEW1 

	for num 0/2 :gen imX_Father = GEN1 ==X
	for num 0/2 :gen imX_Mother = GEN2 ==X
	
	forvalues i = 0/2 {
		forvalues j = 0/2 {
			cap drop im`i'`j'
			gen im`i'`j' = GEN1 ==`i' & GEN2 ==`j'
		}
	}
	
	cap merge 1:1 CID using "${DATA}/DIV_GEND_16", keep(match) keepusing(TYPEVERBINTENIS)
	cap gen reg_par = TYPEVERBINTENIS =="P"
	* auxiliary data generation for the syntehtic code
	cap gen reg_par = floor(runiform()*1.2)
 
 
	gen SEP=event==1
	
	for var SEP  im* prim1 sec1  ter1 mis1 prim2 sec2 ter2 mis2 oowed reg_par : replace X = X*100
}
	
TTEST2 , base( BALLT ) by(DAUT) com(B1 B2 YOW AGEW1 AGEW2 AGEP1 AGEP2 dur im00 im01 im02 im10 im11 im12 im20 im21 im22 prim1 sec1 ter1 mis1 prim2 sec2 ter2 mis2 EMP1 EMP2 INC1 INC2 oowed reg_par nosib Bspac2chld SEP )


********************************************************************************
*explanation of the variables plotted above:
********************************************************************************
*B1 B2              - birth year, father & mother
*YOW 	            - year of wedding
*AGEW1 AGEW2	    - age at wedding, father & mother
*AGEP1 AGEP2	    - age at first birth, father & mother
*dur                - marriage/RP duration at birth
*im00 im01 im02 im10 im11 im12 im20 im21 im22 
*                   - nativity 
*                   - 0 = native, 1 = 1st gen. immigrant, 2 = 2nd gen. immigrant	
*                   - first numeral father, second numeral mother
*prim1 sec1 ter1 mis1 prim2 sec2 ter2 mis2
*                   - education levels of mother and father
*                   - less than HS / HS / University / Missing
*EMP1 EMP2          - employment of mother and father
*INC1 INC2          - earnings of mother and father
*oowed 	            - child born prior to marriage/RP
*reg_par            - parents are registered partners
*nosib              - number of siblings
*Bspac2chld         - time between first two children, in months
*SEP                - parents divorced or ended registered partnership
********************************************************************************

