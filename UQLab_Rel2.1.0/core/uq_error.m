function uqException = uq_error(uqException)

% Retrieve the error stack
uqStack = uqException.stack;
% identify the stack components in p-files
sidx = true(size(uqStack));
for ii = 1:length(uqStack)
    [~,fn, ext] = fileparts(uqStack(ii).file);
    % make sure the file has .p extension and uq_prefix
    if strcmp(ext, '.p') && strcmpi(fn(1:2), 'uq')
        sidx(ii) = 0;
    end
end

% Give at least the last file if the error happened in a p-file
if ~sum(sidx)
    sidx(1) = true;
end

% build the new exception by removing the stack
fnames = {'message','identifier'};
for ii = 1:length(fnames)
    newException.(fnames{ii}) = uqException.(fnames{ii});
end

% Set the new stack in the exception
newException.stack = uqStack(sidx);
% and re-throw it
rethrow(newException);