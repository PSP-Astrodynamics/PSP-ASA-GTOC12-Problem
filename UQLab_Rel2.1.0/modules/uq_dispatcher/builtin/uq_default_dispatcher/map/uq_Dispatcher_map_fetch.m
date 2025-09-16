function filesToFetch = uq_Dispatcher_map_fetch(DispatcherObj,numProcs)
%UQ_DISPATCHER_MAP_FETCH fetches the remote results for a mapping tasks.

% Create filenames to copy to local machine
filesToFetch = cell(numProcs,1);
for i = 1:numProcs
    processID = sprintf('%.4d',i);
    filenameToFetch = sprintf(...
        [DispatcherObj.Internal.RemoteFiles.Output,'_%s.mat'],...
        processID);
    filesToFetch{i} = filenameToFetch;
end

end
