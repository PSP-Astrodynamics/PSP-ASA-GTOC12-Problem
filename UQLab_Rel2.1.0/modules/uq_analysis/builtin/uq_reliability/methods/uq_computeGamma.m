function [ gammai ] = uq_computeGamma( lsfhistory, qi, Pfi, Options )
% [gammai] = UQ_COMPUTEGAMMA(lsfhistory, qi, Pfi, Options):
%     computes the gamma factor for the estimation of the 
%     coefficient of variation in subset simulation.
%
% References:
%
%     Papaioannou et al., 2015, MCMC algorithms for subset simulation,
%     Probabilitistic Enginerring Mechanics 41, 89-103.
%
% See also: UQ_SUBSETSIM

%"minimum" length of the chains
chainlength = floor(1/Options.Subset.p0);
chainnumber = floor(Options.Simulation.BatchSize*Options.Subset.p0);
Nchainlength = chainlength * chainnumber;
Nsubset = Options.Simulation.BatchSize;

%rearranging the lsfhistory vector to a matrix to have each chain seperate
LSFH = reshape(lsfhistory(1:Nchainlength), chainnumber, []);
I = zeros(size(LSFH));
I(LSFH <= qi) = 1;

%computing the autocorrelation coefficient of the samples (rho)
%considering every chain independently
Rik = [];
for k = 1:chainlength - 1
    sums = 0;
    for l = 1 : Nsubset/chainnumber-k 
        sums = sums + sum(I(:,l).*I(:,l+k));
    end
    Rik(k) = sums * 1/(Nsubset - k * chainnumber) - Pfi^2;
         
end

%computation of gamma
rho = Rik / (Pfi*(1-Pfi));
gammai = 2 * sum( rho.*(1-(1:length(rho))*chainnumber / Nsubset) );