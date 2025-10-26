function [Y_class,Y_svc] = uq_SVC_eval( X0, module )
% UQ_SVC_EVAL(CURRENT_MODEL,X0) evaluates the response of the SVC
% metamodel CURRENT_MODEL onto the vector of inputs X0
%
% Y = UQ_SVC_EVAL(...) returns the SVC class prediction
% [Y_class, Y_svc] = UQ_SVC_EVAL(...) returns the SVC class prediction and
% SVC continous output

%
% See also: UQ_SVC_CALCULATE, UQ_EVAL_UQ_METAMODEL, UQ_KRIGING_EVAL,
% UQ_SVR_EVAL

% do nothing if X0 is empty

%% session retrieval, argument and consistency checks
% do nothing if X is empty
if isempty(X0)
    Y_class = [] ;
    Y_svc = [];
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
% Number of output
Nout = current_model.Internal.Runtime.Nout;


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
% Initialize predictor output
Y_class = zeros(N0,Nout) ;
Y_svc = zeros(N0,Nout) ;

% cycle through each output
for oo = 1 : Nout
    %% Get the training points
    if KeepOnlySvs
        Xtrain = current_model.ExpDesign.U(current_model.SVC(oo).Coefficients.SVidx,:);
    else
        Xtrain = current_model.ExpDesign.U;
    end
    Xtrain = Xtrain(:,nonConstIdx);
    Ntrain = size(Xtrain, 1) ;

    Yval = zeros(1,N0) ;
    Yclass = ones(1,N0) ;
    if KeepOnlySvs
        beta = current_model.SVC(oo).Coefficients.beta(current_model.SVC.Coefficients.SVidx,:) ;
    else
        beta = current_model.SVC(oo).Coefficients.beta ;
    end
    b = current_model.SVC(oo).Coefficients.bias;
    % Calculate Kernel
    KerOptions = current_model.Internal.SVC(oo).Kernel ;
    evalK_handle = KerOptions.Handle ;

    theta = current_model.SVC(oo).Hyperparameters.theta;
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
            Kpred = evalK_handle( Xtrain, U0( :, CurrentEvals + 1 : CurrentEvals + BatchSize).', theta, KerOptions);
            Yval( 1, CurrentEvals + 1 : CurrentEvals + BatchSize ) = transpose(beta) * Kpred + b ;
            
            % Update the number of sampled already evaluated
            CurrentEvals = CurrentEvals + BatchSize ;
            % Update the numero of the loop
            LoopNo = LoopNo + 1 ;
            if CurrentEvals >= N0; break; end;
        end
    else
        Kpred = evalK_handle( Xtrain, U0.', theta, KerOptions);
        % Calculate Prediction
        Yval = transpose(beta) * Kpred + b ;
    end
    
    Yclass(Yval < 0) = -1;
    Y_class(:,oo) = Yclass' ;
    if nargout > 1
        Y_svc(:,oo) = Yval' ;
    end
end
% end
end