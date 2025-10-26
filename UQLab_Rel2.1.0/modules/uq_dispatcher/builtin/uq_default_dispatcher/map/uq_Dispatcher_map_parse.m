function results = uq_Dispatcher_map_parse(fetchedFiles)
%UQ_DISPATCHER_MAP_MERGE Summary of this function goes here
%   Detailed explanation goes here

results = cell(numel(fetchedFiles),1);

for i = 1:numel(fetchedFiles)
     % load the output files and only retrieve the important information
     matOutObj = matfile(fetchedFiles{i});
     results{i} = matOutObj.Y;
end

end
