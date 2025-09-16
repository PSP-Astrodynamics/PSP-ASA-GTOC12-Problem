function varargout = uq_wrapper_uqlink( X , P, varargin )

if nargin > 3
    action = varargin{1} ;
    RecoverySource = varargin{2} ;
elseif nargin > 2
    action = varargin{1} ;
    RecoverySource = '' ;
else
    action = '' ;
    RecoverySource = '' ;
end
if ~isempty(RecoverySource)
    if ~isvector(RecoverySource)
        IsmatFile = exist(RecoverySource,'file') ;
        error('The given recovery source cannot be found!');
    end
end
% Number of output arguments
num_of_out_args = max(nargout,1);


%% 0. Preprocessing
% Create subfolders for archiving when required. The folders are created in
% the SaveFolder (option given by the user) path and named UQLinkInput, UQLinkOutput and UQLinkAux
% respectively for the generated input files, the output files and any
% other annex file generated during execution.
if strcmpi(P.Archiving.Action, 'save')
    SaveFolder = P.Runtime.ArchiveFolderName ;
    if ~isdir(P.Runtime.ArchiveFolderName)
        mkdir(P.Runtime.ArchiveFolderName);
    end
    InputFolder = fullfile(SaveFolder,'UQLinkInput') ;
    OutputFolder = fullfile(SaveFolder,'UQLinkOutput') ;
    AuxFolder = fullfile(SaveFolder, 'UQLinkAux') ;
    % Check if the folder exists. If it does, throw a warning and do
    % nothing. If doesn't create a new one.
    if isdir(InputFolder)
        warning('Files archiving: The folder %s already exists', InputFolder );
    else
        mkdir( InputFolder ) ;
    end
    if isdir(OutputFolder)
        warning('Files archiving: The folder %s already exists ', OutputFolder );
    else
        mkdir( OutputFolder ) ;
    end
    if isdir(AuxFolder)
        warning('Files archiving: The folder %s already exists ', AuxFolder );
    else
        mkdir( AuxFolder ) ;
    end
end

% Initialize stuff
outFull=cell(1,num_of_out_args);
outCurr=cell(1,num_of_out_args);
P.Runtime.OutputNotFound = true ;
outputsize = ones(1,num_of_out_args) ;
firstValidRunID = -1 ;
reshapeMat = true ;
reshapeoutFull = true ;
TrueSizeisNotknown = true ;
% Now prepare all the run IDs:
% By default, \ie when no resume or recover option is given this list is
% .Offset+1 : .Offset + Nrun
% If resume or recover is given, two options again:
% a. The user gives a list of runs to be re-run, 
% b. uq_ProcessedY is read and only run numbers
% corresponding to all NaNs in the output are rerun.

% Proceed for each input realization in X
if isempty(action)
    % No resume or recover option, run for all inputs
    RunList = P.Counter.Offset + 1 : P.Counter.Offset + size(X,1) ;
    uq_ProcessedX = [] ;
    uq_ProcessedY = [] ;
    
    % Save all X variables, just in case
    uq_AllX = X ;
    save(P.Runtime.Processed,'uq_AllX') ;
