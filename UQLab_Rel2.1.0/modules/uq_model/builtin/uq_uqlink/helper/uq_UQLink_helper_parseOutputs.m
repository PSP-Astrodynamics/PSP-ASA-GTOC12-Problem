function [parsedOutputs,InternalProp] = uq_UQLink_helper_parseOutputs(...
    exeSuccess, outputFiles, InternalProp)
%UQ_UQLINK_HELPER_PARSEOUTPUTS parses the outputs of the current run index.
%
%   Inputs
%   ------
%   - exeSuccess: Flag indicating the execution is successful, logical
%   - outputFiles: List of output files, cell array
%   - InternalProp: Internal properties of UQLink object, struct
%       The current run index is stored in the 'Runtime' field of
%       'InternalProp'.
%
%   Outputs
%   -------
%   - parsedOutputs: parsed outputs, cell array
%       the number of elements in parsedOutputs is the same as the number
%       of elements in outputFiles.
%   - InternalProp: Internal properties of UQLink object, struct
%       Assigning this struct to the output will update it by updating the
%       fields 'TrueSizeisNotknown', 'FirstValidRunID', and 'OutputSizes'.

%% Set local variables (shortwriting)
% Use raw index here, not run index because when dispatched, each process
% will evaluate a sliced array. For example, Process #2 might evaluate
% runIdx = [31 32 33], if raw index is not used then the first valid run
% index will be taken as 31 instead of 1.
rawIdx = InternalProp.Runtime.RawIdx;
numOfOutArgs = InternalProp.Runtime.NumOfOutArgs;

%% Parse Current Output
if exeSuccess
    % Update the ID of the first valid run index
    if InternalProp.Runtime.FirstValidRunIdx == -1
        InternalProp.Runtime.FirstValidRunIdx = rawIdx;
    end

    % Handle of the read output function
    parserHandle = InternalProp.Output.Parser;

    parsedOutputs = uq_UQLink_util_parseOutputs(...
        outputFiles, parserHandle, numOfOutArgs);

    if strcmpi(InternalProp.Runtime.Action,'default')

        % Once the first valid output is found, update the size of the 
        % outputs, but only in 'default' action.
        if InternalProp.Runtime.TrueSizeIsNotKnown
            % Use cellfun to get the number of columns of each output
            InternalProp.Runtime.OutputSizes = cellfun(...
                @(X) size(X,2), parsedOutputs);
            InternalProp.Runtime.TrueSizeisNotknown = false;
        end

    end

else
    % Return NaN as ouputs
    parsedOutputs = uq_UQLink_util_returnNaN(...
        InternalProp.Runtime.OutputSizes);
end

end
