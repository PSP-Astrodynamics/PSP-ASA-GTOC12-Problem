function Y = uq_GM(X,MuVec,CovMat,W)
% PDF = UQ_GM(X,MuVec,CovMat) evaluate multivariate Gaussian Mixture PDF with
% specified mean vector MuVec (NGxM matrix: one mean value for each
% Gaussian in the mixture) and specified Covariance matrices CovMat
% (MxMxNG, matrix) 

[N,M] = size(X);
NG = size(MuVec,1);
if ~exist('W','var')
   W = ones(NG,1);
end

if size(MuVec,2) ~= M || size(CovMat,3) ~= NG
    error('Please check the dimensions of the inputs')
end


%% Evaluate the PDF
Y = zeros(N,1);
for ii = 1:NG
    Y = Y + W(ii)*mvnpdf(X,MuVec(ii,:),CovMat(:,:,ii));
end

% Normalize the output
Y = Y/sum(abs(W));