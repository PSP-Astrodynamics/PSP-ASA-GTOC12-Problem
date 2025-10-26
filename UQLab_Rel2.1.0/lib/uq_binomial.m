function value = uq_binomial(n, k)
% VALUE = UQ_BINOMIAL(N, K) returns the binomial coefficient VALUE between 
% N and K. This is identical to the nchoosek function, but hopefully more 
% stable

%% using a recursive formula
value = 1;
for ii = 1:k
    value = value*(n - (k - ii))/ii;
end
