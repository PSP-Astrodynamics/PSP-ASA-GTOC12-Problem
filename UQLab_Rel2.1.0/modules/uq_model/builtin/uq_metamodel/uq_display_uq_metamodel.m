function varargout = uq_display_uq_metamodel(current_model, varargin)
% varargout = UQ_DISPLAY_UQ_METAMODEL(CURRENT_MODEL,VARARGIN): define the
%     behavior of the uq_display function for uq_metamodel objects
%
% See also UQ_PCE_DISPLAY, UQ_KRIGING_DISPLAY

%% Seperate outidx from varargin
if nargin > 1 && isnumeric(varargin{1})
    % is the first argument an output idx
    % check for numeric, because integers are converted to doubles in array
    outArray = varargin{1};
    if length(varargin) > 1
        varargin = varargin(2:end);
    else
        varargin = {};
    end
    % check that requested outArray is not too large
    if max(outArray) > length(current_model.Error)
        error('Requested output range is too large') ;
    end
else
    % the first varargin is not numeric, add outArray = 1
    outArray = 1;
    if isfield(current_model.ExpDesign,'Y') && (size(current_model.ExpDesign.Y,2) > 1)
        warning('The selected %s has more than 1 output. Only the 1st output will be printed', current_model.Options.MetaType);
        fprintf('You can specify the outputs you want to be displayed with the syntax:\n')
        fprintf('uq_display(myMetaModel, OUTARRAY)\nwhere OUTARRAY is the index of desired outputs, e.g. 1:3 for the first three\n\n')
    end
end
    

%% Choose the proper display function depending on the metatype
switch lower(current_model.MetaType)
    case 'pce' 
        if nargin == 1
            [varargout{1:nargout}] = uq_PCE_display(current_model, outArray);
        else
            [varargout{1:nargout}] = uq_PCE_display(current_model, outArray, varargin{:});
        end
    case 'kriging'
        if nargin == 1
            [varargout{1:nargout}] = uq_Kriging_display(current_model, outArray);
        else
            [varargout{1:nargout}] = uq_Kriging_display(current_model, outArray, varargin{:});
        end        
    case 'pck'
        if nargin == 1
            [varargout{1:nargout}] = uq_PCK_display(current_model, outArray);
        else
            [varargout{1:nargout}] = uq_PCK_display(current_model, outArray, varargin{:});
        end
    case 'lra'
        if nargin == 1
            [varargout{1:nargout}] = uq_LRA_display(current_model, outArray);
        else
            [varargout{1:nargout}] = uq_LRA_display(current_model, outArray, varargin{:});
        end
        
    case 'svr'
        if nargin > 1
            [varargout{1:nargout}] = uq_SVR_display(current_model, outArray, varargin{:});
        else
            [varargout{1:nargout}] = uq_SVR_display(current_model, outArray);
        end
        
    case 'svc'
        if nargin > 1
            [varargout{1:nargout}] = uq_SVC_display(current_model, outArray, varargin{:});
        else
            [varargout{1:nargout}] = uq_SVC_display(current_model, outArray);
        end
        
    case 'sse'
        if nargin > 1
            H = uq_SSE_display(current_model, outArray, varargin{:});
        else
            H = uq_SSE_display(current_model, outArray);
        end
        varargout{1} = H;
    case 'glam'
        if nargin == 1
            [varargout{1:nargout}] = uq_GLaM_display(current_model, outArray);
        else
            [varargout{1:nargout}] = uq_GLaM_display(current_model, outArray, varargin{:});
        end    
    case 'spce'
        if nargin == 1
            [varargout{1:nargout}] = uq_SPCE_display(current_model, outArray);
        else
            [varargout{1:nargout}] = uq_SPCE_display(current_model, outArray, varargin{:});
        end     
end