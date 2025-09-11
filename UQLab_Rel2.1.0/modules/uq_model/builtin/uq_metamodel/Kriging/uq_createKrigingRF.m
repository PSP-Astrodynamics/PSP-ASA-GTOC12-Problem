function status = uq_createKrigingRF(current_model)

%% Get the number of output dimensions
Nout = current_model.Internal.Runtime.Nout ;

% Flag to know whether we are using a custom Kriging or not (custom Kriging
% does not have the field .Internal.Kriging, hence the special treatment)
isNotCustomKriging = ~isfield(current_model.Options,'Kriging');

%% General options
% Options defined by the user (or default for GP)
RFInput = current_model.Internal.GRF ;
RFInput.Type = 'RandomField' ;

% Cycle through each output
for oo = 1:Nout

    %% Options specific to the built GP model
    if current_model.Internal.Regression(oo).IsRegression
        % In case of regression, pass the regression options to the random
        % field
        RFInput.Regression.isRegression = current_model.Internal.Regression(oo).IsRegression;
        RFInput.Regression.isHomoscedastic = current_model.Internal.Regression(oo).IsHomoscedastic;

        % Process (sigmaSQ) and noise variances (sigmaNSQ)
        if isNotCustomKriging
            RFInput.Regression.sigmaSQ = current_model.Kriging(oo).sigmaSQ ;
            RFInput.Regression.sigmaNSQ = current_model.Kriging(oo).sigmaNSQ ;
        else
            RFInput.Regression.sigmaSQ = current_model.Internal.Kriging(oo).GP.sigmaSQ ;
            RFInput.Regression.sigmaNSQ = current_model.Internal.Kriging(oo).sigmaNSQ ;
        end
    end

    % Pass the correlation options (with special treatment for custom
    % Kriging)
    if isNotCustomKriging
        % Specify the correlation family
        RFInput.Corr = current_model.Internal.Kriging(oo).GP.Corr ;
        % Specify the correlation length
        RFInput.Corr.Length = current_model.Kriging(oo).theta ;
    else
        % Specify the correlation family
        RFInput.Corr = current_model.Internal.Kriging(oo).GP.Corr ;
        % Specify the correlation length
        RFInput.Corr.Length = current_model.Options.Kriging(oo).theta ;
    end

    %%
    % Specify the domain of definition of the random field
    RFInput.Domain = current_model.Internal.GRF.Domain ;

    %%
    % Specify the mean and standard deviation of the random field:

    % Zero-mean, the trend will be added later at evaluation time
    RFInput.Mean = 0 ;

    % Unit standard deviation. The latter is directly given in the
    % covariance matrix
    RFInput.Std = 1 ;

    %%
    % Add the Kriging model to the random field options
    RFInput.Model = current_model ;

    %%
    % Create the random field
    if ~isfield(current_model,'Kriging')
        uq_addprop(current_model,'Kriging');
    end
    current_model.Kriging(oo).GRF = uq_createInput(RFInput,'-private') ;

end
status = 1 ;
end