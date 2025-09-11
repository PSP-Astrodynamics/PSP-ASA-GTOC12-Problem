%% define stochastic simulator (the usual way that the user would define a simulator)
function Y = uq_testfnc_mfileSthocSIR(X,StochOpts,P)
% Y(1): total outbreak time
% Y(2): total number of newly infected individuals

% define total number of individuals
M=2000;
% no maximum simulation time span
imm = 0;
Y = zeros(1,2);
[~, Y(1), Y(2), ~, ~, ~, ~] = simulateSIR(X(1),X(2),M,X(3),X(4),imm);
end

%% Here we define the original SIR simulator
function [maxI, totT, totI, S, I, R, T]= simulateSIR(S0,I0,M,beta,gamma,imm)
curS = zeros(1,M);
curI = zeros(1,M);
curT = zeros(1,M);

count = 1;
maxI = I0;
curS(1) = S0;
curI(1) = I0;
while ((curI(count) > 0 && imm == 0) || (curT(count) < 100 && imm > 0))
    infRate = beta * curS(count) * (curI(count) + imm)/(M);
    recRate = gamma * curI(count);
    infTime = -1/infRate * log(rand);
    recTime = -1/recRate * log(rand);
    if infTime < recTime
        curS(count + 1) = curS(count) - 1;
        curI(count + 1) = curI(count) + 1;
        maxI = max(maxI, curI(count + 1));
    else
        curI(count + 1) = curI(count) - 1;
        curS(count + 1) = curS(count);
    end
    curT(count + 1) = curT(count) + min(infTime, recTime);
    count = count + 1;
end
totT = curT(count);
totI = S0 - curS(count);
S = curS;
I = curI;
R = M - curS - curI;
T = curT;
end