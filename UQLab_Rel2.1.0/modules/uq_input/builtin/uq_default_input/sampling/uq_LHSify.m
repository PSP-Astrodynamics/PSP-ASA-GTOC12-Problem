function [Xnew, uNew] = uq_LHSify(X, N, inpt)
% UQ_LHSIFY enriches a sample set in a pseudo LHS fashion. That is, if the
% initial design forms a Latin Hypercube the full design after enrichment
% will still be a Latin Hypercube. If the initial design does not form a
% Latin Hypercube the new design will try to get as close as possible to a
% Latin Hypercube. 
%
% UQ_LHSIFY(X, N) enriches the current set of samples X, defined 
% by the currently selected input object by introducing N additional points
%
% UQ_LHSIFY(X, N, INPUT) allows to specify the the INPUT object that
% corresponds to X
%
% Xnew = UQ_LHSIFY(X, N, ...) returns an NxM matrix (where M is the number 
% of columns in X) that corresponds to the *new* samples (the already existing ones 
% in X are not included)
%
% [Xnew, uNew] = UQ_LHSIFY(...) additionally returns the *new*
% samples in the uniform space
%
% See also UQ_ENRICHLHS, UQ_ENRICH_LHS

% assume 1 output argument when none is selected
num_of_out_args = max(nargout,1);

%% call uq_enrichSample to get the new samples
if exist('inpt', 'var')
    [results{1:num_of_out_args}] = uq_enrichSample(X, N, 'LHS', inpt);
else
    [results{1:num_of_out_args}] = uq_enrichSample(X, N, 'LHS');
end

%% return the results
Xnew = results{1};
if num_of_out_args > 1
    uNew = results{2};
end



