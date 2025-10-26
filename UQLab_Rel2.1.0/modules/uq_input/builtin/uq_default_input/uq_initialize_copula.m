function [myCopula, copula_must_be_inferred] = uq_initialize_copula(...
    iOpts, k, ConstIdx)
% [myCopula, copula_must_be_inferred] = uq_initialize_copula(iOpts, k, ConstIdx):
%     Given a structure iOpts that defines one or more copulas (possibly to 
%     be inferred), and optionally an array of indices of constant marginals, 
%     fills iOpts.Copula(k) by assigning defaults.
%
%     Returns the initialized copula and a logical that determines whether
%     the copula must be inferred.

if ~isfield(iOpts, 'Display'), iOpts.Display = 0; end
if nargin <= 1, k = 1; end
if nargin <=2, ConstIdx = []; end

verbose = (iOpts.Display > 0);

% Define options of test for block independence
default_blockindeptest = struct();
default_blockindeptest.Alpha = 0.1;
default_blockindeptest.Type = 'Kendall';
default_blockindeptest.Correction = 'auto';

if uq_isfield(iOpts, 'Copula.Inference.BlockIndepTest')
    BIT = iOpts.Copula.Inference.BlockIndepTest;
elseif uq_isfield(iOpts, 'Inference.BlockIndepTest')
    BIT = iOpts.Inference.BlockIndepTest;
else
    BIT = struct;
end

blockindeptest = uq_overwrite_fields(...
        BIT, default_blockindeptest, {}, {'Alpha', 'Type', 'Correction'});

% =========================================================================
% Define InferData, the array that contains the data for copula inference.
% In order of priority, InferData is set to be:
% - [], if the copula is independent; otherwise
% - iOpts.Copula.Inference.Data or iOpts.Copula.Inference.DataU, if either 
%   is available (if both are, an error is raised); otherwise,
% - iOpts.Inference.Data, if available.
% Also define InferDataType, which tracks which inference data are used:
% -1: no data available, will raise error if data needed
%  0: data is [] and independent copula was specified (-> no data needed)
%  1: data in the physical space, only for inference of copula (not margs)
%  2: data are pseudo-observations in [0,1]^M, only for copula inference
%  3: data in the physical space, common to copula and marginal inference
% =========================================================================

[InferData, InferDataType] = copula_inference_data(iOpts, k);

% =========================================================================
% Determine dimension M of the copula provided / to be inferred
% =========================================================================
if isfield(iOpts, 'Copula')
    Copula = iOpts.Copula(k);
    try 
        uq_check_copula_is_defined(Copula);
        M = uq_copula_dimension(Copula);
        copula_dim_is_defined = true;
    catch 
        copula_dim_is_defined = false;
    end
    
    if ~copula_dim_is_defined
        if InferDataType == 0  % the copula is the independence copula
            if uq_isnonemptyfield(Copula, 'Inference.DataU')
                M = size(Copula.Inference.DataU, 2);
                Copula.Dimension = M;
            elseif uq_isnonemptyfield(Copula, 'Inference.Data')
                M = size(Copula.Inference.Data, 2);
                Copula.Dimension = M;
            elseif uq_isnonemptyfield(iOpts, 'Inference.Data')
                M = size(iOpts.Inference.Data, 2);
                Copula.Dimension = M;
            else
                M = 0;
            end
        else
            M = size(InferData, 2);
        end
    end
else
    M = size(InferData, 2);
end

% =========================================================================
% If iOpts.Copula does not exist, create a copula for constant variables and
% another for non-constant variables. The latter is obtained by a recursive
% call of this function
% =========================================================================
if ~isfield(iOpts, 'Copula') && ~isempty(ConstIdx)
    
    if InferDataType ~= 3
        error('something is wrong, no correct inference data available')
    end
    
    nonConstIdx = setdiff(1:M, ConstIdx);
    
    % Initialize copula of non-constant marginals, if any
    if ~isempty(nonConstIdx)
        NewiOpts = uq_copy_structure(iOpts);
        NewiOpts.Inference.Data = iOpts.Inference.Data(:, nonConstIdx);
        
        [myCopula, copula_must_be_inferred] = uq_initialize_copula(NewiOpts);
        for cc = 1:length(myCopula)
            myCopula(cc).Variables = nonConstIdx(myCopula(cc).Variables);
        end
        K = length(myCopula);
    else
        K = 0;
    end
    
    % Initialize copula of constant marginals
    myCopula(K+1).Type = uq_copula_stdname('Independent');
    myCopula(K+1).Dimension = length(ConstIdx);
    myCopula(K+1).Parameters = eye(length(ConstIdx));
    myCopula(K+1).Variables = ConstIdx;
    copula_must_be_inferred(K+1) = false;
    
    return
