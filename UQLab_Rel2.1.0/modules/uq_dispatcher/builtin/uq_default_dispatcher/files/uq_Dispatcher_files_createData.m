function uq_Dispatcher_files_createData(location,JobObj)
%UQ_DISPATCHER_FILES_CREATEDATA Summary of this function goes here

if JobObj.Task.MATLAB
    filename = 'uq_tmp_data.mat';
    createDataMAT(fullfile(location,filename),JobObj.Data)
else
    filename = 'uq_tmp_data.txt';
    formatChar = uq_Dispatcher_bash_parseFormat(JobObj.Task.Command);
    createDataText(fullfile(location,filename),...
        JobObj.Data.Inputs, formatChar)
end

end

%% ------------------------------------------------------------------------
function createDataText(filename, Data, formatChar)

for i = 1:size(Data,1)
    if iscell(Data)
        dataLine = Data{i};
    else
        dataLine = Data(i,:);
    end
    % Format each line (row) of data
    formattedData = uq_Dispatcher_bash_printData(dataLine,formatChar);
    % Add new line
    formattedData = sprintf('%s\n',formattedData);
    uq_Dispatcher_util_writeFile(filename, formattedData, 'Permission', 'a')
end

end

%% ------------------------------------------------------------------------
function createDataMAT(filename,Data)

matInpObj = matfile(filename, 'Writable', true);

fnames = fieldnames(Data);
for i = 1:numel(fnames)
    matInpObj.(fnames{i}) = Data.(fnames{i});
end

end


