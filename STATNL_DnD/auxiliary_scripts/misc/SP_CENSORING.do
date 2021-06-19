
/*-- LAST BATCH OF GLOBAL SPELL SELECTIONS (bundled into a parsable program --*/
	cap program drop SP_CENSORING
	program define SP_CENSORING
	syntax ,[keepho sample(int 0)]
		/* DROP COUPLES MARRIED BEFORE 1971*/
			keep if t_AAN > monthly("1971m10","YM")
			
		/* DROP COUPLES WITH FIRST-BORN TWINS */	
			drop if t_BD1 ==t_BD2 & t_BD1 <1084
		
		/* DROP RE-MARRYING COUPLES */
			if "`keepho'" == "" {
				drop if HO==1 //drop higher-order marriages?
			}
		/* SAMPLE FOR TESTING? */ 	
		* user-specified sampling overrides global sampling		
			if `sample'==0 & "${SAMPLE}"!="" {
				local sample = $SAMPLE
			} 
			
		* user-specified non-sampling overrides any sampling
			if `sample'!=100 & `sample'!=0 {
				sample `sample'
				n di as err "Sampling `sample' % of the spells!"
			}	
			else {
				n di as err "Using the full sample."
			}
	end
/* EXECUTE -------------------------------------------------------------------*/	
