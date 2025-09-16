function [Hessian, ModelEvaluations, ExpDesign] = uq_hessian(X, fcn_, M_X, h)
% Hessian = UQ_HESSIAN(X,fcn)
% Calculate the Hessian Matrix of the limit state function, fcn,
% for a given point X.
%
% Hessian = UQ_HESSIAN(X,fcn,M_X)
% Calculate the Hessian Matrix of the limit state function, fcn,
% for a given point X. The argument M_X contains fcn(X) precalculated, 
% so some model evaluations are saved.
%
% [Hessian, ModelEvaluations]= UQ_HESSIAN(...) also returns the
% number of fcn evaluations required to compute the Hessian matrix.
% 
% The fcn can optionally contain information about which inputs are
% constant in order to skip the hessian computation along them.
%
% See also: UQ_SORM

if isfield(fcn_,'nonConst')
    nonConst = fcn_.nonConst;
    fcn = fcn_.handle;
    
    % Number of non-constant variables
    M = size(X(:,find(nonConst)),2);   

else
    fcn = fcn_;
    M = size(X,2);
    nonConst = ones(1,M);
end

% Sample check
N = size(X,1); 
if N > 1
    error('The Hessian is calculated only at a single point.');
end

%% Get the information from the Framework:
% If h is not specified, set it to value of the module or to the default:
if nargin < 4
    h = 1e-3;
end


%% Start the computation (centred scheme):
% Prepare the matrix to compute the displacements:
if M > 1
    Index = nchoosek(1:sum(nonConst),2);
else
    Index = [1, 1];
end
IndLen = size(Index, 1);

% Allocate the displacements
H = zeros(M, IndLen); 

for ii = 1:size(Index, 1)
    HPlus(ii, Index(ii,1)) = h;
    HPlus(ii, Index(ii,2)) = h;
    
    HPlusMinus(ii, Index(ii,1)) = h;
    HPlusMinus(ii, Index(ii,2)) = -h;
end
HMinus = -1*HPlus;
HMinusPlus = -1*HPlusMinus;

% For the diagonal elements:
Hdiag = diag(h*ones(1,sum(nonConst)));
HdiagMinus = -1*Hdiag;

% All of these increments are made on X:
AllHs = bsxfun(@plus, X(:,find(nonConst)), [HPlus; HMinus; Hdiag; HdiagMinus; HPlusMinus; HMinusPlus]);

AllHsTmp = zeros(size(AllHs,1),size(X,2));
AllHsTmp(:,find(nonConst))  = AllHs;
AllHsTmp(:,find(~nonConst)) = repmat(X(:,find(~nonConst)),size(AllHs,1),1);
AllHs = AllHsTmp;

%% Do all the evaluations:
if nargin < 3 || isempty(M_X)
    % There are no evaluated points
    ExpDesign.X = [X; AllHs];
    ExpDesign.Y = fcn(ExpDesign.X);
    M_HPlus = ExpDesign.Y;
    
    Cost = length(M_HPlus);
    M_X = M_HPlus(1:size(X,1));
    M_HPlus(1:size(X,1)) = [];
else
    % We already have M_X:
    ExpDesign.X = AllHs;
    ExpDesign.Y = fcn(ExpDesign.X);
    M_HPlus = ExpDesign.Y;
    Cost = length(M_HPlus);
end
LenHSet = size(HPlus,1);

% Counter for mapping back the evaluations:
% The order was: HPlus, HMinus, Hdiag, HdiagMinus, HPlusMinus, HMinusPlus
I = LenHSet;
M_HMinus = M_HPlus(I + 1:I + LenHSet);
I = I + LenHSet;

M_Hdiag = M_HPlus(I + 1:I + M);
I = I + M;

M_HdiagMinus = M_HPlus(I + 1: I + M);
I = I + M;

M_HPlusMinus = M_HPlus(I + 1:I + LenHSet);
I = I + LenHSet;

M_HMinusPlus = M_HPlus(I + 1:I + LenHSet);

M_HPlus = M_HPlus(1:LenHSet);

% Now that everything is evaluated, create the Hessian:
Hessian = zeros(M, M);
for i = 1:M
        
    for j = 1:M
         
        if i==j 
            % Diagonal element, the formula is easier
            Hessian(i,j) = (M_Hdiag(i)  - 2*M_X + M_HdiagMinus(i))/h^2;
        else
            % The rest of elements:            
            [~, idx] = ismember([min(i,j), max(i,j)], Index, 'rows');
            ipjp =   M_HPlus(idx);
            imjm = M_HMinus(idx);
            ipjm =   M_HPlusMinus(idx);
            imjp = M_HMinusPlus(idx);
            Hessian(i,j) = (ipjp - ipjm - imjp + imjm)/(4*h^2);
        end
    end
end

if nargout > 1
    ModelEvaluations = Cost;
end

% For consistency simply set the hessian values that correspond to
% constants to zero:
Htmp = zeros(length(nonConst),length(nonConst));
Htmp(find(nonConst),find(nonConst)) = Hessian;
Hessian = Htmp;
