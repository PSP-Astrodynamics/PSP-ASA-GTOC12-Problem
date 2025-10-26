function varargout = uq_evalModel(varargin)
% UQ_EVALMODEL evaluate a UQLab MODEL object.
%    Y = UQ_EVALMODEL(X) evaluates the currently selected UQLab MODEL on the
%    vector of input parameters X. Note that size(X) = [N M], where N is
%    the number of realizations of the input parameters, and M is the
%    dimension of the input parameter space.  
%
%    Y = UQ_EVALMODEL(myModel,X) evaluates the UQLab MODEL object myModel
%    on the vector of input parameters X. 
%
%    [Y1,...,YM] = UQ_EVALMODEL(...) returns multiple outputs if the
%    MODEL object supports multiple return values (e.g. Kriging metamodels)
%
%    For more detailed usage scenarios of UQ_EVALMODEL, please refer to the
%    relevant <a href="matlab:uq_doc">UQLab User Manuals</a>
%
%    See also: uq_createModel, uq_getModel, uq_listModels, uq_selectModel
%

% step 1: figure out whether the first argument is of type uq_model. If it
% is, define a 'module' argument to be used in the rest
if nargin && isa(varargin{1}, 'uq_model')
    module = varargin{1};
    varargin = varargin(2:end);
end

% HPC initialization
HPCflag = 0;


if exist('module', 'var') && ~isempty(module)
    current_model = uq_getModel(module);
else
    current_model = uq_getModel;
end

if isempty(current_model)
    error('No model defined!');
end

% enable parallelization if specified in the model
if isfield(current_model.Internal, 'HPC') && isfield(current_model.Internal.HPC, 'enable_HPC') && current_model.Internal.HPC.enable_HPC
    HPCflag = 1;
end

% override the previous setting if specified in the command line
if any(strcmpi(varargin, 'HPC'))
    varargin = varargin(~strcmpi(varargin, 'HPC'));
    HPCflag = 1;
end


%% we can now distribute the model evaluations if configured
% program the dispatcher if not under execution

if HPCflag 
    if ~exist('UQ_dispatcher', 'var')
        UQ_dispatcher = uq_getDispatcher;
    end
    if ~strcmp(UQ_dispatcher.Type, 'empty') 
        if ~UQ_dispatcher.isExecuting  % don't do anything if it is executing or if we specify not to parallelize it
            UQ_dispatcher.Internal.Data.X = varargin{1};
            UQ_dispatcher.Internal.Data.current_model = current_model;
            UQ_dispatcher.Internal.current_model = current_model;
            UQ_dispatcher.Internal.Data.Nargout = nargout;
            % now remotely execute the model evaluation
            [varargout{1:nargout}] = UQ_dispatcher.run;
            %varargout{1} = Y;
            % and, once done, return
            return;
        else % if we are running, retrieve the important information and run!
            % retrieve the execution status
            cpuID = UQ_dispatcher.Runtime.cpuID;
            ncpu = UQ_dispatcher.Runtime.ncpu;
            % needs to be fixed absolutely!!
            X = varargin{1};
            chunksize = floor(size(X, 1)/ncpu);
        
            % now resize X to the correct chunk
            minidx = (cpuID-1)*chunksize + 1;
            maxidx = (minidx - 1) + chunksize;
            if cpuID == ncpu
                maxidx = size(X,1);
            end
            
            dispidx = minidx:maxidx;
            fprintf('Distributed model evaluation.\n')
            fprintf('Calculating node %d of %d\n', cpuID, ncpu);
            fprintf('Elements %d to %d\n', minidx, maxidx);
            which uqlab
            % and trim the X
            varargin{1} = X(dispidx,:);
            
        end
    end
end

% Eval the current model (with error handling)
try
    [varargout{1:nargout}]  = current_model.eval(current_model,varargin{:});
catch uqException
    uq_error(uqException);
end

