function Y = uq_PCA_postproc(data, Parameters)
% Y = UQ_PCA_POSTPROC(ED,PARAMETERS): Post-process the experimental design 
%     in ED.X and ED.Y with PCA and the parameters
%     specified in PARAMETERS (normally created by uq_PCA_preproc).
%
% See also: UQ_PCA_PREPROC

Ypre = data.Y;
%% retrieve mean and principal components
muX = Parameters.muX;
PC = Parameters.PC;

%% Calculate the new response
Y = bsxfun(@plus, Ypre*PC',muX);

