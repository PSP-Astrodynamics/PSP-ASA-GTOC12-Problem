function femodel = uq_truss_model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           FE model of a 23-bar truss structure            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   Number of DOF per node
    NDOF = 2 ;

    
%   Mean variables ;
    E_hor = 2.1e11 ;
    E_obl = 2.1e11 ;
    A_hor = 2.0e-3 ;
    A_obl = 1.0e-3 ;
    P1 = 5.0e4 ;
    P2 = 5.0e4 ;
    P3 = 5.0e4 ;
    P4 = 5.0e4 ;
    P5 = 5.0e4 ;
    P6 = 5.0e4 ;
    
%   Nodes coordinates (x,y)    
    COORD(1,:) = [  0         0     ];
    COORD(2,:) = [  4        0      ];
    COORD(3,:) = [  8        0    ];
    COORD(4,:) = [  12       0    ];
    COORD(5,:) = [  16       0   ];
    COORD(6,:) = [  20       0    ];
    COORD(7,:) = [  24       0    ];
    COORD(8,:) = [  22       2   ];
    COORD(9,:) = [  18       2   ];
    COORD(10,:) = [ 14       2     ];
    COORD(11,:) = [ 10       2     ];
    COORD(12,:) = [ 6        2     ];
    COORD(13,:) = [ 2        2     ];
    
    [NbNodes , DdlPerNode] =  size(COORD);    
    
%   Elements    
    for i=1:6
        CONEC(i,:) = [i i+1] ;
    end;
    for i=7:11
        CONEC(i,:) = [i+1 i+2] ;
    end;
    
    CONEC(12,:) = [1 13] ;
    CONEC(13,:) = [2 13] ;
    CONEC(14,:) = [2 12] ;
    CONEC(15,:) = [3 12] ;
    CONEC(16,:) = [3 11] ;
    CONEC(17,:) = [4 11] ;
    CONEC(18,:) = [4 10] ;
    CONEC(19,:) = [5 10] ;
    CONEC(20,:) = [5 9] ;
    CONEC(21,:) = [6 9] ;
    CONEC(22,:) = [6 8] ;
    CONEC(23,:) = [7 8] ;
    
    [NbElts , NodePerElt ] =  size(CONEC);
    
%   Element type: '2' for bar elements    
    ELMAT.type = 2*ones([1 , NbElts]);  
    
%   Horizontal bars: material '1'    
    ELMAT.mat(1:11) = ones([1 , 11]);
    
%   Oblical bars: material '2'  
    ELMAT.mat(12:23) = 2*ones([1 , 12]);
    
%   Elements '1' properties    
    MATS{1}.Emean = E_hor;
    MATS{1}.Amean = A_hor;
    
%   Elements '2' properties     
    MATS{2}.Emean = E_obl;
    MATS{2}.Amean = A_obl;
    
%   Boundary conditions: free=0 & blocked=1    
    BC = zeros ([NbNodes , DdlPerNode]);  % default value is free
    BC(1,:) = [1 1] ;
    BC(7,2) = 1 ;
    
%   Loading 
    LOADS = zeros([NbNodes , DdlPerNode]);
    LOADS(13,2) = -P1 ;
    LOADS(12,2) = -P2 ;
    LOADS(11,2) = -P3 ;
    LOADS(10,2) = -P4 ;
    LOADS(9,2) = -P5 ;
    LOADS(8,2) = -P6 ;
        
    TypeDef = 0 ;
    
%   Gathering the data in a structure called 'femodel'    
    femodel = MakeModel_gPC(TypeDef,COORD,CONEC,BC,MATS, ELMAT, LOADS, NDOF) ;
    
%   Compute the displacement field    
%     U = myfem(femodel);
%     
% %   Display the deformed structure    
%     plot_output(1,COORD, CONEC,U,0)
% %   Print the maximal deflection (i.e. at node 4)    
%     fprintf('u4 = %13.7e \n', U(4));
