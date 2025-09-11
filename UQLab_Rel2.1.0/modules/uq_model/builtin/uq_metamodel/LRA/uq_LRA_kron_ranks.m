function [kronranks_z z_noconst] = uq_LRA_kron_ranks(LRA, input_dims)
% FUNCTION KRONRANKS = UQ_LRA_KRON_RANKS(MODEL,INPUT_DIMS)
%
% A helper function that returns the LRA indices for specific input
% dimensions. The total indices are computed using the sum over all rank-1 
% components of the Kroneker product of the zeta coefficients along the
% specified dimensions. In case the dimensions are not provided, it
% computes the coefficients for all dimensions (for example in order to
% provide the total variance of the LRA model).
% Choose the function that infers the spectral component of the

coeff_determ = @(a,b) kron(a,b);

NInp = size(LRA.Coefficients.z{1},2);

if ~exist('input_dims','var')
    input_dims = 1:NInp;
end

if max(input_dims)>NInp
    error('Invalid dimension.');
end

% trim zeta:
z_tot = 0;
for ll = 1:LRA.Basis.Rank

    Coefs = LRA.Coefficients.z{ll};
    
    z_tmp=Coefs(:,input_dims(1));
    
    for kk = 2:length(input_dims)
        
        z_tmp = coeff_determ(Coefs(:,input_dims(kk)),z_tmp);
        
    end

    % This is to plot all the ranks if needed later on:
    
    z_tot = z_tot + z_tmp*LRA.Coefficients.b(ll);
    
end
kronranks_z = z_tot;