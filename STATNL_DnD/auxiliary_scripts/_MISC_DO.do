*------------------j.kabatek@unimelb.edu.au, 01/2016, (c)----------------------*
* _MISC_DO initializes auxiliary programs used in the main projects
*INITIALIZING
set more off
cd "${DOFILES}/misc" 
*------------------------------------------------------------------------------*
********************************************************************************
* CSAVE - saves compressed dataset         
********************************************************************************
cap qui do   CSAVE

********************************************************************************
* DESTRING - faster decoding of string vars        
********************************************************************************
cap qui do  DESTRING

********************************************************************************
* ESTIMATES - add values to the ereturn list
********************************************************************************
*generalized
cap qui do  EST_ADD
*daughter-specific
cap qui do  ESTIMATES 
cap qui do  EST_SPCOUNT_MC 

********************************************************************************
* GETTIME - decodes CBS "20001231" time stamps        
********************************************************************************
cap qui do  GETTIME

********************************************************************************
* GETBD - generates float birthday variable        
********************************************************************************
cap qui do  GETBD

********************************************************************************
* GETCID - generates couple identifiers  
********************************************************************************
cap qui do  GETCID

********************************************************************************
* GROPT - apply graph house style to the last graph 
********************************************************************************
cap qui do  GROPT

********************************************************************************
* GTFF - get time from float: generates yr/mo/da variables from GETBD variable     
********************************************************************************
cap qui do  GTFF

********************************************************************************
* GTFS - get time from string: generates yr/mo/da variables from CBS time stamps     
********************************************************************************
cap qui do  GTFS

********************************************************************************
* MATA_IV - special IV 2sls routine with dissimilar N across the two stages
********************************************************************************
cap qui do  MATA_IV

********************************************************************************
* PLOTAREA - plots area shares        
********************************************************************************
cap qui do  PLOTAREA

********************************************************************************
* PLOTRATE - plots job accession/separation rates        
********************************************************************************
cap qui do  PLOTRATE

********************************************************************************
* PLOTTAB - plots frequencies over time        
********************************************************************************
cap qui do  PLOTTAB
cap qui do  PLOTTABS

********************************************************************************
* PLOTSUMS - plots means over time / prespecified variable       
********************************************************************************
cap qui do  PLOTSUMS

********************************************************************************
* RESULTS_DGH - a set of external publishing commands for the daughter project
********************************************************************************
cap qui do  RESULTS_DGH

********************************************************************************
* SP_CENSORING - a set of external selection commands for the daughter project
********************************************************************************
cap qui do  SP_CENSORING

********************************************************************************
* TICTOC - Matlab style timer     
********************************************************************************
cap qui do  TICTOC

********************************************************************************
* TTEST - compare means of independent data subsets       
********************************************************************************
cap qui do  TTEST
cap qui do  TTEST2

********************************************************************************
* W2L - reshapes wide data to long         
********************************************************************************
cap qui do  W2L

n di "Auxiliary programs loaded!"
