function [K_out , F_out] = boundary_conditions(K_in,F_in,BC)
%     
%     	boundary_conditions(StifMatrix,BC)
%     	
%     	Transform the global stiffness matrix in order to
%     	take into account boundary conditions.
%     	
%     	Current version : only zero imposed displacements
%     					  are taken into account
%     	
  K_out = K_in;
  F_out = F_in;
  IndicesImposed = find(BC); % returns indices of blocked ddl in the global
							 % numbering (1 ... Nddl)
  for j = 1 : length(IndicesImposed);
	index = IndicesImposed(j);
	K_out(index , :) = 0. ;
	K_out(:     , index) = 0. ;
	K_out(index , index) = 1. ;
	% No modification of load vector when no non zero
	% imposed displacements applied
	F_out(index) = 0. ;
  end;
  


