function [g_X, M_X, ArgOut] = uq_evalLimitState(X, FullModel, LSOptions, HPC)
% [G_X, M_X, ARGOUT] = UQ_EVALLIMITSTATE(X,FULLMODEL,LSOPTIONS):
%     evaluates the limit state function at input sample X on the FULLMODEL
%     and the limit state function options LSOPTIONS
% 

%% NUMBER of function evaluations
%set up a global counter for the number of function evaluations
persistent LimitStateCounter;
if isempty(LimitStateCounter)
    LimitStateCounter = 0;
end

% Check the request:
if ischar(X)
	switch X
        %return the number of function evaluations
		case 'count'	
			g_X = LimitStateCounter;
			return
        
        %reset the counter to 0
		case 'reset'
			LimitStateCounter = 0;
			return

		otherwise
			error('uq_sin_counter called with unknown option "%s"', X);

	end
end

%% NORMAL limit state function evaluation
% If it gets to this point, it was a normal call
% Increase the number of model evaluations and return Y = g(X)

N = size(X, 1);

% increase the counter
LimitStateCounter = LimitStateCounter + N;


%%%UQHPCSTART%%%
% If not specified, HPC is disabled:
if ~exist('HPC', 'var')
    HPC = false;
end

% Threshold for the limit state function:
TH = LSOptions.Threshold;

% Evaluate the function:
if HPC
    HPCflag = 'HPC';
else
    HPCflag = [];
end

if nargout > 2
    if isempty(HPCflag)
        [M_X, ArgOut] = uq_evalModel(FullModel,X);
    else
        [M_X, ArgOut] = uq_evalModel(FullModel,X,HPCflag);
    end
else
    if isempty(HPCflag)
        M_X = uq_evalModel(FullModel,X);
    else
        M_X = uq_evalModel(FullModel,X,HPCflag);
    end
end
%%%UQHPCEND%%%

% Determine the failures:
switch LSOptions.CompOp
    case {'<', '<=', 'leq'}
        g_X = M_X  - TH;
        
    case {'>', '>=', 'geq'}
        g_X = TH - M_X;
end

