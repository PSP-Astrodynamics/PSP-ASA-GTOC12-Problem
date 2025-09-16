function success = uq_SPCE_initialize( current_model )
% success = UQ_SPCE_INITIALIZE(CURRENT_MODEL): Initialize a stochastic polynomial chaos expansion metamodel
% based on the user-specified Options.
% 
% See also: UQ_INITIALIZE_UQ_METAMODEL

%% SET THE TYPE OF EMULATOR TO STOCHASTIC
uq_addprop(current_model, 'isStochastic', true);

%% Success
success = 0;

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
if uq_isnonemptyfield(current_model.ExpDesign,'isTrajectory')
    if current_model.ExpDesign.isTrajectory
        error('Independent samples should be used to build stochastic polynomial chaos expansions')
    else
        current_model.ExpDesign.isTrajectory = false;
    end
else
    % by default we consider the independent model runs
    current_model.ExpDesign.isTrajectory = false;
end
%% Default values

% default method
DEFAULTMethod = 'Regression';

% default latent variables
DEFAULTLatent(1).Type = 'Gaussian';
DEFAULTLatent(1).Parameters = [0,1];
DEFAULTLatent(2).Type = 'Uniform';
DEFAULTLatent(2).Parameters = [-1,1];

% SPCE settings
DEFAULTSPCE.Degree=1:5;
DEFAULTSPCE.TruncOptions.qNorm = 1;
DEFAULTSPCE.IntMethod = 'Quadrature';

% Options related to quadrature for integration
DEFAULTQUAD.Level = 100;

% Options related to MCS for integration
DEFAULTSampling.N = 1e3;
DEFAULTSampling.Method = 'LHS';

% Options related to the matlab integral
DEFAULTMatlabInt = struct([]);

% Default earlystop Options
DegreeEarlyStop = true;
qNormEarlyStop = true;

% whether the data should be standardized
DEFAULTStandardize = true;

% Model selection criterion (for degree and qNorm adaptivity)
DEFAULTSelectCrit = 'CV';

% Options related to sigma selections
DEFAULTSigma.Value = [];% candidate values: either a fixed value or an array
% Compute the number of CV folds based on the total sample size
Nall = current_model.ExpDesign.NSamples*current_model.ExpDesign.Replications;
if Nall<=200
    DEFAULTSigma.CVFolds = 10;
elseif Nall<=1000
    DEFAULTSigma.CVFolds = 5;
else
    DEFAULTSigma.CVFolds = 3;
end

% Set default cross-validation Options for sigma selection
% for quadrature method
DEFAULTVALQUAD.Level = 1000;
% for Sampling method
DEFAULTVALSampling = DEFAULTSampling;
DEFAULTVALSampling.N = 2*DEFAULTVALSampling.N;% by default the validation samples are twice the fitting procedure

% Possible setting for the mean estimation
DEFAULTMeanReg.Method = 'LARS';
% by default the mean function is fitted once without following the degree and q-norm adaptivity
DEFAULTMeanReg.separateFit = true;

%% RETRIEVE THE OPTIONS AND PARSE THEM
Options = current_model.Options;

%% add SPCE field
uq_addprop(current_model, 'SPCE', []);

%% initialize the fitting method (this field is not used but mainly for distinguishing with the custom method)
[fitMethod, Options] = uq_process_option(Options, 'Method', DEFAULTMethod, 'char');
if fitMethod.Invalid
    error('The fitting method should be a string!')
end
current_model.Internal.Method = fitMethod.Value;

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

%% initialize the latent variables
AuxInput = struct;
if uq_isnonemptyfield(Options,'Latent')
    for il = 1:length(Options.Latent)
        if uq_isnonemptyfield(Options.Latent(il),'Type')
            AuxInput.Marginals(il).Type = Options.Latent(il).Type;
            if  uq_isnonemptyfield(Options.Latent(il),'Parameters')
                AuxInput.Marginals(il).Parameters = Options.Latent(il).Parameters;
            else
                % if the parameter fields is empty, for normal and uniform
                % distribution, we initialize the standard parameters
                switch(lower(Options.Latent(il).Type))
                    case 'gaussian'
                        AuxInput.Marginals(il).Parameters = [0,1];
                    case 'uniform'
                        AuxInput.Marginals(il).Parameters = [-1,1];
                    case 'constant'
                        error('The latent variable cannot be a constant!');
                    % otherwise, throw an error    
                    otherwise
                        error('The parameters are missing for %s latent distribution',Options.Latent(il).Type)
                end
            end
        else
            error('The type of candidate latent variables %d is not specified',il);
        end
    end
