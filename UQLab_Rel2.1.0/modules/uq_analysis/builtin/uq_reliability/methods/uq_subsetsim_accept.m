function [Uaccept, Yaccept, LSF, Yexeval, mcmcopts] = uq_subsetsim_accept(mcmcopts, U, Y, Uprop)
% [X, Y] = UQ_SUBSETSIM_ACCEPT(MCMCOPTS, X, Y, XPROP) defines the
%      acceptance criterion in subset simulation and applies it to the 
%      candidate samples Xprop


%% ALGORITHM
% basic checks
a = size(U);
b = size(Uprop); 
assert(a(2)==b(2),'input dimensions inconsistent')
assert(a(1)==b(1),'number of samples inconsistent')

% options
AcceptOpts = mcmcopts.AcceptCrit;
SNS = AcceptOpts.SNS;
gi = AcceptOpts.gi;

%check whether the LSF response values are available
LSF = AcceptOpts.LSF;
Yexeval = AcceptOpts.Y;

if ~isfield(mcmcopts, 'Runtime'); mcmcopts.Runtime = []; end

if ~isfield(mcmcopts.Runtime, 'LSF')
    mcmcopts.Runtime.LSF = LSF;
    mcmcopts.Runtime.Y = Yexeval;
end
    
c = size(LSF);

% the current output of interest
oo = AcceptOpts.oo;


%% switcher for the original/modified MH algorithm
if AcceptOpts.Componentwise
    % set array size limit and perform computation 
    maxArraySizeGB = 10; arraySizeGB = a(1)*a(2)^2*8/(2^30);
    nSplits = ceil(arraySizeGB/maxArraySizeGB);
    sizeSplit = floor(a(1)/nSplits);
    
    % loop over splits
    % init
    Uprop2 = zeros(size(U)); idx = false(size(U,1),1);
    for ii = 1:nSplits
        % get idx
        lowerIdx = (ii-1)*sizeSplit+1;
        upperIdx = min([ii*sizeSplit,a(1)*a(2)]);
        % init
        U_curr = U(lowerIdx:upperIdx,:);
        Y_curr = Y(lowerIdx:upperIdx);
        Uprop_curr = Uprop(lowerIdx:upperIdx,:);
        % MH componentwise
        UU = repmat(U_curr,a(2),1);
        UPROP = repmat(Uprop_curr, a(2), 1);
        jj = kron(eye(a(2)), ones(size(U_curr,1),1));
        UU(jj==1) = UPROP(jj==1);
        YPROP = sum(-log(2*pi)/2 -(UU.^2)/2,2);
        YY = repmat(Y_curr, a(2), 1);
        idx_curr = ( rand(size(Uprop_curr,1)*b(2),1) < exp(YPROP - YY) );
        IDX = reshape(idx_curr, size(U_curr,1), []);
        
        % fill Uprop2
        Uprop2_curr = U_curr;
        Uprop2_curr(IDX) = Uprop_curr(IDX);
        Uprop2(lowerIdx:upperIdx,:) = Uprop2_curr;
        
        % update idx
        idx(lowerIdx:upperIdx) = sum(IDX,2) ~= 0;
    end
    
    Yprop = sum(-log(2*pi)/2 -(Uprop2.^2)/2,2);
    Uprop = Uprop2;
    
    %when X is in a range of PDF=0
    idx(Y == 0) = true;
else
    % MH global
    Yprop = sum(-log(2*pi)/2 -(Uprop.^2)/2,2);
    idx = ( rand(b(1),1) < exp(Yprop - Y));
    
    %when X is in a range of PDF=0
    idx(Y == 0) = true; 
end

%% Assigning the new samples of the Markov Chain
%transform of the U input space to X for the function evaluations
Xprop = uq_GeneralIsopTransform( Uprop, SNS.Marginals, SNS.Copula, AcceptOpts.Input.Marginals, AcceptOpts.Input.Copula );

%evaluate the true model and the limit state function
Yeval = NaN*ones(a(1), c(2));
LSFacc = NaN*zeros(a(1), c(2));

[LSFacc(idx, :), Yeval(idx, :)] = uq_evalLimitState( Xprop(idx,:), AcceptOpts.model, AcceptOpts.LimitState, 0 );

%assign the new samples according to the threshold
Uaccept = U;
Uaccept(idx & (LSFacc(:,oo)<gi),:) = Uprop(idx & (LSFacc(:,oo)<gi),:);

%the value of the sampling PDF
Yaccept = Y;
Yaccept(idx &(LSFacc(:,oo)<gi)) = Yprop(idx &(LSFacc(:,oo)<gi));

%save the limit state function evaluations and the computational model runs
LSFaccept = LSF;
LSFaccept(idx &(LSFacc(:,oo)<gi),:) = LSFacc(idx &(LSFacc(:,oo)<gi),:);
mcmcopts.Runtime.LSF = [mcmcopts.Runtime.LSF; LSFaccept];
mcmcopts.AcceptCrit.LSF = LSFaccept;

Cevalaccept = Yexeval;
Cevalaccept(idx &(LSFacc(:,oo)<gi),:) = Yeval(idx &(LSFacc(:,oo)<gi),:);
mcmcopts.Runtime.Y = [mcmcopts.Runtime.Y; Cevalaccept];
mcmcopts.AcceptCrit.Y = Cevalaccept;