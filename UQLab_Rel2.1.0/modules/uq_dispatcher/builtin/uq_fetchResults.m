function varargout = uq_fetchResults(DispatcherObj,varargin)
%UQ_FETCHRESULTS fetches the results of the remote computation.
%
%   RESULTS = uq_fetchResults(DISPATCHEROBJ) fetches the results of the
%   remote computation of the lastly created Job associated with the
%   Dispatcher object DISPATCHEROBJ. RESULTS depends on the Job.
%
%   RESULTS = uq_fetchResults(DISPATCHEROBJ,JOBIDX) fetches the results of
%   the remote computation of a Job associated with the DISPATCHEROBJ
%   selected by its index JOBIDX.
%
%   RESULTS = uq_fetchResults(..., NAME, VALUE) fetches the results of the
%   remote computation with additional (optional) NAME/VALUE arguments
%   pairs. The supported NAME/VALUE arguments are:
%
%       NAME            VALUE
%       'KeepFiles'     Flag to keep the fetched files
%                       Default: false
%
%       'DestDir'       Destination directory 
%                       Default: DispatcherObj.LocalStagingLocation
%
%       'ForceFetch'    Flag to force the fetching
%                       Default: false
%
%       'SrcDir'        Source directory in the local client. This argument
%                       can be used when the results have been previously
%                       fetched into a 'DestDir' and the files have been
%                       kept.
%                       Default: ''

%% Parse and Verify Inputs

% Verify if a DISPATCHER object is specified
if ~isa(DispatcherObj,'uq_dispatcher')
    error('DISPATCHER object is expected, instead get a *%s* type.',...
        class(DispatcherObj))
end

% Get the number of Jobs in the DISPATCHER unit
numJobs = numel(DispatcherObj.Jobs);

% Check if there's a Job to update its status in the first place
if  numJobs == 0
    error('No Job is associated with DISPATCHER unit **%s**.',...
        DispatcherObj.Name)
end

% If no particular Job is specified, use the lastly created Job
if nargin == 1
    jobIdx = numJobs;
end

% Get the rest of the optional arguments as is
if nargin >= 2
    if isnumeric(varargin{1})
        % Job indices are directly given
        jobIdx = varargin{1};
        varargin = varargin(2:end);
    else
        jobIdx = numJobs;
        varargin = varargin(:);
    end
end

%% Switch to different types of Dispatcher object
switch lower(DispatcherObj.Type)
    case 'uq_default_dispatcher'
        [varargout{1:nargout}] = uq_fetchResults_uq_default_dispatcher(...
            DispatcherObj, jobIdx, varargin{:});
    otherwise
        error('Fetching results from a Job of a Dispatcher type *%s* is not supported!',...
            DispatcherObj.Type)
end

end
