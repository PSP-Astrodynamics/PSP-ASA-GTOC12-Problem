function [ errors, additional_metrics] = uq_SVC_calc_leaveKout( current_model )
% UQ_SVC_CALC_LEAVEKOUT performs cross validation and computes some
% associated error

% Get the current output
current_output = current_model.Internal.Runtime.current_output ;
% Non-constant index
nonConst = current_model.Internal.Runtime.nonConstIdx ;
% Get the training sample
X = current_model.ExpDesign.U(:,nonConst) ;
Y = current_model.ExpDesign.Y(:,current_output) ;

% ED size
N = length(X);

% Number of classes / Number of folds for CV
Nclasses = current_model.Internal.SVC(1).CV.Folds;

evalK_handle = current_model.Internal.SVC(current_output).Kernel.Handle ;
KernelOptions = current_model.Internal.SVC(current_output).Kernel ;
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
            Xtest = X(indValidate,:);
            Ytrain = Y(indTrain ) ;
            Ytest = Y(indValidate) ;
            
            % Solve the SVC QP problem to get the alpha and bias term
            [alpha,~,lambda,~] = uq_SVC_compute_alphas( Xtrain, Ytrain, current_model ) ;
            beta = alpha.*Ytrain;
            if isempty(lambda)
                % Meaning we used Matlab solver:
                b = current_model.Internal.Runtime.bias ;
            else
                b = lambda.eqlin(1) ;
            end
            Kpred = evalK_handle( Xtrain, Xtest, theta, KernelOptions);
            % Evaluate the testing set given the found SVC coefficients
            Yval = transpose(beta) * Kpred + b;
            Yclass = ones(size(Yval));
            Yclass( Yval < 0 ) = -1;
            % Count the number of misclassifications
            errors(jj) = mean(Yclass' .* Ytest < 0) ;
        end
        return
    case 2
        
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
            
            % Solve the SVC QP problem to get the alpha and bias term
            [alpha,~,lambda,~] = uq_SVC_compute_alphas( Xtrain, Ytrain, current_model ) ;
            beta = alpha.*Ytrain;
            if isempty(lambda)
                % Meaning we used Matlab solver:
                b = current_model.Internal.Runtime.bias ;
            else
                b = lambda.eqlin(1) ;
            end
            Kpred = evalK_handle( Xtrain, Xtest, theta, KernelOptions);
            % Evaluate the testing set given the found SVC coefficients
            Yval = transpose(beta) * Kpred + b;
            Yclass = ones(size(Yval));
            Yclass(Yval < 0) = -1;
            % Count the number of misclassifications
            errors(jj) = mean(Yclass'.*Ytest < 0) ;
            
        end
        additional_metrics.CV_error = mean(errors);
end
end

