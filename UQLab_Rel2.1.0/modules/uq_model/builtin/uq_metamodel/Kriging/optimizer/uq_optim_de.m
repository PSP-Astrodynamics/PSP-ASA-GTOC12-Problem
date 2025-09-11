function [ x, fval, output ] = uq_optim_de(fhandle,M,N, LB, UB, options )
%[x, fval, output ] = UQ_OPTIM_DE(fhandle, M, N, LB, UB, options):
%   Differential evolution optimization.
%
%     M : dimension of each individual
%     N : population size
%     options.Ndiff
%        .mutatedVector
%        .F
%        .CR
%     output.exitflag = 0 : max iterations reached
%                   1 : max stall generations reached
%                   2 : J < Jmin found
%
% See also UQ_OPTIM_SADE

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
if isrow(LB), LB = transpose(LB);end
if isrow(UB), UB = transpose(UB);end
LB = repmat(LB,1,N);
UB = repmat(UB,1,N);

% assign default value to mutation strategy
if ~isfield(options,'mutatedVector') || isempty(options.mutatedVector)
    options.mutatedVector = 'best' ;
    %     warning('F was assigned the default value: %5.0f',F);
end
% assign default value to F
if ~isfield(options,'F') || isempty(options.F)
    F = 0.5 ;
    warning('F was assigned the default value: %5.0f',F);
else
    F = options.F(1);
end
% assign default value to CR
if ~isfield(options,'CR') || isempty(options.CR)
    CR = 0.5 ;
    warning('CR was assigned the default value: %5.0f',CR);
else
    CR = options.CR ;
end
% assign default value to nStallMax
if ~isfield(options,'nStall') || isempty(options.nStall)
    nStallMax = 4 ;
    warning('nStall was assigned the default value: %i',nStallMax);
else
    nStallMax = options.nStall ;
end
% assign default value to Jmin
if ~isfield(options,'Jmin') || isempty(options.Jmin)
    Jmin = 1e-8 ;
    warning('nStall was assigned the default value: %d',Jmin);
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
    MaxIter = 20 ;
else
    MaxIter = options.MaxIter ;
end

%% ------- DE Initialization

% Produce random candidates
clear Marginals;
% uqlab;
[Marginals(1:M).Type] = deal('uniform') ;
for ii = 1 : M
    Marginals(ii).Parameters = [LB(ii), UB(ii)] ;
end
Sampling.Method = 'LHS';
c = clock ;
inputStr = ['input', mat2str(c)];
uq_createInput(inputStr,'uq_default_input',Marginals,Sampling);
uq_retrieveSession;
pop_t = uq_getSample(N) ;
J_t = zeros(1,N) ;
nfeval = 0;

% Ndiff = options.Ndiff ;
Ndiff = 3; %!!!TEMP

% calculate the fitness of each individual
for jj = 1 : N
    J_t(jj) = fhandle(pop_t(:,jj)) ;
    nfeval = nfeval + 1;
end
[J_best_it, i_best] = min(J_t);
x_best_it = pop_t(:,i_best);
x_best_ever = x_best_it;
J_best_ever = J_best_it;

nStall = 0;
exitflag = 0;
%% ------- Main Differential Evolution Algorithm
if strcmpi(Display,'iter')
    fprintf('\n                               Best           Mean      Stall\n');
    fprintf('Generation      f-count        f(x)           f(x)    Generations\n');
end
for ii = 1 : MaxIter    
    % Mutation
    v = zeros(size(pop_t)) ;
    r_i = zeros(Ndiff,N);
    for jj = 1 : N
        r_i(:,jj) = randperm(N,Ndiff) ;
    end
    r_i = transpose(r_i);
    
    FF = F*ones(M,N);
    switch lower(options.mutatedVector)
        case 'rand'
            if Ndiff == 3
                v = pop_t(:,r_i(:,1)) + FF .* (pop_t(:,r_i(:,2)) - pop_t(:,r_i(:,3)) ) ;
            elseif Ndiff == 5
                v = pop_t(:,r_i(:,1)) + FF .* (pop_t(:,r_i(:,2)) - pop_t(:,r_i(:,3)) ) +...
                    FF .* (pop_t(:,r_i(:,4)) - pop_t(:,r_i(:,5)) );
            else
                error('uq_de Error: Unsupported number of differences')
            end
        case 'best'
            if Ndiff == 3
                v = repmat(x_best_it,1,N)  + FF .* (pop_t(:,r_i(:,2)) - pop_t(:,r_i(:,3)) ) ;
            elseif Ndiff == 5
                v = repmat(x_best_it,1,N)  + FF .* (pop_t(:,r_i(:,2)) - pop_t(:,r_i(:,3)) ) +...
                     FF .* (pop_t(:,r_i(:,4)) - pop_t(:,r_i(:,5)) );
            else
                error('uq_de Error: Unsupported number of differences')
            end
        case 'rand_to_best'
            v = pop_t(:,r_i(:,1)) + FF .* (pop_t(:,r_i(:,2)) - pop_t(:,r_i(:,3)) ) +...
                FF .* (repmat(x_best_it,1,N)- pop_t(:,r_i(:,1)) );
        case 'curr_to_best'
            v = pop_t + FF .* (pop_t(:,r_i(:,2)) - pop_t(:,r_i(:,3)) ) +...
                FF .* (repmat(x_best_it,1,N)- pop_t );
            
    end
    
    
    % Recombination
    if M == 1 %scalar case
        u = v;
    else
        u = zeros(size(v));
        randMat = rand(size(v));
        i1 = randMat <= CR ;
        mat1 = repmat((1:M)',1,N) ;
        mat2 = repmat(datasample(1:M,N),M,1);
        i2 = i1|(mat1 == mat2);
        u(i2) = v(i2) ;
        i3 = ~( i2);
        u(i3) = pop_t(i3);
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
        Ju_t = fhandle(u(:,jj)) ;
        nfeval = nfeval + 1;
        if Ju_t < J_t(jj)
            pop_tp1(:,jj) = u(:,jj);
            J_tp1(jj) = Ju_t ;
        end
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
    % Stopping criterion
    if J_best_ever < Jmin
        exitflag = 2 ;
        break;
    end
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
    end
    fprintf('obj. value = %12.6g \n',J_best_ever)
end
x = x_best_ever ;
fval = J_best_ever ;
output.niter = ii;
output.fcount = nfeval ;
output.exitflag = exitflag ;
end



