function [processedX,processedY,allX,outputSizes] = ...
    uq_UQLink_helper_initProcessedXY(X, action, numOfOutArgs, recoveryFile)
%UQ_UQLINK_HELPER_INITPROCESSEDXY initializes the matrices that contain the
%   input/output (X/Y) processed so far; it can be based on the previous
%   runs from 'recoveryFile'. The function also returns the size of each
%   outputs (i.e., number of columns).

%% empty evaluate action
% Start fresh
if strcmpi(action,'default')
    processedX = [];  % Start fresh
    processedY = [];  % Start fresh
    allX = X;
    outputSizes = uq_UQLink_util_initSizes(numOfOutArgs,processedY);
    return
end

%% 'recover' or 'resume evaluate action
% Get processedX and processedY from 'recoverySourceFile'.

% Explicitly load variables from the recovery source
% 'uq_ProcessedX' (processed X so far)
processedMAT = load(recoveryFile,'uq_ProcessedX');
processedX = cell2mat(struct2cell(processedMAT));
% 'uq_ProcessedY*' (processed Yo's so far)
% Older version saved 'uq_ProcessedY*' individually for each output.
% That is, 'uq_ProcessedY1' for the 1st output, 'uq_ProcessedY2' for 
% the 2nd output, etc.
% Import everything as cell array to avoid using 'eval' statement.
processedMAT = load(recoveryFile,'uq_ProcessedY*');
processedY = struct2cell(processedMAT);
% Use the input X for All X
allX = X;
% Get the output sizes from the processed outputs
outputSizes = uq_UQLink_util_initSizes(numOfOutArgs,processedY);

end
