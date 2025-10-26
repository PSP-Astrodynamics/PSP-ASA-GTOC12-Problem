function varargout = uq_runAnalysis(varargin)
% uq_runAnalysis: run the currently selected analysis in UQLab
% uq_runAnalysis(MODULE): run the analysis specified by module MODULE

% step 1: figure out whether the first argument is of type uq_model. If it
% is, define a 'module' argument to be used in the rest
if nargin && isa(varargin{1}, 'uq_analysis')
    module = varargin{1};
    varargin = varargin(2:end);
end


% if no module is specified, retrieve the current session and run the default analysis
if exist('module', 'var')
    current_analysis = uq_getAnalysis(module);
  else
    current_analysis = uq_getAnalysis;
end

if isempty(current_analysis)
    error('No Analysis defined!');
end

% This is run analysis: it will remove all of the existent results first
current_analysis.Results = [];

% and then run the analysis for the first time
try
    [varargout{1:nargout}] = current_analysis.run(current_analysis, varargin{:});
catch uqException
    uq_error(uqException);
end
