function [ errors, additional_metrics] = uq_SVR_calc_leaveKout( current_model )
% UQ_SVR_CALC_LEAVEKOUT performs cross validation and computes some
% associated error

% Get the current output
current_output = current_model.Internal.Runtime.current_output ;
nonConst = current_model.Internal.Runtime.nonConstIdx ;
% Get the training sample
X = current_model.ExpDesign.U(:,nonConst) ;
Y = current_model.ExpDesign.Y(:,current_output) ;

% ED size
N = length(X);

% Number of classes / Number of folds for CV
Nclasses = current_model.Internal.SVR(1).CV.Folds;

evalK_handle = current_model.Internal.SVR(current_output).Kernel.Handle ;
KernelOptions = current_model.Internal.SVR(current_output).Kernel ;
theta = current_model.Internal.Runtime.Kernel.Params ;

%% Split data first here
errors = zeros(Nclasses,1) ;
% Produce the indices of each part that is then going to be treated either
% as a training or a validation set
nElemsPerPart = floor(N/Nclasses) ;
nIndices = repmat(nElemsPerPart, 1 , Nclasses);
nIndices(end) = N - nElemsPerPart * (Nclasses-1) ;

% randomly permute Y (only when it's not K = 1 )
if Nclasses < N
    randInd = randperm(N);
else
    randInd = 1:N;
end
randInd = mat2cell(randInd,1, nIndices );
fullInd = 1:N;

switch nargout
    case {0,1}
        for jj = 1 : Nclasses
            % get the indices of the current training and validation set
            indValidate = randInd{jj} ;
            tidx = true(size(fullInd)) ;
            tidx(indValidate) = false ;
            indTrain = fullInd(tidx) ;
            
            % Training and validation sets
            Xtrain = X(indTrain,:);
            Xtest = X(indTrain,:);
            Ytrain = Y(indTrain ) ;
            Ytest = Y(indValidate) ;
            Ntrain = length(Ytrain);
            
            % Solve the SVR QP problem to get the alpha and bias term
            [alpha,~,lambda,~] = uq_SVR_compute_alphas( Xtrain, Ytrain, current_model ) ;
            a_star = alpha(1:Ntrain,:);
            a = alpha(Ntrain+1 : 2*Ntrain,:);
            beta = a_star - a;
            if isempty(lambda)
                % Meaning we used Matlab solver:
                b = current_model.Internal.Runtime.bias ;
            else
                b = lambda.eqlin(1) ;
            end
            Kpred = evalK_handle( Xtrain, Xtest, theta, KernelOptions);
            % Evaluate the testing set given the found SVR coefficients
            Ypred = beta' * Kpred + b ;
            % Compute the mean square error
            errors(jj) = sum((Ytest - Ypred').^2)/ length(Ytest) ;
        end
        return
    case 2
        MAE = zeros(Nclasses,1) ;
        
        for jj = 1 : Nclasses
            % get the indices of the current training and validation set
            indValidate = randInd{jj} ;
            tidx = true(size(fullInd)) ;
            tidx(indValidate) = false ;  
            indTrain = fullInd(tidx) ;
            
            % Training and validation sets
            Xtrain = X(indTrain,:);
            Xtest = X(indValidate,:);
            Ytrain = Y(indTrain ) ;
            Ytest = Y(indValidate) ;
            Ntrain = length(Ytrain);
            
            % Solve the SVR QP problem to get the alpha and bias term
            [alpha,~,lambda,~] = uq_SVR_compute_alphas( Xtrain, Ytrain, current_model ) ;
            a_star = alpha(1:Ntrain,:);
            a = alpha(Ntrain+1 : 2*Ntrain,:);
            beta = a_star - a;
            if isempty(lambda)
                % Meaning we used Matlab solver:
                b = current_model.Internal.Runtime.bias ;
            else
                b = lambda.eqlin(1) ;
            end
            Kpred = evalK_handle( Xtrain, Xtest, theta, KernelOptions);
            % Evaluate the testing set given the found SVR coefficients
            Ypred = beta' * Kpred + b ;
            
            % Mean square error
            errors(jj) = sum((Ytest - Ypred').^2)/ length(Ytest) ;
            % Mean Absolute error (another metric)
            MAE(jj) = sum( abs(Ytest - Ypred'))/ length(Ytest);
            
        end
        additional_metrics.MAE = mean(MAE);
        additional_metrics.NMSE = mean(errors);
end
end

