function currSSE = uq_SSE_calculate_single(currentModel)
% UQ_SSE_CALCULATE_SINGLE(CURRENTMODEL) calculates a SSE metamodel for a
%     single output as specified in CURRENT_MODEL
%
%     currSSE = UQ_SSE_CALCULATE_SINGLE(CURRENTMODEL)
%     returns the calculated SSE
%
% See also: 

%% Pass options and initialize SSE
oo = currentModel.Internal.Runtime.currentOutput;
SSEProperties = currentModel.Internal.SSE(oo);
Input = currentModel.Internal.NonConstInput;

% experimental design
ExpDesign = currentModel.ExpDesign;
if isfield(ExpDesign,'Y')
    ExpDesign.Y = currentModel.ExpDesign.Y(:,oo);
end

% runtime
Runtime = currentModel.Internal.Runtime;

% full model
if isfield(currentModel.Internal, 'FullModel')
    FullModel = currentModel.Internal.FullModel;
else
    FullModel = [];
end

% call constructor
currSSE = sseClass(SSEProperties, Input, ExpDesign, FullModel, Runtime);

%% calculate SSE

% refine SSE
while currSSE.Runtime.continue
    % refine SSE
    currSSE = refine(currSSE);
end

% check if flatten and flatten
if SSEProperties.PostProcessing.Flatten
    currSSE = uq_SSE_flatten(currSSE);
end

% check if compute output moments and compute them
if SSEProperties.PostProcessing.OutputMoments
    currSSE.Moments = uq_SSE_outputMoments(currSSE);
end
end