function [Y] = uq_eval_ExpDesign(current_model, X, varargin)
% Y = UQ_EVAL_EXPDESIGN(CURRENT_MODEL): evaluate the experimental desing as
%     specified in the CURRENT_MODEL object
%
% Y = UQ_EVAL_EXPDESIGN(CURRENT_MODEL, X): evaluate the experimental desing as
%     specified in the CURRENT_MODEL object on the points specified in X (which
%     may differ from CURRENT_MODEL.ExpDesign.X;
%
% See also:
% UQ_PCE_CALCULATE_COEFFICIENTS_REGRESSION,UQ_PCE_CALCULATE_COEFFICIENTS_PROJECTION


%% Initialize common options and retrieve necessary information
% Verbosity level
DisplayLevel = current_model.Internal.Display;

% If not specified in the command line, retrieve the points onto which to
% calculate the experimental design from the CURRENT_MODEL object:
if ~exist('X', 'var')
    X = current_model.ExpDesign.X;
end

%% Calculate the experimental design only if it was not provided as an input
switch lower(current_model.ExpDesign.Sampling)
    case {'user','data'}
        % do nothing: the ExpDesign is already calculated, just get it
        Y = current_model.ExpDesign.Y;
    otherwise % sampling methods
        % get the full model
        full_model = current_model.Internal.FullModel;
        
        if DisplayLevel > 1
            fprintf('Evaluating the full model on the experimental design...\n')
        end
        
        %%%UQHPCSTART%%%
        % Use HPC if configured
        % evaluate it on the entire experimental design in parallel
        UQ_dispatcher = uq_getDispatcher;
        if ~strcmp(UQ_dispatcher.Type,'empty') && ~UQ_dispatcher.isExecuting
            uq_evalModel(full_model, X, 'hpc');
            uq_waitForJob(UQ_dispatcher);
            Y = uq_fetchResults(UQ_dispatcher);
        else
            % evaluate the experimental design normally if not specified
            Y = uq_evalModel(full_model,X,varargin{:});
        end
        %%%UQHPCEND%%%
        if DisplayLevel > 1
            fprintf('Experimental design evaluation finished\n');
        end
end

%% Preprocess the ED if configured
if isfield(current_model.ExpDesign,'PreprocY') && ~isempty(current_model.ExpDesign.PreprocY)
    current_model.ExpDesign.Yraw = Y;
    current_model.ExpDesign.Y = Y;
    [current_model.ExpDesign, PostYPar] = uq_evalModel(current_model.ExpDesign.PreprocY,current_model.ExpDesign);
    % re-associate the newly calculated exp design to Y;
    Y = current_model.ExpDesign.Y;
    if isfield(current_model.ExpDesign,'PostprocY') && ~isempty(current_model.ExpDesign.PostprocY)
        current_model.ExpDesign.PostprocY.Parameters = PostYPar;
    end
end


% put the calculated experimental design in the metamodel
% current_model.ExpDesign.Y = Y;
% and update the number of output variables
current_model.Internal.Runtime.Nout = size(Y,2);

% store in the internal field info about the variance of Y
current_model.Internal.ExpDesign.varY = var(Y);
