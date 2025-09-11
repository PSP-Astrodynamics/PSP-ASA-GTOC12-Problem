function Metrics = uq_GLaM_evalModelSampleMetrics(GLaModel,X,Y,varargin)
%% Compute the error metrics between a generalized lambda model and data points (X,Y)
% GLaModel: the generalize lambda model
% X: the input data
% Y: the associated output samples
% varargin: *('WSDOrder',p) order of the Wasserstein distance (WSD) 
%           *('WSDcalcMethod',method) the method to compute WSD 
%            see uq_GLD_Wasserstein for the possible options
%           *('TruncLambdai',[l,u]) the lambda_i is truncted within [a,b],
%            i.e., if its value is outside, it will be set to the value of 
%            the nearest bound.
%           *('TruncLambda',[l_1,u_1;l_2,u_2;l_3,u_3;l_4,u_4]) set the
%            bounds for lambda1-4 all together, and the i-th row corresponds
%            to the bounds for lambdai''

% retrieve important informations
Nout = size(Y,2);
R = size(Y,3);

%% compute the Wasserstein distance between GLDs and the samples
parse_keys = {'WSDOrder','WSDcalcMethod'};
parse_types = {'p','p'};
[parsed, ~] = uq_simple_parser(varargin, parse_keys, parse_types);

% the user does not specify the order of the Wasserstein Distance (WSD)
if strcmp(parsed{1},'false')
    % we set by default p=2
    p=2;
else
    % the user specifies the order of WSD
    p = parsed{1};
end
% the user does not specify the way to evaluate WSD
if strcmp(parsed{2},'false')
    % we set by default the exact WSD
    calcMethod= 'ot';
else
    % the user specifies calculation method for WSD
    calcMethod = parsed{2};
end

% evaluate lambda's: set truncated values to have a finite Wasserstein
% distance
parse_keys = {'TruncLambda3','TruncLambda4'};
parse_types = {'p','p'};
[parsed, ~] = uq_simple_parser(varargin, parse_keys, parse_types);
if strcmp(parsed{1},'false')
    varargin = [varargin,'TruncLambda3',[-1/(p+1),inf]];
end
if strcmp(parsed{2},'false')
    varargin = [varargin,'TruncLambda4',[-1/(p+1),inf]];
end
lambda = uq_GLaM_evalLambda(GLaModel,X,varargin);

% compute WSD
WSD = uq_GLD_Wasserstein(lambda,Y,p,calcMethod);

%% save the results
Metrics = struct;
for oo=1:Nout
    Yoo = permute(Y(:,oo,:),[3,1,2]);
    Yoo = Yoo(:);
    lambdaoo = permute(lambda(:,oo,:),[1,3,2]);
    lambdaoo=kron(lambdaoo,ones(R,1));
    
    % evaluate the associated negative likelihood
    Metrics(oo).NLoglikelihood = uq_GLD_NLogLikelihood(Yoo,lambdaoo);
    
    % compute the normalized Wasserstein distance
    Metrics(oo).NormalizedWSD = mean(WSD(:,oo).^p)/mean(abs(Yoo(:)-mean(Yoo(:))).^p);
    Metrics(oo).WSD = WSD(:,oo);
end

end