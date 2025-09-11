function addTreeToPath = uq_Dispatcher_matlab_addTreeToPath(addTrees)
%UQ_DISPATCHER_MATLAB_ADDTOPATH add a list of directories (incl. their 
%   sub-directories) to MATLAB path.

addTreeToPath = cell(numel(addTrees),1);

for i = 1:numel(addTrees)   
    addTreeToPath{i} = sprintf('addpath(genpath(''%s''))',addTrees{i});
end

addTreeToPath = [sprintf('%s\n',addTreeToPath{1:end-1}),...
    addTreeToPath{end}];

end
