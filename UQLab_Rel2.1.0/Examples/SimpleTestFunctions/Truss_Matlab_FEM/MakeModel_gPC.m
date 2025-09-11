function Model = MakeModel_gPC(TypeDef,COORD,CONEC,BC,MATS, ELMAT, LOADS,NDOF) 
%
%      Model = MakeModel_gPC(TypeDef,COORD,CONEC,BC,MATS, ELMAT);
%  
%      Allows to pack all the data describing the structure in a single
%      structure 'Model'.  
%
%      Has to be called before analysing with myfem or ssfem.
%  
  
%   [NbNodes , DdlPerNode] =  size(COORD);
  NbNodes = size(COORD,1);
  DdlPerNode = NDOF ;
  [NbElts , NodePerElt ] =  size(CONEC);
  Nddl = NbNodes * DdlPerNode ;

  Model.NbNodes = NbNodes;
  Model.DdlPerNode = DdlPerNode;
  Model.NbElts  = NbElts;
  Model.NodePerElt = NodePerElt; 
  Model.Nddl    = Nddl;
  Model.TypeDef = TypeDef;
  Model.COORD   = COORD;
  Model.CONEC   = CONEC;
  Model.BC      = BC';   %       !!!!! Look at the transposition
  Model.LOADS   = LOADS ;
  
  % Add some fields to the MATS structure if they don't exist
  for j = 1 : length(MATS)
	if (isfield(MATS{j} , 'bodyforces'))
	else
	  MATS{j}.bodyforces = [0. 0.];
	end
	if (isfield(MATS{j} , 'initialstress'))
	else
	  MATS{j}.initialstress = zeros([3, 4]);
	end
  end
  
  Model.MATS    = MATS;
  Model.ELMAT   = ELMAT;
  
  %%------------------------------------------------------------%%
  %      Compute Gauss Integration Schemes
  %%------------------------------------------------------------%%
  Model.IntSchemes = IntegrationSchemes;
  
  
