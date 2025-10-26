function success = uq_GLaM_initialize( current_model )
% success = UQ_GLAM_INITIALIZE(CURRENT_MODEL): Initialize a generalized lambda model based on the
%     user-specified options.
% 
% See also: UQ_INITIALIZE_UQ_METAMODEL

%% SET THE TYPE OF EMULATOR TO STOCHASTIC
uq_addprop(current_model, 'isStochastic', true);

%% Success
success = 0;

M = current_model.Internal.Runtime.M;

%% Preprocess the experimental design
% check and set up replications
USER_SPECIFIED_ED =  any(strcmpi(current_model.ExpDesign.Sampling, {'user', 'data'}));
if USER_SPECIFIED_ED
    if ~isfield(current_model.ExpDesign,'Replications')
        current_model.ExpDesign.Replications = size(current_model.ExpDesign.Y,3);
    end
else
    if ~isfield(current_model.ExpDesign,'Replications')
        current_model.ExpDesign.Replications = 1;
    end
end

% check and set up trajectories
if isfield(current_model.ExpDesign,'isTrajectory')
    if current_model.ExpDesign.isTrajectory
        error('Independent samples should be used to build the generalized lambda model')
    else
        current_model.ExpDesign.isTrajectory = false;
    end
else
    % by default we consider the independent model runs
    current_model.ExpDesign.isTrajectory = false;
end
%% Default values

% PCE for lambda
DEFAULTLam(1).Degree=0:3;
DEFAULTLam(1).TruncOptions.qNorm = 1;
DEFAULTLam(1).Transform.Type = 'identity';

DEFAULTLam(2).Degree=0:2;
DEFAULTLam(2).TruncOptions.qNorm = 1;
DEFAULTLam(2).Transform.Type = 'exp';

DEFAULTLam(3).Degree=0:1;
DEFAULTLam(3).TruncOptions.qNorm = 0.75;
DEFAULTLam(3).Transform.Type = 'identity';

DEFAULTLam(4).Degree=0:1;
DEFAULTLam(4).TruncOptions.qNorm = 0.75;
DEFAULTLam(4).Transform.Type = 'identity';

% Default earlystop options
DegreeEarlyStop = true;
qNormEarlyStop = true;

% Default algorithm
if current_model.ExpDesign.Replications>50
    DEFAULTMethod = 'RepJoint';
else
    DEFAULTMethod = 'FullReg';
end

% two-step + joint fitting algorithm
DEFAULTRepJoint.RepMethod = 'MLE';
DEFAULTRepJoint.RegMethod = {'LARS','LARS','LARS','LARS'};

% regression algorithm
DEFAULTFullReg.Mean.Method = 'LARS';
DEFAULTFullReg.Mean.updateBasis = false;
DEFAULTFullReg.Var.Method = 'LARS';
DEFAULTFullReg.Var.updateBasis = true;
DEFAULTFullReg.SelectCrit = 'BIC';
DEFAULTFullReg.FullLambda = [3,4];


%% RETRIEVE THE OPTIONS AND PARSE THEM
Options = current_model.Options;

%% add add PCE field for lambdas
uq_addprop(current_model, 'GLaM', []);

%% initialize the input model
if ~isfield(Options, 'Input')
    current_input = uq_getInput;
else
    current_input = [];
end
[input, Options] = uq_process_option(Options, 'Input', current_input, 'uq_input');
current_model.Internal.Input = input.Value;

%% Make sure that the constant inputs are correctly dealt with
% Book-keeping of non-constant variables
% Find the non-constant variables
if isprop(current_model.Internal.Input, 'nonConst') && ~isempty(current_model.Internal.Input.nonConst)
    nonConst = current_model.Internal.Input.nonConst;
else
    %  find the constant marginals
    Types = {current_model.Internal.Input.Marginals(:).Type}; % 1x3 cell array of types
    % get all the marginals that are non-constant
    nonConst =  find(~strcmpi(Types, 'constant'));
end
% Store the non-constant variables
current_model.Internal.Runtime.MnonConst = numel(nonConst);
current_model.Internal.Runtime.nonConstIdx = nonConst;
%% initialize the fitting method
[method, Options] = uq_process_option(Options, 'Method', DEFAULTMethod, 'char');
if method.Invalid
    error('The Method field must be a string!')
else
    current_model.Internal.Method = method.Value;
end

%% initialize Earlystop options
[earlystop, Options] = uq_process_option(Options, 'DegreeEarlyStop', DegreeEarlyStop, 'logical');
if earlystop.Invalid
    error('The DegreeEarlyStop field must be a logical!')
