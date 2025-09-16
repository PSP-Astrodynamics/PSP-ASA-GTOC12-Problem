function  varargout =  postprocess(Model,TheU,action,varargin)
%
%     	varargout =  postprocess(Model,TheU)
%     	Postprocess the displacement vector TheU to get element strains and stresses
%     	
%	    Model: the finite element model
%       TheU:  the displacement vector
%       action: a string in ['stress', 'strain', 'stressprinc','strainprinc','Coulomb']
%       varargin: two real numbers, Cohesion and FrictionAngle (in case of action = 'Coulomb')
%
%

  NbNodes = Model.NbNodes;
  DdlPerNode = Model.DdlPerNode;
  NbElts = Model.NbElts;
  NodePerElt = Model.NodePerElt; 
  Nddl = Model.Nddl;
  TypeDef = Model.TypeDef;
  COORD = Model.COORD;
  CONEC = Model.CONEC;
  MATS = Model.MATS;
  ELMAT  = Model.ELMAT;

%   Transforms the action into computational action
%   'stress' --> 'stress'
%   'strain' --> 'strain'
%   'stressprinc' --> 'stress'  (then eigenvalues computed)
%   'strainprinc' --> 'strain'  (then eigenvalues computed)
  ComputAction = action(1:6) ;
 if isequal(action, 'Coulomb')
     ComputAction = 'stress';
 end
 
  
for elnum = 1 : NbElts      %loop on elements
    % Compute the nodal coordinates of the current element
  for i = 1 : NodePerElt  
	xy (i, :) = COORD( CONEC(elnum, i) , :); % save the relevant node
                                             % coordinates in xy
  end;
  
  % Retrieve the element nodes
  ConecEl=CONEC(elnum,:);
 
  switch ELMAT.type(elnum)
  case 0                    %TRI3 elements
      ELDDL=[ConecEl(1)*2-1, ConecEl(1)*2,ConecEl(2)*2-1, ConecEl(2)*2,ConecEl(3)*2-1, ConecEl(3)*2]; 
      ue = TheU(ELDDL);  % vector of nodal displacements of the current element
      tmp= elem_tri3(ComputAction,elnum, ...
          MATS{ELMAT.mat(elnum)},xy, TypeDef,0,ue);  
      sigs(elnum, :) = tmp' ;

  case 1                   % Quad4 elements
      ELDDL=[ConecEl(1)*2-1, ConecEl(1)*2,ConecEl(2)*2-1, ConecEl(2)*2,ConecEl(3)*2-1, ConecEl(3)*2, ...
          ConecEl(4)*2-1, ConecEl(4)*2]; 
      ue = TheU(ELDDL);  % vector of nodal displacements of the current element
      
      %to be implemented : mean stress in the element
      tmp= elem_quad4(ComputAction,elnum, ...
							MATS{ELMAT.mat(elnum)},xy, TypeDef, ...
							Model.IntSchemes{1}, ue);  
      sigs(elnum, :) = tmp' ;

   otherwise
	fprintf('Invalid choice of element type \n');
  end
  
end;

switch action
case 'stress'   % stress tensor in element center
    varargout = {sigs};
    
case 'strain'   % strain tensor in element center
    varargout = {sigs};
    
case 'stressprinc',   % principal stresses 
    for elnum = 1 : NbElts 
        sigtmp = sigs(elnum,:);
        sigtensor = [[sigtmp(1), sigtmp(4)];[sigtmp(4),sigtmp(2)]];
        sigprin (elnum,:)= eigs(sigtensor)';
    end
    varargout = {sigprin};
case 'strainprinc',   % principal strains
    for elnum = 1 : NbElts 
        sigtmp = sigs(elnum,:);
        sigtensor = [[sigtmp(1), sigtmp(4)];[sigtmp(4),sigtmp(2)]];
        sigprin (elnum,:)= eigs(sigtensor)';
    end
    varargout = {sigprin};
    
case 'Coulomb',   % principal stresses or strains
    Cohesion = varargin{1};
    FrictionAngle = varargin{2};
    for elnum = 1 : NbElts 
        sigtmp = sigs(elnum,:);
        sigtensor = [[sigtmp(1), sigtmp(4)];[sigtmp(4),sigtmp(2)]];
%         sigtensor = [sigtmp(1) sigtmp(4) 0 ;...
%                      sigtmp(4) sigtmp(2) 0 ;...
%                      0         0         sigtmp(3)] ;
        sigprin = sort(eigs(sigtensor)') ; sigprin = sigprin(end:-1:1);    % eigs returns the largest eigen value, then second largest 
        Crit = (sigprin(1)-sigprin(2)) + (sigprin(1)+sigprin(2))*sin(FrictionAngle) - ...
            2*Cohesion*cos(FrictionAngle);
        CoulombCrit(elnum) = Crit;
    end
    
    varargout = {CoulombCrit'};
    
otherwise
    disp('This is an illegal action in postprocess.m!!');
end



%fprintf('\n');


