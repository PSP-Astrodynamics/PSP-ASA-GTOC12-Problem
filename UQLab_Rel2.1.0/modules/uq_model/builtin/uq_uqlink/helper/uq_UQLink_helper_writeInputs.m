function uq_UQLink_helper_writeInputs(X,InternalProp)
%UQ_UQLINK_HELPER_WRITEINPUTS writes the inputs for the current realization
%   based on a set of templates.

%% Set local runtime variables
runIdx = InternalProp.Runtime.RunIdx;

%% 1. create external input file corresponding to ii_th realization
% Define the input file name for each run of the code. By convention if
% the template is e.g. myInput.inp.tpl, then for each run we will have
% myInput000001.(dat, or whatever InputExtension), myInput000002,...,
% myInput000010, etc. (by default the number of digits is 6 but
% this is an option th euser can set)
inputfilename = strcat(InternalProp.Runtime.InputFileName,...
    num2str(runIdx,InternalProp.Runtime.DigitFormat));
inputfile = fullfile(InternalProp.Runtime.RunDirIdx,...
    strcat(inputfilename, '.', InternalProp.Runtime.InputExtension));

for tt = 1:length(InternalProp.Template)
    
    % Open for reading the template file
    % TODO use template path!!
    templateFile = fullfile(...
        InternalProp.Runtime.TemplatePath, InternalProp.Template{tt});
    ftemp = fopen(templateFile,'r');

    % TODO: This should have been decided during initialization
    if ftemp < 0
        error('Error : template file not found! Please provide one.') ;
    end

    finp = fopen(inputfile{tt},'w') ; % open the created file for writing only

    while ~feof(ftemp)  % Read the template until the end of file is reached

        % Catch in a string a current line
        str = fgetl(ftemp);
        str = uq_UQLink_util_parseMarkerSimple(...
            str, X, InternalProp.Marker, InternalProp.Format);
        str = uq_UQLink_util_parseMarkerExpression(...
            str, X, InternalProp.Marker, InternalProp.Format);

        % Replace all occurrences of output filename in the template with
        % the number one.
        outputFilenameIndexed = strcat(...
            InternalProp.Runtime.OutputFileName,...
            num2str(runIdx,InternalProp.Runtime.DigitFormat));
        str = uq_UQLink_util_replaceFilenames(...
            str,...
            InternalProp.Runtime.OutputFileName,...
            outputFilenameIndexed);

        % Copy the current line (possibly modified) of the template file
        % into the new input file
        fprintf(finp,'%s\r\n', str);

    end
    fclose(ftemp);
    status_file = fclose(finp) ; % 0 if ok, -1 if nok
    if status_file ~=0
        error('Something went wrong when closing the new generated input file') ;
    end

end
    
end

