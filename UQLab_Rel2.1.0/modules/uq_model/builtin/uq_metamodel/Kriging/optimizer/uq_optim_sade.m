function [ x, fval, output ] = uq_optim_sade(fhandle,M,N, LB, UB, options )
% [x, fval, output ] = UQ_OPTIM_SADE(fhandle, M, N, LB, UB, options):
%   
% M : dimension of each individual
% N : population size
% options.Ndiff
%        .mutatedVector
%        .F
%        .CR
% output.exitflag = 0 : max iterations reached
%                   1 : max stall generations reached
%                   2 : J < Jmin found
%                   3 : The relative change of J < TolFun during past nStall generations 
%
% See also: UQ_OPTIM_DE

%% ------- USER INPUT Initialization
% check bounds
if isempty(LB),LB= -1e5;end
if isempty(UB),UB= 1e5;end

if length(LB) ~= length(UB)
    error('Dimension mismatch between LB, UB !')
end
if length(LB) ~= M && length(LB) > 1
    error('Bounds should either be a scalar or a vector of size M!')
elseif length(LB) ~= M && length(LB) == 1
    LB = repmat(LB,M,1);
    UB = repmat(UB,M,1);
end
if N < 5
    warning('Population size must be at least 5. Assigning the value of 5..')
    N = 5;
end
if isrow(LB), LB = transpose(LB);end
if isrow(UB), UB = transpose(UB);end
LB = repmat(LB,1,N);
UB = repmat(UB,1,N);


% assign default value to TolFun
if ~isfield(options,'TolFun') || isempty(options.TolFun)
    TolFun = 1e-3 ;
    warning('TolFun was assigned the default value: %d',TolFun);
else
    TolFun = options.TolFun ;
end
% assign default value to Jmin
if ~isfield(options,'Jmin') || isempty(options.Jmin)
    Jmin = [] ;
else
    Jmin = options.Jmin ;
end
% assign default value to Jmin without warning
if ~isfield(options,'Display') || isempty(options.Display)
    Display = 'iter' ;
else
    Display = options.Display ;
end
% assign default value to MaxIter without warning
if ~isfield(options,'MaxIter') || isempty(options.MaxIter)
    MaxIter = 50 ;
else
    MaxIter = options.MaxIter ;
end
% assign default value to LP (Learning Period) without warning
if ~isfield(options,'LP') || isempty(options.LP)
    LP = floor(0.25* MaxIter) ;
else
    LP = options.LP ;
end
% assign default value to nStallMax
if ~isfield(options,'nStall') || isempty(options.nStall)
    nStallMax = LP ;
    warning('nStall was assigned the default value: %i',nStallMax);
else
    nStallMax = options.nStall ;
end

% assign default value to the optimization strategies
if ~isfield(options,'Strategies') || isempty(options.Strategies)
strategies = {'rand_1_bin', 'rand_2_bin', 'rand_to_best_2_bin','curr_to_rand_1',...
    'best_1_bin','rand_2_bin','rand_to_best_2_bin'};
else
    strategies = options.Strategies ;
end

% keep the number of strategies
nStrategies = length(strategies) ;

% assign default value to the probability of using each strategy
if ~isfield(options,'pStr') || isempty(options.pStr)
    pStrategies = (1/nStrategies)* ones(nStrategies,1) ;
else
    pStrategies = options.pStr ;
end

% assign default value to the Recombination probability coefficient
if ~isfield(options,'CRm') || isempty(options.CRm)
    CRm = repmat(0.5,nStrategies,1);
else
    CRm = options.CRm;
end

%% ------- DE Initialization
nWin = zeros(nStrategies,1);
nFail = zeros(nStrategies,1);
nWinTot = [];
nFailTot = [];
CRmem = repmat({[]},nStrategies,1);
% Produce random candidates
clear Marginals;
% uqlab;
[inputopts.Marginals(1:M).Type] = deal('uniform') ;
for ii = 1 : M
    inputopts.Marginals(ii).Parameters = [LB(ii), UB(ii)] ;
end

% produce a unique input identifier
c = clock ;
inputStr = ['input', mat2str(c)];
inputopts.Name = inputStr;
% create the input and draw samples
% uq_createInput(inputStr,Marginals,Sampling);
InitPop_Input = uq_createInput(inputopts, '-private');


%<TMPTRANSPOSE>
pop_t = uq_getSample(InitPop_Input,N,'Sobol').' ;

% Initialize some matrices
J_t = zeros(1,N) ;
nfeval = 0;



% calculate the fitness of each individual
for jj = 1 : N
    J_t(jj) = fhandle(pop_t(:,jj)) ;
    nfeval = nfeval + 1;
end
[J_best_it, i_best] = min(J_t);
x_best_it = pop_t(:,i_best);
x_best_ever = x_best_it;
J_best_ever = J_best_it;
J_best_mem = zeros(nStallMax,1) ;
nStall = 0;
exitflag = 0;
%% ------- Main Differential Evolution Algorithm
if strcmpi(Display,'iter')
    fprintf('\n                               Best           Mean      Stall\n');
    fprintf('Generation      f-count        f(x)           f(x)    Generations\n');
