function [X, u] = uq_default_input(current_input,varargin)
% UQ_DEFAULT_INPUT generates samples of random vectors. The elements of the random vector
% may be dependent. The dependence is specified via the copula formalism. 
% At the current stage, Gaussian copulas, C- and D-vines are supported.
% This function is called by uq_getSample when the currently selected input
% object is of type uq_default_input.
%
% UQ_DEFAULT_INPUT(N) generates N samples from the random vector specified 
% by the currently selected Input object using the default sampling strategy
% 
% UQ_DEFAULT_INPUT(N, Options) allows to specify additional
% options (e.g. the sampling strategy). For more information please refer
% to the UQLab user manual: The Input module
% 
% X = UQ_DEFAULT_INPUT(...) returns an NxM matrix of the samples in the
% physical space
%
% [X, u] = UQ_DEFAULT_INPUT(...) additionally returns an NxM matrix of
% the samples in the uniform space


%% Parameters
LHSiterations_default = 5;

%% Parse sampling options
nargs = length(varargin);
if ~nargs
   error('Number of samples not specified. Usage: uq_getSample(N)');
end
N = varargin{1};

if nargs > 1 
    sampling = varargin{2};
end

if nargs > 1 && ~isempty(sampling)
    % Obtain sampling method if specified
    current_input.Sampling.Method = sampling;
else 
    % otherwise use the default one
    current_input.Sampling.Method = current_input.Sampling.DefaultMethod;
end
samplingOptions = current_input.Sampling;

%% Parse additional options
if nargs > 2
    
    % Make the NAME of optional arguments lower for case insensitive
    % treatment
    nameValuePairs = varargin(3:end);
    nameValuePairs(1:2:end) = lower(nameValuePairs(1:2:end));
    
    % Optional input argument: LHS number of iterations
    parseKey = {'lhsiterations'};
    parseType = {'p'};
    
    % Now parse the additional options
    [optInput,~] = uq_simple_parser(nameValuePairs, parseKey, parseType);
    
    % 'iterations' option
    if ~strcmp(optInput{1},'false')
        samplingOptions.LHSiterations = optInput{1};
        if ~isscalar(samplingOptions.LHSiterations)
            error('iterations must be a scalar value.')
        end
    else
        samplingOptions.LHSiterations = LHSiterations_default;
    end
else
    % Assign the default values
    samplingOptions.LHSiterations = LHSiterations_default;
end

%% Calculate/Retrieve samples
if strcmpi(current_input.Sampling.Method,'Data')
    % Since the sampling method is 'data', [X,u] are going to be retrieved from an external file 
    % It is assumed that the input data file correctly contains them, i.e.
    % no additional checks are taking place after the values are loaded IF
    % loading succeeds
    try
        load(current_input.DataFile);
    catch
        error('Error: The data file %s could not be loaded!',current_input.DataFile)
    end
else
    % In this case the samples need to be generated
    
    %% Keep track of constant/non-constant variables
    % Get the indices of the marginals of type constant (if any)
    Types = {current_input.Marginals(:).Type};
    
    % Get the indices of non-constant marginals
    indConst = find(strcmpi(Types, 'constant'));
    indNonConst    = 1:length(Types);
    indNonConst(indConst) = [];

    nrConst = length(indConst);
    M = length(indNonConst) ;
    
    %% Generate samples in uniform space (u)
    % At least one non-constant element should exist in the random vector
    % to proceed in generating samples
    if M
        u(:,indNonConst) = uq_sampleU(N, M,samplingOptions);
        if strcmpi(current_input.Sampling.Method, 'Sobol')
            if ~isfield(current_input.Sampling, 'SobolGen') || ...
                    isempty(current_input.Sampling.SobolGen)
                % create the Sobol-set generator if it doesn't exist
                current_input.Sampling.SobolGen = sobolset(M);
                current_input.Sampling.SobolGen.Skip = N+1;
            else
            % If generator exists, update Sobol index seed
            current_input.Sampling.SobolGen.Skip = ...
                current_input.Sampling.SobolGen.Skip + N;
            end
            
        elseif strcmpi(current_input.Sampling.Method, 'Halton')
            
            if ~isfield(current_input.Sampling, 'HaltonGen') || ...
                    isempty(current_input.Sampling.HaltonGen)
                % create the Halton-set generator if it doesn't exist
                current_input.Sampling.HaltonGen = haltonset(M);
                % scramble the sequence
                current_input.Sampling.HaltonGen = ...
                    scramble( current_input.Sampling.HaltonGen,'RR2');
                current_input.Sampling.HaltonGen.Skip = N+1;
            else
                % If generator exists, update Halton index seed
                current_input.Sampling.HaltonGen.Skip = ...
                    current_input.Sampling.HaltonGen.Skip + N;
            end
        end
    end
    % Prepare the description of the u vector. This is going to be used in
    % order to perform an Isoprobabilistic transform of the samples from uniform
    % to physical space
    switch lower(current_input.Sampling.Method)
        case 'data'
            uMarginals = current_input.Marginals;
        otherwise            
            % Assign uniform(0,1) marginals  to non-constant marginals
            if ~isempty(indNonConst)
                uMarginals(indNonConst) = uq_StdUniformMarginals(M); 
            end
            % Assign constant(0.5) marginals to constant marginals
            if ~isempty(indConst)
                uMarginals(indConst) = uq_ConstantMarginals(0.5*ones(1,nrConst));
            end
            % Fix the values of all u samples that correspond to constant
            % marginal to 0.5 (mean of uniform distribution in [0,1])
            u(:,indConst) = 0.5 * ones(N, numel(indConst)) ;
    end
    
    %% Obtain X samples from u samples
    X = zeros(size(u));
    NrCopulas = length(current_input.Copula);
    for cc = 1:NrCopulas
        tmpCopula = current_input.Copula(cc);
        tmpVars = tmpCopula.Variables;
        tmpVarsNonConst = find(ismember(tmpVars, indNonConst));
        tmpVarsConst = find(ismember(tmpVars, indConst));
        
        tmpM = length(tmpVarsNonConst);
        tmpNrConst = length(tmpVarsConst);

        tmpu = u(:, tmpVars);
        tmpuMarginals = uMarginals(:, tmpVars);
        tmpXMarginals = current_input.Marginals(tmpVars);
        
        switch lower(tmpCopula.Type)
            case {'independent', 'independence'}
                tmpX = uq_IsopTransform(tmpu, tmpuMarginals, tmpXMarginals);
            case 'gaussian'
                % Define  Umarginals corresponding to non-constant/constant
                % variables as standard normal / constant 0
                clear UMarginals
                if ~isempty(tmpVarsNonConst)
                    UMarginals(tmpVarsNonConst) = uq_StdNormalMarginals(tmpM);
                end
                if ~isempty(tmpVarsConst)
                    UMarginals(tmpVarsConst) = uq_ConstantMarginals(...
                        zeros(1,tmpNrConst));
                end
                % Map tmpu -> U(standard normal space) by PIT
                U = uq_IsopTransform(tmpu, tmpuMarginals, UMarginals);
                % Then map: U -> X(physical space) by inverse Nataf transf
                tmpX = uq_invNatafTransform(...
                    U, tmpXMarginals, tmpCopula);
            case {'pair', 'cvine', 'dvine'}
                tmpX = uq_invRosenblattTransform(...
                    tmpu, tmpXMarginals, tmpCopula);
            otherwise
                error('Error: copula of type %s unknown or not supported yet', ...
                    current_input.Copula.Type)
        end
        X(:, tmpVars) = tmpX;
    end
    
end




