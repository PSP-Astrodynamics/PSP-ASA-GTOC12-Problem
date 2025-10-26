function addToPath = uq_Dispatcher_matlab_addToPath(addDirectories)
%UQ_DISPATCHER_MATLAB_ADDTOPATH add a list of directories to MATLAB path.

addToPath = cell(numel(addDirectories),1);

for i = 1:numel(addDirectories)   
    addToPath{i} = sprintf('addpath(''%s'')',addDirectories{i});
end

addToPath = [sprintf('%s\n', addToPath{1:end-1}), addToPath{end}];

end
