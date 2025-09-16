function varargout = uq_loadDispatcher(filename,varargin)
%UQ_LOADISPATCHER loads a Dispatcher object stored in a MAT-file.
%
%   UQ_LOADDISPATCHER loads a DISPATCHER object stored in an auto-saved 
%   MAT-file located in the current working directory and adds the object
%   to the current UQLab session. The MAT-file is, by default,
%   automatically created with a special filename when a DISPATCHER object
%   is created. When there are multiple of such files, the most recent one
%   is automatically loaded.
%
%   UQ_LOADDISPATCHER(FILENAME) loads a Dispatcher object stored in a MAT-
%   file named FILENAME and adds the object to the current UQLab session.
%   If the '.mat' extension is not given in FILENAME, it will be added.
%   If a Dispatcher object of the same name already in the current UQLab
%   session, the new object is loaded with a modified name.
%
%   UQ_LOADDISPATCHER(..., 'NoDuplicate', false) loads a Dispatcher object
%   stored in a MAT-file and only adds the object to the current UQLab
%   session if there is no Dispatcher object of the same name already
%   in the session.
%
%   DISPATCHEROBJ = UQ_LOADDISPATCHER(...) additionally returns the
%   Dispatcher object in a variable DISPATCHEROBJ.
%
%   DISPATCHEROBJ = UQ_LOADDISPATCHER(FILENAME,'-private') loads a
%   Dispatcher object stored in FILENAME and returns the object
%   DISPATCHEROBJ. The Dispatcher object will not be imported to the
%   current UQLab session.
%
%   See also UQ_SAVEDISPATCHER.

%% Parse and verify inputs

% Filename is not specified
if nargin == 0
    filename = getRecentAutoSavedFile();
end

isPrivateObject = false;
if nargin > 0
    if strcmpi(filename,'-private')
        isPrivateObject = true;
        varargin = varargin(1:end);
        filename = getRecentAutoSavedFile();
    else
        if mod(numel(varargin),2) == 1
            if strcmpi(varargin{1},'-private')
                varargin = varargin(2:end);
                isPrivateObject = true;
            else
                varargin = [filename varargin];
                filename = getRecentAutoSavedFile();
            end
        end
    end
end

% Check if the Job status needs to be updated
[noDuplicate,varargin] = uq_parseNameVal(varargin, 'NoDuplicate', true);
    
% Throw warning if varargin is not exhausted
if ~isempty(varargin)
    warning('There is %s Name/Value argument pairs.',num2str(numel(varargin)))
end

%% Load the Dispatcher object
matObj = matfile(filename, 'Writable', false);
DispatcherObj = matObj.DispatcherObj;

if nargout
    varargout{1} = DispatcherObj;
end

%% Add the Dispatcher object into the UQLab session if requested
if ~isPrivateObject

    if noDuplicate
        idx = 1;
        try
            while true
                currentDispatcherObj = uq_getDispatcher(idx);
                if strcmp(currentDispatcherObj.Name,DispatcherObj.Name)
                    error(['A Dispatcher object of the same name',...
                        ' is already in the UQLab session. The object is not imported.'])
                end
                idx = idx + 1;
            end
        catch ME
            if ~isempty(regexp(ME.message,'does not exist', 'once'))
                % If the object does exist in the session, import it
                impDisp = uq_importObj(DispatcherObj);
                % also select it
                uq_selectDispatcher(impDisp);
            else
                % Otherwise, skip importing it and show warning
                warning(ME.message)
            end
        end
    else
        impDisp = uq_importObj(DispatcherObj);
        uq_selectDispatcher(impDisp);
        if nargout
            varargout{1} = DispatcherObj;
        end
    end
end

end


%% ------------------------------------------------------------------------
function recentAutoSavedFile = getRecentAutoSavedFile()
% Get the most recent auto-saved file in the current working directory.

% Get all files in the current working directory
files = dir;
filenames = uq_map(@(x) x.name, files);
filedatenums = uq_map(@(x) x.datenum, files);
filedatenums = [filedatenums{:}];

% Select files that match the Dispatcher object auto-saved filename
% convention
filenames = regexp(filenames,...
    'uq_Dispatcher_.*_.*.mat', 'match');
matchedFilenames = [filenames{~cellfun(@isempty,filenames)}];

% If file not found, throw an error
if isempty(matchedFilenames)
    error('Dispatcher object MAT-file not specified,\n%s',...
        'and none found in the current working directory.');
end

% Get the index of the most recent file
matchedFiledatenums = filedatenums(~cellfun(@isempty,filenames));
[~,maxIdx] = max(matchedFiledatenums);

% Return the most recent file
recentAutoSavedFile = matchedFilenames{maxIdx};

end
