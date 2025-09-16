function uq_Dispatcher_files_createSetPATH(location, JobObj, DispatcherObj)
%UQ_DISPATCHER_FILES_CREATESETPATH Summary of this function goes here
%   Detailed explanation goes here

addDirectories = [JobObj.AddToPath, DispatcherObj.AddToPath];
addTrees = [JobObj.AddTreeToPath, DispatcherObj.AddTreeToPath];

scriptSetPATH = {};
scriptSetPATH{end+1} = DispatcherObj.Internal.RemoteConfig.Shebang;
scriptSetPATH{end+1} = uq_Dispatcher_bash_setPATH(addDirectories,addTrees);
scriptSetPATH = [sprintf('%s\n',scriptSetPATH{1:end-1}),scriptSetPATH{end}]; 

setPATHFile = fullfile(location,DispatcherObj.Internal.RemoteFiles.SetPATH);

uq_Dispatcher_util_writeFile(setPATHFile,scriptSetPATH);

end
