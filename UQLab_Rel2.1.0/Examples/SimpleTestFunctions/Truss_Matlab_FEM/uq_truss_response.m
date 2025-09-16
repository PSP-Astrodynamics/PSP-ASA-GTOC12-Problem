function    Y   =   uq_truss_response(XX)
% Simple Finite Elements truss structure response calculation

% get the model: it will create variable "fem_model"
fem_model = uq_truss_model;
n = size(XX,1);
Y = zeros(n,1);

% non vectorized FEM evaluation
for ii = 1:n
    X = XX(ii,:);
    fem_model.MATS{1}.Emean = X(1) ;
    fem_model.MATS{2}.Emean = X(2) ;
    fem_model.MATS{1}.Amean = X(3) ;
    fem_model.MATS{2}.Amean = X(4) ;
    fem_model.LOADS(13,2) = -X(5) ;
    fem_model.LOADS(12,2) = -X(6) ;
    fem_model.LOADS(11,2) = -X(7) ;
    fem_model.LOADS(10,2) = -X(8) ;
    fem_model.LOADS(9,2) = -X(9) ;
    fem_model.LOADS(8,2) = -X(10) ;
    
    U = myfem(fem_model) ;
    
    %pause(1);
    Y(ii,1) = U(8) ;
end
%    Y = U([3:13 15:26])' ;

