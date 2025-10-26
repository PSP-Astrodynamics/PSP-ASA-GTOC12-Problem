function success = uq_PCK_initialize( current_model )
%UQ_PCK_INITIALIZE Initialization script of a UQ Kriging metamodel
success = 0;

M = current_model.Internal.Runtime.M;

Options = current_model.Options;

%% Default values 
% PCK
DEFAULTmode = 'sequential';
DEFAULTCombCrit = 'rel_loo';

% Kriging
DEFAULTKriging = [];

% PCE
DEFAULTPCE.MetaType = 'PCE';
DEFAULTPCE.Degree = 1:3;
DEFAULTPCE.Method = 'LARS';

%% initialize the PCK specifc options 

%initialize the input model
if ~isfield(Options, 'Input')
    current_input = uq_getInput;
else
    current_input = [];
end
[input, Options] = uq_process_option(Options, 'Input', current_input, 'uq_input');
current_model.Internal.Input = input.Value;

% combination mode: 'sequential' or 'optimal'
[mode, Options] = uq_process_option(Options, 'Mode', DEFAULTmode, 'char');
if strcmpi(mode.Value,'sequential')
    current_model.Internal.Mode = mode.Value;
else if strcmpi(mode.Value, 'optimal')
        current_model.Internal.Mode = mode.Value;
    else
        error('something went wrong over here')
    end
end


% 'user' or 'pce' trend
if ~isfield(Options, 'PCE') && ~isfield(Options, 'PolyIndices')
    %nothing is specified -> use default PCE options
    current_model.Internal.PCE = DEFAULTPCE;
    current_model.Internal.TrendMethod = 'pce';
    
else 
    if ~isfield(Options, 'PCE') && isfield(Options, 'PolyIndices')
        %only the polyindices and polytypes are given -> transport them to
        %internal 
        if ~isfield(Options, 'PolyTypes')
            error('PolyTypes are missing')
        end
        [polyindices, Options] = uq_process_option(Options, 'PolyIndices', [], 'double');
        current_model.Internal.PolyIndices = polyindices.Value;
        [polytypes, Options] = uq_process_option(Options, 'PolyTypes', [], 'cell');
        current_model.Internal.PolyTypes = polytypes.Value;
        current_model.Internal.TrendMethod = 'user';
        
    else 
        if isfield(Options, 'PCE') && ~isfield(Options, 'PolyIndices')
            %if there are PCE options but no polyindices
            [pce, Options] = uq_process_option(Options, 'PCE', DEFAULTPCE, 'struct');
            current_model.Internal.PCE = pce.Value;
            current_model.Internal.TrendMethod = 'pce';
            % only OLS, LARS or OMP are available for PCK at the moment
            if ~any(strcmpi(current_model.Internal.PCE.Method,{'lars','omp'}))
                error('PCK only supports LARS or OMP sparse regression methods for the PCE trend')
            end

        else
            %both are specified
            error('options for pce and the set of polynomials cannot be given at the same time')
        end
    end
end


% comparison criterion if mode='optimal'
if strcmpi(current_model.Internal.Mode, 'optimal')
    [combo, Options] = uq_process_option(Options, 'CombCrit', DEFAULTCombCrit, 'char');
    current_model.Internal.CombCrit = lower(combo.Value);  
end


% use the options for Kriging and maybe set some defaults different from
% the "normal" Kriging models
[kriging, ~] = uq_process_option(Options, 'Kriging', DEFAULTKriging, 'struct');
current_model.Internal.Kriging = kriging.Value;


%% finish the specific initialization for PC-Kriging
success = 1;