else
    AuxInput.Marginals = DEFAULTLatent;
end

% Create and save the latent input object
current_model.Internal.SPCE.Latent.Dist = uq_createInput(AuxInput,'-private');

% Compute the number of candidate latent variables
NCandidateLatent = length(AuxInput.Marginals);
current_model.Internal.SPCE.Latent.NCandidateLatent=NCandidateLatent;

%% initialize the degree and truncation schemes

% set the degree value properly
[Degree, Options] = uq_process_option(Options, 'Degree', DEFAULTSPCE.Degree, 'double');
if Degree.Invalid
    error('The Degree field must be a constant, an array or a cell array!')
end
current_model.Internal.SPCE.Basis.Degree = Degree.Value;

[TruncOptions, Options] = uq_process_option(Options,'TruncOptions', DEFAULTSPCE.TruncOptions, 'struct');
if TruncOptions.Invalid
   error('TruncOptions must be a structure!') ;
end
% directly pass the truncation Options to the SPCE. It will take care of
% building the basis appropriately
current_model.Internal.SPCE.Basis.Truncation = TruncOptions.Value;

% store the maximum degree
if uq_isnonemptyfield(TruncOptions.Value,'Custom')
    maxLatentDeg = max(TruncOptions.Value.Custom(:,end));
    maxInputDeg = max(TruncOptions.Value.Custom(:,1:end-1),[],'all');
    if ~ismember(zeros(1,length(nonConst)),TruncOptions.Value.Custom,'rows')
        DEFAULTStandardize = false;
    end
else
    maxLatentDeg = max(Degree.Value);
    maxInputDeg = maxLatentDeg;
end
current_model.Internal.SPCE.Basis.maxLatentDeg = maxLatentDeg;
%% options to fit the mean function
[MeanOpt,Options]= uq_process_option(Options, 'MeanReg', DEFAULTMeanReg, 'struct');
if MeanOpt.Invalid
    error('The mean fitting field must be a structure!');
end
current_model.Internal.SPCE.MeanReg = MeanOpt.Value;

% extract the maximum input degrees
if uq_isnonemptyfield(MeanOpt.Value,'Degree')
    maxInputDeg = max(maxInputDeg,max(MeanOpt.Value.Degree));
    current_model.Internal.SPCE.MeanReg.separateFit = true;   
else
    % if the degree is not given, set to the SPCE degree
    current_model.Internal.SPCE.MeanReg.Degree = current_model.Internal.SPCE.Basis.Degree;
    
    % if custom mean indices are provided, then update the maximum input
    % degrees
    if isfield(MeanOpt.Value,'TruncOptions')&&uq_isnonemptyfield(MeanOpt.Value.TruncOptions,'Custom')
        maxInputDeg = max(maxInputDeg,max(MeanOpt.Value.TruncOptions.Custom,[],'all'));
    end
end

% if we fit seperatly the mean function, adapt the truncation options
if current_model.Internal.SPCE.MeanReg.separateFit && ~isfield(MeanOpt.Value,'TruncOptions')
    current_model.Internal.SPCE.MeanReg.TruncOptions = TruncOptions.Value;
end

% if the truncation scheme of the overall model is given, retrieve those
% related to the mean function
if uq_isnonemptyfield(TruncOptions.Value,'Custom')
    current_model.Internal.SPCE.MeanReg.separateFit = true;
    ind = current_model.Internal.SPCE.Basis.Truncation.Custom(:,end)==0;
    current_model.Internal.SPCE.MeanReg.TruncOptions.Custom = current_model.Internal.SPCE.Basis.Truncation.Custom(ind,1:end-1);
end

current_model.Internal.SPCE.Basis.maxInputDeg = maxInputDeg;

%% initialize the PCE basis
current_model = uq_SPCE_initialize_PCEBasis(current_model);

%% initialize the model selection criterion 
[SelectCrit, Options] = uq_process_option(Options,'SelectCrit', DEFAULTSelectCrit, 'char');
if SelectCrit.Invalid
   error('The model selection criterion must be a string!') ;