end

% =========================================================================
% Set defaults
% =========================================================================
default_truncation = min(M, 2);
default_inference_crit = 'AIC';

default_pairindeptest = struct();
default_pairindeptest.Alpha = 0.1;
default_pairindeptest.Type = 'Kendall';
default_pairindeptest.Correction = 'auto';

% =========================================================================
% Build the structure myCopula that this function returns, which extends 
% iOpts.Copula (if existing) or builds a brands new copula structure,
% by assigning default values to options that were not specified
% =========================================================================

% If iOpts.Copula does not exist, define a brand new structure
if ~isfield(iOpts, 'Copula')
    if M == 0 % then inference data empty or missing => no inference
        myCopula = uq_IndepCopula(length(iOpts.Marginals));
        myCopula.Variables = 1:length(iOpts.Marginals);
        copula_must_be_inferred = false;
        
    else % then there are inference data => inference
        if k >= 2 
            error('Cannot initialize unspecified copula %d', k)            
        end
        
        if InferDataType < 0
            error('Copula inference requested but inference data missing.')
        end
        
        myCopula = struct();
        
        % Perform Block Independence Test
        if M > 2 && blockindeptest.Alpha > 0
            [Blocks, PVs, History] = uq_test_block_independence(...
                InferData, blockindeptest.Alpha, blockindeptest.Type, ...
                blockindeptest.Correction, verbose);
        else
            Blocks = {1:M};
        end
        
        for bb = 1:length(Blocks)
            
            % Assign copula Variables (all variables from 1 to M)
            Vars = Blocks{bb};
            
            myCopula(bb).Variables = Vars;

            % Assign copula type
            if length(Vars) == 1
                myCopula(bb).Type = uq_copula_stdname('Independent');
                myCopula(bb).Parameters = 1;
                copula_must_be_inferred(bb) = false;
                continue
            elseif length(Vars) == 2
                myCopula(bb).Type = 'Pair';
            elseif length(Vars) == 3
                myCopula(bb).Type = {'Gaussian', 'DVine'};
            elseif length(Vars) >= 4
                myCopula(bb).Type = {'Gaussian', 'CVine', 'DVine'};
            else
                error('Copula dimension %d inconsistent with other options.', M)
            end

            % if iOpts.Inference.Criterion does not exist, assign default
            % inference criterion to myCopula.Inference.Criterion
            if ~uq_isnonemptyfield(iOpts, 'Inference.Criterion')
                myCopula(bb).Inference.Criterion = default_inference_crit;
            end

            % Assign inference data
            if InferDataType == 1
                myCopula(bb).Inference.Data = InferData(:, Vars);
            elseif InferDataType == 2
                myCopula(bb).Inference.DataU = InferData(:, Vars);
            end

            % Set Parameters to 'auto'
            myCopula(bb).Parameters = 'auto';

            % Set Inference.PCfamilies and Inference.PairIndepTest
            % if vine of pair copula inference wanted
            if any(ismember(lower(myCopula(bb).Type), {'cvine', 'dvine', 'pair'})) 
                if uq_isnonemptyfield(iOpts, 'Inference.PCfamilies')
                    myCopula(bb).Inference.PCfamilies = ...
                        iOpts.Inference.PCfamilies;
                else
                    myCopula(bb).Inference.PCfamilies = 'auto';
                end

                if uq_isnonemptyfield(iOpts, 'Inference.PairIndepTest')
                    myCopula(bb).Inference.PairIndepTest = ...
                        iOpts.Inference.PairIndepTest;
                end
            end        

            % Set options specific to pair copulas
            if any(strcmpi(myCopula(bb).Type, 'pair'))
                myCopula(bb).Family = 'auto';
                myCopula(bb).Rotation = 'auto';
            end

            % Set options specific to vine copulas
            if any(ismember(lower(myCopula(bb).Type), {'cvine', 'dvine'}))
                myCopula(bb).Truncation = default_truncation;
                myCopula(bb).Families = 'auto';
                myCopula(bb).Inference.PCfamilies = 'auto';
                if any(strcmpi(myCopula(bb).Type, 'cvine'))
                    myCopula(bb).Inference.CVineStructure = 'auto';
                end
                if any(strcmpi(myCopula(bb).Type, 'dvine'))
                    myCopula(bb).Inference.DVineStructure = 'auto';
                end
            end

            copula_must_be_inferred(bb) = true;
        end
    end
    

