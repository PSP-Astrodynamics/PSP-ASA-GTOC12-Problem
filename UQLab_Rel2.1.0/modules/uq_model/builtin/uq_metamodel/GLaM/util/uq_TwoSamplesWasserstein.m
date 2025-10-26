function discrepancy = uq_TwoSamplesWasserstein(sample1,sample2,p,calcMethod,U)
%% Calculate Wasserstein distance of order p between two discrete probability measures 
%   
%   discrepancy = uq_TwoSamplesWasserstein(sample1, sample2) returns the 2-Wasserstein 
%   distance between the discrete probability measures u and v 
%   corresponding to the sample vectors sample1 and sample2
%
%   discrepancy = uq_TwoSamplesWasserstein(sample1, sample2, p) returns the p-Wasserstein 
%   distance between the discrete probability measures u and v
%   corresponding to the sample vectors sample1 and sample2. 
% 
%   discrepancy = uq_TwoSamplesWasserstein(sample1, sample2, p, calcMethod) returns the p-Wasserstein 
%   distance between the discrete probability measures u and v
%   corresponding to the sample vectors sample1 and sample2 using the
%   method specified by calcMethod. 
% 
%   calcMethod can take two values 'quantile' and 'ot'. 
%   1. 'quantile': the wasserstein distance is calcualted based on the empirical quantile 
%      specified by u. By default, u=0.0005:0.01:0.9995. 
%   2. 'mixed': a mixed way to compute the Wasserstein distance
%                based on mean, standard deviation and quantile correlations.
%                See: Schefzik, R. et al. Fast identification of differential distributions in
%                single-cell RNA-sequencing data with waddR. Bioinformatics, 37:3204–3211.
%   3. 'ot': the exact empirical Wasserstein distance (based on optimal transport) is calculated, 
%             modified based on https://github.com/nklb/wasserstein-distance.

% by default WSD of order 2 is calcualted
if nargin<3
    p=2;
end

% by default the exact emprical WSD is computed
if nargin<4
	calcMethod = 'ot';
end

% ensure column vectors
sample1 = sample1(:);
sample2 = sample2(:);

% calculate WSD
switch lower(calcMethod)
    
    % WSD based on empirical quantiles
    case 'quantile'
        if nargin<5
            U = 0.0005:0.01:0.9995;
        end
        % get the quantiles from sample 1
        quant1 = quantile(sample1,U);
        % get the quantile from sample 2
        quant2 = quantile(sample2,U);
        % compute WSD
        discrepancy = (mean(abs((quant1 - quant2)).^p))^(1/p);
    
    % mixed ways (only available for WSD of order 2)
    case 'mixed'
        if p~=2
            error('The mixed method is not available for the Wasserstein distance of order %d.',p);
        else
            if nargin<5
                U = 0.0005:0.01:0.9995;
            end
            mus1 = mean(sample1);sigmas1 = std(sample1);
            quant1 = quantile(sample1,U);
            mus2 = mean(sample2);sigmas2 = std(sample2);
            quant2 = quantile(sample2,U);
            rhou = corr(quant1,quant2);
            
            discrepancy = sqrt( (mus1-mus2).^2+(sigmas1-sigmas2).^2+2*sigmas1.*sigmas2.*(1-rhou) );
        end
        
    % exact WSD calculation between two empirical distributions   
    case 'ot'
        % This part of the code is modified from the original work of
        % Niklas Kolbe, available at: https://github.com/nklb/wasserstein-distance
        % In the following we reproduce the MIT license of the original
        % code, which applies to this section of the function.

        %% MIT LICENSE
        % 
        % Copyright (c) 2020 Niklas Kolbe
        % 
        % Permission is hereby granted, free of charge, to any person obtaining a copy
        % of this software and associated documentation files (the "Software"), to deal
        % in the Software without restriction, including without limitation the rights
        % to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        % copies of the Software, and to permit persons to whom the Software is
        % furnished to do so, subject to the following conditions:
        % 
        % The above copyright notice and this permission notice shall be included in all
        % copies or substantial portions of the Software.
        % 
        % THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        % IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        % FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        % AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        % LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        % OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        % SOFTWARE.

        % sort the samples
        sample1_sorted = sort(sample1(:));
        sample2_sorted = sort(sample2(:));
        
        % for WSD of order 1, we choose to use the alternative formular
        % $\int \abs{F_1(x)-F_2(x)} dx$
        if p == 1
            all_samples = unique([sample1_sorted; sample2_sorted], 'sorted');
            
            sample1_cdf = find_interval(sample1_sorted, all_samples(1:end-1)) ...
                / numel(sample1);
            sample2_cdf = find_interval(sample2_sorted, all_samples(1:end-1)) ...
                / numel(sample2);
            
            discrepancy = diff(all_samples)'*abs(sample1_cdf - sample2_cdf);
        
        % for other orders p, we solve the simplified Kantorovich problem
        % in 1d
        else
            % calculate lengths
            N1 = length(sample1);
            N2 = length(sample2);
            
            % find the probabilities
            [all_prob,~,index] = unique([(0:N1) / N1, (0:N2) / N2]', 'sorted');
            
            sample1_icdf = zeros(length(all_prob)-1,1);
            sample2_icdf = sample1_icdf;
            
            % calculate the associated values for sample1
            sample1_icdf(index(2:(N1+1))-1) = sample1_sorted;
            sample1_icdf = flipud(sample1_icdf);
            idx = sample1_icdf~=0;tmp = sample1_icdf(idx);
            sample1_icdf = tmp(cumsum(idx));
            sample1_icdf = flipud(sample1_icdf);
            
            % calculate the associated values for sample2
            sample2_icdf(index((N1+3):end)-1) = sample2_sorted;
            sample2_icdf = flipud(sample2_icdf);
            idx = sample2_icdf~=0;tmp = sample2_icdf(idx);
            sample2_icdf = tmp(cumsum(idx));
            sample2_icdf = flipud(sample2_icdf);
            
            % evaluate WSD
            discrepancy = (diff(all_prob)'*abs(sample1_icdf-sample2_icdf).^p)^(1/p);
        end
end
end

function res = stableIntOperation(operation,res)
    thre = 1e-14;
    roundres = round(res);
    indIncorrect= abs(res-roundres)<thre;
    res(indIncorrect) = roundres(indIncorrect);
    res(~indIncorrect) = operation(res(~indIncorrect));
end

function idx = find_interval(bounds, vals)
% Given the two sorted arrays bounds and vals, the function 
% idx = FIND_INTERVAL(bounds, vals) identifies for each vals(i) the index 
% idx(i) s.t. bounds(idx(i)) <= vals(i) < bounds(idx(i) + 1).

m = 0;
bounds = [bounds(:); inf];
idx = zeros(numel(vals), 1);

for i = 1:numel(vals)
    while bounds(m+1) <= vals(i)
        m = m + 1;
    end
    idx(i) = m;
end
end