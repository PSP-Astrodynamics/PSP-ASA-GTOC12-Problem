function pass = uq_default_input_test_samplesFromMoments( level )
% pass = UQ_DEFAULT_INPUT_TEST_SAMPLESFROMMOMENTS(LEVEL): validation and 
% test for the random variable specification via moments (mean and standard
% deviation)
%
% Summary:
% Samples of random variables that follow each of the available built-in distributions
% are generated. The required moments of the distribution are set during the 
% specification of the random variables and their values are tested against
% the actual moments of the samples that are generated. In order to further
% test the Moments to Parameters transformation instead of comparing the
% moments directly the corresponding parameters are tested instead. 
 

%% initialize test
evalc('uqlab');
if nargin < 1
    level = 'normal'; 
    rng(20);
end
fprintf(['\nRunning: |' level '| uq_default_input_test_parametersMoments...\n']);

pass = 1;

%% parameters
N = 1e4;
epsRel = 2e-2 ;
Ncases = 50;
meanBnd = [1.5,6];
stDevBnd = [0.1 1];

%% get available marginals
marginalTypes = uq_getAvailableMarginals() ;


%% exclude some distributions from this test
% Student's distribution is actually tested but it is treated as a special
% case
marginalTypes(strcmpi(marginalTypes,'student')) = [] ;
marginalTypes(strcmpi(marginalTypes,'triangular')) = [] ; 
marginalTypes(strcmpi(marginalTypes,'ks')) = [] ; 

testPass = zeros(length(marginalTypes), 2);

for ii = 1 : length(marginalTypes)
    %% generate random moment values
    Input.Marginals(1).Type = 'Uniform';
    Input.Marginals(1).Parameters = meanBnd ;
    Input.Marginals(2).Type = 'Uniform';
    Input.Marginals(2).Parameters = stDevBnd ;
    
    % apply some bounds on the allowable moment values for some
    % distributions
    switch lower(marginalTypes{ii})
        case {'lognormal', 'weibull'}
            Input.Marginals(1).Bounds = [1 , 3];
            Input.Marginals(2).Bounds = [0.1, 0.6];
        case {'beta','gamma'}
            Input.Marginals(1).Bounds = [0.3 , 0.6];
            Input.Marginals(2).Bounds = [0.1 , 0.2];
        case {'gumbel','gumbelmin'}
            Input.Marginals(1).Bounds = [1 , 3];
            Input.Marginals(2).Bounds = [0.1, 0.8];
        otherwise
            % do nothing
    end
    

    % Create a set of desired moments for othe current random vector
    uq_createInput(Input);
    Moments = uq_getSample(Ncases,'LHS') ;
    clear Input  ;
    
    %% Produce an Ncases-dimensional random vector , each dimension has one of the sampled Moments
    bounds = zeros(Ncases,2) ;
    for jj = 1 : Ncases
        Input.Marginals(jj).Type = marginalTypes{ii};
        Input.Marginals(jj).Moments = Moments(jj,:);
        
        if strcmpi(marginalTypes{ii},'Beta')
         %  produce random support
            bounds(jj,:) = [Input.Marginals(jj).Moments(1) - 3 *  Input.Marginals(jj).Moments(2),...
               Input.Marginals(jj).Moments(1) + 3 *  Input.Marginals(jj).Moments(2)] ;
         % add the support to the moments definition
         Input.Marginals(jj).Moments = [Input.Marginals(jj).Moments bounds(jj,:)];
        end
        
    end
    myInput = uq_createInput(Input);
    %% generate samples from that random vector
    X = uq_getSample(N, 'Sobol');
    
    %% estimate the moments from the samples
    muEst = mean(X, 1);
    stdevEst = std(X, 0, 1);
    for jj = 1 : Ncases
        MarginalsEst(jj).Type = marginalTypes{ii};
        MarginalsEst(jj).Moments = [muEst(jj), stdevEst(jj)] ;
        if strcmpi(marginalTypes{ii},'Beta')
            % If beta distribution add the bounds in moments
            MarginalsEst(jj).Moments = [MarginalsEst(jj).Moments bounds(jj,:)];
        end
    end
    
    %% Estimate the Parameters from the Estimated Moments
    MarginalsEst = uq_MarginalFields(MarginalsEst) ;
    % If its a beta distributon only keep the actual parameters and not the
    % bounds
    if strcmpi(marginalTypes{ii},'Beta')
        for jj = 1 : Ncases
            MarginalsEst(jj).Parameters = MarginalsEst(jj).Parameters(1:2);
        end
    end
    
    %% Calculate error
    % Calculate the error between the Parameters that were calculated using
    % the sampled moments and the Parameters that were calculated using
    % the estimated moments 
    [MargParams{1:Ncases}] = deal(myInput.Marginals(:).Parameters) ;
    MargParams = cell2mat(MargParams.') ;
    if strcmpi(marginalTypes{ii},'Beta')
        MargParams = MargParams(:,1:2);
    end
    [MargEstParams{1:Ncases}] = deal(MarginalsEst(:).Parameters) ;
    MargEstParams = cell2mat(MargEstParams.') ;
    % the relative error is calculated 
    errRel = abs(  (MargParams(:) - MargEstParams(:))./  MargParams(:) *100);


    maxErr = max(errRel)  ;
    testPass(ii,:) = maxErr < epsRel*100;
    currTestPassed = sum(testPass(ii,:)) == 2;
    
    %% reporting
    if length(marginalTypes{ii}) > 9
        fprintf('\n   Marginal: %s,\t\t Max. Error: %6.2f %%\t Pass: %i',...
            marginalTypes{ii}, maxErr, currTestPassed)
    else
         fprintf('\n   Marginal: %s,\t\t\t Max. Error: %6.2f %%\t Pass: %i',...
             marginalTypes{ii}, maxErr, currTestPassed)
    end
    
    pass = pass & currTestPassed ;
    clear Input Marginals MarginalsEst MargParams MargEstParams;
end

%% Student distribution-specific test
clear Input  ;
for jj = 1 : 6
    Input.Marginals(jj).Type = 'Student';
    Input.Marginals(jj).Parameters = jj + 2;
end
myInput = uq_createInput(Input);
X = uq_getSample(N, 'Sobol').';
% estimate moments
muEst = mean(X, 2);
stdevEst = std(X, 0, 2);
for jj = 1 : 6
    MarginalsEst(jj).Type = 'Student';
    MarginalsEst(jj).Moments = [muEst(jj), stdevEst(jj)] ;
end
% Estimate the Parameters from the Estimated Moments
MarginalsEst = uq_MarginalFields(MarginalsEst) ;

% Calculate the error between the Parameters that were calculated using
% the sampled moments and the Parameters that were calculated using
% the estimated moments
[MargParams{1:6}] = deal(myInput.Marginals(:).Parameters) ;
MargParams = cell2mat(MargParams.') ;

[MargEstParams{1:6}] = deal(MarginalsEst(:).Parameters) ;
MargEstParams = cell2mat(MargEstParams.') ;
% the relative error is calculated
errRel = abs(  (MargParams - MargEstParams)./  MargParams *100);
maxErr = max(errRel)  ;
testPass = maxErr < epsRel*100;
currTestPassed = testPass == 1;
fprintf('\n   Marginal: %s,\t\t\t Max. Error: %6.2f %%\t Pass: %i',...
    'student', maxErr, currTestPassed)

pass = pass & currTestPassed ;

