function [Y,lambda] = uq_GLaM_eval(GLaModel,X,varargin)
% evaluate the generalized lambda model

%% parse replications
R = 1;
if ~isempty(varargin)
    if isnumeric(varargin{1})
        if length(varargin{1})==1 && varargin{1}>0 && varargin{1}-round(varargin{1})==0
            R = varargin{1};
        else
            error('The number of replications should be a positive integer.');
        end
        varargin{1}=[];
    end
end

%% parse the other options
parse_keys = {'evalTraj'};
parse_types = {'p'};
[parsed, ~] = uq_simple_parser(varargin, parse_keys, parse_types);

% the user does not specify the option of trajectories
if strcmp(parsed{1},'false')
    % we set by default not calculating trajectories
    evalTraj = false;
else
% the user specifies option of trajectories
    evalTraj = parsed{1};
end
%% retrieve information
N = size(X,1);
Nout = GLaModel.Internal.Runtime.Nout;

%% prepare for the data generation

% evaluate the value of lambda's
lambda = uq_GLaM_evalLambda(GLaModel,X);

%% generate the data
% initialization
Y = zeros(N,Nout,R);

% loop over the outputs
for oo=1:Nout
    % get the associated lambda
    lamoo = lambda(:,oo,:);
    % transform it to a 2d matrix
    lamoo = permute(lamoo,[1,3,2]);
    % repeat the value to accelerate evaluating replications
    lamoo = repmat(lamoo,R,1);    
    % generate the latent variable
    if evalTraj
        u = rand(R,1);
        u = kron(u,ones(N,1));
    else
        u = rand(N*R,1);
    end
    % get the associated data
    Yoo = uq_GLD_quantile(u,lamoo);
    % reshape it to fit the output format
    Y(:,oo,:)=reshape(Yoo,[N,1,R]);
end

end

