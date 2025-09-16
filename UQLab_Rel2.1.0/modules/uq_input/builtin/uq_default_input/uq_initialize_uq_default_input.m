function success = uq_initialize_uq_default_input(module)
% UQ_INITIALIZE_UQ_DEFAULT_INPUT initializes an Input object of type
% uq_default_input
success = 0; 

%% parameters
DefaultCopula.Type = 'Independent';
defaultSampling.Method = 'MC';
defaultSampling.DefaultMethod = 'MC';
% number of points for the lookup tables (for kernel-smoothing)
ks.NP = 1e4;
% number of plus/minus standard deviations for the bounds of
% kernel-smoothing
ks.Nstd = 8;
%% retrieve the Input object
if exist('module', 'var')
    current_input = uq_getInput(module);
else
    current_input = uq_getInput;
end
% The module must be of "uq_default_input" type
if ~strcmp(current_input.Type, 'uq_default_input')
    error('uq_initialize_default_input error: you must initialize a uq_default_input type object, not a % one!!', current_input.Type);
end
% retrieve the options
Options = current_input.Options;

% Add default .Display options
if ~isfield(Options, 'Display')
    Options.Display = 0;
end

[Marginals, Options] = uq_process_option(Options, 'Marginals');
% Make a copy opts of structure Options
opts = struct();
flds = fields(Options);
for ff = 1:length(flds)
    opts.(flds{ff}) = Options.(flds{ff});
end

if ~isfield(Options, 'Inference')
    if Marginals.Missing || Marginals.Invalid
        error('Input Marginals must be defined!');
    end
    opts.Marginals = Marginals.Value;
    marginals = Marginals.Value;
elseif Marginals.Missing
    marginals = uq_initialize_marginals(Options);
else
    opts.Marginals = Marginals.Value;
    marginals = uq_initialize_marginals(opts);
end

% Get the number of Inputs
M = length(marginals);

% Infer KS
for ii = 1 : M
    % Fill in the variable names
    if ~isfield(marginals(ii),'Name') || isempty(marginals(ii).Name)
        % set a default name if none is specified 
        marginals(ii).Name = sprintf('X%d', ii);
    end
    
    % Initialize kernel smoothing-based marginals: caching and lookup tables
    if strcmpi(marginals(ii).Type, 'ks')
        % the data to be used for KS
        if strcmpi(marginals(ii).Parameters, 'auto')&&isfield(marginals(ii), 'Inference')&&isfield(marginals(ii).Inference,'Data')
            marginals(ii).Parameters = marginals(ii).Inference.Data;
        end
        KSPar = marginals(ii).Parameters;
        % kernel smoothing options
        ksopts = {};
        if isfield(marginals(ii), 'Options') && ~isempty(marginals(ii).Options)
            ff = fieldnames(marginals(ii).Options);
            for kk = 1:length(ff)
                ksopts = [ksopts ff{kk} marginals(ii).Options.(ff{kk})];
            end
        else
            marginals(ii).Options = [];
        end
        
        % get the bounds
        if isfield(marginals(ii), 'Bounds') && ~isempty(marginals(ii).Bounds)
            uBounds = marginals(ii).Bounds;
        elseif isfield(marginals(ii), 'Options') && isfield(marginals(ii).Options, 'Support') && ~isempty(marginals(ii).Options.Support)
            marginals(ii).Bounds = marginals(ii).Options.Support;
            uBounds = marginals(ii).Options.Support;
        else
            uBounds = [-inf,inf];
        end
        
        % set the bounds to reasonable values
        if any(isinf(uBounds))
            stdKSPar = std(KSPar);
            if isinf(uBounds(1))
                uBounds(1) = min(KSPar) - ks.Nstd*stdKSPar;
            end
            if isinf(uBounds(2))
                uBounds(2) = max(KSPar) + ks.Nstd*stdKSPar;
            end
        end
        % create the u vector that will be used to cache the values of KS
        marginals(ii).KS.u = linspace(uBounds(1), uBounds(2), ks.NP);
        
        % cache the pdf
        marginals(ii).KS.pdf = ksdensity(KSPar, marginals(ii).KS.u, ksopts{:});
        [marginals(ii).KS.cdf, cdfidx] = unique(ksdensity(KSPar, marginals(ii).KS.u, ksopts{:}, 'function', 'cdf'));
        marginals(ii).KS.ucdf = marginals(ii).KS.u(cdfidx);
    end
