# Replication code for Kabatek & Ribar (2021)
                                                                             
This replication package contains three sets of codes. One for the principal analysis that draws on the data provided by Statistics Netherlands (STATNL), one for the LISS analysis, and one for the analysis that draws on CPS data.  

All codes were written and executed in STATA 15.0, OS Windows 10.            
All supplementary packages are provided with the code and they are stored in the subfolder 'auxiliary_scripts'. There is no need to install them.         

To run the analyses, please execute the do-files stored in the respective folders (STATNL_DnD.do, LISS_DnD.do & CPS_DnD.do). To operationalize the code, please change the global MAIN_FOL macro to the directory which contains the respective do-files                                             
                                                                              
The codes are commented and they contain additional information that should facilitate the replication efforts. Estimation results are stored in the designated subfolders '/XXX_DnD/results/XLS'.                                
                                                                              
---

The STATNL analysis draws on proprietary data, which means that the datasets are not supplied in the replication package.                                 

The package contains a synthetic dataset that illustrates the workings of the models. The dataset is generated from random data, which means that the resulting model estimates bear no meaningful information.                    

To execute the code with proprietary STATNL data, make sure that you have access to the following datasets: 

ADOPTIEKINDEREN                            
BAANSOMMENTAB                              
GBAHUISHOUDENSBUS                          
GBAPERSOONTAB (x)                          
GBAVERBINTENISPARTNERBUS (x)               
HOOGSTEOPLTAB                              
KINDOUDERTAB (x)                           

The datasets marked with (x) are essential. The other datasets add valuable information, however the code can be adjusted to run without them.           

Inquiries regarding the STATNL data access should be addressed to microdata@cbs.nl                                                         

The runtime of the full STATNL analysis is approximately two weeks.          
The runtime of the synthetic STATNL analysis is 45 minutes.                  

The code produces estimates for the following figures and tables:            
                                                                              
     Table 2  (line 269, STATNL_DnD.do, the output is stored in a designated  
               log file, TABLE_2_${VERSION}_sumstat.log )                     
     Table 3  (lines 494-714, STATNL_DnD.do, except for the last CPS row.     
               Estimates saved in TABLE_3_${VERSION}_het.xml)                 
     Figure 1 (line 462, STATNL_DnD.do, figure constructed manually from      
               estimates saved in Column 2, TABLE_A1_${VERSION}_main.xml)     
     Figure 2 (line 484, STATNL_DnD.do, figure constructed manually from      
               estimates saved in Column 3, TABLE_A1_${VERSION}_main.xml)     
     Figure 3 (line 732 STATNL_DnD.do, figure saved as FIGURE_3.png)          

     ---------------------------------                                        
     Table A1 (lines 462-484, STATNL_DnD.do)                                  
     Table A2 (lines 494-714, STATNL_DnD.do, estimates saved in rows 245-252  
               of TABLE_B1_${VERSION}_het.xml.)                               
     Table B1 (lines 494-714 and 756, STATNL_DnD.do, estimates saved in       
               TABLE_B1_${VERSION}_het.xml.)                                  
     Table B2 (lines 742-800, STATNL_DnD.do), estimates saved in              
               rows 245-252 of TABLE_B1_${VERSION}_het.xml.)                  
                                                                              

---

 The LISS replication package contains three LISS data extracts (both in .dta 
 and .csv formats, no downloads are necessary.                                

 The LISS data extracts can be also constructed from raw LISS data (see file  
 LISS_DnD.do for further instructions)                                        

 The runtime of the LISS analysis is 5 minutes.                               

 The code produces estimates for the following tables:                        
                                                                              
     Table 4  (lines 572-720 LISS_DnD.do Estimates for parents are saved in   
               TABLES_4_AND_B3__parent.xml, rows 5 & 9. Estimates for teens   
               are saved in TABLES_4_AND_B3__teen.xml, row 6) FDR-adjusted    
               significance levels were calculated manually (for details, see 
               M. Anderson's 2008 JASA article ).                             
     ---------------------------------                                        
     Table A3 (lines 522-70 LISS_DnD.do. Frequencies are saved in             
               TABLE_A3__Liss_frequencies.xls)                                
     Table B3 (lines 572-720 LISS_DnD.do Estimates for parents are saved in   
               TABLES_4_AND_B3__parent.xml. Estimates for teens saved in      
               TABLES_4_AND_B3__teen.xml)                                     
                                                                              

---

The CPS replication package contains the CPS-MFS data (both in .dta and csv formats, no downloads are necessary.                                     

The runtime for the CPS analysis is 10 minutes.                              

The code produces estimates for the following tables:                        
                                                                              
     Table 3  (line 143 CPS_DnD.do, the last CPS row. Estimates saved in      
               TABLE_3__last_row.xml)                                         
     ---------------------------------                                        
     Table A4 (lines 139-43 CPS_DnD.do, estimates saved in TABLE_A4_CPS.xml)  
                                                                              
