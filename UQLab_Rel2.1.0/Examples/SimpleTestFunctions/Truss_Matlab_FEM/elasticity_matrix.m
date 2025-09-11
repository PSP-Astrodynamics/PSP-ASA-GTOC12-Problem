function   D = elasticity_matrix(elmat,type)
%%------------------------------------------------------------%%
%
%     compute 4 * 4 two-dimensional elasticity matrix
%     yielding the stress tensor components from the 
%     elastic strain tensor
%
%     [Sxx , Syy , Szz , Sxy] = D . [ Exx, Eyy , Ezz , 2 Exy] 
%
%     !!!! Remember the 2Exy in the representation
%
%     elmat : structure containing the material properties 
%     type  : 'regular'  or 'unit' (in this case Young's modulus is set
%             to 0 )

  
%     Retrieve material properties
  switch type
	case 'regular'
	 E = elmat.Emean;       
	 
   case 'unit' 
	 E =  1.;
  end;
  
  Poi = elmat.nu   ; 
  deuxmu = E/(1 + Poi);
  lambda = deuxmu*Poi/(1-2*Poi);

%     Compute the elasticity matrix  
  D =zeros(4);
  D (1 , : ) = [lambda + deuxmu , lambda , lambda , 0] ;
  D (2 , : ) = [lambda , lambda + deuxmu , lambda , 0] ;
  D (3 , : ) = [lambda , lambda , lambda + deuxmu , 0] ;
  D (4 , : ) = [0 , 0 , 0 , deuxmu/2] ;

  

				
