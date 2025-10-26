function varargout = uq_getSample(varargin)
% UQ_GETSAMPLE get a sample from the current INPUT object
%    X = UQ_GETSAMPLE(N) draws a sample of size N from the currently
%    selected UQLab INPUT object. Note that size(X) = [N M], where M is the
%    dimension of the input space.
%
%    X = UQ_GETSAMPLE(myInput,N) draws a sample of size N from the INPUT object
%    myInput  
%
%    X = UQ_GETSAMPLE(..., METHOD) use the specified METHOD to draw samples
%    from the input objects. 
%    METHOD is one of the following strings:
%    'MC'     - Standard Monte Carlo sampling
%    'LHS'    - Latin hypercube sampling (space filling)
%    'Sobol'  - Sobol' pseudorandom sequence
%    'Halton' - Halton pseudorandom sequence
%
%    See also: uq_createInput, uq_selectInput, uq_getInput
%
%    For a list of all available sampling methdos and options, please
%    consult the INPUT User Manual (<a href="matlab:uq_doc('input','html')">HTML</a>,<a href="matlab:uq_doc('input','pdf')">PDF</a>)


% step 1: figure out whether the first argument is of type uq_model. If it
% is, define a 'module' argument to be used in the rest
if nargin && isa(varargin{1}, 'uq_input')
    module = varargin{1};
    varargin = varargin(2:end);
end


% if no module is specified, retrieve the current session and run the default analysis
if exist('module', 'var') 
    current_input = uq_getInput(module);
else
    % retrieve the current session's module
    current_input = uq_getInput;
end

% Execute the relevant module call with proper error handling
try 
    [varargout{1:nargout}] = current_input.getSample(current_input,varargin{:});
catch uqException
    uq_error(uqException);
end



