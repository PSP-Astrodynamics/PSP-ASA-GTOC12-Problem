function [Xnew, uNew] = uq_enrichHalton( X, N, inpt )
% UQ_ENRICHHALTON Enriches a Halton sequence with additional elements of
% that sequence.
%
% UQ_ENRICHHALTON(X, N) enriches the current Halton design X,
%  defined by the currently selected input object by introducing
% N additional points
%
% UQ_ENRICHHALTON(X, N, INPUT) allows to specify the the INPUT object that
% corresponds to X
%
% Xnew = UQ_ENRICHHALTON(X, N, ...) returns an NxM matrix (where M is the number 
% of columns in X) that corresponds to the *new* samples (the already existing ones 
% in X are not included)
%
% [Xnew, uNew] = UQ_ENRICHHALTON(...) additionally returns the *new*
% samples in the uniform space

% assume 1 output argument when none is selected
num_of_out_args = max(nargout,1);

%% call uq_enrichSample to get the new samples
if exist('inpt', 'var')
    [results{1:num_of_out_args}] = uq_enrichSample(X, N, 'Halton', inpt);
else
    [results{1:num_of_out_args}] = uq_enrichSample(X, N, 'Halton');
end

%% return the results
Xnew = results{1};
if num_of_out_args > 1
    uNew = results{2};
end