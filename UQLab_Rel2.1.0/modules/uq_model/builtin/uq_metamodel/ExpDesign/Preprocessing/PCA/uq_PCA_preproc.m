function [EDPre, Parameters] = uq_PCA_preproc(ED, Options)
% [EDPRE,PARAMETERS] = UQ_PCA_PREPROC(ED,OPTIONS): Pre-process the
%     experimental design in ED.X and ED.Y with PCA and the options specified
%     in OPTIONS. The parameters necessary to postprocessing are returned in
%     PARAMETERS.
%
% See also: UQ_PCA_POSTPROC

%% retrieve the options 
if exist('Options', 'var') && isfield(Options,'VarThreshold')
    Th = Options.VarThreshold;
else
    Th = 0.99; % default to 99% variance
end

%% Get the PCA and the mean
X = ED.Y;
[PC,lambda,relVar] = pca(X);
muX = mean(X);

%% perform variance-threshold-based selection
maxPC = find(cumsum(relVar/sum(relVar))>Th,1);

%% Return values
% Preprocessed X (PCA coordinates):
Xpre = lambda(:,1:maxPC);
% Spectral decay
Parameters.explained = cumsum(relVar/sum(relVar));
% Mean value
Parameters.muX = muX;
% Principal components (eigenvectors)
Parameters.PC = PC(:,1:maxPC);
EDPre = ED;
EDPre.Y = Xpre;

