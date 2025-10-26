function [ke,fe] = elem_truss_3d(elmat, xy)
%
%   [ke,fe] = elem_truss(action, elnum, elmat, xy, Type2D,IntScheme)

%%------------------------------------------------------------%%
%     Initialization
%%------------------------------------------------------------%%
% Number of nodes per element
ElNode = 2 ;

% Local stiffness matrix
ke = zeros(6) ;
% Local force vector
fe = zeros([6 1]) ;


%%------------------------------------------------------------%%
%     Compute the stiffness matrix
%%------------------------------------------------------------%%
% Get the Young modulus and the bar cross-sectional area
E = elmat.Emean;
A = elmat.Amean ;

% Loal coordinate-wise distances in the matrix
delta_x = xy(2,1) - xy(1,1) ;
delta_y = xy(2,2) - xy(1,2) ;
delta_z = xy(2,3) - xy(1,3) ;

% Length of the bar
L = sqrt( delta_x^2 + delta_y^2 + delta_z^2 );


% Stiffness matrix
delta_xx = delta_x * delta_x ;
delta_yy = delta_y * delta_y ;
delta_zz = delta_z * delta_z ;
delta_xy = delta_x * delta_y ;
delta_xz = delta_x * delta_z ;
delta_yz = delta_y * delta_z ;
delta_block = [ delta_xx delta_xy delta_xz ;
    delta_xy delta_yy delta_yz ;
    delta_xz delta_yz delta_zz ] ;

ke = (E*A/L^3) * [  delta_block  -delta_block ;
    -delta_block   delta_block ] ;



%%------------------------------------------------------------%%
%     Compute the load vector
%%------------------------------------------------------------%%

