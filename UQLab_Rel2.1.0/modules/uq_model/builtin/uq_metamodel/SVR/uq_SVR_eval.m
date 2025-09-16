function Y = uq_SVR_eval( X0, module )
% UQ_SVR_EVAL(CURRENT_MODEL,X0) evaluates the response of the SVR
% metamodel CURRENT_MODEL onto the vector of inputs X0
%
% Y = UQ_SVR_EVAL(...) returns the SVR predcition
%
%
% See also: UQ_SVR_CALCULATE, UQ_EVAL_UQ_METAMODEL, UQ_KRIGING_EVAL,
% UQ_SVC_EVAL

% do nothing if X0 is empty

%% session retrieval, argument and consistency checks
% do nothing if X is empty
if isempty(X0)
    Y = [];
    return;
end

uq_retrieveSession;

% if the module is not specified on the command line, retrieve the default
if exist('module', 'var')
    if ischar(module)
        current_model = UQ.model.get_module(module);
    elseif isobject(module)
        current_model = module;
    end
else
    current_model = UQ_model;
end

% These options can be pushed to the user level
MaxKernelMatrixSize = 1e5;
KeepOnlySvs = false ;

% get dimensions of X0
M0 = size(X0,1);
% make sure that X0 dimensions are consistent with the experimental design
if M0 ~= current_model.Internal.Runtime.M
    error('Inconsistent dimensions of supplied input with respect to the experimental design!')
end

%% Make sure that current_model is calculated
if  ~current_model.Internal.Runtime.isCalculated
    uq_calculateMetamodel(current_model);
end

%% Map X0 to the appropriate space to get U0
SCALING = current_model.Internal.Scaling;
SCALING_BOOL = isa(SCALING, 'double') || isa(SCALING, 'logical') || isa(SCALING, 'int');
        
if SCALING_BOOL && SCALING
    muX = current_model.Internal.ExpDesign.muX;
    sigmaX = current_model.Internal.ExpDesign.sigmaX;
    U0 = bsxfun(@rdivide,(bsxfun(@minus,X0,muX.')), sigmaX.');
elseif SCALING_BOOL && ~SCALING
    U0 = X0;
end

if ~SCALING_BOOL
    % In that case SCALING is an INPUT object. An isoprobabilistic
    % transform is performed from:
    % current_model.Internal.Input
    % to:
    % current_model.Internal.Scaling
    
    U0 =  uq_GeneralIsopTransform(X0,...
        current_model.Internal.Input.Marginals, current_model.Internal.Input.Copula,...
        SCALING.Marginals, SCALING.Copula);
end



%% filter out the constants from the experimental design
nonConstIdx = current_model.Internal.Runtime.nonConstIdx;
U0 = U0(nonConstIdx,:);
N0 = size(U0,2);
N = size(current_model.ExpDesign.Y, 1);
% Retrieve necessary quantities
Nout = current_model.Internal.Runtime.Nout;
% Initialize predictor output
Y = zeros(Nout,N0) ;

% cycle through each output
for oo = 1 : Nout
    %% Get training points
    if KeepOnlySvs
        Xtrain = current_model.ExpDesign.U(current_model.SVR(oo).Coefficients.SVidx,:);
    else
        Xtrain = current_model.ExpDesign.U;
    end
    Xtrain = Xtrain(:,nonConstIdx);
    Ntrain = size(Xtrain, 1) ;
    alpha = current_model.SVR(oo).Coefficients.alpha ;
    a_star = alpha(1:N,:);
    a = alpha(N+1 : 2*N,:);
    b = current_model.SVR(oo).Coefficients.bias;
    % Calculate Kernel
    KerOptions = current_model.Internal.SVR(oo).Kernel ;
    evalK_handle = KerOptions.Handle ;
    theta = current_model.SVR(oo).Hyperparameters.theta;

    
    % Now create sub groups to avoid storing an extremely large kernel
    % matrix
    if Ntrain * N0 > MaxKernelMatrixSize
        BatchSize = ceil(MaxKernelMatrixSize / Ntrain) ;
        CurrentEvals = 0 ;
        LoopNo = 1 ;
        while 1
            if CurrentEvals + BatchSize > N0
                % Decrease the batch size, so CurrentEvals won't N0:
                BatchSize = N0 - CurrentEvals;
            end
            %<TRANSPOSE>
            Kpred = evalK_handle( Xtrain, U0( :, CurrentEvals + 1 : CurrentEvals + BatchSize).', theta, KerOptions);
            % Calculate Prediction
            Y(oo, CurrentEvals + 1 : CurrentEvals + BatchSize) = transpose(-a + a_star) * Kpred + b ;
            
            % Update the number of sampled already evaluated
            CurrentEvals = CurrentEvals + BatchSize ;
            % Update the numero of the loop
            LoopNo = LoopNo + 1 ;
            if CurrentEvals >= N0; break; end;
        end
    else
        %<TRANSPOSE>
        Kpred = evalK_handle( Xtrain, U0.', theta, KerOptions);
        % Calculate Prediction
        Y(oo,:) = transpose(-a + a_star) * Kpred + b ;
    end
end

%%
% Transform back to original space if output scaling was enabled
if current_model.Internal.SVR(1).OutputScaling == 1
    for oo = 1 : Nout
        Y(oo,:) = Y(oo,:) * current_model.Internal.Runtime.stdY(:,oo) + ...
            current_model.Internal.Runtime.muY(:,oo) ;
    end
end