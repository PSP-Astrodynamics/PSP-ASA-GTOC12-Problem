function uq_UQLink_helper_updateProcessedFile(currentX, currentY, InternalProp)
%UQ_UQLINK_UTIL_SAVEOUTPUTS updates the processed file with the inputs and
%   outputs of the current iteration.
%
%   Inputs
%   ------
%   - currentX: Input (X) at the current iteration, numeric array
%   - currentY: Outputs (Y) at the current iteration, cell array
%   - InternalProp: Internal property of UQLink MODEL object, struct
%
%   Output
%   ------
%       None

%% Open the processed file
processedMAT = matfile(...
    InternalProp.Runtime.ProcessedFile, 'Writable', true);

%% Set local runtime variable
runIdx = InternalProp.Runtime.RunIdx;

%% Update the file with the current input (X)
if any(ismember(fieldnames(processedMAT),'uq_ProcessedX'))
    processedMAT.uq_ProcessedX(runIdx,:) = currentX;

else
    processedMAT.uq_ProcessedX = currentX;
end

%% Update the file with the current output (Y)
if InternalProp.Runtime.NumOfOutArgs > 1
    % Now loop and save each of the variables
    for oo = 1:InternalProp.Runtime.NumOfOutArgs
        % For backward compatibility, in the case of multiple outputs, the
        % variable names are: 'uq_ProcessedY1', 'uq_ProcessedY2', etc.
        fname = sprintf('uq_ProcessedY%d',oo);
        if any(ismember(fieldnames(processedMAT),fname))
            processedMAT.(fname)(runIdx,:) = currentY{oo};

        else
            processedMAT.(fname) = currentY{oo};
        end
    end

else
    % Only a single output
    if any(ismember(fieldnames(processedMAT),'uq_ProcessedY'))
        processedMAT.uq_ProcessedY(runIdx,:) = currentY{1};
    else
        processedMAT.uq_ProcessedY = currentY{1};
    end
end
    
end
