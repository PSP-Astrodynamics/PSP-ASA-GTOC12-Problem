function [sampleMean, sampleVar] = uq_inversion_mean(Sample3D)
% UQ_INVERSION_MEAN computes the mean of the passed SAMPLE3D. 
%
% See also UQ_POSTPROCESSINVERSIONMCMC, UQ_INVERSION_PERCENTILES

% reshape Sample3D to Sample2D
nDim = size(Sample3D,2);
Sample2D = reshape(permute(Sample3D,[2 1 3]),nDim,[]).';

% compute mean
sampleMean = mean(Sample2D);
sampleVar = var(Sample2D);
end