else
    current_model.Internal.DegreeEarlyStop = earlystop.Value;
end
[earlystop, Options] = uq_process_option(Options, 'qNormEarlyStop', qNormEarlyStop, 'logical');
if earlystop.Invalid
    error('The qNormEarlyStop field must be a logical!')
else
    current_model.Internal.qNormEarlyStop = earlystop.Value;
end

%% set PCE options lambda's

% initialize maximum degree
maxDeg = 0;
if uq_isnonemptyfield(Options,'Lambda')
    ll = length(Options.Lambda);
    if ~isstruct(Options.Lambda)|| ll>4
        error("Options related to the lambda's should be an structure array of length less than or equal to 4!")
    else
        
        Lambda = struct();
        for ilam=1:ll
            % for user defined lambda
            % initialize the degree
            Optilam = Options.Lambda(ilam);
            % if degrees have been provided
            if uq_isnonemptyfield(Optilam,'Degree')
                % if the degrees are correctly given
                if isnumeric(Optilam.Degree)
                    Lambda(ilam).Degree = sort(Optilam.Degree,'ascend');
                    % throw an error if the provided degrees are not correct
                else
                    error(['The degree of lambda',num2str(ilam),' must be an numeric array!']);
                end
            else
                % get the default degree
                Lambda(ilam).Degree = DEFAULTLam(ilam).Degree;
            end
            
            % initialize the truncation scheme
            if uq_isnonemptyfield(Optilam,'TruncOptions')
                [TruncOptions, Optilam] = uq_process_option(Optilam,'TruncOptions', DEFAULTLam(ilam).TruncOptions, 'struct');
                if TruncOptions.Invalid
                    error('TruncOptions must be a structure!') ;
                end
                Lambda(ilam).TruncOptions = TruncOptions.Value;
            else
                Lambda(ilam).TruncOptions = DEFAULTLam(ilam).TruncOptions;
            end
            
            % update the maximum degree
            if uq_isnonemptyfield(Lambda(ilam).TruncOptions,'Custom')
                maxDeg = max(maxDeg,Lambda(ilam).TruncOptions.custom(:));
            else
                maxDeg = max(maxDeg,Lambda(ilam).Degree(end));
            end
        end
        
        % for undefined lambdas, use the default values
        for ilam=ll+1:4            
            Lambda(ilam).Degree=DEFAULTLam(ilam).Degree;
            Lambda(ilam).TruncOptions=DEFAULTLam(ilam).TruncOptions;
            % update the maximum degree
            maxDeg = max(maxDeg,Lambda(ilam).Degree(end));
        end
        
        % cache the lambdas' setting
        current_model.Internal.Lambda = Lambda;
    end
else
    current_model.Internal.Lambda = DEFAULTLam;
end

% get the maximum degree
current_model.Internal.Basis.maxDeg = maxDeg;

% initialize transforms
uq_GLaM_initialize_transform(current_model,DEFAULTLam);

%% Initialize PCE basis
current_model = uq_GLaM_initialize_PCEBasis(current_model);

%% initialize the algorithm for each fitting method
switch lower(method.Value)
    case 'repjoint'
        [joint, Options] = uq_process_option(Options,'RepJoint', DEFAULTRepJoint,'struct');
        if joint.Invalid
            error('The RepJoint field must be a structure!');
        else 
            if ischar(joint.Value.RegMethod)
                RegMethod = cell(1,4);
                RegMethod(:) = {joint.Value.RegMethod};
                joint.Value.RegMethod = RegMethod;
            elseif length(joint.Value.RegMethod)~=4
                error('The regression method should be either a string or a cell array of length 4');
            end
            current_model.Internal.RepJoint = joint.Value;
        end
    case 'fullreg'
        if isfield(Options,'FullReg')
            fields = fieldnames(DEFAULTFullReg);
            for is = 1:length(fields)
                ic = fields{is};
                cl = class(DEFAULTFullReg.(ic));
                [reg, Options.Regression] = uq_process_option(Options.FullReg,ic, DEFAULTFullReg.(ic),cl);
                if reg.Invalid
                    error(['The ',ic,' field in regression must be of the class ',cl,'!']);
                else
                    current_model.Internal.FullReg.(ic) = reg.Value;
                end
            end
            if isempty(fieldnames(Options.FullReg))
                Options = rmfield(Options,'FullReg');
            end
        else
            current_model.Internal.FullReg = DEFAULTFullReg;
        end
end


%% finish the specific initialization for GLaM
success = 1;

end

