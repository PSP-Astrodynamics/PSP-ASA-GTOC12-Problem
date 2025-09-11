function success = uq_GLaM_initialize_custom(current_model,Options)
% success = UQ_GLAM_INITIALIZE_CUSTOM(CURRENT_MODEL,OPTIONS) initialize a
%     custom generalized lambda model (predictor only) in CURRENT_MODEL 
%     based on the options given in the OPTIONS structure
%
% See also: UQ_PCE_INITIALIZE

% initialize return value to 0
success = 0;

% get Lambda
if ~isfield(Options, 'Lambda')
    error('Custom Lambda has been selected, but no Lambda field is defined in the options!')
end
NPCE = length(Options.Lambda);
Nout = floor(NPCE/4);
remaider = NPCE - 4*Nout;
if remaider~=0
    error('The number of lambdas should be evenly divided by 4');
end

% check that the basis is is defined and retrieve it
if ~isfield(Options.Lambda, 'Basis')
    error('Custom GLaM has been defined, but no Basis was specified!')
end

% check that the coefficients are available
if ~isfield(Options.Lambda, 'Coefficients')
    error('Custom GLaM has been requested, but no polynomial coefficients are given!')
end

for ip=1:NPCE
    % retrieve the basis polynomial indices (\alpha vectors in the documentation)
    if ~isfield(Options.Lambda(ip).Basis, 'Indices')
        error('Custom GLaM has been requested, but no basis indices are given!')
    end
    
    % retrieve the polynomial types
    if ~isfield(Options.Lambda(ip).Basis, 'PolyTypes')
        error('Custom GLaM has been requested, but no polynomial types are given!')
    end
end

% Don't allow custom PCE when no input has been defined
if uq_isnonemptyfield(Options,'Input')
    current_model.Internal.Input = uq_getInput(Options.Input);
else
    error('You have not specified an input module! Custom GLaM is not allowed when an input module is not specifically defined.');
end

current_model.Internal.Method = 'Custom';

%% initialze transforms
current_model.Internal.Lambda = Options.Lambda;
uq_GLaM_initialize_transform(current_model);
%% Build a custom PCE
PCEOpt.Type = 'Metamodel';
PCEOpt.MetaType = 'PCE';
PCEOpt.Method = 'Custom';
PCEOpt.Input = current_model.Internal.Input;
for ip=1:NPCE
    PCEOpt.PCE(ip).Basis = Options.Lambda(ip).Basis;
    PCEOpt.PCE(ip).Coefficients = Options.Lambda(ip).Coefficients;
end
LambdaPCE = uq_createModel(PCEOpt,'-private');

%% retrieve the important information
uq_addprop(current_model,'GLaM');
for oo=1:Nout
    for ilam=1:4
        olam = 4*(oo-1)+ilam;
        current_model.GLaM(olam).Lambda = ilam;
        current_model.GLaM(olam).OutputId = oo;
        current_model.GLaM(olam).Basis = LambdaPCE.PCE(olam).Basis;
        current_model.GLaM(olam).Coefficients = LambdaPCE.PCE(olam).Coefficients;
        current_model.GLaM(olam).Transform = current_model.Internal.Lambda(ilam).Transform;
    end
end
%% Make sure that the constant inputs are correctly dealt with
% Book-keeping of non-constant variables
% Find the non-constant variables

% add the remaining runtime arguments that may be needed
M = length(current_model.Internal.Input.Marginals);
current_model.Internal.Runtime.M = LambdaPCE.Internal.Runtime.M;
current_model.Internal.Runtime.nonConstIdx = LambdaPCE.Internal.Runtime.nonConstIdx;
current_model.Internal.Runtime.MnonConst = LambdaPCE.Internal.Runtime.MnonConst;
current_model.Internal.Runtime.Nout = Nout;
current_model.Internal.Runtime.isCalculated = true;
current_model.Internal.Runtime.current_output = 1;

% add the missing marginals and related parameters
current_model.Internal.ED_Input = LambdaPCE.Internal.ED_Input;

% Return, as no further initialization is needed
success = 1;
