function  [StifMatrix , Force] =  assemble(Model)
%
%     	Assembling procedure -  for each element :
%
%     	  - compute the localisation table, i.e
%     		the global number of dof for each local number of dof.
%     	  - compute the stiffness matrix
%     	  - add it up to the global stiffness matrix


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


StifMatrix = sparse(Nddl , Nddl);
StifMatrixNew = sparse(Nddl , Nddl);
Force = zeros([Nddl , 1]);
ForceNew = zeros([Nddl , 1]);

xy = zeros (NodePerElt,length(COORD( CONEC(1, 1) , :)));
for elnum = 1 : NbElts
    if (mod (elnum , ceil(NbElts/10)) == 0)
        %fprintf(' %1.0f0%% /', (10 * elnum / NbElts));  % displays the status of
        % simulation
    end;
    % Compute the localization table giving the global ddl number as a
    % function of the local ddl number in the element
    LOCE = zeros([1 , NodePerElt * DdlPerNode ]);
    switch ELMAT.type(elnum)
        case 11  % 1D thermal problem / 1 ddl per node
            LOCE = [CONEC(elnum,1) CONEC(elnum,2)];
        case {3, 21} % Beam and 3D bar elements
            LOCE = [ [1:3]+(CONEC(elnum,1)-1)*3 [1:3]+(CONEC(elnum,2)-1)*3] ;
        otherwise
            for  i = 1 : NodePerElt
                LOCE(2*i-1) = 2 * CONEC(elnum,i)-1;
                LOCE(2*i)   = 2 * CONEC(elnum,i);
            end;
    end;
    
    %     LOCE = zeros([1 NodePerElt * DdlPerNode]) ;
    %     LOCE = [1:6] + 3*(elnum-1) ;
    
    
    % Compute the element stiffness matrix
    for i = 1 : NodePerElt
        xy (i, :) = COORD( CONEC(elnum, i) , :); % save the relevant node
        % coordinates in xy
    end;
    switch ELMAT.type(elnum)
        case 0                    %TRI3 elements
            [ke , fe ] = elem_tri3('st&fo',elnum, ...
                MATS{ELMAT.mat(elnum)},xy, TypeDef);
        case 1                   % quad4 elements
            [ke , fe ] = elem_quad4('st&fo',elnum, ...
                MATS{ELMAT.mat(elnum)},xy, TypeDef, ...
                Model.IntSchemes{1});
        case 2                   % bar2 elements
            [ke , fe] = elem_truss(MATS{ELMAT.mat(elnum)}, xy) ;
        case 3                   % beam elements
            [ke , fe] = elem_beam(MATS{ELMAT.mat(elnum)}, xy) ;
        case 11
            [ke , fe] = elem_diff1D(MATS{ELMAT.mat(elnum)}, xy);
        case 21                   % bar3 elements
            [ke , fe] = elem_truss_3d(MATS{ELMAT.mat(elnum)}, xy) ;
        otherwise
            fprintf('Invalid choice of element type \n');
    end
    
    % Assemble the element stiffness matrix to the global stiffness matrix
    %and the nodal forces to the load vector
    %     for i = 1 : length(LOCE)
    %         ii = LOCE(i) ;
    %         for j = 1 : length(LOCE)   % Assemble upper part
    %             jj = LOCE(j);
    %             StifMatrix(ii , jj) =  ...
    %                 StifMatrix(ii , jj) + ke (i,j) ;
    %         end;
    %         Force(ii) =  Force(ii) + fe(i) ;
    %     end;
    %     for i = 1 : length(LOCE)
    %         ii(i) = LOCE(i) ;
    %         for j = 1 : length(LOCE)   % Assemble upper part
    %             jj(j) = LOCE(j);
    %
    %         end;
    %         Force(ii) =  Force(ii) + fe(i) ;
    %     end;
    
    
    
        
    ii = repmat(LOCE,numel(LOCE),1); jj = repmat(LOCE, 1,numel(LOCE));
    StifMatrix = StifMatrix + sparse(ii(:),jj(:),ke(:), Nddl,Nddl);
    Force(LOCE) = Force(LOCE) + reshape(fe, size(Force(LOCE)));
end;

%fprintf('\n');


