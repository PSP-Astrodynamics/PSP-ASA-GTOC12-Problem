function pass = uq_default_input_test_samplesFromParameters( level )
% pass = UQ_DEFAULT_INPUT_TEST_SAMPLESFROMPARAMETERS(LEVEL): validation and
% non-regression test for the random variable specification via the parameters 
% of its distribution. In addition the numerical moments estimator
% uq_estimateMoments is validated. 
%
% Summary:
% Random variables are generated via specifying their distribution and its
% parameters. The moments that correspond to these parameters are compared
% against the estimated moments calculated by sampling the random variables 

%% initialize test
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_tauInv...\n']);
rng(500)

marginalTypes = uq_getAvailableMarginals();

pass = 1;

%% parameters
if strcmpi(level,'normal')
    nsamples = 3e5;
    epsRel = 3.5e-2;  
    nrep = 1 ;
else
    nsamples = 1e6;
    epsRel = 2e-3;  
    nrep = 10;
end

iRep = 1;
% while iRep <= nrep && pass
while iRep <= nrep 
    clear Input
    %% create a set of parameters
    [Input.Marginals(1:2).Type] = deal('uniform');
    Input.Marginals(1).Parameters = [4 12];
    Input.Marginals(2).Parameters = [1 3];
    
    paramInpt = uq_createInput(Input);
    paramSample = uq_getSample(paramInpt,length(marginalTypes),'LHS');
    clear Input
    
    %% Create an input with as many marginals as the available ones with some
    % valid parameter values
    for ii = 1 : length(marginalTypes)
        Input.Marginals(ii).Type = marginalTypes{ii};
        % make some additional tuning of the parameters in some marginal types
        if strcmpi(marginalTypes{ii},'student')
            Input.Marginals(ii).Parameters = 4 + randi(6);
        elseif strcmpi(marginalTypes{ii},'uniform')
            Input.Marginals(ii).Parameters = fliplr(paramSample(ii,:));
        elseif strcmpi(marginalTypes{ii},'lognormal')
            Input.Marginals(ii).Parameters = [paramSample(ii,1), 0.2+0.7*rand];
        elseif strcmpi(marginalTypes{ii},'triangular')
            p1 = rand;
            p2 = 200 * rand;
            p3 = (p2 - p1)* rand; 
            Input.Marginals(ii).Parameters = [p1 p2 p3];
        elseif strcmpi(marginalTypes{ii}, 'ks')
            Input.Marginals(ii).Parameters = uq_lhs(10000,1);
        elseif strcmpi(marginalTypes{ii},'custom')
            custompars(1).pdf = @(x) uq_uniform_pdf(x,[0,1]);
            custompars(1).cdf = @(x) uq_uniform_cdf(x,[0,1]);
            custompars(1).inv_cdf = @(x) uq_uniform_invcdf(x,[0,1]);
            Input.Marginals(ii).Parameters = custompars;
        else
            Input.Marginals(ii).Parameters = paramSample(ii,:);
        end
    end
    
    %% Copula definition
    Input.Copula.Type = 'Gaussian';
    Input.Copula.Parameters = eye(length(Input.Marginals));
    
    %% Create the random vector and get samples
    myInput = uq_createInput(Input);
    
    
    
    x = uq_getSample(myInput,nsamples,'Sobol');

    %% Numerically estimate the moments using uq_estimateMoments
    moments_uqestim = zeros(length(marginalTypes),2);
    for ii = 1 : length(marginalTypes)
        % it is important to use the *initialized* marginals due to some
        % particularities with ks 
        moments_uqestim(ii,:) = uq_estimateMoments(myInput.Marginals(ii));
    end
    %% Test uq_MarginalFields error
    % check for each marginal the expected vs the estimated moments
    moments_true = cell2mat({myInput.Marginals(:).Moments}');
    moments_estim = [ mean(x,1)', std(x,0,1)' ] ;
    [maxErr,maxInd] = getMaxMargErr(moments_true, moments_estim, marginalTypes);
    pass = pass & (maxErr <= epsRel) ;
    
    % reporting
    report_max_err(maxErr, maxInd, iRep, marginalTypes, Input, 'uq_MarginalFields')
    
    %% Test uq_estimateMoments error
    % check for each marginal the expected vs the estimated moments
    [maxErr,maxInd] = getMaxMargErr(moments_true, moments_uqestim, marginalTypes);
    pass = pass & (maxErr <= epsRel) ;
    % reporting
    report_max_err(maxErr, maxInd, iRep, marginalTypes, Input, 'uq_estimateMoments')
    pass = pass & (maxErr <= epsRel) ;
    
    
    iRep = iRep + 1;
    
end

function [maxErr,maxInd] = getMaxMargErr(moments_true, moments_estim, marginalTypes)
zidx = moments_true == 0;
nzidx = ~zidx;
Diff = zeros(size(zidx));
Diff(nzidx) = abs((moments_true(nzidx) - moments_estim(nzidx))./moments_true(nzidx));
Diff(zidx) =  abs(moments_estim(zidx)) ;
[maxErr, maxInd] = max(Diff(:));
[maxInd,~] = ind2sub([length(marginalTypes),2],maxInd);

function report_max_err(maxErr, maxInd, iRep, marginalTypes, Input, Case)

switch Case
    case 'uq_MarginalFields'
        fprintf('[uq_MarginalFields] ')
    case 'uq_estimateMoments'
        fprintf('[uq_estimateMoments] ')
end    
fprintf('Rep.Num:%i, MaxErr = %e, in marginal: %s with parameters ', iRep, ...
    maxErr,...
    marginalTypes{maxInd})
if length(Input.Marginals(maxInd).Parameters) > 1
    for jj = 1 : length(Input.Marginals(maxInd).Parameters) -1
        fprintf('%f, ', Input.Marginals(maxInd).Parameters(jj))
        % stop printing all values if Parameters vector is too long
        % (e.g. in ks)
        if jj > 8
            fprintf('..., ')
            break
        end
    end
end
fprintf('%f\n', Input.Marginals(maxInd).Parameters(end))