% If iOpts.Copula exists, extend it by assigning defaults
else
    
    % Copy the Type, or assign default 'auto'. Also check consistency with
    % dimension of the problem
    if uq_isnonemptyfield(Copula, 'Type')
        myCopula.Type = Copula.Type;
        if isa(myCopula.Type, 'char') && strcmpi(myCopula.Type, 'auto')
            if M==2
                myCopula.Type = {'Pair'};
            elseif M==3
                myCopula.Type = {'Gaussian', 'CVine'};
            elseif M>3
                myCopula.Type = {'Gaussian', 'CVine', 'DVine'};
            else 
                error('Copula dimension %d is wrong', M)
            end
        elseif isa(myCopula.Type, 'char')
            if M==2 && any(strcmpi(myCopula.Type, {'cvine', 'dvine'}))
                if verbose
                    msg = 'vine inference requested for bivariate data';
                    warning('%s. Pair copula will be inferred instead', msg)
                end
                myCopula.Type = {'Pair'};
            elseif M>2 && strcmpi(myCopula.Type, 'pair')
                msg = 'inference of a pair copula requested for data';
                error('%s of dimension %d', M)
            end
        elseif isa(myCopula.Type, 'cell')
            coptypes = lower(myCopula.Type);
            if M==2 
                coptypes(ismember(coptypes, 'cvine')) = 'pair';
                coptypes(ismember(coptypes, 'dvine')) = 'pair';
                if verbose && any(ismember(coptypes, {'cvine', 'dvine'}))
                    msg = 'vine inference requested for bivariate data';
                    warning('%s. Pair copula will be inferred instead', msg)
                end
            elseif M>=3 && any(ismember(coptypes, 'pair'))
                error('pair copula inference requested for data with dimension %d', M)
            end
        end
    else
        % Assign copula type
        if M > 2
            myCopula.Type = {'Gaussian', 'CVine', 'DVine'};
        elseif M == 2
            myCopula.Type = 'Pair';
        else
            error('Copula dimension %d inconsistent with other options.', M)
        end
    end
    
    % Copy Variables field
    if uq_isnonemptyfield(Copula, 'Variables')
        myCopula.Variables = Copula.Variables;
    end
    
    % Determine whether the copula must be inferred
    copula_must_be_inferred = must_be_inferred(Copula);
    
    % If copula not to be inferred, just copy the relevant fields into
    % myCopula and raise errors/warning for wrongly specified fields
    if ~copula_must_be_inferred
        switch lower(Copula.Type)
            case {'independent', 'gaussian'}
                mandatory_fields = {};
                optional_fields = {'Parameters', 'RankCorr', 'cholR'};
            case 'pair'
                mandatory_fields = {'Parameters', 'Family'};
                optional_fields = {'Rotation'};
            case {'cvine', 'dvine'}
                if uq_isIndependenceCopula(Copula)
                    myCopula.Type = 'Independent';
                    myCopula.Parameters = eye(M);
                    if verbose
                        msg = 'Specified vine is equivalent to the independence';
                        warning('%s copula. The latter will be returned.', msg)
                    end
                    mandatory_fields = {};
                    optional_fields = {};
                else
                    mandatory_fields = {'Structure', 'Families', 'Parameters'};
                    optional_fields = {'Rotations', 'Truncation'};
                end                
            otherwise
                error('copula type ''%s'' unknown or not supported yet', ...
                    Copula.Type)
        end
        
        optional_fields = [optional_fields, 'Dimension', 'Display'];
         
        % Copy all mandatory and optional fields into myCopula
        myCopula = uq_copy_fields(Copula, myCopula, mandatory_fields,...
            optional_fields);
        
        % Define Variables coupled by myCopula
        if ~uq_isnonemptyfield(myCopula, 'Variables') 
            try
                myCopula.Variables = 1:length(iOpts.Marginals);
            catch 
                myCopula.Variables = 1:uq_copula_dimension(myCopula);
            end
        end
            
        % If the copula is a vine...
        if strcmpi(lower(myCopula.Type(2:end)), 'vine') 
            % ...Add field Rotations if missing
            if ~uq_isnonemptyfield(myCopula, 'Rotations')
                myCopula.Rotations = zeros(1, length(myCopula.Families));
            end
            % ...if truncated, add independent pair copulas if missing
            if isfield(myCopula, 'Truncation')
                VCopula = uq_VineCopula(myCopula.Type, myCopula.Structure, ...
                    myCopula.Families, myCopula.Parameters, ...
                    myCopula.Rotations, myCopula.Truncation, 0);
                myCopula = uq_overwrite_nonemptyfields(VCopula, myCopula);
            end
        end
        
        % Raise warnings for ignored fields
        given_fields = fields(Copula);
        for ff = 1:length(given_fields)
            fld = given_fields{ff};
            if ~any(strcmpi(fld, ['Type', mandatory_fields, optional_fields])) && verbose
                warning('field ''%s'' specified but not used: ignored', fld)
            end
        end
        
        uq_check_copula_is_defined(myCopula);
    
    % Copy or Assign all fields needed if the copula must be inferred
    else
     
        % Check which copula types should be inferred
        if isa(myCopula.Type, 'char') && strcmpi(myCopula.Type, 'auto')
            if M == 2
                must_infer_pair = true;
                must_infer_gaussian = false;
                must_infer_cvine = false;
                must_infer_dvine = false;
                must_infer_vine = false;
            elseif M == 3
                must_infer_pair = false;
                must_infer_gaussian = true;
                must_infer_cvine = true;
                must_infer_dvine = false;
                must_infer_vine = true;
            elseif M > 3
                must_infer_pair = false;
                must_infer_gaussian = true;
                must_infer_cvine = true;
                must_infer_dvine = true;
                must_infer_vine = true;
            else
                error('Dimension M=%d incompatible with copula inference', M)
            end
        elseif isa(myCopula.Type, 'char')
            must_infer_pair = false;
            must_infer_gaussian = false;
            must_infer_cvine = false;
            must_infer_dvine = false;
            must_infer_vine = false;
            switch lower(myCopula.Type)
                case 'pair'
                    must_infer_pair = true;
                case 'gaussian'
                    must_infer_gaussian = true;
                case 'dvine'
                    must_infer_dvine = true;
                    must_infer_vine = true;
                case 'cvine'
                    must_infer_cvine = true;
                    must_infer_vine = true;
                otherwise
                    error('copula of type ''%s'' unknown or not supported yet', myCopula.Type)
            end
        elseif isa(myCopula.Type, 'cell')
            must_infer_pair = false;
            must_infer_gaussian = false;
            must_infer_cvine = false;
            must_infer_dvine = false;
            must_infer_vine = false;
            for tt = 1:length(myCopula.Type)
                coptype = myCopula.Type{tt};
                switch lower(coptype)
                    case 'pair'
                        must_infer_pair = true;
                    case 'gaussian'
                        must_infer_gaussian = true;
                    case 'dvine'
                        must_infer_dvine = true;
                        must_infer_vine = true;
                    case 'cvine'
                        must_infer_cvine = true;
                        must_infer_vine = true;
                    otherwise
                        error('copula of type ''%s'' unknown or not supported yet', myCopula.Type)
                end
            end
        end

        % Assess whether many copula types must be inferred, or only one
        must_infer_many = (sum([must_infer_pair, must_infer_gaussian, ...
            must_infer_cvine, must_infer_dvine])>1);
        
        % Raise error if inference requested but parameters given
        if uq_isnonemptyfield(Copula, 'Parameters') ...
                if ~isa(Copula.Parameters, 'char') 
                    msg1 = 'copula inference requested but copula parameters';
                    msg2 = 'given. Set it to char ''auto'' instead';
                    error('%s %s', msg1, msg2)
                elseif ~strcmpi(Copula.Parameters, 'auto')
                    msg1 = 'copula inference requested, but Copula.Parameters';
                    msg2 = 'Set it to char ''auto'' instead';
                    error('%s=%s. %s', msg1, Copula.Parameters, msg2)
                end
        end

        % Raise errors if rank correlation is provided and is not 'auto'
        if uq_isnonemptyfield(Copula, 'RankCorr') && ~(...
                isa(Copula.RankCorr, 'char') && ...
                strcmpi(Copula.RankCorr, 'auto'))
            if must_infer_gaussian && ~must_infer_many
                error('Gaussian copula inference requested but rank correlations given')
            else
                error('Inference of non-Gaussian copulas with given rank correlations is not supported')
            end    
        end

        % =================================================================
        % Assign inference options valid for all copula types, and check
        % for consistency/correctness
        % =================================================================

        % Set Parameters to 'auto'
        params_is_auto = isfield(Copula, 'Parameters') && ...
            isa(Copula.Parameters, 'char') && ...
            strcmpi(Copula.Parameters, 'auto');
            
        if params_is_auto
            myCopula.Parameters = 'auto';
        elseif ~isfield(Copula, 'Parameters')
            myCopula.Parameters = 'auto';
        else
            error('copula inference requested, but copula parameters assigned')
        end
           
        % Set inference data
        switch InferDataType
            case -1 % no data provided
                error('Copula inference requested but inference data missing.')
            case 1  % data provided in physical space, specific to copula
                myCopula.Inference.Data = InferData;
            case 2  % data provided as pseudo-observations in [0,1]^M
                myCopula.Inference.DataU = InferData;
            case 3  % data provided in physical space, common to marginals
                % do nothing
            otherwise
                error('Copula inference requested but no valid data specified')
        end

        % Copy Variables field, if existing. Check dimension and uniqueness
        if isfield(Copula, 'Variables')
            myCopula.Variables = Copula.Variables;
            if length(unique(myCopula.Variables)) < length(myCopula.Variables)
                error('Provide unique variable ids for copula %d', k)
            end
            
            if length(myCopula.Variables) ~= size(InferData, 2)
                msg = 'Number of variables coupled by copula is different';
                error('%s from dimension of inference data', msg);
            end
        else
            myCopula.Variables = 1:size(InferData, 2);
        end
        

        % Set Copula.Inference options valid for all copula types that have
        % not been assigned yet (criterion and independence test options)
        if ~isfield(Copula, 'Inference')
            
            % Set default values, if iOpts.Inference not provided
            if ~isfield(iOpts, 'Inference')
                myCopula.Inference.Criterion = default_inference_crit;
                myCopula.Inference.PairIndepTest = default_pairindeptest;
            % Otherwise copy the options from iOpts.Inference, if provided
            else
                %...Criterion
                if ~isfield(iOpts.Inference, 'Criterion')
                    myCopula.Inference.Criterion = default_inference_crit;
                elseif isa(iOpts.Inference.Criterion, 'char') && ...
                        strcmpi(iOpts.Inference.Criterion, 'KS')
                    if verbose
                        msg = 'Inference criterion ''KS'' not valid for';
                        warning('%s copulas. Set to ''%s'' instead', ...
                            default_inference_crit)
                    end
                    myCopula.Inference.Criterion = default_inference_crit;
                else
                    myCopula.Inference.Criterion = iOpts.Inference.Criterion;
                end
                
                %...PairIndepTest
                if ~isfield(iOpts.Inference, 'PairIndepTest')
                    myCopula.Inference.PairIndepTest = ...
                        default_pairindeptest;
                else
                    myCopula.Inference.PairIndepTest = ...
                        iOpts.Inference.PairIndepTest;
                end
            end    
        else
            % ...Assign Inference.Criterion
            if uq_isnonemptyfield(Copula.Inference, 'Criterion')
                myCopula.Inference.Criterion = Copula.Inference.Criterion;
            elseif uq_isnonemptyfield(iOpts, 'Inference.Criterion') 
                if strcmpi(iOpts.Inference.Criterion, 'KS')
                    if verbose
                        msg = 'Inference criterion ''KS'' not valid for';
                        warning('%s copulas. Set to ''%s'' instead', ...
                            default_inference_crit)
                    end
                    myCopula.Inference.Criterion = default_inference_crit;
                else
                    myCopula.Inference.Criterion = iOpts.Inference.Criterion;
                end
            else
                myCopula.Inference.Criterion = default_inference_crit;
            end
            
            % ...Assign Inference.PairIndepTest
            if uq_isnonemptyfield(Copula.Inference, 'PairIndepTest')
                myCopula.Inference.PairIndepTest = ...
                    Copula.Inference.PairIndepTest;
            elseif uq_isnonemptyfield(iOpts, 'Inference') 
                if ~uq_isnonemptyfield(iOpts.Inference, 'PairIndepTest')
                    myCopula.Inference.PairIndepTest = default_pairindeptest;
                else
                    myCopula.Inference.PairIndepTest = ...
                        iOpts.Inference.PairIndepTest;
                end
            else
                myCopula.Inference.PairIndepTest = default_pairindeptest;
            end
        end

        % =================================================================
        % Set inference options specific to vines
        % =================================================================
        if must_infer_vine 
            % Copy the Truncation field, or assign default
            if uq_isnonemptyfield(Copula, 'Truncation')
                myCopula.Truncation = Copula.Truncation;
            else
                myCopula.Truncation = default_truncation;
            end
            
            if M>2 && verbose
                warning('Inferred vine truncated at level %d of %d', ...
                    myCopula.Truncation, M-1)
            end

            % Assign Copula.Structure, if given in iOpts; otherwise assign field
            % Copula.Inference.XVineStructure. Raise errors if both specified
            fixed_struct_given = isfield(Copula, 'Structure');
            if fixed_struct_given
                fixed_struct = Copula.Structure;
            end

            inf_struct_cvine_given = isfield(Copula, 'Inference') && ...
                isfield(Copula.Inference, 'CVineStructure');
            if inf_struct_cvine_given
                inf_struct_cvine = Copula.Inference.CVineStructure;
            end

            inf_struct_dvine_given = isfield(Copula, 'Inference') && ...
                isfield(Copula.Inference, 'DVineStructure');
            if inf_struct_dvine_given
                inf_struct_dvine = Copula.Inference.DVineStructure;
            end

            if fixed_struct_given
                if inf_struct_cvine_given && ~all(fixed_struct == inf_struct_cvine)
                    msg = 'Copula.Structure and Copula.Inference.CVineStructure';
                    error('%s differ. Provide only one', msg)
                else
                    myCopula.Inference.CVineStructure = fixed_struct;
                end
                
                if inf_struct_dvine_given && ~all(fixed_struct == inf_struct_dvine)
                    msg = 'Copula.Structure and Copula.Inference.DVineStructure';
                    error('%s differ. Provide only one', msg)
                else
                    myCopula.Inference.DVineStructure = fixed_struct;
                end
            else
                if inf_struct_cvine_given
                    myCopula.Inference.CVineStructure = inf_struct_cvine;
                else
                    myCopula.Inference.CVineStructure = 'auto';
                end

                if inf_struct_dvine_given
                    myCopula.Inference.DVineStructure = inf_struct_dvine;
                else
                    myCopula.Inference.DVineStructure = 'auto';
                end
            end
                
            % Set fields Copula.Families/Copula.Inference.PCfamilies
            fixed_pcfam_given = isfield(Copula, 'Families');
            if fixed_pcfam_given
                fixed_pcfam = Copula.Families;
                fixed_pcfam_is_auto = isa(fixed_pcfam, 'char') && ...
                    strcmpi(fixed_pcfam, 'auto');
            end

            inf_pcfam_given = isfield(Copula, 'Inference') && ...
                isfield(Copula.Inference, 'PCfamilies');
            if inf_pcfam_given
                inf_pcfam = Copula.Inference.PCfamilies;
                inf_pcfam_is_auto = isa(inf_pcfam, 'char') && ...
                    strcmpi(inf_pcfam, 'auto');
            end

            if fixed_pcfam_given 
                if fixed_pcfam_is_auto
                        myCopula.Families = 'auto';
                    if inf_pcfam_given
                        myCopula.Inference.PCfamilies = inf_pcfam;
                    else
                        myCopula.Inference.PCfamilies = 'auto';
                    end
                else
                    myCopula.Families = fixed_pcfam;
                    if inf_pcfam_given
                        msg = 'Copula.Families assigned. Copula.Inference.PCfamilies';
                        warning('%s will be ignored (only fitting takes place)', msg)
                    end
                end
            else
                myCopula.Families = 'auto';
                if inf_pcfam_given
                    myCopula.Inference.PCfamilies = inf_pcfam;
                else
                    myCopula.Inference.PCfamilies = 'auto';
                end
            end

            % Set fields Copula.Rotations/Copula.Inference.Rotations
            fixed_rots_given = isfield(Copula, 'Rotations');
            if fixed_rots_given
                fixed_rots = Copula.Rotations;
                fixed_rots_is_auto = isa(fixed_rots, 'char') && ...
                    strcmpi(fixed_rots, 'auto');
            end

            inf_rots_given = isfield(Copula, 'Inference') && ...
                isfield(Copula.Inference, 'Rotations');
            if inf_rots_given
                inf_rots = Copula.Inference.Rotations;
                inf_rots_is_auto = isa(inf_rots, 'char') && ...
                    strcmpi(inf_rots, 'auto');
            end

            if fixed_rots_given 
                if fixed_rots_is_auto
                        myCopula.Rotations = 'auto';
                    if inf_rots_given
                        myCopula.Inference.Rotations = inf_rots;
                    else
                        myCopula.Inference.Rotations = 'auto';
                    end
                else
                    myCopula.Rotations = fixed_rots;
                    if inf_rots_given
                        msg = 'Copula.Rotations assigned. Copula.Inference.Rotations';
                        warning('%s will be ignored (only fitting takes place)', msg)
                    end
                end
            else
                myCopula.Rotations = 'auto';
                if inf_rots_given
                    myCopula.Inference.Rotations = inf_rots;
                else
                    myCopula.Inference.Rotations = 'auto';
                end
            end            
        end

        % =================================================================
        % Set inference options specific to pair copulas
        % =================================================================
        if must_infer_pair 
            % Set fields Copula.Family/Copula.Inference.PCfamilies
            fixed_pcfam_given = isfield(Copula, 'Family');
            if fixed_pcfam_given
                fixed_pcfam = Copula.Family;
                fixed_pcfam_is_auto = isa(fixed_pcfam, 'char') && ...
                    strcmpi(fixed_pcfam, 'auto');
            end

            inf_pcfam_given = isfield(Copula, 'Inference') && ...
                isfield(Copula.Inference, 'PCfamilies');
            if inf_pcfam_given
                inf_pcfam = Copula.Inference.PCfamilies;
                inf_pcfam_is_auto = isa(inf_pcfam, 'char') && ...
                    strcmpi(inf_pcfam, 'auto');
            end

            if fixed_pcfam_given 
                if fixed_pcfam_is_auto
                        myCopula.Family = 'auto';
                    if inf_pcfam_given
                        myCopula.Inference.PCfamilies = inf_pcfam;
                    else
                        myCopula.Inference.PCfamilies = 'auto';
                    end
                else
                    myCopula.Family = fixed_pcfam;
                    if inf_pcfam_given
                        msg = 'Copula.Family assigned. Copula.Inference.PCfamilies';
                        warning('%s will be ignored (only fitting takes place)', msg)
                    end
                end
            else
                myCopula.Family = 'auto';
                if inf_pcfam_given
                    myCopula.Inference.PCfamilies = inf_pcfam;
                else
                    myCopula.Inference.PCfamilies = 'auto';
                end
            end

            % Set fields Copula.Rotation/Copula.Inference.Rotation
            fixed_rots_given = isfield(Copula, 'Rotation');
            if fixed_rots_given
                fixed_rots = Copula.Rotation;
                fixed_rots_is_auto = isa(fixed_rots, 'char') && ...
                    strcmpi(fixed_rots, 'auto');
            end

            inf_rots_given = isfield(Copula, 'Inference') && ...
                isfield(Copula.Inference, 'Rotation');
            if inf_rots_given
                inf_rots = Copula.Inference.Rotations;
                inf_rots_is_auto = isa(inf_rots, 'char') && ...
                    strcmpi(inf_rots, 'auto');
            end

            if fixed_rots_given 
                if fixed_rots_is_auto
                        myCopula.Rotations = 'auto';
                    if inf_rots_given
                        myCopula.Inference.Rotations = inf_rots;
                    else
                        myCopula.Inference.Rotations = 'auto';
                    end
                else
                    myCopula.Rotations = fixed_rots;
                    if inf_rots_given
                        msg = 'Copula.Rotations assigned. Copula.Inference.Rotations';
                        warning('%s will be ignored (only fitting takes place)', msg)
                    end
                end
            else
                myCopula.Rotations = 'auto';
                if inf_rots_given
                    myCopula.Inference.Rotations = inf_rots;
                else
                    myCopula.Inference.Rotations = 'auto';
                end
            end            
        end        
    end
    
    if verbose
        Fields = fieldnames(Copula);
        for ff = 1:length(Fields)
            if ~isfield(myCopula, Fields{ff})
                warning('field iOpts.Copula.%s ignored', Fields{ff})
            end
        end
    end

