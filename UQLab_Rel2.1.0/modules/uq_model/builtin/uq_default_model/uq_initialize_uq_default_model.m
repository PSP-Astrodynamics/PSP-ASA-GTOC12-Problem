function success = uq_initialize_uq_default_model(module)
% UQ_INITIALIZE_UQ_DEFAULT_MODEL initializes the default model in UQLab
%
% See also: UQ_EVAL_UQ_DEFAULT_MODEL


success  = 0;

%% retrieve the current model
if exist('module', 'var')
    current_model = uq_getModel(module);
else
    current_model = uq_getModel;
end


%% RETRIEVE THE OPTIONS AND PARSE THEM
Options = current_model.Options;

% parse the option with respect to stochastic simulations 
defaultIsStochastic = false;
[optStoc, Options] = uq_process_option(Options, 'isStochastic',...
    defaultIsStochastic, {'logical','double'});
if optStoc.Invalid
    warning('The isStochastic option was invalid. Using the default value instead.')
end
uq_addprop(current_model,'isStochastic',optStoc.Value);

% in the case stochastic simulators, parse the related options
if current_model.isStochastic
    defaultStochastic.supportRep = false;
    defaultStochastic.SeedControl = false;
    defaultStochastic.evalTraj = false;
    % if the user provides seed control, we set trajectory evaluation to be true
    if isfield(Options,'stochasticSim')&&isfield(Options.stochasticSim,'SeedControl')&&Options.stochasticSim.SeedControl
        defaultStochastic.evalTraj = true;
    end
    [stochasticSimOption,Options] = uq_process_option(Options, 'stochasticSim',defaultStochastic, 'struct');
    if optStoc.Invalid
        error('The stochasticSim field must be a structure!')
    end
    if stochasticSimOption.Value.supportRep && stochasticSimOption.Value.SeedControl
        warning('Please make sure whether your function can support both replications and seed control');
    end
    uq_addprop(current_model,'stochasticSim',stochasticSimOption.Value);
end

% Include the parameters if any
if isfield(Options,'Parameters')
    uq_addprop(current_model,'Parameters',Options.Parameters);
else 
    uq_addprop(current_model,'Parameters');
end

% Make sure that some kind of model source is given
isMFILE = isfield(Options, 'mFile') && ~isempty(Options.mFile) ;
isMSTRING = isfield(Options, 'mString') && ~isempty(Options.mString) ;
isMHANDLE = isfield(Options, 'mHandle') && ~isempty(Options.mHandle) ;

if isMFILE + isMSTRING + isMHANDLE > 1 
    error('Multiple model definitions found!');
end

if isMFILE + isMSTRING + isMHANDLE < 1 
    error('The model property mFile, or mString or mHandle needs to be defined!')
end


if isMFILE
    uq_addprop(current_model,'mFile',Options.mFile);
    % Add the function handle field 
    current_model.Internal.fHandle = str2func(Options.mFile) ;
end

if isMSTRING
    % check whether the @(X) exists in the beginning of the string
    % if not add it
    if isempty(strfind(Options.mString,'@(X)')) && ...
            isempty(strfind(Options.mString,'@'))
        % if stochastic simulator
        if current_model.isStochastic
            argString = '@(X';
            % add parameters the argument
            if ~isempty(current_model.Parameters)
                argString = [argString,',P'];
            end
            % add replication in the argument
            if current_model.stochasticSim.supportRep
                argString = [argString,',R'];
            end
            % add random seed in the argument
            if current_model.stochasticSim.SeedControl
                argString = [argString,',seed'];
            end
        argString = [argString,')'];    
        else
            argString = '@(X, P)';
        end
        uq_addprop(current_model,'mString',[argString,Options.mString]);
    else
        uq_addprop(current_model,'mString',Options.mString);
    end
    % Add the function handle field 
    current_model.Internal.fHandle = str2func(current_model.mString) ;
end

if isMHANDLE
    uq_addprop(current_model,'mHandle',Options.mHandle);
    % Add the function handle field 
    current_model.Internal.fHandle = Options.mHandle;
end

% Parse the Vectorize option 
if isMFILE
    defaultIsVectorized = 1;
else
    defaultIsVectorized = 0;
end

[optVect, Options] = uq_process_option(Options, 'isVectorized',...
    defaultIsVectorized, {'logical','double'});
if optVect.Invalid
    warning('The isVectorized option was invalid. Using the default value instead.')
end
if optVect.Missing
    %do nothing, just silently assign the default value
end

uq_addprop(current_model,'isVectorized',optVect.Value);

% Store the mfile location in Internal
if isMFILE
    try
        current_model.Internal.Location = which(Options.mFile);
    catch
        % in case which() gives an error it's due to Options.Function being
        % an anonymous function
        error('The m-file : %s cannot be found!', Options.mFile);
    end
else
    current_model.Internal.Location = [] ;
end

%% Set the isInitialized flag
current_model.Internal.Runtime.isInitialized = true;

success = 1;