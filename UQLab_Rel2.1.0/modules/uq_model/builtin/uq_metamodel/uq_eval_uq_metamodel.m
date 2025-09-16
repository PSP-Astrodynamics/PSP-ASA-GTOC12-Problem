function varargout = uq_eval_uq_metamodel(current_model, X, varargin)
% Y = UQ_EVAL_UQ_METAMODEL(CURRENT_MODEL,X): evaluate the metamodel in
%     CURRENT_MODEL onto the input sample X.
%
% See also: UQ_PCE_EVAL, UQ_KRIGING_EVAL

%% ENTRY POINT TO THE PROPER SURROGATE MODELLING EVALUATION FUNCTION
switch lower(current_model.MetaType)
    case 'pce'
        [varargout{1:nargout}] = uq_PCE_eval(current_model,X);
    case 'kriging'
        [varargout{1:nargout}] = uq_Kriging_eval(current_model, X,varargin{:});
    case 'pck'
        [varargout{1:nargout}] = uq_PCK_eval(current_model, X);
    case 'lra'
        [varargout{1:nargout}] = uq_LRA_eval(X,current_model);
    case 'svr'
        varargout{1} = transpose(uq_SVR_eval(X.', current_model)); % note the <TMPTRANSPOSE>
    case 'svc'
        [varargout{1:nargout}]  = uq_SVC_eval(X.', current_model); % note the <TMPTRANSPOSE>
    case 'sse'
        [varargout{1:nargout}]  = uq_SSE_eval(current_model, X, varargin{:});
    case 'glam'
        [varargout{1:nargout}]  = uq_GLaM_eval(current_model, X, varargin{:});
    case 'spce'
        [varargout{1:nargout}]  = uq_SPCE_eval(current_model, X, varargin{:});        
    otherwise
        error('Unknown model type!')
end

%% Postprocessing of the predictions if specified
if isprop(current_model,'ExpDesign') && isfield(current_model.ExpDesign,'PostprocY') && ...
        ~isempty(current_model.ExpDesign.PostprocY)
    data.X = X;
    data.Y = varargout{1};
    varargout{1} = uq_evalModel(current_model.ExpDesign.PostprocY,data);
end