end


if any(copula_must_be_inferred) ...
        && ~uq_isnonemptyfield(iOpts, 'Inference.Data') ...
        && ~uq_isnonemptyfield(myCopula.Inference, 'Data') ...
        && ~uq_isnonemptyfield(myCopula.Inference, 'DataU')
    error('requested inference for copula but no inference data given.')
end

end


% =========================================================================
% Define some utility functions
% =========================================================================

function pass = must_be_inferred(cop)
% Checks if a copula must be inferred
    if ~isfield(cop, 'Type')
        pass = true;
    elseif isa(cop.Type, 'cell') 
        if length(cop.Type) ~= 1
            pass = true;
        elseif strcmpi(cop.Type{1}, 'auto')
            pass = true;
        else % if Type is a cell containing a single copula name
            cop2 = struct();
            flds = fields(cop);
            for ff =1:length(flds)
                cop2.(flds{ff}) = cop.(flds{ff});
            end
            cop2.Type = cop.Type{1};
            pass = must_be_inferred(cop2);
        end
    elseif isa(cop.Type, 'char')
        if strcmpi(cop.Type, 'auto')
            pass = true;
        elseif any(strcmpi(cop.Type, {'independent', 'independence'}))
            pass = false;
        elseif strcmpi(cop.Type, 'gaussian')
            if uq_isnonemptyfield(cop, 'Parameters') 
                if isa(cop.Parameters, 'double')
                    pass = false;
                else
                    pass = true;
                end
            elseif uq_isnonemptyfield(cop, 'RankCorr')
                if isa(cop.RankCorr, 'double')
                    pass = false;
                else
                    pass = true;
                end
            else
                pass = true;
            end
        elseif any(strcmpi(cop.Type, {'cvine', 'dvine', 'pair'}))
            if strcmpi(cop.Type, 'pair') && isfield(cop,'Family') ...
                    && any(strcmpi(cop.Family,{'independent', 'independence'}))
                pass = false;
            elseif uq_isnonemptyfield(cop, 'Parameters')
                if isa(cop.Parameters, 'char') && ...
                        strcmpi(cop.Parameters, 'auto')
                    pass = true;
                else
                    pass = false;
                end
            else
                pass = true;
            end
        else
            error('Unknown copula type: "%s".', cop.Type)
        end
    else
        error('iOpts.Copula.Type must be a char or a cell of char')
    end
