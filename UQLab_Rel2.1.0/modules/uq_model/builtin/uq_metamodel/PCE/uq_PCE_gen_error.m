function [results] = uq_PCE_gen_error(Y, Y_PCE, options)

% UQ_PCE_GEN_ERROR(Y, Y_PCE)
% calculates the generalization error using the normalized empirical error
% See UQLab PCE Manual for additional information
%
% Function allows to compute the generalization error for each sample 
% separately
% Options: 
%   'single':   can be set to 0 or 1 (default 0), computes the relative
%               generalization error using the normalized empirical 
%               error for each sample separately

%% Check for options
% Set default options
single = 0;
variance = 0;

% Check for passed options
if exist('options','var')
    % Check for single sample output option
    if isfield(options','single')
        single = options.single; 
    end
    
    % Check if variance is requested
    if isfield(options,'variance')
        variance = options.variance; 
    end
end

%% Check for size of both inputs
if size(Y,1)~=size(Y_PCE,1)
    % Check that both are passed as column arrays
    Y = Y(:);
    Y_PCE = Y_PCE(:);
    if numel(Y)~=numel(Y_PCE)
        disp('Arrays do not contain the same number of samples');
    end
end

% Retrieve number of elements 
N = numel(Y);

%% Compute the generalization error
% Compute the variance of the true function
varY = var(Y,1);        % Normalized by N

% Compute the squared error
% Check if the user wants single sample output
if single
    % Compute the squared error for each sample separately
    Squared_Error = (Y - Y_PCE).^2;
else
    Squared_Error = 1/N*(Y - Y_PCE)'*(Y - Y_PCE); 
end

%% Check if variance output also requested
if variance
    results.Variance = varY; 
    results.NormEmpErr = Squared_Error / varY; 
else
    results = Squared_Error / varY;
end

