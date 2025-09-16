function varargout = uq_system(varargin)
% UQ_SYSTEM(COMMAND): execute a system command using the original env
% variables

% Store current Library Path
LDPath = getenv('LD_LIBRARY_PATH');
% remove Matlab paths from the current workspace
setenv('LD_LIBRARY_PATH', '');
try
    [varargout{1:nargout}] = system(varargin{:});
catch me
    varargout{1} = -99;
end
% Reassign old library paths
setenv('LD_LIBRARY_PATH',LDPath)