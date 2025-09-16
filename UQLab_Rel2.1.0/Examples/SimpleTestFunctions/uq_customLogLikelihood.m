function logL = uq_customLogLikelihood(params, y, ModelSetup)
% UQ_CUSTOMLOGLIKELIHOOD evaluates the log of a custom likelihood
%   function used in the Bayesian inversion module example
%   uq_Example_Inversion_06_UserDefinedLikelihood.

% Split params into model and discrepancy parameters
modelParams = params(:,1:5);
discrepancyParams = params(:,6:7);

% Extract data
measurements = y.meas;
time = y.time;

% Initialization
sigma2 = discrepancyParams(:,1); % discrepancy variance
theta = discrepancyParams(:,2); % discrepancy correlation length
nOut = size(measurements,2);
nReal = size(modelParams,1); % number of queried realizations

% Evaluate model and keep only every 10th model output for speed-up
modelRuns = uq_hymod(params,ModelSetup);
modelRuns = modelRuns(:,1:10:end);

% Construct h for correlation matrix
h = zeros(nOut,nOut);
for ii = 1:nOut
    for jj = 1:nOut
        h(ii,jj) = abs(time(ii)-time(jj));
    end
end
   
% Loop through realizations
logL = zeros(nReal,1);
for ii = 1:nReal
  % Get the covariance matrix
  D = eye(nOut)*sqrt(sigma2(ii));
  % Get correlation & covariance matrix
  R = exp(-h/theta(ii));
  C = D*R*D;
  L = chol(C,'lower');
  Linv = inv(L);

  % Compute inverse of covariance matrix and log determinant
  Cinv = Linv'*Linv;
  logCdet = 2*trace(log(L));
  % Evaluate log-likelihood
  logLikeli = - 1/2*logCdet - 1/2*diag((measurements...
  -modelRuns(ii,:))*Cinv*(measurements-modelRuns(ii,:))');
  % Assign to logL vector
  logL(ii) = logLikeli;
end