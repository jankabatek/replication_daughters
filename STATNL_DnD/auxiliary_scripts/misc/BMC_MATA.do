
cap mata: mata drop BMC_MATA()
mata
function BMC_MATA(n)
	{
		stata(" mat B_MC = J(1,1,0) " )
		
		B 		= st_matrix("e(b)")
		//B
		V 		= st_matrix("e(V)")
		B_AUX 	= select(B,B[,]:!=0)
		V_AUX 	= select(V,B[,]:!=0)
		V_NZ 	= select(V_AUX,(B[,]:!=0)')
		//cholesky decomposition
		C 		= cholesky(V_NZ)
		
		Z		= (rnormal(n, rows(V_NZ), 0, 1))
		B_MC_AUX= J(n, 1, B_AUX) + Z*C';
		B_MC 	= J(n, cols(B), 0)
		
		j=1
		for (i=1; i<=cols(B); i++) {
			if (B[1,i]==0) { 
				//printf("nula")
			}
			else {
				
				//printf("nenula")
				B_MC[,i]=B_MC_AUX[,j]
				j=j+1
			}
		}	
		
		st_matrix("B_MC",B_MC)
	}
end
