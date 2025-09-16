function varargout = elem_tri3(action, elnum, elmat, xy, Type2D,IntScheme,varargin)
%%------------------------------------------------------------%%
%     varargout = elem_tri3(action, elnum, elmat, xy, Type2D,IntScheme)
%  
%     TRI3 element matrix operations
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
  
  ElNode = 3 ; % 3 nodes per element
    
  ke = zeros(6);
  fe = zeros([6 , 1]);
  

  
%%------------------------------------------------------------%%
%     Compute the elasticity matrix
%%------------------------------------------------------------%%
  D = elasticity_matrix(elmat,'regular') ; 


%%------------------------------------------------------------%%
%     Weighted summation over gauss points
%     No loop since there is a single intergation point
%%------------------------------------------------------------%%

	xi  =  1/3;
	eta =  1/3;
	
  	% Compute the shape functions ShapeFunctions at the current point
	ShapeFunctions(1)= 1. - xi - eta ;
	ShapeFunctions(2)= xi ;
	ShapeFunctions(3)= eta ;
	
	% Compute the shape functions derivative dN/dxi at the current point
	dNdxi(1) =  - 1. ;
	dNdxi(2) =  1.  ;
	dNdxi(3) = 0. ;

	
	% Compute the shape functions derivative dN/deta at the current point
	dNdeta(1) =  - 1.;
	dNdeta(2) =  0. ;
	dNdeta(3) =  1. ;
  
  	% Compute global coordinates of current point
  	CurrentPoint = [ ShapeFunctions * xy( : , 1) ,  ShapeFunctions * xy( ...
 		: , 2)];  
  	
  	% Compute the Jacobian of the transformation
  	Jac(1, :) = [ xy( 2 , 1) - xy(1,1) ,  xy( 2 , 2)- xy(1,2)];
  	Jac(2, :) = [ xy( 3 , 1) - xy(1,1) ,  xy( 3 , 2)- xy(1,2)]; 
  	DetJac = det(Jac);
  	if ( DetJac <= 0)
  	  fprintf('Negative jacobian for element %5.0f . Change numbering', ...
  			  elnum);
	  DetJac = -DetJac;
  	end
  	InvJac = inv(Jac);
  	
  	% Compute the B Matrix ( 4 * 8 )
  	B = zeros ([4 , 6]);        
  	%     First row and part of the 4th row 
  	for  j=1 : ElNode
  	  B(1,2*j-1) = InvJac(1,1)*dNdxi(j) + InvJac(1,2)*dNdeta(j) ;
  	  B(4,2*j) = B(1,2*j-1) ;
  	end
  	%     Second row and part of the 4th row 
  	for  j=1 : ElNode
  	  B(2,2*j) = InvJac(2,1)*dNdxi(j) + InvJac(2,2)*dNdeta(j) ;
  	  B(4,2*j-1) = B(2,2*j) ;
  	end

   
  	
  	if (Type2D == 0) % Plane stress case only
  					 % Note that third row remains blank in plain strain
  	  Poi = elmat.nu ;
  	  dummy = -Poi/(1. - Poi) ;
  	  B(3, :) = dummy*(B(1, : )+B(2, :)) ;
  	end;
  	
  	
  	% Compute the element stiffness matrix
	weight = 0.5 * DetJac;

	if (isequal(action,'stiff') | isequal(action,'st&fo'))
	  ke =  weight * (B' * D * B) ;
	end
	
  	% Compute the nodal forces
	if (isequal(action,'force')| isequal(action,'st&fo'))
	  BodyForces = elmat.bodyforces' ;        % 2x1 vector
	  Sigma0     = elmat.initialstress' * ...
		  [ 1 CurrentPoint(1) CurrentPoint(2)]';     % 4x1 vector
	  
	  if nnz(BodyForces) ~= 0                 % compute nodal forces
                                              % associated to body forces
	  NN = [ShapeFunctions(1) , 0. ,ShapeFunctions(2) , 0. , ...
			ShapeFunctions(3) , 0.  ; ...
			0. , ShapeFunctions(1) , 0. ,ShapeFunctions(2) ,  ...
			0. ShapeFunctions(3) ];
	  fe =  weight * (NN'*BodyForces);
	  end
	  
	  if nnz(Sigma0) ~= 0                     % compute nodal forces
                                              % associated to initial stress
	  fe = fe -  weight * (B' * Sigma0);
	  end 
    end
  
    
 % Compute the stress tensor
if isequal(action,'stress')
    ue = varargin{1};
    StressEl= D*B*ue;
end

if isequal(action,'strain')
    ue = varargin{1};
    StrainEl= B*ue ;
end

switch action
case 'stiff'
    varargout = {ke};
case 'force'
    varargout = {fe};
case 'st&fo'
    varargout = {ke , fe};
case 'stress'
    varargout = {StressEl};       
case 'strain'
    varargout = {StrainEl};       
otherwise
    disp('Illegal call to elem_tri3');
end
 
  
  
  % 

  
