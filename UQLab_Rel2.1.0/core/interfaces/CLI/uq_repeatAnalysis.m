function result = uq_repeatAnalysis(module,N)
% UQ_REPEATANALYSIS(N): repeat the currently selected analysis in UQLab N
% times
% UQ_REPEATANALYSIS(N,ANALYSIS): run the analysis specified in the ANALYSIS
% object

% default to only running the analysis once
if ~exist('N', 'var')
    N = 1;
end


% if no module is specified, retrieve the current session and run the default analysis
if exist('module', 'var')
    current_analysis = uq_getAnalysis(module);
else
    current_analysis = uq_getAnalysis;
end

for ii = 1:N
    run(current_analysis);
end

result = current_analysis;
