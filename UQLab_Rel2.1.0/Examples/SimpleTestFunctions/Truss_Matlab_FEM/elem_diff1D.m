function [ke,fe] = elem_diff1D(elmat, xy)
%   [ke,fe] = elem_diff1D(elmat, xy)

%%------------------------------------------------------------%%
%     Initialization
%%------------------------------------------------------------%%

ke = zeros(2) ;
fe = zeros([2 1]) ;

%%------------------------------------------------------------%%
%     Compute the stiffness matrix
%%------------------------------------------------------------%%
E = elmat.E;
L = xy(2) - xy(1) ;

% Element stiffness matrix in local coordinates
%     ke_local = [ E/L  -E/L   ;
%                 -E/L   E/L  ];
ke = [1. -1. ; ...
        -1. 1.];
ke = (E/L)*ke;

%%------------------------------------------------------------%%
%     Compute the load vector
%%------------------------------------------------------------%%
 f0 = elmat.bodyforces;
 fe =(f0* L/2)*[1 1]; 
 return
 
    