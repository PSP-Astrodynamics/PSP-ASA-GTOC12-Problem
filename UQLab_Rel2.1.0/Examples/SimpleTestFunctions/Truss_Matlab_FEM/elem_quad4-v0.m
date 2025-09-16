function varargout = elem_quad4(action, elnum, elmat, xy, Type2D,IntScheme)
%%------------------------------------------------------------%%
%     ke = elem_quad4(action, elnum, elmat, xy, Type2D, TheSchemes)
%  
%     QUAD4 element matrix operations
%
%     action : 'stiff' --> returns ke 
%              'force' --> returns fe
%              'st&fo' --> returns both
%  
%     elnum  : element number
%     elmat  : element material properties
%
%        elmat.Emean       =  Mean Young's modulus
%        elmat.nu          =  Poisson Ratio
%
%     xy     : element node coordinates 
%               xy(i,j) = j-th coordinate of node i   
%     Type2D : 0 for plane stress
%                  1 for plane strain
%
%
%

%%------------------------------------------------------------%%
%     Initialization
%%------------------------------------------------------------%%
  
  ElNode = 4 ; % 4 nodes per element
    
%  xy(1 , : ) = [0 0];
%  xy(2 , : ) = [0.5 0];
%  xy(3 , : ) = [0.5 0.5];
%  xy(4 , : ) = [0 0.5];
%  
%  elmat.Emean = 2.;      % Mean Young's modulus
%  elmat.nu = 0.3 ;       % Poisson Ratio
%  Type2D = 1;
%  
  ke = zeros(8);
  fe = zeros([8 , 1]);
  

  
%%------------------------------------------------------------%%
%     Compute the elasticity matrix
%%------------------------------------------------------------%%
  D = elasticity_matrix(elmat,'regular') ; 


%%------------------------------------------------------------%%
%     Weighted summation over gauss points
%     2 * 2 integration
%%------------------------------------------------------------%%
  for i = 1 : IntScheme.size
	xi  =  IntScheme.pts(i , 1) ;
	eta =  IntScheme.pts(i , 2) ;
	
	% Compute the shape functions ShapeFunctions at the current point
	ShapeFunctions(1)= (1. - xi)*(1. - eta)/4. ;
	ShapeFunctions(2)= (1.+xi)*(1. - eta)/4. ;
	ShapeFunctions(3)= (1.+xi)*(1.+eta)/4. ;
	ShapeFunctions(4)= (1. - xi)*(1.+eta)/4. ;
	
	% Compute the shape functions derivative dN/dxi at the current point
	dNdxi(1) =  - (1. - eta)/4. ;
	dNdxi(2) =  - dNdxi(1) ;
	dNdxi(3) = (1.+eta)/4. ;
	dNdxi(4) =  - dNdxi(3) ;
	
	% Compute the shape functions derivative dN/deta at the current point
	dNdeta(1) =  - (1. - xi)/4. ;
	dNdeta(2) =  - (1.+xi)/4. ;
	dNdeta(3) =  - dNdeta(2) ;
	dNdeta(4) =  - dNdeta(1) ;
  
  	% Compute global coordinates of current point
  	CurrentPoint = [ ShapeFunctions * xy( : , 1) ,  ShapeFunctions * xy( ...
		: , 2)];  
  	
  	% Compute the Jacobian of the transformation
  	Jac(1, :) = [ dNdxi * xy( : , 1) , dNdxi * xy( : , 2)];
  	Jac(2, :) = [ dNdeta * xy( : , 1) , dNdeta * xy( : , 2)]; 
  	DetJac = det(Jac);
  	if ( DetJac <= 0)
  	  fprintf('Negative jacobian for element %5.0f . Change numbering', ...
  			  elnum);
	  DetJac = -DetJac;
  	end;
  	InvJac = inv(Jac);
  	
  	% Compute the B Matrix (4 * 8 )
  	B = zeros ([4 , 8]);        
  	%     First row and part of the 4th row 
  	for  j=1 : ElNode
  	  B(1,2*j-1) = InvJac(1,1)*dNdxi(j) + InvJac(1,2)*dNdeta(j) ;
  	  B(4,2*j) = B(1,2*j-1) ;
  	end;
  	%     Second row and part of the 4th row 
  	for  j=1 : ElNode
  	  B(2,2*j) = InvJac(2,1)*dNdxi(j) + InvJac(2,2)*dNdeta(j) ;
  	  B(4,2*j-1) = B(2,2*j) ;
  	end;
  	
  	if (Type2D == 0) % Plane stress case only
  					 % Note that third row remains blank in plain strain
  	  Poi = elmat.nu ;
  	  dummy = -Poi/(1. - Poi) ;
  	  B(3, :) = dummy*(B(1, : )+B(2, :)) ;
  	end;
  	
  	
  	% Compute the element stiffness matrix
	weight = IntScheme.wgh(i) * DetJac ;

	if ((action == 'stiff') | (action == 'st&fo'))
	  ke = ke + weight * (B' * D * B) ;
	end
	
  	% Compute the nodal forces
	if ((action == 'force')| (action == 'st&fo'))
	  BodyForces = elmat.bodyforces' ;        % 2x1 vector
	  Sigma0     = elmat.initialstress' * ...
		  [ 1 CurrentPoint(1) CurrentPoint(2)]';     % 4x1 vector
	  
	  if nnz(BodyForces) ~= 0                 % compute nodal forces
                                              % associated to body forces
	  NN = [ShapeFunctions(1) , 0. ,ShapeFunctions(2) , 0. , ...
			ShapeFunctions(3) , 0. ,ShapeFunctions(4) , 0. ; ...
			0. , ShapeFunctions(1) , 0. ,ShapeFunctions(2) ,  ...
			0. ShapeFunctions(3) , 0. ,ShapeFunctions(4) ];
	  fe = fe + weight * (NN'*BodyForces);
	  end
	  
	  if nnz(Sigma0) ~= 0                     % compute nodal forces
                                              % associated to initial stress
	  fe = fe -  weight * (B' * Sigma0);
	  end 
	end
  
  end;
  
  switch action
   case 'stiff'
	varargout = {ke};
   case 'force'
	varargout = {fe};
   case 'st&fo'
	varargout = {ke , fe};
  end
  
  
  % 

  
