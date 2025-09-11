function Y = uq_resampleKriging(current_model,U0,R)
%UQ_RESAMPLEKRIGING generates sample paths of the Kriging model

%   Y = UQ_RESAMPLEKRIGING(current_model,U0,R) returns a N x Nout x R
%   matrix containing R trajectories of the Kriging model. Each trajectory
%  is of size N x 1, where N is the number of discretization point on the
%  sampling mesh
%   matrix F evaluated at points X of a Kriging metamodel stored in
%   current_model.
%
%   See also  UQ_KRIGING_EVAL, UQ_GETRFSAMPLE, UQ_RF_XI_TO_X

% Get the number of output dimensions
Nout = current_model.Internal.Runtime.Nout;

%% 
% Get the number of inputs
N = size(U0,1);

%% 
% cycle through each output
OutCurr=zeros(R,N,Nout);

for oo = 1:Nout
    % Get the random field samples
    outCurr(:,:,oo) = uq_getSample(current_model.Kriging(oo).GRF,R,'Mesh',U0);

end

% Permute to get consistent outputs
Y = permute(outCurr,[2 3 1]) ;
    end