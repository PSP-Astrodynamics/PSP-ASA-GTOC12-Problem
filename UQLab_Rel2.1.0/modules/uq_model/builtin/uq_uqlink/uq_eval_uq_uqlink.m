 function varargout = uq_eval_uq_uqlink(current_model,X,varargin)
% UQ_EVAL_UQ_LINK evaluates a UQLink model
%
% See also:UQ_INITIALIZE_UQ_UQLINK, UQ_WRAPPER_UQLINK

% assume 1 output argument when none is selected
num_of_out_args = max(nargout,1) ;

% do nothing if X is empty
if isempty(X)
    [varargout{1:num_of_out_args}] = deal([]);
    return;
end

%% Model evaluation using Dispatcher unit
DispatcherObj = uq_getDispatcher;
if ~strcmp(DispatcherObj.Type,'empty') && DispatcherObj.isExecuting
    % Always thread-safe
    current_model.Internal.ThreadSafe = true;
      [varargout{1:num_of_out_args}] = uq_UQLink_dispatchWithMATLAB(...
          X, current_model.Internal);
      return
end

%%
% Update the saving folder with the time stamp  if needed - This allows to
% create unique IDs for the .zip and .mat that are created (and avoid
% overwriting them when uq_evalModel is run multiple times)
if current_model.Internal.Archiving.TimeStamp
    if  nargin == 2 || ( nargin > 2 && isempty(varargin{1}) )
        % create the IDs only when 'resume' or 'recover' are not set in
        % uq_evalModel...
        TimeStampID = uq_createUniqueID() ;
        temp = current_model.Internal.Runtime.Processed_generic(1:end-4);
        current_model.Internal.Runtime.Processed = [ ...
            temp, '_', TimeStampID, '.mat'] ;
        % Create the nuique ID for the folder only if the save option is
        % enabled
        if strcmpi(current_model.Internal.Archiving.Action,'save')
            current_model.Internal.Runtime.ArchiveFolderName = ...
                [current_model.Internal.Runtime.ArchiveFolderName, '_', TimeStampID] ;
        end
    end
end

%%
% Evaluate the auxiliary model that will call the third-party software
if nargin > 3
    action = varargin{1} ;
    matfile = varargin{2} ;
    [varargout{1:num_of_out_args}] = uq_wrapper_uqlink(X, current_model.Internal, action, matfile);    
elseif nargin > 2
    action = varargin{1} ;
    [varargout{1:num_of_out_args}] = uq_wrapper_uqlink(X, current_model.Internal, action);
else
    [varargout{1:num_of_out_args}] = uq_wrapper_uqlink(X, current_model.Internal); 
end

end
