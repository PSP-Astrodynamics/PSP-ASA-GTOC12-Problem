function uq_UQLink_helper_manageFiles(...
    listOfFilesPostExec, listOfFilesPreExec, InternalProp)
%UQ_UQLINK_HELPER_MANAGEFILES manages resulting files after 3rd-party code
%   execution depending on the Archiving.Action
%
%   Inputs
%   ------
%   - listOfFilesPostExec: list of files after code execution, cell array
%   - listOfFilesPreExec: list of files before code execution, cell array
%   - InternalOpts: Internal properties of the UQLink object, struct
%
%   Output
%   ------
%       None

%% Set local runtime variables
runIdx = InternalProp.Runtime.RunIdx;
runIdxChar = num2str(runIdx,InternalProp.Runtime.DigitFormat);
runDirIdx = InternalProp.Runtime.RunDirIdx;

outputNotFound = InternalProp.Runtime.OutputNotFound;
changeOutputName = InternalProp.Runtime.ChangeName;

%% Create the input fullnames w/ indices
% Get the input basenames
inputBasenames = InternalProp.Runtime.InputFileName;
inputBasenamesIndexed = strcat(inputBasenames,runIdxChar);
% Filenames (filename = basename + '.' + ext)
inputExtension = InternalProp.Runtime.InputExtension;
inputFilenamesIndexed = strcat(inputBasenamesIndexed,'.',inputExtension);
% Fullnames (fullname = path/to/filename)
inputFullnamesIndexed = fullfile(runDirIdx,inputFilenamesIndexed);

%% Create the output fullnames w/ indices
% Get the output file basenames
outputBasenames = InternalProp.Runtime.OutputFileName;
outputBasenamesIndexed = strcat(outputBasenames,runIdxChar);
% Filenames (filename = basename + '.' + ext)
outputExtension = InternalProp.Runtime.OutputExtension;
outputFilenamesIndexed = strcat(outputBasenamesIndexed, '.', outputExtension);
% Fullnames (fullname = path/to/filename)
outputFullnamesIndexed = fullfile(runDirIdx, outputFilenamesIndexed);
    
%% Manage files according to Archiving.Action
SaveDir = InternalProp.Runtime.SaveDir;
switch (InternalProp.Archiving.Action)
    case 'save'
        % Move the files to the archive,
        % rearrange files into Input, Output, Aux folders if required
        if InternalProp.Archiving.SortFiles
            % Move the input files
            cellfun(@(x) movefile(x,SaveDir.Input), inputFullnamesIndexed)

            % Move the output files
            for oo = 1:numel(outputFullnamesIndexed)
                if outputNotFound && changeOutputName(oo)
                    outputFullname = fullfile(runDirIdx,...
                        InternalProp.Output.FileName{oo});
                    try
                        movefile(outputFullname,...
                            fullfile(SaveDir.Output,...
                                outputFilenamesIndexed{oo}))
                    catch
                        % Do nothing
                    end
                else
                    try
                        movefile(outputFullnamesIndexed{oo},SaveDir.Output)
                    catch
                        % Do nothing
                    end
                end
            end

            % Move the auxiliary files (neither input nor output files)
            newFiles = setdiff(listOfFilesPostExec,listOfFilesPreExec);
            % Remove any output files from that list
            newFiles = setdiff(newFiles,InternalProp.Output.FileName);
            newFiles = setdiff(newFiles,...
                strcat(outputBasenames, runIdxChar, '.', outputExtension));
            % Move the remaining files
            for oo = 1:numel(newFiles)
                try
                    movefile(fullfile(runDirIdx,newFiles{oo}),SaveDir.Aux)
                catch
                    %
                end
            end
            
            if InternalProp.ThreadSafe
                % Delete the isolated running directory
                rmdir(runDirIdx,'s')
            end
        end

    case 'delete'
        % Delete everything,
        if InternalProp.ThreadSafe
            % It is easier if ThreadSafe is used,
            % because everything is isolated in each running directory
            rmdir(runDirIdx,'s')
        else
            % Otherwise the files that have been produced after every 
            % 3rd-party code execution must be kept track
            % and delete only that.
            newFiles = setdiff(listOfFilesPostExec,listOfFilesPreExec);
            for oo = 1:numel(newFiles)
                try
                    delete(fullfile(runDirIdx,newFiles{oo}))
                catch
                    % Do nothing
                end
            end

            % Delete input files
            for oo = 1:numel(inputFullnamesIndexed)
                try
                    delete(inputFullnamesIndexed{oo})
                catch
                    % Do nothing
                end
            end

        end

    case 'ignore'
        % Do nothing

end

end
