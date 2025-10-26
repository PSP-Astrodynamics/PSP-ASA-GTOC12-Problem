function randIdx = uq_Kriging_helper_create_randIdx(nPerClass,N)
%UQ_KRIGING_HELPER_CREATE_RANDIDX creates a cell array of random indices.
%
%   randIdx = uq_Kriging_helper_create_RandIdx(nPerClass,N) returns a cell
%   array of length ceil(N/nPerClass); each cell element contains the
%   indices to create a subset (i.e., class) of the N observation points.
%   It is used in the computation of k-Fold cross-validation.
%
%   See also uq_Kriging_calc_KFold, uq_Kriging_eval_J_of_theta_CV,
%   uq_Kriging_calculate.

%% Create the size of each subset/class
nClasses = ceil(N/nPerClass);
nIndices = repmat(nPerClass, 1, nClasses);
nIndices(end) = N - nPerClass * (nClasses-1);  % The remainder

%% Randomly permute Y (only if K != N)
if nClasses < N
    randIdx = randperm(N);
else
    randIdx = 1:N;
end

randIdx = mat2cell(randIdx, 1, nIndices);

end
