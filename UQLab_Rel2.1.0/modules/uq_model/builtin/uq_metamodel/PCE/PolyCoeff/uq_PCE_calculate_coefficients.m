function success = uq_PCE_calculate_coefficients(current_model)
% success = UQ_PCE_CALCULATE_COEFFICIENTS(CURRENT_MODEL): calculate
%     the coefficients of the PCE specified in CURRENT_MODEL
%
% See also: UQ_PCE_CALCULATE_COEFFICIENTS_PROJECTION,
% UQ_PCE_CALCULATE_COEFFICIENTS_REGRESSION

%% INPUT AND CONSISTENCY CHECKS
% Check that the model is of type "uq_metamodel"
if ~strcmp(current_model.Type, 'uq_metamodel')
    success = 0;
    error('Error: uq_metamodel cannot handle objects of type %s', current_model.Type);
end

% Verbosity level
DisplayLevel = current_model.Internal.Display;

%% CALCULATE THE COEFFICIENTS ACCORDING TO THE OPTIONS
% The available methods are the following
% OLS- Ordinary Least Squares regression 
% LARS - Least Angle Regression
% QUADRATURE - Gaussian quadrature
% OMP - Orthogonal Matching Pursuit

% Loop over the number of output variables
oo = 1;
% the number of output variables is filled in automatically as soon as the
% experimental design is available
while ~isfield(current_model.Internal.Runtime, 'Nout') || oo <= current_model.Internal.Runtime.Nout 
    % update the index of the current output that is used in vector evaluation
    current_model.Internal.Runtime.current_output = oo;
    % calculate the coefficients depending on the method
    switch lower(current_model.Internal.Method) 
        case {'quadrature'}
            if DisplayLevel
                fprintf('---    Calculating the PCE coefficients with quadrature.     ---\n')
            end
            uq_PCE_calculate_coefficients_projection(current_model);
            if DisplayLevel
                fprintf('---                 Calculation finished!                           ---\n')
            end
            
        otherwise
            if DisplayLevel
                fprintf('---   Calculating the PCE coefficients by regression.   ---\n')
            end
            uq_PCE_calculate_coefficients_regression(current_model);
            if DisplayLevel
                fprintf('---                 Calculation finished!                               ---\n')
            end
    end
    
    % after the loop over the variables is done, set some variables that will be used for
    % polynomial evaluation
    if isfield(current_model.Internal.PCE(oo), 'BestDegree')
        current_model.Internal.PCE(oo).MaxDegree = max(current_model.Internal.PCE(oo).BestDegree);
        current_model.Internal.PCE(oo).Degree = current_model.Internal.PCE(oo).MaxDegree;
    else
        current_model.Internal.PCE(oo).MaxDegree = current_model.Internal.PCE(oo).Degree;
    end
    
    Nout = current_model.Internal.Runtime.Nout;
    if Nout > 1
        if DisplayLevel >= 2;
            % add a progress bar on the outputs if requested
            if oo == 1
                wb = waitbar(0,'Calculating PCE coefficients...');
            end
            waitbar(oo/current_model.Internal.Runtime.Nout, wb);
        end
    end
    
    % Store extra information if available, like total variance, maximum
    % effective degree, etc.
    for ii = 1:size(current_model.PCE(oo).Basis.Indices,2)
        % maximum degree for each component
        nnz_coeff = current_model.PCE(oo).Coefficients ~= 0;
        % if there is at least a non-zero coefficient, compute basis
        % summary
        if sum(nnz_coeff)
            current_model.PCE(oo).Basis.MaxCompDeg(ii) = full(max(current_model.PCE(oo).Basis.Indices(nnz_coeff,ii)));
            current_model.PCE(oo).Basis.MaxInteractions = full(max(sum(current_model.PCE(oo).Basis.Indices(nnz_coeff,:) > 0,2)));
        else
            current_model.PCE(oo).Basis.MaxCompDeg(ii) = 0;
            current_model.PCE(oo).Basis.MaxInteractions = 0;
        end
        
    end
    
    current_model.PCE(oo).Basis.Degree = full(max(sum(current_model.PCE(oo).Basis.Indices,2)));
    current_model.PCE(oo).Basis.qNorm = current_model.Internal.PCE(oo).Basis.Truncation.qNorm;
    % moments
    current_model.PCE(oo).Moments.Mean = current_model.PCE(oo).Coefficients(1);
    current_model.PCE(oo).Moments.Var = sum(current_model.PCE(oo).Coefficients(2:end).^2);
    
    % proceed to the next output
    oo = oo + 1;
end

% Close the progress bar if it exists
if exist ('wb', 'var')
    close(wb);
end

success = 1;