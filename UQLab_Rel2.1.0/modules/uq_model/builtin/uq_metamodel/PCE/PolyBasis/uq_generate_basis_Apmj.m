function [p_index, p_index_roots] = uq_generate_basis_Apmj(p, M, truncOpts)
% BASIS = UQ_GENERATE_BASIS_APMJ(P, M, TRUNCOPTS): generate a polynomial chaos basis
%     index to be used in evaluating the basis. P is the maximum polynomial order, M is the
%     number of variables.
%
% Input Parameters:
% 
%  'p'            The order of the polynomials used
%
%  'M'            The dimensions along which to return the polynomial degree indices.
%
% Optional Parameters:
%
%  'truncOptions' Options relevant to the truncation of the basis.
%
% Return Values:
%
%  'BASIS'        A sparse matrix containing the indices that define the
%                 basis
%
% See also UQ_GENERATE_JTUPLES_SUM_P



% BASIS = UQ_GENERATE_BASIS_AMJP(P, M, TRUNCOPTS): generate a polynomial chaos basis
%     index to be used in evaluating the basis. P is the maximum polynomial
%     order, M is the number of variables. The optional structure TRUNCOPTS
%     specifies the truncation strategy.
%
% See also: UQ_GENERATE_JTUPLES_SUM_P, UQ_PCE_CREATE_PSI

%% parsing and checking the arguments for options and consistency

% custom basis: the basis is already provided "as is", return it and do not
% do anything
if exist('truncOpts','var') && isfield(truncOpts, 'Custom')
    % check the dimensionality and degree of the basis and w.r.t. the provided M
    p_index = truncOpts.Custom;
    p_index_roots = p_index;
    if M ~= size(p_index, 2)
       error('The custom basis dimension mismatch: %d provided, %d observed', M,size(p_index,2)); 
    end
    maxUnivDeg = max(max(p_index, [], 2));
    if maxUnivDeg > max(p)
       error('Custom basis max univariate degree (%d) is higher than the specified max (%d)', maxUnivDeg, max(p));
    end
    return;
end

% q-norm
if exist('truncOpts', 'var') && isfield(truncOpts, 'qNorm')
    truncation = 1;
    q = truncOpts.qNorm;
else
    % default to no truncation 
    truncation = 0;
end

% max interaction terms
if exist('truncOpts', 'var') && isfield(truncOpts, 'MaxInteraction')
    J = 1:min(M,truncOpts.MaxInteraction);
end

% default to maximum interaction terms if they don't exist
if ~exist('J', 'var')
    J = 1:min(M,max(p));
end

%% Accumulating the indices as a function of J
% This function should be vectorized, or at least support vectorized syntax
% for future improvements 
NJ = numel(J);
NP = numel(p);

% we will store the root generators in a 2D cell array. It will be used for q-norm
% selection
p_index_roots = cell(NP, NJ);
p_index = cell(NP, NJ);

% Generate all the unique J-tuples of degree P
for pp = 1:NP
    for jj = 1:NJ
        if p(pp) < J(jj)
            continue;
        end
        % getting the jtuple
        cur_jtuple = uq_generate_jtuples_sum_p(p(pp),J(jj));
        jtuple = zeros(size(cur_jtuple,1), M);
        try
            % padding to the correct directon to the left (Blatman Thesis, Appendix C)
            jtuple(:, (M-size(cur_jtuple,2)+1):end) = cur_jtuple;
            
        catch me
            fprintf('Failed to pad jtuple M = %d jj = %d', M, jj);
            rethrow(me);
        end
        % applying truncation if necessary
        if truncation
           switch truncation 
               case 1 % q-norm selection
                   q_norm = uq_q_norm(jtuple,q);
                   jtuple = squeeze(jtuple(q_norm <= max(p),:));
           end
        else
            q_norm = sum(jtuple,2);
            jtuple = squeeze(jtuple(q_norm <= max(p),:));
        end
        % Save the outputs
        p_index_roots{pp,jj} = jtuple;
        
        % Loop over every line of the jtuple
        tmpidx = cell(size(jtuple,1),1); % store the intermediate results in a temporary index
        % loopuq
        for kk = 1:size(jtuple,1)
           tmpidx{kk} = double(uq_permute_coefficients(jtuple(kk,:)));
        end
        % and now concatenate all of them together in a sparse matrix
        p_index{pp,jj} = sparse(cat(1, tmpidx{:}));
    end % end of loop over the polynomial degree
end % end of loop ver ntuples

%%  Reshape the final output so that it has the proper format
% All the calculated cell arrays are concatenated in a unique large
% bidimensional array ordered rowwise by P and columnwise by the variable
% index (up to M). This can be very large for high dimensional problems
% (hence it is stored as a sparse matrix)! 

p_index = reshape(p_index', numel(p_index),1);
if ~min(p) 
    % add the constant term when min degree is 0
    p_index = [zeros(1,M); p_index];
end
% Concatenate everything
p_index = cat(1,p_index{:});