end

marginals_to_infer = [];
% If marginals have to be inferred, infer them! 
for ii = 1 : M
    % If Moments have been specified, convert to Parameters
    if ~uq_isnonemptyfield(marginals(ii), 'Parameters') && ...
            uq_isnonemptyfield(marginals(ii), 'Moments') && ...
            isa(marginals(ii).Moments, 'double')
        newmarg_ii = uq_MarginalFields(marginals(ii));
        marginals(ii).Type = newmarg_ii.Type;        
        marginals(ii).Parameters = newmarg_ii.Parameters; 
        marginals(ii).Moments = [];
    end
    
    % If marginal ii to be inferred, infer it
    if (isa(marginals(ii).Type, 'char') && (...
            ~uq_isnonemptyfield(marginals(ii), 'Parameters') || ...
             (isa(marginals(ii).Parameters, 'char') && ...
              strcmpi(marginals(ii).Parameters, 'auto')))) || ...
       (isa(marginals(ii).Type, 'cell') && (...
               length(marginals(ii).Type) > 1 || ...
               ~isfield(marginals, 'Parameters') || ...
               isempty(marginals(ii).Parameters) || (...
                   isa(marginals(ii).Parameters, 'char') && ...
                   strcmpi(marginals(ii).Parameters, 'auto')))) || ...
       strcmpi(marginals(ii).Type, 'auto')
   
        marginals_to_infer = [marginals_to_infer, ii];
        x = marginals(ii).Inference.Data;        
        [inferred_marginal_ii, gof_ii] = uq_infer_marginals(...
            x, marginals(ii));
        marginals(ii).Type = inferred_marginal_ii.Type;
        marginals(ii).Parameters = inferred_marginal_ii.Parameters;
        marginals(ii).GoF = gof_ii{1};
    end
end

% Fill-in Parameters (Moments) field if Moments (Parameters) is given
marginals = uq_MarginalFields(marginals);

% Get the indices of the marginals that are non-constant and store them in
% the input object
nonConstIdx = uq_find_nonconstant_marginals(marginals);
ConstIdx = uq_find_constant_marginals(marginals);

% Create the property that is needed
uq_addprop(current_input, 'nonConst', nonConstIdx);

for mm = ConstIdx
    nr_par = length(marginals(mm).Parameters);
    if nr_par>1
        error('constant marginals can have only one parameter; %d provided', nr_par)
    end
end

%% Initialize, infer, and/or complete copula(s)
AllCopulas = {};
copula_must_be_inferred = [];

% Case: no copula is specified in the input options
if ~uq_isnonemptyfield(opts, 'Copula')
    
    % Case: no copula neither inference data specified -> copula cannot be 
    % inferred and must be the independence copula. No initialization needed
    if ~uq_isnonemptyfield(opts, 'Inference.Data')
        AllCopulas{1} = uq_IndepCopula(length(marginals));
        AllCopulas{1}.Variables = 1:length(marginals);
        copula_must_be_inferred = false;
        
    % Otherwise, initialize copula(s), and check which ones must be inferred
    else     
        [TheseCopulas, these_copulas_must_be_inferred] = ...
            uq_initialize_copula(opts, 1, ConstIdx);
        % Add the initilized copula(s) to the list of existing ones
        for kkk = 1:length(TheseCopulas)
            AllCopulas{kkk} = TheseCopulas(kkk);
            copula_must_be_inferred(kkk) = these_copulas_must_be_inferred(kkk);
        end
    end
    
