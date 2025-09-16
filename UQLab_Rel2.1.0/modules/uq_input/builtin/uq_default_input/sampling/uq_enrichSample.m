function [Xnew, Unew] = uq_enrichSample( X, N, sampling, inpt)
% UQ_ENRICH_SAMPLE Enriches the current experimental design X by introducing
% N additional points.
%
% UQ_ENRICHSAMPLE(X, N) enriches the current experimental design X,
% defined by the currently selected input object by introducing N
% additional points
%
% UQ_ENRICHSAMPLE(X, N, SAMPLING) allows to specify the SAMPLING strategy
% that is going to be used for the enrichment
%
% UQ_ENRICHSAMPLE(X, N, INPUT) allows to specify the the INPUT object that
% corresponds to X
%
% UQ_ENRICHSAMPLE(X, N, SAMPLING, INPUT) allows to specify both the
% SAMPLING method and the INPUT object
%
% Xnew = UQ_ENRICHSAMPLE(X, N, ...) returns an NxM matrix (where M is the number 
% of columns in X) that corresponds to the *new* samples (the already existing ones 
% in X are not included)
%
% [Xnew, uNew] = UQ_ENRICHSAMPLE(...) additionally returns the *new*
% samples in the uniform space


%% retrieve the input object
if exist('inpt', 'var')
    current_input = uq_getInput(inpt);
else
    current_input = uq_getInput;
end

%% In case there are two input variables only, figure out if the second is sampling or module
if nargin == 3
    switch class(sampling)
        case 'uq_input' % if it is an uq_input object, set it as the current method
            current_input = sampling;
            sampling = [];
        case 'char' % if it is a string only, then figure out if it is a known sampling strategy
            if ~any(strcmpi({'mc', 'lhs', 'sobol', 'halton'}, sampling))
                % if it is not a known sampling strategy, then it must be
                % an input object name
                current_input = sampling;
                sampling = ''; % set sampling to the empty string
            end
    end
end

%% check whether the sampling scheme is specified
if nargin > 2 && ~isempty(sampling)
    current_input.Sampling.Method = sampling;
else
    % if not use the default
    current_input.Sampling.Method = current_input.Sampling.DefaultMethod; 
end

%% consistency checks
if strcmpi(current_input.Sampling.Method,'Data')
    error('Error: Experimental Design Enrichment is not supported for Sampling.method with value Data!')
end

%% bookkeeping of constant and non-constant marginals
% Get the indices of the marginals of type constant (if any)
indNonConst = uq_find_nonconstant_marginals(current_input.Marginals);
indConst = uq_find_constant_marginals(current_input.Marginals);
nrNonConst = length(indNonConst);
nrConst = length(indConst);

%%   sampling of U (standard uniform space)

% Fix the values of all u samples that correspond to constant
% marginal to 0.5 (mean of uniform distribution in [0,1])
U_constant = 0.5;
Unew(1:N, indConst) = U_constant;

% Fill the columns of Unew that correspond to non-constant marginals of X
if ~isempty(indNonConst) 
     M = length(indNonConst);
    switch lower(current_input.Sampling.Method)
        case 'mc'
            % just re-run Monte Carlo sampling
            Unew(:,indNonConst) = rand(N, M);
        case 'lhs'
            % Build the input that corresponds to non-constant marginals
            % (Physical space)
            InputNonConst = uq_remove_constants_from_input(current_input, true);
            
            % Now we can get the mapping from X to u (non-constants)
            UNonConst = uq_GeneralIsopTransform(...
                X(:,indNonConst),...
                InputNonConst.Marginals, ...
                InputNonConst.Copula, ...
                uq_StdUniformMarginals(nrNonConst),...
                uq_IndepCopula(nrNonConst));
            
            % Enrich the Latin Hypercube
            Unew(:,indNonConst) = uq_enrich_lhs(UNonConst, N) ;
        case 'sobol'
            % Skip the number of points that have already been evaluated
            % Assuming that all the previous points belong to the Sobol
            % sequence
            Nskip = size(X,1) ;
            if isfield(current_input.Sampling, 'SobolGen') && ...
                    any(strcmp('Skip', properties(current_input.Sampling.SobolGen)))
                % retrieve the existing Sobol series object
                SobolGen = current_input.Sampling.SobolGen;
                % make sure that the index seed has correct value
                if SobolGen.Skip ~= Nskip+1
                    SobolGen.Skip = Nskip + 1 ;
                end
            else
                % this is the case were the previous points were not
                % produced by Sobol sampling but we still treat them as if
                % they were

                %create a Sobol series object
                SobolGen = sobolset(M, 'Skip', Nskip+1);
                current_input.Sampling.SobolGen = SobolGen ;
            end
                
            % get the u samples
            Unew(:,indNonConst) = SobolGen(1:N,:);
            % update Sobol index seed
            current_input.Sampling.SobolGen.Skip = ...
                current_input.Sampling.SobolGen.Skip + N;
            
        case 'halton'
            % Skip the number of points that have already been evaluated
            % Assuming that all the previous points belong to the Halton
            % sequence
            Nskip = size(X,1) ;
            if isfield(current_input.Sampling, 'HaltonGen') && ...
                    any(strcmp('Skip', properties(current_input.Sampling.HaltonGen)))
                % retrieve the existing Halton series object
                HaltonGen = current_input.Sampling.HaltonGen;
                % make sure that the index seed has correct value
                if HaltonGen.Skip ~= Nskip+1
                    HaltonGen.Skip = Nskip + 1 ;
                end
            else
                % this is the case were the previous points were not
                % produced by Sobol sampling but we still treat them as if
                % they were

                %create a Halton series object
                HaltonGen = scramble(haltonset(M, 'Skip', Nskip+1),'RR2');
                current_input.Sampling.HaltonGen = HaltonGen ;
            end
            % get the u samples
            Unew(:,indNonConst) = HaltonGen(1:N,:);
            
            % update Halton index seed
            current_input.Sampling.HaltonGen.Skip = ...
                current_input.Sampling.HaltonGen.Skip + N;
        otherwise
            error('The required type of u sampling is not defined. Please choose one of the following: MC, LHS, Sobol, Halton.')
    end
end

%% map the samples from Unew (uniform space) to Xnew (physical space)

% Define the marginals of U (constant if the corresponding marginals of X
% are constant, standard uniform otherwise), and copula (independent)
Unew_Marginals(indNonConst) = uq_StdUniformMarginals(nrNonConst);
if nrConst
    Unew_Marginals(indConst) = uq_ConstantMarginals(U_constant*ones(1,nrConst));
end
Unew_Copula = uq_IndepCopula(M);

Xnew = uq_GeneralIsopTransform(Unew, ...
                               Unew_Marginals, ...
                               Unew_Copula, ...
                               current_input.Marginals, ...
                               current_input.Copula);
