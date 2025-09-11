function [Y_MU, Y_SIGMA, Y_COV] = uq_PCK_eval(current_model, X)
% Y = UQ_PCK_EVAL(X, MODEL): evaluates the metamodelling response from the 
% calculated coefficients

% retrieve the number of response variables (Nout)
Nout = current_model.Internal.Runtime.Nout;

% assign a vector for the response vector(s)
Y_MU = zeros(size(X,1),Nout);
if nargout>1; Y_SIGMA = zeros(size(X,1),Nout); end
if nargout>2; Y_COV = zeros(size(X,1),size(X,1),Nout); end

% remove the constants from the experimental design
X = X(:,current_model.Internal.Input.nonConst);


% cycle through each output
for oo =  1 : Nout
    
    %select a given Kriging model with trend for response variable oo
    Kriging_oo = current_model.Internal.Kriging(oo);
    
    if nargout == 1
        % compute the prediction mean value only
        Y_mu = uq_Kriging_eval(Kriging_oo, X);
        Y_MU(:,oo)    = Y_mu;
    else if nargout == 2
            % compute the prediction mean value and variance
            [Y_mu, Y_sigma] = uq_Kriging_eval(Kriging_oo, X);
            Y_MU(:,oo)    = Y_mu;
            Y_SIGMA(:,oo) = Y_sigma;
        else
            % compute the prediction mean value, variance and covariance
            % matrix
            [Y_mu, Y_sigma, Y_Cov] = uq_Kriging_eval(Kriging_oo, X);
            Y_MU(:,oo)    = Y_mu;
            Y_SIGMA(:,oo) = Y_sigma;
            Y_COV(:,:,oo) = Y_Cov;
        end
    end
    
end