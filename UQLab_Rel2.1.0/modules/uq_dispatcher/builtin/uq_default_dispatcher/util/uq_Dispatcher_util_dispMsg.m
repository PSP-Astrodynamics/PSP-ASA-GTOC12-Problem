function dispChar = uq_Dispatcher_util_dispMsg(msg,varargin)

%% Parse and verify inputs

% MaxNumChars (maximum number of characters)
DefaultValue.MaxNumChars = 70;
[maxNumChars,varargin] = uq_parseNameVal(...
    varargin, 'MaxNumChars', DefaultValue.MaxNumChars);

% PaddingChar (padding character)
DefaultValue.PaddingChar = '.';
[paddingChar,varargin] = uq_parseNameVal(...
    varargin, 'PaddingChar', DefaultValue.PaddingChar);

% PaddingDir (padding direction)
DefaultValue.PaddingDir = 'right';
[paddingDir,varargin] = uq_parseNameVal(...
    varargin, 'PaddingDir', DefaultValue.PaddingDir);
if ~strcmpi(paddingDir,{'left','right'})
    paddingDir = DefaultValue.PaddingDir;
end

% Check if there's a NAME/VALUE pair leftover
if ~isempty(varargin)
    warning('Unparsed NAME/VALUE argument pairs remain.')
end

%% Create display message

leftNumChars = maxNumChars - length(msg);
if leftNumChars <= 0
    msg = msg(1:maxNumChars-3);
    leftNumChars = 3;
end
paddingChars = repmat(paddingChar, 1, leftNumChars);

switch paddingDir
    case 'left'
        fmtChar = sprintf('%%-%ds',maxNumChars);
    case 'right'
        fmtChar = sprintf('%%%ds',maxNumChars);
end

dispChar = sprintf(fmtChar, [msg paddingChars]);


end