end

for ii = 1 : MaxIter
     
    CRtot = [];
    % get samples of F
    Ftot  = 0.5 + 0.3*randn(M,N);
    
    % Mutation
    v = zeros(size(pop_t)) ;
    u = v;
    r_i = zeros(5,N);
    for jj = 1 : N
        r_i(:,jj) = randperm(N,5) ;
    end
    r_i = transpose(r_i);
    
    
    % decide mutation strategy for each individual
    dec = rand(N,1);
    nn = zeros(nStrategies,1);
    for jj = 1 : nStrategies-1
        ind = dec <= jj*pStrategies(jj);
        nn(jj) = sum(ind) ;
        dec = dec(~ind);
    end
    nn(end) = N - sum(nn(1:end-1));
    
    indFirst = 1;
    for jj = 1 : nStrategies
        indLast = indFirst + nn(jj)-1;
        L = length(indFirst:indLast);
        FF = Ftot(:,indFirst:indLast) ; 
        switch lower(strategies{jj})
            case 'rand_1_bin'
                    v(:,indFirst:indLast) = pop_t(:,r_i(indFirst:indLast,1)) + ...
                        FF .* (pop_t(:,r_i(indFirst:indLast,2)) - pop_t(:,r_i(indFirst:indLast,3)) ) ;
            case 'rand_2_bin' 
                v(:,indFirst:indLast) = pop_t(:,r_i(indFirst:indLast,1)) + ...
                    FF .* (pop_t(:,r_i(indFirst:indLast,2)) - pop_t(:,r_i(indFirst:indLast,3)) ) +...
                    FF .* (pop_t(:,r_i(indFirst:indLast,4)) - pop_t(:,r_i(indFirst:indLast,5)) );
            case 'best_1_bin'  
                v(:,indFirst:indLast) = repmat(x_best_it,1,L)  + ...
                    FF .* (pop_t(:,r_i(indFirst:indLast,2)) - pop_t(:,r_i(indFirst:indLast,3)) ) ;
            case 'best_2_bin' 
                v(:,indFirst:indLast) = repmat(x_best_it,1,L)  +...
                    FF .* (pop_t(:,r_i(indFirst:indLast,2)) - pop_t(:,r_i(indFirst:indLast,3)) ) +...
                    FF .* (pop_t(:,r_i(indFirst:indLast,4)) - pop_t(:,r_i(indFirst:indLast,5)) );
            case 'rand_to_best_1_bin'  
                v(:,indFirst:indLast) = pop_t(:,r_i(indFirst:indLast,1)) + ...
                    FF .* (pop_t(:,r_i(indFirst:indLast,2)) - pop_t(:,r_i(indFirst:indLast,3)) ) +...
                    FF .* (repmat(x_best_it,1,L)- pop_t(:,r_i(indFirst:indLast,1)) );
            case 'rand_to_best_2_bin'
                v(:,indFirst:indLast) = pop_t(:,r_i(indFirst:indLast,1)) + ...
                    FF .* (pop_t(:,r_i(indFirst:indLast,2)) - pop_t(:,r_i(indFirst:indLast,3)) ) +...
                    FF .* (pop_t(:,r_i(indFirst:indLast,4)) - pop_t(:,r_i(indFirst:indLast,5)) ) +...
                    FF .* (repmat(x_best_it,1,L)- pop_t(:,r_i(indFirst:indLast,1)) );
            case 'curr_to_best_1_bin'
                v(:,indFirst:indLast) = pop_t(:,indFirst:indLast) + ...
                    FF .* (pop_t(:,r_i(indFirst:indLast,2)) - pop_t(:,r_i(indFirst:indLast,3)) ) +...
                    FF .* (repmat(x_best_it,1,L)- pop_t(:,indFirst:indLast) );
            case 'curr_to_best_2_bin'
                v(:,indFirst:indLast) = pop_t(:,indFirst:indLast) + ...
                    FF .* (pop_t(:,r_i(indFirst:indLast,2)) - pop_t(:,r_i(indFirst:indLast,3)) ) +...
                    FF .* (pop_t(:,r_i(indFirst:indLast,4)) - pop_t(:,r_i(indFirst:indLast,5)) ) +...
                    FF .* (repmat(x_best_it,1,L)- pop_t(:,indFirst:indLast) );
            case 'curr_to_rand_1'
                KK = rand(size(FF)) ;
                v(:,indFirst:indLast) = pop_t(:,indFirst:indLast) + ...
                    FF .* (pop_t(:,r_i(indFirst:indLast,2)) - pop_t(:,r_i(indFirst:indLast,3)) ) +...
                    KK .* (pop_t(:,r_i(indFirst:indLast,1)) - pop_t(:,indFirst:indLast) );
            otherwise
                error('Unknown mutation type!')
                
        end
        
        
        % Recombination
        switch lower(strategies{jj}(end-2:end))
            case 'bin'
                if M == 1 %scalar case
                    u(:,indFirst:indLast) = v(:,indFirst:indLast);
                else
                    randMat = rand(size(v(:,indFirst:indLast)));
                    CR = CRm(jj) + 0.1*randn(size(randMat)) ;
                    CRtot =[CRtot, CR] ;
                    i1 = randMat <= CR ;
                    %     u(i1) = v(i1) ;
                    mat1 = repmat((1:M)',1,L) ;
                    mat2 = repmat(datasample(1:M,L),M,1);
                    i2 = i1|(mat1 == mat2);
                    u_LOCAL = zeros(size(i2));
                    u_LOCAL(i2) = v(i2) ;
                    i3 = ~( i2);
                    u_LOCAL(i3) = pop_t(i3);
                    u(:,indFirst:indLast) = u_LOCAL ;
                end
                
            otherwise
                u(:,indFirst:indLast) = v(:,indFirst:indLast);
        end
        
        indFirst = indFirst + nn(jj);
    end

    % Make sure that constraints are satisfied
    i1 = u > UB;
    i2 = u < LB;
    u(i1) = UB(i1);
    u(i2) = LB(i2);
    % Selection using greedy criterion
    pop_tp1 = pop_t;
    J_tp1 = J_t;

    for jj = 1 : N
        kStrat = findStrategy(jj, nn);
        Ju_t = fhandle(u(:,jj)) ;
        nfeval = nfeval + 1;
        if Ju_t < J_t(jj)
            pop_tp1(:,jj) = u(:,jj);
            J_tp1(jj) = Ju_t ;
            % add a win to current strategy (kStrat) 
            nWin(kStrat) = nWin(kStrat) + 1;
            if strcmpi(strategies{kStrat}(end-2:end),'bin') && M > 1
                CRmem{kStrat} = [CRmem{kStrat};CRtot(jj)];
            end
        else
            % add a failure to current strategy (kStrat)
            nFail(kStrat) = nFail(kStrat) + 1; 
        end
    end
    
    if ii <= LP
       nWinTot = [nWinTot, nWin] ;
       nFailTot = [nFailTot, nFail] ; 
    else
        nWinTot = [nWinTot(:,2:end), nWin] ;
        nFailTot = [nFailTot(:,2:end), nFail] ;
        S = sum(nWinTot,2) ./ (sum(nWinTot,2) + sum(nFailTot,2))+0.01;
        pStrategies = S / sum(S);
        for jj = 1 : nStrategies 
            if isempty(CRmem{jj})
                CRm(jj) = 0.5;
            else
                CRm(jj) = median(reshape(CRmem{jj},1,[])) ;
            end
        end
        CRmem = repmat({[]},nStrategies,1);
    end


    [J_best_it, i_best] = min(J_tp1);
    x_best_it = pop_tp1(:,i_best);
    if J_best_it < J_best_ever
        x_best_ever = x_best_it;
        J_best_ever = J_best_it;
        nStall = 0;
    else
        nStall = nStall + 1 ;
    end
    % Stopping criterions
    % 1) Remember the last nStallMax J_best_ever and if the difference between
    % the max and min is below TolFun stop
    if ii <= nStallMax
        J_best_mem(ii) = J_best_ever ;
    else
        J_best_mem = [J_best_mem(2:end,1); J_best_ever];
        if abs(max(abs(J_best_mem)) / min(abs(J_best_mem)) -1 ) <= TolFun
            exitflag = 3 ;
            break;
        end
    end
    
    % 2) If J_best_ever is below Jmin stop now (only perform this check if some 
    % Jmin has been defined by the user)
    if ~isempty(Jmin) && J_best_ever < Jmin
        exitflag = 2 ;
        break;
    end
    % 3) If the maximum number of stall generations has been reached stop
    if  nStall >= nStallMax
        exitflag = 1 ;
        break;
    end
    % Reporting
    if strcmpi(Display,'iter')
        fprintf('%i               %i      %12.6g    %12.6g         %i\n',...
            ii, nfeval, J_best_ever, mean(J_tp1), nStall);
    end
    % make current population equal to the new population before starting
    % new iteration
    pop_t = pop_tp1;
    J_t = J_tp1;
end

%% ------- Return Results
if strcmpi(Display,'iter') || strcmpi(Display,'final')
    switch exitflag
        case 0
            fprintf('\n\nMaximum number of generations reached\n')
        case 1
            fprintf('\nMaximum number of stall generations reached\n')
        case 2
            fprintf('\nMinimum found\n')
        case 3
            fprintf('\nThe relative change of J was below TolFun\n')
    end
    fprintf('obj. value = %12.6g \n',J_best_ever)
end
x = x_best_ever ;
fval = J_best_ever ;
output.niter = ii;
output.fcount = nfeval ;
output.exitflag = exitflag ;
output.strategies = strategies ;
output.pStrategies = pStrategies ;
output.CRm = CRm ;
end

function kStrat = findStrategy(index, Mat)
% Find the strategy index 'kStrat' of 'index'
a = 1;
k = 1;
for ii = 2 : length(Mat)
    a = a   + Mat(ii-1);
    if index < a
        kStrat = k;
        return;
    end
    k = k + 1;
end
% if not found already 
kStrat = k;
end

