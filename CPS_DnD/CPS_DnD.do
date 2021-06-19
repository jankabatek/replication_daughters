*------------------j.kabatek@unimelb.edu.au, 10/2020, (c)----------------------*
*                          Daughters and Divorce                               *
*                          J.Kabatek & D.C.Ribar                               *
*                                 -(J<)-                                       *
*------------------------------------------------------------------------------*
* README:                                                                      *
* This code combines the 80, 85, 90, 95 CPS MFS data sets and creates a        *
* discrete-time hazard data set. Cloglog models are estimated.                 *
*                                                                              *  
* CHANGE THE FIRST UNCOMMENTED LINE TO OPERATIONALIZE THE CODE                 *
*                                                                              * 
* The total runtime is several minutes.                                        *               
*------------------------------------------------------------------------------*

global MAIN_FOL "D:/Data/CPS_DD" 

#delimit ;
clear all;
set more off;

local maxspell  = 35;
local kidagemax = 26;
local intvwageh = 65;
local intvwagel = 20; 

local statadest "${MAIN_FOL}";
local dictdest  "${MAIN_FOL}";
local datadest  "${MAIN_FOL}/data_sets";

cap log close;
log using "`statadest'/log_CPS.log", replace;

/* Use 80, 85, 90, 95 CPS MFS data sets (note: differing in-scope samples, */
/* all samples restricted to civilian adults in interviewed households     */

/* Note: Where possible am using recoded measures from the MFS data sets   */
/* (e.g., year of birth, age at first marriage) instead of contructing     */
/* constructing variables                                                  */

use "`datadest'/spell80", clear;    
append using "`datadest'/spell85";
append using "`datadest'/spell90";
append using "`datadest'/spell95";

/* Apply restrictions                                                      */
/* 1) Consistent age of 20-65 at interview                                 */
/* 2) No first-born before marriage                                        */
/* 3) No observations with zero weights                                    */
/* 4) First child's sex not missing                                        */

keep if a_age<=`intvwageh';
drop if a_age< `intvwagel';
  
drop if fbm1900<fmstm1900; 
drop if a_fnlwgt==0;
drop if fbm1900==. | fb_girl==.;

gen agefm = floor(fmagem/12);
gen tmardur = yofd + 1 - yofm;

/* Create within-survey weights that sum to survey sample size             */

bysort cpsyear: egen wgttot = total(a_fnlwgt);
by cpsyear: gen nwgt = a_fnlwgt*_N / wgttot;
drop wgttot;

/* Check sample-size against simple LPM sample size                        */

gen checkk = pesa1>0 & fbm1900<=fmendm1900;
tab checkk;
drop if checkk==0;
 
/***************************************************************************/
/* Create spells                                                           */
/***************************************************************************/
 
gen tid = _n;
stset (tmardur), f(fmdiv) id(tid);
stsplit curdur, every(1);

rename _d xtfmdiv;
replace curdur = curdur + 1;

drop if curdur > `maxspell';

/***************************************************************************/
/* Create explanatory models within the event-history file                 */
/***************************************************************************/

/* Create time-varying calendar year and FB kid-age variables; drop        */
/* observations past the maximum FB kid age                                */

gen curyear = curdur + yofm - 1;
gen kid1age = curyear - yofb if yofb<=.;
replace kid1age = . if kid1age<0;
drop if kid1age>`kidagemax' & kid1age<.;

/* Create duration dummies (exclude duration 1)                            */

forvalues yr = 2 / `maxspell' {;
   gen dd`yr' = (`yr' == curdur);
   };

/* Create first-born kid-age dummies (exclude age 0)                       */

forvalues yr = 0 / `kidagemax' {;
   gen kd`yr' = (`yr' == kid1age);
   gen dkd`yr' = kd`yr'*(fb_girl==1);
   };
drop kd0;
   
/* Create first-born daughter interactions                                 */

gen dk0012 = (kid1age>= 0 & kid1age<=12) * (fb_girl==1);
gen dk1318 = (kid1age>=13 & kid1age<=18) * (fb_girl==1);
gen dk19up = (kid1age>=19 & kid1age<.) * (fb_girl==1);

/* Create other controls                                                   */

gen nokid  = (kid1age==.);
gen agefmsq = (agefm^2)/100;
gen agefmcu = (agefm^3)/10000;
gen yr5 = floor(max(min(curyear,94),30)/5)*5;
gen bc5 = floor(min(yob,79)/5)*5;

/* turn bc70 into bc70+ (prevents dropping the 75 cases) */
replace bc5 = 70 if bc ==75;

*sum;

/* KM hazards, check cell sizes                                            */

tab curdur  xtfmdiv, row;
tab kid1age xtfmdiv, row;
 
cap erase "`statadest'/results/XLS/TABLE_A4_CPS.txt";
 
/* ESTIMATES AND OUTPUT FOR TABLE A4                                          */
cloglog xtfmdiv dk0012 dk1318 dk19up kd* nokid [pweight=nwgt], ef vce(robust);
outreg2 using "`statadest'/results/XLS/TABLE_A4_CPS.xml", replace side excel dec(4) title("CPS MFS -- No restriction") ctitle("No covariates") stats(coef se) e(ll) eform;
cloglog xtfmdiv dk0012 dk1318 dk19up kd* nokid dd* [pweight=nwgt], ef vce(robust);
outreg2 using "`statadest'/results/XLS/TABLE_A4_CPS.xml", append side excel dec(4) ctitle("Mar. duration") stats(coef se) e(ll) eform;
cloglog xtfmdiv dk0012 dk1318 dk19up kd* nokid dd* agefm agefmsq agefmcu black orace hs coll i.cdiv i.yr5 i.bc5 [pweight=nwgt], ef vce(robust);
mat RT = r(table);
outreg2 using "`statadest'/results/XLS/TABLE_A4_CPS.xml", append side excel dec(4) ctitle("All covariates") stats(coef se) e(ll) eform;
  
estimates save full, replace;
bys tid : gen count = 1 if _n==1;
 
do "`statadest'/auxiliary_scripts/EST_SPCOUNT_MC.do";
do "`statadest'/auxiliary_scripts/RESULTS_DGH.do";
 
/* EXCESS HAZARDS, CUMMULATIVE PROBABILITIES, AND ROBUST STANDARD ERRORS FOR THE LAST ROW OF TABLE 3 */
/* Bootstrapped standard errors, full sample (100), 200 iterations */ 
local MC_onoff          = "mc";
local MC_sample         = 100;
set seed 123;
EST_SPCOUNT_MC count, `MC_onoff' it(200) sample(`MC_sample') ext;
cd "`statadest'";
RESULTS_HET COHAB 1;

log close;
cap erase "`statadest'/results/XLS/TABLE_A4_CPS.txt"
clear all;
#delimit cr

