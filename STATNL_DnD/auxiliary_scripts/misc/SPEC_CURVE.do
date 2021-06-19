* specification curve code by Hans H. Sievertsen h.h.sievertsen@bristol.ac.uk, 29/10-2019
* JK: adjusted to do exponentiated intervals
*
/*- PROGRAM ------------------------------------------------------------------*/
 
cap program drop specchart
program specchart
syntax anything, [replace] spec(string) [name(string)]
	* save current data
	cap qui sum count
	preserve
	*dataset to store estimates
	if "`replace'"!=""{
			clear
			gen beta=.
			gen se=.
			gen spec_id=.
			gen u95=.
			gen u90=.
			gen l95=.
			gen l90=.
			gen n =.
			save `"${DATA}/`name'.dta"',replace
	}	
	else{
		* load dataset
		use `"${DATA}/`name'.dta"',clear
	}
	* add observation
	local obs=_N+1
	set obs `obs'
	replace spec_id=`obs' if _n==`obs'
	* store estimates
	replace beta =exp(_b[`anything']) if  spec_id==`obs'
	replace se=_se[`anything']   if  spec_id==`obs'
	replace u95=exp(_b[`anything']+invt(e(N)-e(k),0.975)*se) if  spec_id==`obs'
	replace u90=exp(_b[`anything']+invt(e(N)-e(k),0.950)*se) if  spec_id==`obs'
	replace l95=exp(_b[`anything']-invt(e(N)-e(k),0.975)*se) if  spec_id==`obs'
	replace l90=exp(_b[`anything']-invt(e(N)-e(k),0.950)*se) if  spec_id==`obs'
	replace n = r(N)  if  spec_id==`obs'
	* store specification
	foreach s in `spec'{
		cap gen `s'=1 			if  spec_id==`obs'
		cap replace `s'=1 		 if  spec_id==`obs'
	}
		save `"${DATA}/`name'.dta"',replace
	* restore dataset	
	restore
end

/*- COHORTS CONTROLS ---------------------------------------------------------*/

 forvalues g = 1/2 {

	cap drop COH`g'
	gen byte COH`g' = .
	replace COH`g' = 1 if YOB`g'<1955
	replace COH`g' = 2 if YOB`g'>=1955 & YOB`g'<1965
	replace COH`g' = 3 if YOB`g'>=1965 & YOB`g'!=.
}

cap gen byte IMBALT2 = 1*(GEN1==GEN2 & GEN1==1) + 2*(GEN1!=GEN2 & GEN1==1) + 3*(GEN1!=GEN2 & GEN2==1) 

local ctrlist i.TM_Y PREMAR  i.YR RP GEN1#GEN2 age_aw_1 c.age_aw_1#(c.age_aw_1 c.age_aw_1#c.age_aw_1)  age_aw_2 c.age_aw_2#(c.age_aw_2 c.age_aw_2#c.age_aw_2) i.EDU1 i.EDU2  

/*- ESTIMATE THE FULL THING --------------------------------------------------*/

 preserve
 
 cloglog event  N_KID N_PUB N_ADU N_KID_D N_PUB_D N_ADU_D `ctrlist', eform
 specchart  N_PUB_D, spec(main) name(estimates_1) replace
 specchart  N_PUB_D, spec(main) name(estimates_2) replace
	 
 forvalues g = 1/2 {
	 
	 cap gen coef2 = . 	
	 cap gen tstat = .
	 local i = 0
	 
	 forvalues i1 = 0/3 {
		local var1 IMBALT2
		local ifclause1 `var1' ==`i1'	
		
		forvalues i2 = 1/3 {
			local var2 COH`g'
			local ifclause2 & `var2' ==`i2'
			
			foreach i3 in 1 2 3 99 {
				local var3 EDU`g'
				local ifclause3 & `var3' ==`i3'
						
				keep if `ifclause1' `ifclause2' `ifclause3' 
				cap cloglog event  N_KID N_PUB N_ADU N_KID_D N_PUB_D N_ADU_D `ctrlist', eform 
				if _rc ==0 { 
						 specchart  N_PUB_D, spec(`var1'_`i1' `var2'_`i2' `var3'_`i3' ) name(estimates_`g')
				}
				restore, preserve
			}
		}
	 }
 }
  
  
/*- ESTIMATE THE SIB MODEL  --------------------------------------------------*

cap preserve

local ctrlist i.TM_Y PREMAR  i.YR RP GEN1#GEN2 age_aw_1 c.age_aw_1#(c.age_aw_1 c.age_aw_1#c.age_aw_1)  age_aw_2 c.age_aw_2#(c.age_aw_2 c.age_aw_2#c.age_aw_2) i.EDU1 i.EDU2
	 
 forvalues g = 1/1 {
	 
	keep if SIB`g' ==0 | SIB`g' ==1 
	
	cloglog event  N_KID N_PUB N_ADU N_KID_D N_PUB_D N_ADU_D `ctrlist', eform
	specchart  N_PUB_D, spec(main) name(estimates_sib_`g') replace
	 
	 forvalues i1 = 0/1 {
		local var1 SIB`g' 
		local ifclause1 `var1' ==`i1'	
			
		foreach i2 in 1 2 3 99 {
			local var2 EDU`g'
			local ifclause2 & `var2' ==`i2'
					
			keep if `ifclause1' `ifclause2' 
			cap cloglog event  N_KID N_PUB N_ADU N_KID_D N_PUB_D N_ADU_D `ctrlist', eform 
			if _rc ==0 { 
					 specchart  N_PUB_D, spec(`var1'_`i1' `var2'_`i2') name(estimates_sib_`g')
			}
			else {
				cap cloglog event  N_KID N_PUB N_ADU N_KID_D N_PUB_D N_ADU_D, eform 
				if _rc ==0 { 
					specchart  N_PUB_D, spec(`var1'_`i1' `var2'_`i2') name(estimates_sib_`g')
				}
			}
			restore, preserve
		}
		
	 }
 }

/*- CHART PLOT ---------------------------------------------------------------*/
 */
 
 cd "${DATA}"
 
forvalues g = 1/2 {

	*local sib _sib
	*define upper and lower bound of the graph
		if "`sib'" == "" {
			local ub = 2.5
			local lb = 0.6
			local sc = (`ub' - `lb')/9
			local unit = round( (`ub' - `lb')/5 , 0.1)
			local ysc r(0.6 2.7)
			local rowheight 0.5
			local textsize tiny
			local msize vsmall
			local anylist IMB* EDU* COH* 
			}
		else {
			local ub = 2.
			local lb = 0.8
			local sc = (`ub' - `lb')/9
			local unit = round( (`ub' - `lb')/5 , 0.1)
			local rowheight 0.4
			local textsize vsmall
			local anylist EDU* SIB* 
			local msize small
			}
			
		local start : word 1 of `anylist'
		local rest : list anylist - start
		
		 
		if `g' == 1 {
			local sibname sister
			local title Father
			}
		else {
			local sibname brother
			local title Mother
			}
		
		* create chart
		use "estimates`sib'_`g'.dta",clear
 
		* auxiliary selection criteria for the syntehtic dataset 
		drop if beta > 10.4 | beta <.5
		drop if u90 > 10
		drop if se ==0
 
		 

		* drop duplicates 
		duplicates drop `anylist' , force
		/* sort specification by category */
		*gsort -cubic -quadratic -linear -covars, mfirst

		/* sort estimates by coefificent size, uncomment to activate sort by category */
		sort beta
		* rank
		gen rank=_n


	* gen indicators and scatters
		local scoff=" "
		local scon=" "
		local cnt = 0
		local sc`cnt' = -1.0*`sc' + `lb'
		local cnt = `cnt'+1
		
		local ind=-1.5*`sc' + `lb'
		local sc`cnt' = `ind'
		local cnt = `cnt'+1
		
		qui d `start', varl
		local varlist = "`r(varlist)'"
		di "`varlist'"
		
		foreach var in `varlist'  {
		   cap gen i_`var'=`ind'
		   local ind=`ind'-`rowheight'*`sc'
		   local sc`cnt' = `ind' 
		   local cnt = `cnt'+1
			
		   local scoff="`scoff' (scatter i_`var' rank,msize(`msize') mcolor(gs12))" 
		   local scon="`scon' (scatter i_`var' rank if `var'==1,msize(`msize') mcolor(black))" 
		}
		* samples
		local ind=`ind'-`rowheight'*`sc'
		local sc`cnt' = `ind'
		local cnt = `cnt'+1
		
		*****************************************************************************
		
		foreach name in `rest'  {
			qui d `name', varl
			local varlist = "`r(varlist)'"
			di "`varlist'"
			
			foreach var in `varlist'  {
			   cap gen i_`var'=`ind'
			   local ind=`ind'-`rowheight'*`sc'
			   local sc`cnt' = `ind' 
			   local cnt = `cnt'+1
				
			   local scoff="`scoff' (scatter i_`var' rank,msize(`msize') mcolor(gs12))" 
			   local scon="`scon' (scatter i_`var' rank if `var'==1,msize(`msize') mcolor(black))" 
			}
			* samples
			local ind=`ind'-`rowheight'*`sc'
			local sc`cnt' = `ind'
			local cnt = `cnt'+1
		}	

		for var `anylist' : replace  X = 1 if main==1
		gen axisline = 1
	 
	* plot
	tw (scatter beta rank if main==1, mcolor(white) mlcolor(black) msymbol(D)  msize(small)) ///  main spec 
	   (rbar u95 l95 rank, fcolor(gs9) lcolor(gs12) lwidth(none)) /// 95% CI
	   (line axisline rank, lcolor(gs3) ) ///
	   (scatter beta rank, mcolor(black) msymbol(D) msize(small)) ///  point estimates
	   `scoff' `scon' /// indicators for spec
	   (scatter beta rank if main==1, mcolor(white) mlcolor(black) msymbol(D)  msize(small)) ///  main spec 
	   ,legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI"  ) region(lcolor(white)) ///
		pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	   xtitle(" ") ytitle(" ") ytitle("Relative hazard probabilities") name(Graph`sib'_`g', replace) ///
	   yscale(noline `ysc') xscale(noline) ylab(`lb'(`unit')`ub', noticks nogrid angle(horizontal) labsize(vsmall)) xlab("", noticks) ///
	   graphregion (fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))  

	   
	  if "`sib'" == "" { 
		* now add stuff to the y axis  
		local cnt = 0
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"Immigration status         "', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"Native"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"1st gen"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"Blended, im. father"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"Blended, im. mother"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1

		gr_edit .yaxis1.add_ticks `sc`cnt'' `"Education                       "', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"Less than HS"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"High School"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"University"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"Missing"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1

		gr_edit .yaxis1.add_ticks `sc`cnt'' `"Cohorts                          "', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"1935-1955"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"1956-1965"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"1966-1985"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
	}
	if "`sib'" != "" { 
		* now add stuff to the y axis  
		local cnt = 0
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"Education                       "', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"Less than HS"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"HS"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"University"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"Missing"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1

		gr_edit .yaxis1.add_ticks `sc`cnt'' `"Sibship                           "', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"No `sibname'"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
		gr_edit .yaxis1.add_ticks `sc`cnt'' `"Has `sibname'"', custom tickset(major) editstyle(tickstyle(textstyle(size(`textsize'))) )
		local cnt = `cnt' + 1
	}
}

*graph combine  Graph_sib_1 Graph_sib_2
