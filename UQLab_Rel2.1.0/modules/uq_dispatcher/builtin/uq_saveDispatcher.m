function uq_saveDispatcher(filename,varargin)
%UQ_SAVEDISPATCHER saves a Dispatcher object to a MAT-file.
%
%   UQ_SAVEDISPATCHER(FILENAME) saves the Dispatcher object currently
%   selected in the UQLab session to a MAT-file named FILENAME. If not
%   given, then the file extension is automatically provided. If given,
%   the extension must be '.mat'.
%
%   UQ_SAVEDISPATCHER(FILENAME,DISPATCHEROBJ) saves a Dispatcher object
%   DISPATCHEROBJ to a MAT-file named FILENAME.
%
%   UQ_SAVEDISPATCHER(FILENAME,DISPATCHERIDX) saves the Dispatcher object
%   selected by its index DISPATCHERIDX from the current UQLab session to
%   a MAT-file named FILENAME. 
%
%   UQ_SAVEDISPATCHER(FILENAME,DISPATCHERNAME) saves the Dispatcher object
%   selected by its name DISPATCHERNAME from the current UQLab session
%   to a MAT-file named FILENAME. 
%
%   See also UQ_LOADDISPATCHER.

%% Parse and verify inputs

% Get the Dispatcher object
if nargin < 2
    DispatcherObj = uq_getDispatcher;
else
    if isnumeric(varargin{1}) && isscalar(varargin{1})
        % Index of the Dispatcher object in the UQLab session
        dispatcherIdx = varargin{1};
        DispatcherObj = uq_getDispatcher(dispatcherIdx);
    elseif ischar(varargin{1})
        % Name of the Dispatcher object in the UQLab session
        dispatcherName = varargin{1};
        DispatcherObj = uq_getDispatcher(dispatcherName);
    else
        % Dispatcher object stored in a variable
        DispatcherObj = varargin{1};
    end
end

% Process the filename
[pathname,rootname,ext] = fileparts(filename);

if isempty(ext)
    ext = '.mat';
else
    if ~strcmpi(ext,'.mat')
        error('If extension is given, it must be .mat.')
    end
end

filename = fullfile(pathname, [rootname ext]);

%% Save the Dispatcher object
S.DispatcherObj = DispatcherObj;

save(filename, '-struct', 'S', '-v7.3') 

end
