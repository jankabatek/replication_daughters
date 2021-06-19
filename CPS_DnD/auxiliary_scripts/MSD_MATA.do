/***************************************************************************/
/* Program appending the Monte Carlo estimates to a big matrix             */
/***************************************************************************/
 
cap mata: mata drop MSD()

mata 
function MSD(name)
	{
		/*name = "Haz_18_MC"*/
		RES = st_matrix(name)
		Bhat0 = st_matrix("Res_base")
		BHAT = J(1,cols(RES),.)
		BHAT[1,1..cols(Bhat0)] = Bhat0
		
		mean = mean(RES)*100
		mean[1,4..5] = mean[1,4..5]-J(1,2,100)
		sd = diagonal(cholesky(diag(variance(RES)))*100)'
		OUT = (BHAT*100 \mean \ sd)
		stata(" mat OUT = J(1,1,.) ")
		st_matrix("OUT",OUT)
	}
end