else
    if strcmpi(action, 'recover')
        % Check first that X == uq_ProcessedX
        RunList = [] ;
        if isempty(RecoverySource)
            RecoverySource = P.Runtime.Processed ;
        end
        if ~ischar(RecoverySource) || isnumeric(RecoverySource)
            load(P.Runtime.Processed) ;
            % Now check that X and Processed X are the same
            if X ~= uq_ProcessedX
                error('The given input ''X'' differs from the previously saved ''uq_ProcessedX''!');
            end
            if any(RecoverySource > size(X,1))
                error('The list of runs contains IDs larger than the size of ''X''!');
            end
            RunList = RecoverySource ;
            if num_of_out_args > 1
                for oo = 1:num_of_out_args
                    eval(sprintf('outputsize(oo) = size(uq_ProcessedY%d,2) ;',oo));
                end
            else
                for oo = 1:num_of_out_args
                    outputsize(oo) = size(uq_ProcessedY,2) ;
                end
            end
        else
            load(RecoverySource) ;
            % Now check that X and Processed X are the same
            if X ~= uq_ProcessedX
                error('The given input ''X'' differs from the previously saved ''uq_ProcessedX''!');
            end
            if num_of_out_args > 1
                for ii = 1: size(uq_ProcessedY1,1)
                    if any(isnan(uq_ProcessedY1(ii,:)))
                        RunList = [RunList, ii] ;
                    end
                end
                
                for oo = 1:num_of_out_args
                    eval(sprintf('outputsize(oo) = size(uq_ProcessedY%d,2) ;',oo));
                end
            else
                for ii = 1: size(uq_ProcessedY,1)
                    if any(isnan(uq_ProcessedY(ii,:)))
                        RunList = [RunList, ii] ;
                    end
                end
                
                for oo = 1:num_of_out_args
                    outputsize(oo) = size(uq_ProcessedY,2) ;
                end
            end

        end
    elseif strcmpi(action, 'resume')
        if isempty(RecoverySource)
            RecoverySource = P.Runtime.Processed ;
        end
        load(RecoverySource) ;
        % Check consisteny for the recovery
        N_processed = size(uq_ProcessedX, 1) ;
        N_total = size(X, 1) ;
        if N_total < N_processed
            error('Inconsistency between the given ''X'' and the recovery source ''uq_ProcessedX''!');
        elseif uq_ProcessedX ~= X(1:N_processed,:)
            error('The processed part of the given ''X'' differs from the previously saved ''uq_ProcessedX''!');
        end
        RunList = N_processed + 1 : N_total ;
        if num_of_out_args > 1
            for oo = 1:num_of_out_args
                eval(sprintf('outputsize(oo) = size(uq_ProcessedY%d,2) ;',oo));
            end
        else
            for oo = 1:num_of_out_args
                outputsize(oo) = size(uq_ProcessedY,2) ;
            end
        end
    else
        error('The chosen action is not known! Valid arguments are ''recover'' and ''resume''.') ;
    end