% Case: copula(s) were specified in the input options
else
    % Initialize each and add it to the list of existing ones
    K = length(opts.Copula);
    for kk = 1:K
        [TheseCopulas, these_copulas_must_be_inferred] = ...
            uq_initialize_copula(opts, kk);
        tot_nr_copulas = length(AllCopulas);
        for kkk = 1:length(TheseCopulas)
            AllCopulas{tot_nr_copulas+kkk} = TheseCopulas(kkk);
            copula_must_be_inferred(tot_nr_copulas+kkk) = ...
                these_copulas_must_be_inferred(kkk);
        end
    end
end

% For each initialized copula, perform inference if needed and complete its
% fields
for kk = 1:length(AllCopulas)

    copula = AllCopulas{kk};
    Vars = copula.Variables;
    M_now = length(Vars);

    % Infer the copula if needed
    if copula_must_be_inferred(kk)
        if uq_isfield(copula, 'Inference.DataU') 
            U = copula.Inference.DataU;
        elseif uq_isfield(copula, 'Inference.Data') 
            X = copula.Inference.Data;
            U = uq_all_cdf(X, marginals);
        elseif uq_isfield(opts, 'Inference.Data')
            X = opts.Inference.Data(:, Vars);
            U = uq_all_cdf(X, marginals(Vars));
        else
            error('Copula inference requested but inference data missing');
        end
        
        if size(U, 2) ~= M_now
            error('Inference data inconsistent with copula dimension')
        end
        
        [copula, gof] = uq_infer_copula(U, copula);
        copula.GoF = gof;
    end

    % Complete the copula with missing fields, depending on its type
    if strcmpi(copula.Type, 'gaussian')
        % Copula correlation matrix: consistency checks
        % Naming convention for Gaussian copula: 
        %   copula.Parameters : linear correlation matrix R
        %   copula.RankCorr   : Spearman correlation matrix Rc 
        COPULA_R_EXISTS = uq_isnonemptyfield(copula,'Parameters');
        COPULA_RC_EXISTS = uq_isnonemptyfield(copula,'RankCorr');
        COPULA_TK_EXISTS = uq_isnonemptyfield(copula,'TauK');
        switch (COPULA_R_EXISTS + COPULA_RC_EXISTS + COPULA_TK_EXISTS)
            case 1
            case {2 3}
                error('You can only define one of the possible copula correlation matrices!');
            case 0
                error('No copula correlation matrix defined!');
        end

        if COPULA_RC_EXISTS % The Spearman correlation matrix is given
            % the linear correlation matrix can be directly obtained
            copula.Parameters = 2*sin(pi/6*copula.RankCorr);
        end
        % R should be square
        if size(copula.Parameters,1) ~= size(copula.Parameters,2)
            error('Error: The copula matrix should be square!')
        end
        % R size should match the number of marginals
        if size(copula.Parameters,1) ~= length(Vars) 
            msg = 'Error: The copula matrix size is not consistent with';
            error('%s the number of marginals!', msg)
        end
        % R should be positive definite
        nonconstidx = find(ismember(copula.Variables, nonConstIdx));
        uq_check_correlation_matrix(copula.Parameters(nonconstidx,nonconstidx));

    elseif strcmpi(copula.Type, 'independent') % independent copula
        % Create and store the copula's linear and Spearman correlation matrix
        copula.Parameters = eye(M_now);
        copula.RankCorr = copula.Parameters;

    elseif strcmpi(copula.Type, 'pair') % independent copula
        if ~isfield(copula, 'Dimension')
            copula.Dimension = 2;
        elseif copula.Dimension ~= 2
            error('Pair copula cannot have dimension %d', copula.Dimension);
        end

        if ~isfield(copula, 'Rotation')
            copula.Rotation = 0;
        end

    elseif any(strcmpi(copula.Type, {'cvine', 'dvine'}))
        uq_check_copula_is_vine(copula);
        % Build Vcopula, a copy of copula (completed with independent PCs
        % in the case of truncated vines)
        Vtype = [upper(copula.Type(1)) 'Vine'];
        Vfams = copula.Families;
        Vstruct = copula.Structure;
        Vpars = copula.Parameters;
        Vrots = uq_vine_copula_rotations(copula);   
        Vtrunc = uq_vine_copula_truncation(copula);
        Vcopula = uq_VineCopula(Vtype, Vstruct, Vfams, Vpars, Vrots, Vtrunc); 
        
        copula = uq_overwrite_nonemptyfields(Vcopula, copula);
    else
        error('Copula type "%s" unknown or not supported yet', copula.Type);
    end

    % Overwrite AllCopulas{kk} with copula 
    AllCopulas{kk} = copula;
