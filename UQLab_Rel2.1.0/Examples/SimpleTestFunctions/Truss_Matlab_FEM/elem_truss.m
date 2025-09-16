function [ke,fe] = elem_truss(elmat, xy)
%
%   [ke,fe] = elem_truss(action, elnum, elmat, xy, Type2D,IntScheme)

%%------------------------------------------------------------%%
%     Initialization
%%------------------------------------------------------------%%

    ElNode = 2 ;
    
    ke = zeros(4) ;
    fe = zeros([4 1]) ;
    
    
%%------------------------------------------------------------%%
%     Compute the stiffness matrix
%%------------------------------------------------------------%%    

    E = elmat.Emean;
    A = elmat.Amean ;
    
    delta_x = xy(2,1) - xy(1,1) ;
    delta_y = xy(2,2) - xy(1,2) ;
    
    L = sqrt( delta_x^2 + delta_y^2 );
    if delta_x == 0    % If element is vertical
    if delta_y < 0  % If element is vertical and upside down
        theta = -pi/2;
        else
            theta = pi/2;
        end
    else
        theta = atan( delta_y / delta_x );
    end
	
    % Element stiffness matrix in local coordinates
%     ke_local = [ E*A/L  -E*A/L   ;
%                 -E*A/L   E*A/L  ];
            
    ke_local = (E*A/L) * [ 1 0 -1 0 ;
                           0 0  0 0 ;
                          -1 0  1 0 ;
                           0 0  0 0] ;

    % Transformation to global coordinate system
    c = cos(theta);
    s = sin(theta);
    T = [ c  s   0  0  ;
         -s  c   0  0  ;
          0  0   c  s   ;
          0  0  -s  c ] ;
     
    ke = T' * ke_local * T;        
    
%%------------------------------------------------------------%%
%     Compute the load vector
%%------------------------------------------------------------%%    

    