end
%
for ii = RunList
    if any(strcmpi(P.Display,{'verbose', 'standard'}))
        fprintf('Running Realization %d\n', ii)  ;
    end
    P.RunNumber = ii ;
    
    %% 1. create external input file corresponding to ii_th realization
    %     if iscell(P.Template)
    for tt = 1:length(P.Template)
        % Open for reading the template file
        ftemp = fopen( fullfile(P.ExecutionPath, P.Template{tt}), 'r' ) ;
        if ftemp < 0
            error('Error : template file not found! Please provide one.') ;
        end
        % Define the input file name for each run of the code. By convention if
        % the template is e.g. myInput.inp.tpl, then for each run we will have
        % myInput000001.(dat, or whatever InputExtension), myInput000002,...,
        % myInput000010, etc. (by default the number of digits is 6 but
        % this is an option th euser can set)
        inputfilename{tt} = strcat( P.Runtime.InputFileName{tt}, num2str(ii, P.Runtime.DigitFormat) ) ;
        inputfile{tt} = fullfile( P.ExecutionPath, strcat( inputfilename{tt}, '.', P.Runtime.InputExtension{tt} ) ) ;

        finp = fopen(inputfile{tt},'w') ; % open the created file for writing only
        
        % regular expression starting and finishing with the markers -
        % This is what will be sought for in each line
        expr_bounds = strcat(P.Marker{1} ,'.*?', P.Marker{3}) ; % Thanks Paul!
        
        while ~feof(ftemp)  % Read the template until the end of file is reached
            % Catch in a string a current line
            str = fgetl(ftemp);
            % for each possible input dimension
            for jj = 1 : size(X,2)
                % Define the variable name in the input file that should be
                % replaced by the realizaztion x(ii,jj)
                expression = strcat( P.Marker{1}, P.Marker{2}, num2str(jj,'%04u'), P.Marker{3} ) ;
                % Convert into a string with appropriate formatting the value
                % of the realization x(ii,jj)
                if length(P.Format) == 1
                    param_value_as_str = num2str( X(ii,jj), P.Format{1} ) ;
                else
                    param_value_as_str = num2str( X(ii,jj), P.Format{jj} ) ;
                end
                
                % Search for expression in the current line (str), if found
                % replaced it by param_value_as_str
                str = regexprep( str, expression, param_value_as_str ) ;
                
                % Now we will try to replace mathematical expressions if
                % they exist...
                % First, look for all occurences of the bounded markers in
                % the current line
                str_expr = regexp(str,expr_bounds,'match');
                
                % If there is at least one occurence of the markers...
                % Try to replace the mathematical expression, if any
                if ~isempty(str_expr)
                    % Iterate through all occurences of the markers
                    for occ = 1:length(str_expr)
                    str_temp = str_expr{occ};

                    if length(str_temp) - (length(P.Marker{1})+length(P.Marker{2})) > length(P.Marker{2}) + 4
                        % Either there is an expression and/or multiple occurence of the delimiters
                        % in the same line. Split the line and treat these separately
                        % But first remove the space in expression, if any.    
                        str_temp_nospace = str_temp(~isspace(str_temp));
                        
                        % Replace the expression in the original str with
                        % one withouth spaces
                        str = strrep( str,  str_temp, str_temp_nospace) ;

                        str_split = strsplit(str_temp_nospace) ;
                        % Keep an original copy of str_split to use later
                        % for updating the original string str
                        str_split_original = str_split ;
                        for ll = 1:length(str_split)
                            
                            if ~isempty(regexp(str_split{ll}, expr_bounds, 'match')) ...
                                && length(str_split{ll})  - (length(P.Marker{1})+length(P.Marker{2})) > length(P.Marker{2})+4
                                % An expression has been found if the opening and
                                % closing markers are found (by default < >) AND the
                                % size of its content is larger than variable marker +
                                % 4 (number of digits) (for instance > 5 for 2*X0001)
                                % Loop through all variables and find and replace
                                % them
                                for kk = 1:size(X,2)
                                    if length(P.Format) == 1
                                        param_value_as_str = num2str( X(ii,kk), P.Format{1} ) ;
                                    else
                                        param_value_as_str = num2str( X(ii,kk), P.Format{kk} ) ;
                                    end
                                    str_split{ll} = regexprep( str_split{ll}, ...
                                        strcat(P.Marker{2}, num2str(kk,'%04u')), ...
                                        param_value_as_str ) ;
                                end
                                str_temp_split = strsplit(str_split{ll},{P.Marker{1},P.Marker{3}}) ;
                                % Now evaluate the expression
                                expr_value = eval(str_temp_split{2}) ;
                                % Finally replace it in the string
                                % Note that regexprep does not work here for some
                                % reason. Replaced by "replace" function 08/07/2019
                                str = strrep( str,  str_split_original{ll}, num2str(expr_value)) ;
                            end
                        end
                    end
                    end
                    
                    
                end
                
                
                % Now search for the output file name and if found,
                % replaced it by the numbered one - This is in case the
                % output file has a name different than the input
                if jj == 1
                    % Replace only once
                    newstr = regexprep( str, P.Runtime.OutputFileName, strcat(P.Runtime.OutputFileName,num2str(ii, P.Runtime.DigitFormat) ) ) ;
                    if ~strcmpi(newstr,str)
                        % The name of the output file has been found.
                        % Then update the new string and put a flag saying
                        % that it was found in the input
                        str = newstr ;
                        P.Runtime.OutputNotFound = false ;
                    end
                end
            end
            % Copy the current line (possibly modified) of the template file
            % into the new input file
            fprintf(finp,'%s\r\n', str);
        end
        fclose(ftemp) ;
        status_file = fclose(finp) ; % 0 if ok, -1 if nok
        if status_file ~=0
            error('Something went wrong when closing the new generated input file') ;
        end
        
    end
    
    
    %% 2. Execute external code
    
    % Get the execution command
    exeCmd = P.Command ;
    % Add the executable path if it is given
    if ~isempty(P.ExecutablePath)
        exeCmd = fullfile(P.ExecutablePath, exeCmd) ;
    end
    
    
    % Add now double quotes around the executable part to make sure that
    % the command is robust to spaces in the folder.
    % This part is carried out only if there were no double quote in the
    % first place AND if the executable command contains a non-empty path
    if ~strcmpi(exeCmd(1),'"') && ~isempty(strfind(exeCmd,filesep))
        SplitCmd = regexp(exeCmd, ' ', 'split') ;
        tempCmd = SplitCmd{1} ; % If there is no space in the path, this should be directly the executable
        if ispc
            dirtest = dir([tempCmd,'.*']) ;
        else
            dirtest = dir(tempCmd) ;
        end
        dircounter = 1 ;
        while isempty(dirtest) && dircounter < length(SplitCmd)
            dircounter = dircounter+1 ;
            tempCmd =  [tempCmd, ' ', SplitCmd{dircounter}] ;
            if ispc
                dirtest = dir([tempCmd,'.*']) ;
            else
                dirtest = dir(tempCmd) ;
            end
        end
        
        % If the executable has been found, replace the executable part of 
        % the command line by the same but adding double quotes around 
        % the path to the executbable.
        if ~isempty(dirtest)
            % This is done by the next two lines, even though intuitively they
            % should be done with regexprer, i.e :
            % tempCmd = regexprep(tempCmd, dirtest.folder, ['"', dirtest.folder,'"']) ;
            Splitexe = regexp(tempCmd, filesep, 'split') ;
            if isunix || ismac
               Splitexe = [filesep Splitexe];
            end
            % Get the folder name (NOTE: WITHOUT using the property
            % dirtest.folder that is introduced in recent versions of
            % matlab)
            % We will then recombine Splitexe by letting out the last term
            exeFolderName = Splitexe{1} ;
            if length(Splitexe) > 1  % Just safeguarding for unforeseen cases...
                for mm = 2:length(Splitexe) - 1  ;
                   exeFolderName = fullfile(exeFolderName, Splitexe{mm}) ; 
                end
            end
            % Eventually add the double quotes around the folder name
            exeCmd = fullfile(['"',exeFolderName,'"'],Splitexe{end}) ;
            % Now add the remaining parts of the
            while dircounter < length(SplitCmd)
                dircounter = dircounter+1 ;
                exeCmd = [exeCmd, ' ', SplitCmd{dircounter}] ;
            end
        end
    end
    
    % Modify the input file name in the command line
    for tt = 1:length(inputfilename)
        % First look for the input file name with extension  in the command line
        modified_exeCmd = regexprep(exeCmd, strcat( P.Runtime.InputFileName{tt} ...
            , '.',P.Runtime.InputExtension{tt}), strcat(inputfilename{tt}, '.',P.Runtime.InputExtension{tt} ));
        % If not found, look for the input file name without extension
        if strcmpi(modified_exeCmd,exeCmd)
            % The input file name was not found, then second option
            exeCmd = regexprep(exeCmd, P.Runtime.InputFileName{tt}, ...
                inputfilename{tt});
        else
            % Found. Rename the command line
            exeCmd = modified_exeCmd ;
        end
    end
    
    % Modify the output file name in the command line
    for tt = 1:length(P.Runtime.OutputFileName)
        outputfilename{tt} = strcat( P.Runtime.OutputFileName{tt}, num2str(ii, P.Runtime.DigitFormat) ) ;
        % First look for the input file name with extension  in the command line
        newexeCmd = regexprep(exeCmd, strcat( P.Runtime.OutputFileName{tt} ...
            , '.',P.Runtime.OutputExtension{tt}), strcat(outputfilename{tt}, '.',P.Runtime.OutputExtension{tt} ));
        
        if ~strcmpi(newexeCmd,exeCmd)
            % The output if found in the exe cmd line.
            % Update the exe cmd and put a flag saying that it was
            exeCmd = newexeCmd ;
            P.Runtime.OutputNotFound = false ;
        end
        % We didn't think about that but if the input and output have the same name
        % then we have to assume that in the command line and they are given
        % without extension, then we are ...
        % Need to check that this does not happen and then add a constraint
        %     % If not found, look for the input file name without extension
        %     if strcmpi(modified_exeCmd,exeCmd)
        %         % The input file name was not found, then second option
        %         exeCmd = regexprep(exeCmd, P.Runtime.OutputFileName{tt}, ...
        %             outputfilename{tt});
        %     else
        %         % Found. Rename the command line
        %         exeCmd = modified_exeCmd ;
        %     end
    end
    % Create a new command that also include cd to execution path
    % Note that the command includes double quotes around the main quote
    if ispc
        % add /d to force drive change if necessary: cd /d C: ...
        exeCmd_with_cd = ['cd /d "', P.ExecutionPath, '" && ', exeCmd] ;
    else
        exeCmd_with_cd = ['cd "', P.ExecutionPath, '" && ', exeCmd] ;
    end
    
    % Just before execution, list all files that are in the execution path
    if isempty(P.ExecutionPath)
        dummy = dir(pwd) ;
    else
        dummy = dir(P.ExecutionPath);
    end
    Files_at_T0 = {dummy.name} ;
    
    % Execute command
    try
        if strcmpi(P.Display,'verbose')
            status_run = system(exeCmd_with_cd, '-echo') ;
        else
            dummy_catch = evalc('status_run = system(exeCmd_with_cd) ;') ;
        end
        % Check that the third-party software did not return an error
        if status_run ~= 0
            warning('Third party software returned an error for run #%d \n: Returning NaN in the corresponding output',ii) ;
            
            exesuccessfull = false ;
        else
            exesuccessfull = true ;
        end
    catch ME
        warning('Problem executing the third party software for run #%d \n: Returning NaN in the corresponding output',ii) ;
        exesuccessfull = false ;
    end
    % after execution, check all the new list of files in the execution folder
    if isempty(P.ExecutionPath)
        dummy = dir(pwd) ;
    else
        dummy = dir(P.ExecutionPath);
    end
    Files_at_T1 = {dummy.name} ;
    
    % Name of the output file
    for tt = 1: length(outputfilename)
        outputfile{tt} = fullfile(P.ExecutionPath,strcat(outputfilename{tt}, '.',P.Runtime.OutputExtension{tt} )) ;
    end
    
    % Now if the output file name was not found either in the command line
    % or in the input file:
    % - Option 1: Assume that the third-party software will automatically
    % generate an ouptut file with the same name as the input file, i.e. by
    % adding a numeric counter. So check for this file. If it does not
    % exist, go for option 2
    % - Option 2: If the name automatically assigned by uqlab does not
    % exist, consider the output file name to be exactly what was given by
    % the user.
    if P.Runtime.OutputNotFound
        for tt = 1: length(outputfilename)
            outputfile{tt} = fullfile(P.ExecutionPath,strcat(outputfilename{tt}, '.',P.Runtime.OutputExtension{tt} )) ;
            if ~exist(outputfile{tt}, 'file')
                outputfile{tt} = fullfile(P.ExecutionPath, P.Output.FileName{tt}) ;
                P.Runtime.ChangeName{tt} = true ;
            else
                P.Runtime.ChangeName{tt} = false ;
            end
        end
    end
    
    %% 3. Retrieve the results from the external output file
    % Define the full name of the output file, i.e. with the extension
    % If there is only one output file, save the full name as a string
    % otherwise save all the names in a cell array.
    if exesuccessfull
        % Update the ID of the first valid run.
        if firstValidRunID == -1
            firstValidRunID = ii ;
        end
        
        % Handle of the readoutput function
        fHandle = P.Output.Parser ;
        
        % If the output is a scalar or a vector just store it in the ii-th row
        % of Y. Otherwise (\eg output is a matrix), handle each output
        % separately by putting it in a cell
        if length(outputfile) == 1
            [outCurr{1:num_of_out_args}]  = fHandle(outputfile{1}) ;
        else
            [outCurr{1:num_of_out_args}]  = fHandle(outputfile) ;
        end
        % once the first valid output is found, update the size of the outputs
        % This only happens when we are not in recovery or resume mode
        if TrueSizeisNotknown && isempty(action)
            for oo = 1:num_of_out_args
                outputsize(oo)= size(outCurr{oo},2) ;
            end
            TrueSizeisNotknown = false ;
        end
        % Prepare results to be saved for processing up to now
        uq_ProcessedX(ii,:) = X(ii,:) ;
        % Now if the first valid ID > 1 , this means all other previous results
        % should be NaN of appropriate size. So Simply re-write all the values
        % up to now with the appropriate size
        if firstValidRunID > 1 && reshapeMat && isempty(action)
            if num_of_out_args > 1
                for oo = 1:num_of_out_args
                    % Create names for the output in the saved .mat file:
                    % uq_ProcessedY1, uq_ProcessedY2, uq_ProcessedY3, etc...
                    processedY_name = sprintf('uq_ProcessedY%d',oo);
                    % Assign value to each Processed name
                    eval([processedY_name,' = NaN * ones(ii-1,outputsize(oo));']) ;
                end
            else
                uq_processedY = NaN * ones(ii-1,outputsize(oo)) ;
            end
            reshapeMat = false ;
        end
        % Now add the next iteration to the results
        if num_of_out_args > 1
            for oo = 1:num_of_out_args
                % Create names for the output in the saved .mat file:
                % uq_ProcessedY1, uq_ProcessedY2, uq_ProcessedY3, etc...
                processedY_name = sprintf('uq_ProcessedY%d',oo);
                % Assign value to each Processed name
                eval([processedY_name,'(ii,:) = outCurr{oo};']) ;
            end
        else
            uq_ProcessedY(ii,:) = outCurr{1} ;
        end
    else
        % Retrun NaN to outCurr and
        % Prepare results to be saved for processing up to now
        uq_ProcessedX(ii,:) = X(ii,:) ;
        if num_of_out_args > 1
            for oo = 1: num_of_out_args
                % Create names for the output in the saved .mat file:
                % uq_ProcessedY1, uq_ProcessedY2, uq_ProcessedY3, etc...
                processedY_name = ['uq_ProcessedY',num2str(oo)];
                % Assign value to each Processed name
                eval([processedY_name,'(ii,:) = NaN * ones(1,outputsize(oo));']) ;
                
                % Asssign NaN to the current failed simulation
                outCurr{oo} = NaN * ones(1,outputsize(oo)) ;
            end
        else
            uq_ProcessedY(ii,:) = NaN * ones(1,outputsize) ;
        end
    end
    % Concatenate all the results to be returned
    if firstValidRunID > 1 && reshapeoutFull && isempty(action)
        for oo = 1:num_of_out_args
            outFull{oo} = repmat(outFull{oo},1,outputsize(oo)) ;
        end
        reshapeoutFull = false ;
    end
    outFull = cellfun(@(x1,x2)cat(1,x1,x2),outFull,outCurr,...
        'UniformOutput',0);
    % Save currently processed results
    if num_of_out_args > 1
        save(P.Runtime.Processed , 'uq_ProcessedX','-append') ;
        % Now loop and save each ofthe variables
        for oo = 1:num_of_out_args
            eval(sprintf('save(P.Runtime.Processed , ''uq_ProcessedY%d'', ''-append'');', oo)) ;
        end
        
    else
        save(P.Runtime.Processed , 'uq_ProcessedX','uq_ProcessedY','-append') ;
    end
    %% 4. Managing the resulting files
    switch (P.Archiving.Action)
        case 'save'
            % The generated input and output files will be saved
            % Move input file
            for tt = 1:length(inputfile)
                movefile(inputfile{tt},InputFolder) ;
            end
            
            % Move output files
            for tt = 1:length(outputfile)
                % If the name was not found anywhere
                if P.Runtime.OutputNotFound && P.Runtime.ChangeName{tt}
                    % First rename the output to give it a new name
                    % with counter
                    newoutputfile{tt} =  strcat(outputfilename{tt}, '.',P.Runtime.OutputExtension{tt} ) ;
                    if exist(outputfile{tt}, 'file')
                        try
                            movefile( outputfile{tt},fullfile(OutputFolder,newoutputfile{tt})) ;
                        catch
                            % do nothing
                        end
                    end
                else
                    if exist(outputfile{tt},'file')
                        % Not usre the try is necessary here as there is a
                        % condition before the movefile is called
                        try
                            movefile(outputfile{tt},OutputFolder) ;
                        catch
                            % do nothing
                        end
                    end
                end
            end
            
            % Move the auxiliary files
            % First get the list of all new files
            newfiles = setdiff(Files_at_T1, Files_at_T0) ;
            % Now remove from that list the output files as they have
            % already been moved
            for tt = 1:length(outputfilename)
                if P.Runtime.OutputNotFound && P.Runtime.ChangeName{tt}
                    newfiles = setdiff(newfiles,{P.Output.FileName{tt}}) ;
                else
                    newfiles = setdiff(newfiles,{strcat(outputfilename{tt}, '.',P.Runtime.OutputExtension{tt} )}) ;
                end
            end
            % Finally move the remaining files, \ie those that have been
            % created during execution, to AuxFolder ;
            for tt = 1:length(newfiles)
                try
                    % Create a subfolder with the run number to put the
                    % corresponding 
                    CurrentRunAuxFolder = fullfile(AuxFolder,sprintf('Run_%06u',ii));
                    if tt == 1 % Only create the folder at the first run
                    mkdir(CurrentRunAuxFolder) ;
                    end
                    movefile(fullfile(P.ExecutionPath,newfiles{tt}),CurrentRunAuxFolder);
                catch
                    % do nothing
                end
            end
            
        case 'delete'
            newfiles = setdiff(Files_at_T1, Files_at_T0) ;
            for tt = 1:length(newfiles)
                try
                    delete(fullfile(P.ExecutionPath,newfiles{tt}));
                catch
                    % do nothing
                end
            end
            % Delete the input files(s) now
            for tt=1:length(inputfile)
                try
                    delete(inputfile{tt}) ;
                catch
                    % do nothing
                end
            end
            
        case 'ignore'
            % Well, ignore
    end
    
    
    
end

% Now create the zip file, if asked by the user
% Zip folder if asked by the user
if P.Archiving.Zip
    zip(SaveFolder, SaveFolder) ;
    % Now delete the original folders
    rmdir(SaveFolder, 's') ;
end
% Return the results
if num_of_out_args == 1
    varargout{1} = uq_ProcessedY ;
else
    for oo = 1 : num_of_out_args
        eval(sprintf('varargout{oo} = uq_ProcessedY%d ;',oo)) ;
    end
end