end


function [InferData, InferDataType] = copula_inference_data(iOpts, k)
% Extracts the data for copula inference from structure iOpts. Also
% determines the data type:
% * -1: no data
% * 0: no data, but none needed (copula is independent)
% * 1: data in physical space, specific to copula (not marginal) inference
% * 2: data in unit hypercube
% * 3: data in physical space, common to copula and marginals

    % Initialize InferData to []
    InferData = [];
    InferDataType = -1;

    if isfield(iOpts, 'Copula') && length(iOpts.Copula) >= k
        Copula = iOpts.Copula(k);
        copula_given = true;
        
    elseif ~isfield(iOpts, 'Copula')
        if k~=1
            error('Cannot initialize more than one copula if iOpts.Copula not specified')
        end
        copula_given = false;
        
    elseif length(iOpts.Copula) <= k
        error('%d-th copula requested, but only %d copulas specified', ...
            k, length(iOpts.Copula))
    elseif k > 1
        error('%d-th copula requested, but no copulas specified', ...
            k, length(iOpts.Copula))
    else
        copula_given = false;
    end
    
    % ...as empty, if the copula does not have to be inferred
    if copula_given && isfield(Copula, 'Type') && ...
            isa(Copula.Type, 'char') && uq_isIndependenceCopula(Copula)
        InferDataType = 0;
    % ...from iOpts.Copula.Inference.Data or .DataU, if existing
    elseif copula_given && isfield(Copula, 'Inference') && ...
                (isfield(Copula.Inference, 'Data') || ...
                 isfield(Copula.Inference, 'DataU'))
            is_dataX = isfield(Copula.Inference, 'Data');
            is_dataU = isfield(Copula.Inference, 'DataU');
            if is_dataX && ~is_dataU
                InferData = Copula.Inference.Data;
                InferDataType = 1;
            elseif is_dataU && ~is_dataX
                InferData = Copula.Inference.DataU;
                InferDataType = 2;
            elseif is_dataX && is_dataU
                error('Copula.Inference has both .Data and .DataU. Provide only one')
            end
    % ...from iOpts.Inference.Data, if available
    elseif isfield(iOpts, 'Inference') && isfield(iOpts.Inference, 'Data')
        InferData = iOpts.Inference.Data;
        if isa(iOpts.Inference.Data, 'cell')
            InferData = cell2mat(InferData);
        elseif ~isa(iOpts.Inference.Data, 'double')
            error('iOpts.Inference.Data must be either a matrix or a cell array')
        end

        % Take only the columns of inference data associated with the
        % variables coupled by the current copula
        if copula_given
            if isfield(Copula, 'Variables')
                InferData = InferData(:, Copula.Variables);
            elseif k == 1
                % do nothing
            else
                error('Field iOpts.Copula.Variables needed for inputs with 2+ copulas')
            end
        end

        is_dataX = true;
        is_dataU = false;
        InferDataType = 3;
    end
end

