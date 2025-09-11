function [ke,fe] = elem_beam(elmat, xy)
%
%   [ke,fe] = elem_truss(action, elnum, elmat, xy, Type2D,IntScheme)

%%------------------------------------------------------------%%
%     Initialization
%%------------------------------------------------------------%%

    ElNode = 2 ;
    
    ke = zeros(6) ;
    fe = zeros([6 1]) ;
    
    
%%------------------------------------------------------------%%
%     Compute the stiffness matrix
%%------------------------------------------------------------%%    

    E = elmat.Emean;
    A = elmat.Amean ;
    I = elmat.Imean ;
    nu = 0.3 ; %default Poisson's coefficient
    G = E/(2*(1+nu)) ; % shear modulus
    
    
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
%             
%     ke_local = [   E*A/L  0           0        -E*A/L        0             0      ;
%                0      12*E*I/L^3  6*E*I/L^2      0       -12*E*I/L^3   6*E*I/L^2  ;
%                0      6*E*I/L^2   4*E*I/L        0       -6*E*I/L^2    2*E*I/L    ;
%                -E*A/L 0           0              E*A/L   0             0          ;
%                0      -12*E*I/L^3 -6*E*I/L^2     0       12*E*I/L^3    -6*E*I/L^2 ;    
%                0      6*E*I/L^2   2*E*I/L        0       -6*E*I/L^2    4*E*I/L    ];

    k = 5/6 ; % assuming a full rectangular cross section    
    phi = (12/(L^2)) * E*I/(k*G*A) ; % correction d'effort tranchant

    ke_local = 1/(1+phi)*...
               [   (1+phi)*E*A/L  0           0        (1+phi)*(-E*A/L)        0             0      ;
               0      12*E*I/L^3  6*E*I/L^2      0       -12*E*I/L^3   6*E*I/L^2  ;
               0      6*E*I/L^2   (4+phi)*E*I/L        0       -6*E*I/L^2    (2-phi)*E*I/L    ;
               (1+phi)*(-E*A/L) 0           0              (1+phi)*E*A/L   0             0          ;
               0      -12*E*I/L^3 -6*E*I/L^2     0       12*E*I/L^3    -6*E*I/L^2 ;    
               0      6*E*I/L^2   (2-phi)*E*I/L        0       -6*E*I/L^2    (4+phi)*E*I/L    ];

%     ke_local = E*I/L^3* [12     6*L     -12     6*L
%                          6*L    4*L^2   -6*L    2*L^2
%                          -12    -6*L    12      -6*L
%                          6*L    4*L     -6*L    4*L^2] ;

    % Transformation to global coordinate system
    c = cos(theta);
    s = sin(theta);
    T = [ c  s  0     0  0  0 ;
         -s  c  0     0  0  0 ;
          0  0  1     0  0  0 ;
          0  0  0     c  s  0 ;
          0  0  0    -s  c  0 ;
          0  0  0     0  0  1 ];

%     T = [ c  s   0  0  ;
%          -s  c   0  0  ;
%           0  0   c  s   ;
%           0  0  -s  c ] ;
     
    ke = T' * ke_local * T;        
    


    