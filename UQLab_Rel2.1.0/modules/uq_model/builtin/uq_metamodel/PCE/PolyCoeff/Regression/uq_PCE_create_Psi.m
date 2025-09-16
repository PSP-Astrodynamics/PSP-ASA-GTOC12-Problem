function Psi = uq_PCE_create_Psi(Indices, univ_p_val)
% PSI = UQ_PCE_CREATE_PSI(INDICES, UNIV_P_VALUES): assemble the design
%     matrix Psi from the given basis index set INDICES and the univariate
%     polynomial evaluations univ_p_val.
%
% See also: UQ_PCE_EVAL_UNIPOLY,UQ_GENERATE_BASIS_APMJ

%% INITIALIZATION AND CONSISTENCY CHECKS
% number of input variables
M = size(univ_p_val, 2);

% size of the experimental design
N = size(univ_p_val, 1);

% number of basis elements
P = size(Indices, 1);

% check that the variables have consistent sizes
if M ~= size(Indices, 2)
    error('Error: Index and univ_p_val don''t seem to have consistent sizes!!');
end


% Preallocate the Psi matrix for performance
Psi = ones(N,P);
% Assemble the matrix
for mm = 1:size(Indices,2)
    aa = Indices(:,mm) > 0;
    try
        Psi(:,aa) = Psi(:,aa) .* reshape(univ_p_val(:,mm, Indices(aa,mm)+1), size(Psi(:,aa)));
    catch me
        % give an error if something odd happens
        warning(me.message);
    end
end
