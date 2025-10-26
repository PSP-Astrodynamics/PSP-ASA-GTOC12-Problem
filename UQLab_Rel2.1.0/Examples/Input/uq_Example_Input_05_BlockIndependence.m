%% INPUT MODULE: BLOCK-INDEPENDENT MARGINALS
%
% This example showcases how to define a probabilistic input model with
% several inter-independent sets (blocks) of random variables.
% Each block is identified by its own copula, and the copula of the full
% random vector is given by the tensor product of the copulas of the
% individual blocks.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of eight random variables:
%
% $$X_i \sim \mathcal{N}(0, 1) \quad i=1,\ldots,8$$

%%
% Specify the marginals of these variables:
for i=1:8
    InputOpts.Marginals(i).Type = 'Gaussian';    
    InputOpts.Marginals(i).Moments = [0 1];  
end

%%
% The random variables are grouped into four independent blocks,
% each characterized by its own copula:
%
% # $(X_1,X_4,X_6)$: Vine copula
% # $(X_3,X_7)$: Gaussian copula
% # $(X_2,X_8)$: t-pair copula
% # $X_5$: stand-alone

%%
% Specify these three copulas:
InputOpts.Copula(1) = uq_VineCopula(...
    'CVine', 1:3, ...
    {'Clayton', 'Gumbel', 'Gaussian'}, {1.4, 2, 0.3}, [0 0 0]);
InputOpts.Copula(1).Variables = [1 4 6];

InputOpts.Copula(2) = uq_GaussianCopula([1 -.5; -.5 1]);
InputOpts.Copula(2).Variables = [3 7];

InputOpts.Copula(3) = uq_PairCopula('t', [.5 2], 0);
InputOpts.Copula(3).Variables = [2 8];

%%
% Create an INPUT object based on the specified marginals and copulas:
myInput = uq_createInput(InputOpts);

%%
% Print a report on the INPUT object: 
uq_print(myInput)

%%
% Display a visualization of the input model:
uq_display(myInput)

%% 3 - VALIDATION OF BLOCK INDEPENDENCE
%
% The four blocks specified above can be numerically validated that they
% are mutually independent.
%
% First, get the independent blocks as the sets of variables coupled
% by each copula:
Blocks = {myInput.Copula.Variables};
NrBlocks = length(Blocks);
VarNames = {myInput.Marginals.Name};

%%
% Draw a sample from the input model:
X = uq_getSample(1000);

%%
% Calculate the correlation matrix |R| on the sample |X| obtained above
R = corr(X, 'type', 'Kendall');

fprintf('Full correlation matrix:\n')
uq_printMatrix(R,VarNames,VarNames)

%%
% Extract the correlation submatrices corresponding to different blocks
% and check that they contain values close to 0
for ii = 1:(NrBlocks-1)
    for jj = (ii+1):NrBlocks
        subR = R(Blocks{ii}, Blocks{jj});
        fprintf('Correlation matrix of blocks %d and %d:\n', ii, jj)
        uq_printMatrix(subR, VarNames(Blocks{ii}), VarNames(Blocks{jj}))
        fprintf('\n')
    end
end

%% 4 - STATISTICAL TEST OF BLOCK INDEPENDENCE
%
% UQLab also provides the possibility to determine independent blocks of
% random variables given a multivariate sample set.
% In this way, the blocks defined above can be tested:
BlocksHat = uq_test_block_independence(X, 0.05);
