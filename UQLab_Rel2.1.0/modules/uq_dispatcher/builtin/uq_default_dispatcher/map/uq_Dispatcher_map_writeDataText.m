function uq_Dispatcher_map_writeDataText(filename,data,formatChar)

%%
for i = 1:size(data,1)
    if iscell(data)
        dataLine = data{i};
    else
        dataLine = data(i,:);
    end
    % Format each line (row) of data
    formattedData = uq_Dispatcher_map_printData(dataLine,formatChar);
    % Add new line
    formattedData = sprintf('%s\n',formattedData);
    uq_Dispatcher_util_writeFile(filename, formattedData, 'Permission', 'a')
end

end