end

% Transform cell array AllCopulas into structure Copula:
% ...first initialize a Copula with an empty field for each fieldname
% found across all copulas in AllCopulas
Copula = struct;
for kk = 1:length(AllCopulas)
    Fields = fieldnames(AllCopulas{kk});
    for ff = 1:length(Fields)
        Copula(1).(Fields{ff}) = [];
    end
end
% ...then replace the fields with the correct one for each copula
for kk = 1:length(AllCopulas)
    Fields = fieldnames(AllCopulas{kk});
    for ff = 1:length(Fields)
        Copula(kk).(Fields{ff}) = AllCopulas{kk}.(Fields{ff});
    end
end

%% Check that all copula variables are properly assigned
AllVars = [Copula(:).Variables];
% Check that the copula variables are mutually exclusive sets
if length(AllVars) > length(unique(AllVars))
    error('Two or more copulas couple the same variable(s).')
end
% Check that no variable is different from 1,2,...,M
if any(~ismember(AllVars, 1:M))
    error('One or more variables misspecified. Provide integers from 1 to %d', M)
end

%% Check that all constant variables are coupled by independence copula only

% For each copula Cop:
% * check that the variables assigned to each match the copula dimension
% * raise error if some variables coupled by Cop are constant and Cop is not 
%   the independence copula
for cc = 1:length(Copula)
    Cop = Copula(cc);
    Vars = Cop.Variables;
    if uq_copula_dimension(Cop) ~= length(Vars)
        error('Wrong number of variables (%d) assigned to copula %d of dimension %d', ...
            length(Vars), cc, uq_copula_dimension(Cop))
    end
    
    if any(ismember(Vars, ConstIdx))
        if ~uq_isIndependenceCopula(Cop)
            error('Constant variables %s cannot be coupled by %s copula', ...
                mat2str(Vars), Cop.Type)
        end
    end
end

%% Assign indep copula to all variables that were not explicitely coupled by one
NonAssignedVars = setdiff(1:M, AllVars);
if ~isempty(NonAssignedVars)
    newopts.Copula = Copula;
    L = length(Copula);
    newopts = uq_add_copula(newopts, uq_IndepCopula(length(NonAssignedVars)));
    newopts.Copula(L+1).Variables = NonAssignedVars;
    Copula = newopts.Copula;
end

%% Change copula names to standard names (support synonims)
for cc = 1:length(Copula)
    Copula(cc).Type = uq_copula_stdname(Copula(cc).Type);
end

%% Initialize sampling
% Set some defaults to the sampling method that is going to be used when
% getting samples from the random vector specified by this input object
[Sampling, Options] = uq_process_option(Options, 'Sampling', defaultSampling);
sampling = Sampling.Value;

%% Store the (initialized) main ingredients of the Input object
uq_addprop(current_input, 'Marginals', marginals);
uq_addprop(current_input, 'Copula', Copula);
uq_addprop(current_input, 'Sampling', sampling);

success = 1;

end
