function fullCmd = uq_Dispatcher_bash_printCommand(command,inputs)
%UQ_DISPATCHER_BASH_PRINTCOMMAND creates a CLI command as char.

parsedCommand = uq_Dispatcher_bash_parseCommand(command);
formatChar = uq_Dispatcher_bash_parseFormat(command);

%% Format the inputs
formattedInputs = cell(numel(inputs),1);
for i = 1:numel(inputs)
    if isempty(formatChar{i})
        formattedInputs{i} = sprintf('%s',num2str(inputs{i}));
    else
        templateChar = sprintf('%s',formatChar{i});
        formattedInputs{i} = sprintf(templateChar,inputs{i});
    end
end

%% Replace the value in the parsedCommand
fullCmd = parsedCommand;
for i = 1:numel(formattedInputs)
    key = sprintf('${%d}',i);
    fullCmd = strrep(fullCmd, key, formattedInputs{i});
end

end
