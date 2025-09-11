function varargout = uq_subsetsim_samples(Xseed, N, mcmcopts)
%[U, F] = UQ_SUBSETSIM_SAMPLES(SIMOPTS, N) performs a Markov Chain Monte
%    Carlo simulation for the current subset in subset simulation


%% ALGORITHM
X = Xseed;
% evaluate logarithm of standard normal pdf
Y = sum(-log(2*pi)/2 -(X.^2)/2,2);
Xsample = [];
Ysample = [];


%% Markov Chains
while 1
    
    % Random sampler
    a = size(X);
    switch lower( mcmcopts.RW.propDistr.Type )
        case 'uniform'
            Xprop = X + (rand(a)*2-1).*mcmcopts.RW.propDistr.Parameters; % maybe change here by a factor of 2 [xxx]
        case 'gaussian'
            Xprop = X + randn(a).*mcmcopts.RW.propDistr.Parameters;
        otherwise
            error('proposal distribution not defined')
    end
    
    % New sample vector
    [X, Y, LSF, Yexeval, mcmcopts] = uq_subsetsim_accept(mcmcopts, X, Y, Xprop);
    %assign LSF to the mcmcopts to have it somewhere here
    Xsample = [ Xsample; X];
    
    
    % Also store the (caluculated) limit-state function evaluations
    Ysample = [ Ysample; Y ];
    
    % Stopping criterion
    if size(Xsample, 1) >= N; break; end
    
end


%% Allocate intermediate model evaluations
Runtime.LSF = mcmcopts.Runtime.LSF;
Runtime.Y = mcmcopts.Runtime.Y;


%% Return values
varargout{1} = Xsample;

if nargout > 1
    %the sample distribution value at locations Xsample
    varargout{2} = Ysample; 
end

if nargout > 2
    %return the current modified mcmcopts
    varargout{3} = Runtime;
end
    