function setPATH = uq_Dispatcher_bash_setPATH(addToPath,addTreeToPath)
%UQ_DISPATCHER_BASH_SETPATH creates a command to put folders in the PATH.
%
%   Inputs
%   ------
%   - addToPath: cell array of char
%       List of folders to add to the PATH.
%   - addTreeToPath: cell array of char
%       List of folders, including their subfolders to add to the PATH
%
%   Output
%   ------
%   - setPATH: char array
%       (Bash) shell command to include additional folders in the PATH.       
%
%   Example
%   -------
%       addToPath = {}
%       addTreeToPath = {}
%       uq_Dispatcher_bash_setPATH(addToPath,addTreeToPath)
%           % 'export PATH=$PATH'
%
%       addToPath = {'~/apps/bin'}
%       uq_Dispatcher_bash_setPATH(addToPath)
%           % 'PATH="$PATH:~/apps/bin"
%           %  
%           %  export PATH=$PATH'
%
%       addToPath = {'~/apps/bin'};
%       addTreePath = {'~/myProgs'}
%       uq_Dispatcher_bash_setPATH(addToPath,addTreeToPath)
%           % 'PATH="$PATH:~/test:~/projects"
%           %
%           %  subfolders=`find ~/myProgs -type d`
%           %  for folder in $subfolders; do PATH="$PATH:$folder"; done
%           % 
%           %  export PATH=$PATH'
%
%   NOTE
%   ----
%   - BASH shell is assumed.
%   - Adding additional folders to the PATH makes all executables callable
%     everywhere in the current shell context.

%% Input Verification
if nargin < 1
    addToPath = {};
end

if nargin < 2
    addTreeToPath = {};
end

%% Add Additional Folders to PATH
setPATH = '';

% Additional folders
if ~isempty(addToPath)
    folders = [sprintf('%s:',addToPath{1:end-1}) addToPath{end}];
    setPATH = sprintf('%sPATH="$PATH:%s"',setPATH,folders);
end

% Additional folders and their subfolders
if ~isempty(addTreeToPath)
    setPATH = sprintf('%s\n\n',setPATH);
    addSubfolders = cellfun(...
        @(x) sprintf(['subfolders=`find %s -type d`\n',...
            'for folder in $subfolders; do PATH="$PATH:$folder"; done'],...
            x),...
        addTreeToPath, 'UniformOutput', false);

    setPATH = sprintf('%s%s\n',setPATH,addSubfolders{:});
end

% Export the PATH
if isempty(setPATH)
    setPATH = sprintf('%sexport PATH=$PATH',setPATH);
else
    setPATH = sprintf('%s\n\nexport PATH=$PATH',setPATH);
end

end
