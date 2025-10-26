function runIndices = uq_UQLink_helper_getRunIndices(InternalProp)
%uq_UQLink_helper_getRunIndices gets the indices of realizations to run.

%% Get the indices based on action
action = InternalProp.Runtime.Action;

switch action
    
    case 'default'
        counterOffset = InternalProp.Counter.Offset;
        X = InternalProp.Runtime.X;
        nTotal = size(X,1);
        runIndices = getRunIndicesDefault(counterOffset,nTotal);

    case 'recover'
        processedY = InternalProp.Runtime.ProcessedY;
        selectedRunIndices = InternalProp.Runtime.SelectedRunIndices;
        runIndices = getRunIndicesRecover(processedY,selectedRunIndices);
        
    case 'resume'
        X = InternalProp.Runtime.X;
        nTotal = size(X,1);
        processedX = InternalProp.Runtime.ProcessedX;
        nProcessed = size(processedX,1);
        runIndices = getRunIndicesResume(nProcessed,nTotal);

end

end


%% ------------------------------------------------------------------------
function runIndices = getRunIndicesDefault(counterOffset,nTotal)

runIndices = (counterOffset+1):(counterOffset+nTotal);
 
end


%% ------------------------------------------------------------------------
function runIndices = getRunIndicesRecover(processedY,selectedIndices)

if ~isempty(selectedIndices)
    % Indices given explicitly
    runIndices = selectedIndices;
else
    % Look for NaN in the processed output
    nProcessed = size(processedY{1},1);
    runIndices = 1:nProcessed;
    nanIdx = any(arrayfun(@(X) isnan(X), processedY{1}),2);
    runIndices = runIndices(nanIdx);
end

end


%% ------------------------------------------------------------------------
function runIndices = getRunIndicesResume(nProcessed,nTotal)

runIndices = (nProcessed+1):(nTotal);    

end