end
current_model.Internal.SPCE.SelectCrit = SelectCrit.Value;

%% initialize Earlystop Options
[earlystop, Options] = uq_process_option(Options, 'DegreeEarlyStop', DegreeEarlyStop, 'logical');
if earlystop.Invalid
    error('The DegreeEarlyStop field must be a logical!')
else
    current_model.Internal.SPCE.DegreeEarlyStop = earlystop.Value;
end
[earlystop, Options] = uq_process_option(Options, 'qNormEarlyStop', qNormEarlyStop, 'logical');
if earlystop.Invalid
    error('The qNormEarlyStop field must be a logical!')
else
    current_model.Internal.SPCE.qNormEarlyStop = earlystop.Value;
end

%% initialize data preprocessing
[standardize, Options] = uq_process_option(Options, 'Standardize', DEFAULTStandardize, 'logical');
if standardize.Invalid
    error('The Standardize field must be a logical!')
else
    current_model.Internal.SPCE.Standardize = standardize.Value;
end

%% initialize the integration method
[IntMethod, Options] = uq_process_option(Options, 'IntMethod', DEFAULTSPCE.IntMethod, 'char');
if IntMethod.Invalid
    error('The Method field must be a string!')
else
    current_model.Internal.SPCE.IntMethod = IntMethod.Value;
end

switch lower(IntMethod.Value)
    case 'quadrature'
        [QuadOptions, Options] = uq_process_option(Options, 'Quadrature', DEFAULTQUAD, 'struct');
        if QuadOptions.Invalid
            error('The Quadrature field must be a structure!');
        end
        current_model.Internal.SPCE.Quadrature = QuadOptions.Value;
               
    case 'sampling'
        [SamplingOptions, Options] = uq_process_option(Options, 'Sampling', DEFAULTSampling, 'struct');
        if SamplingOptions.Invalid
            error('The Sampling field must be a structure!');
        end
        current_model.Internal.SPCE.Sampling = SamplingOptions.Value;
        
        % update the default validation value
        DEFAULTVALSampling.N = 2*SamplingOptions.Value.N;
    
    case 'matlabint'
        MatlabIntOptions = uq_process_option(Options, 'MatlabInt', DEFAULTMatlabInt, 'struct');
        if MatlabIntOptions.Invalid
            error('The MatlabInt field must be a structure!');
        end
        current_model.Internal.SPCE.MatlabInt = MatlabIntOptions.Value;
end

% set the default integration method for cross-validation
DEFAULTSigma.IntMethod = IntMethod.Value;

%% initialize the Options for sigma selections
[SigmaOptions, Options] = uq_process_option(Options, 'Sigma', DEFAULTSigma, 'struct');
if SigmaOptions.Invalid
   error('Sigma must be a structure!') ;
end
% directly pass the Sigma Options to the SPCE. 
current_model.Internal.SPCE.Sigma = SigmaOptions.Value;

% Generate the cross-validation sets
current_model.Internal.SPCE.Sigma.CV = cvpartition(current_model.ExpDesign.NSamples,'KFold',current_model.Internal.SPCE.Sigma.CVFolds);
%% initialize the Options related to cross-validations
switch lower(SigmaOptions.Value.IntMethod)
    case 'quadrature'
        QuadOptions = uq_process_option(SigmaOptions.Value, 'Quadrature', DEFAULTVALQUAD, 'struct');
        if QuadOptions.Invalid
            error('The Quadrature field must be a structure!');
        end
        current_model.Internal.SPCE.Sigma.Quadrature = QuadOptions.Value;

    case 'sampling'
        SamplingOptions = uq_process_option(SigmaOptions.Value, 'Sampling', DEFAULTVALSampling, 'struct');
        if SamplingOptions.Invalid
            error('The Sampling field must be a structure!');
        end
        current_model.Internal.SPCE.Sigma.Sampling = SamplingOptions.Value;
        
    case 'matlabint'
        MatlabIntOptions = uq_process_option(SigmaOptions.Value, 'MatlabInt', DEFAULTMatlabInt, 'struct');
        if MatlabIntOptions.Invalid
            error('The Quadrature field must be a structure!');
        end
        current_model.Internal.SPCE.Sigma.MatlabInt = MatlabIntOptions.Value;
        
end


%% finish the specific initialization for SPCE
success = 1;

end

