function Metrics = uq_SPCE_evalModelSampleMetrics(mySPCE,X,Y,varargin)
%% Compute the error metrics between a generalized lambda model and data points (X,Y)
% mySPCE: the stochastic polynomial chaos metamodel
% X: the input data
% Y: the associated output samples
% varargin: *('Nllh',calcNllh) whether to compute the negative
%            log-likelihood (specified in calcNllh)
%           *('Quadrature',N) use the quadrature with N levels to 
%            evaluate the negative loglikelihood
%           *('MCS'/'LHS'/'Sobol',N) use the specified sampling method with
%            N points to evaluate the negative loglikelihood
%           *('MatlabInt') use the matlab built-in function integral
%            to evaluate the negative loglikelihood
%           *('WSD',calcWSD) whether to compute the error metric 
%            related to the Wasserstein distance (WSD)
%           *('WSDRep',R) the number of replications/samples of SPCE to 
%            evaluate WSD
%           *('WSDOrder',p) order of WSD
%           *('WSDcalcMethod',method) the method to compute WSD 
%            see uq_GLD_Wasserstein for the possible options
% 

%% Retrieve information of the samples
Nout = mySPCE.Internal.Runtime.Nout;
Nval = size(Y,1);
R = size(Y,3);

%% get default integration method (for the likelihood evaluation) if exists 
if uq_isnonemptyfield(mySPCE.Internal,'SPCE') && uq_isnonemptyfield(mySPCE.Internal.SPCE,'Sigma')...
    && uq_isnonemptyfield(mySPCE.Internal.SPCE.Sigma,'IntMethod')
    IntMethod = mySPCE.Internal.SPCE.Sigma.IntMethod;
    switch lower(IntMethod)
        case 'quadrature'
            Nint = mySPCE.Internal.SPCE.Sigma.Quadrature.Level;
        case 'sampling'
            Nint = mySPCE.Internal.SPCE.Sigma.Sampling.N;
    end
end
%% parse and update the options likelihood evaluation
parse_keys = {'Nllh','Quadrature','MCS','LHS','Sobol','MatlabInt'};
parse_types = {'p','p','p','f','p','f'};
[parsed, ~] = uq_simple_parser(varargin, parse_keys, parse_types);

if strcmp(parsed{1},'false')
    calcNllh = true;
else
    calcNllh = parsed{1};
end

if ~strcmp(parsed{2},'false')
    IntMethod = 'Quadrature';
    Nint = parsed{2};
elseif ~strcmp(parsed{3},'false')
    IntMethod = 'MCS';
    Nint = parsed{3};
elseif ~strcmp(parsed{4},'false')
    IntMethod = 'LHS';
    Nint = parsed{4};
elseif ~strcmp(parsed{5},'false')
    IntMethod = 'Sobol';
    Nint = parsed{5};     
elseif ~strcmp(parsed{6},'false')
    IntMethod = 'MatlabInt';
elseif calcNllh
    IntMethod = 'Quadrature';
    Nint = 1e3;
end

%% parse the options related to the Wasserstein distance calculation
parse_keys = {'WSD','WSDRep','WSDOrder','WSDcalcMethod'};
parse_types = {'p','p','p','p'};
[parsed, ~] = uq_simple_parser(varargin, parse_keys, parse_types);

% whether to compute the Wasserstein distance
if ~strcmp(parsed{1},'false')
    calcWSD=parsed{1};
    if calcWSD && R==1
        calcWSD = false;
        warning('No replication in the data, the Wasserstein distance is not calculated.');
    end    
% if not defined, only when there are more than 10 replications will the
% Wasserstein distance be calculated
elseif R>10
    calcWSD = true;
else
    calcWSD = false;
end

% number of replications of the SPCE to evaluate the Wasserstein
% distance
if strcmp(parsed{2},'false')
    % we set by default the number of replications 
    WSDRep=1e4;
else
    % the user specifies number of replications
    WSDRep = parsed{2};
end

% the user does not specify the order of the Wasserstein Distance (WSD)
if strcmp(parsed{3},'false')
    % we set by default p=2
    p=2;
else
    % the user specifies the order of WSD
    p = parsed{3};
end
% the user does not specify the way to evaluate WSD
if strcmp(parsed{4},'false')
    % we set by default the exact WSD
    calcMethod= 'ot';
else
    % the user specifies calculation method for WSD
    calcMethod = parsed{4};
end

%% whether to compute the wasserstein distance

% generate samples to evaluate WSD
if calcWSD
    % try to generate all the data
    try
        Ysamples = uq_evalModel(mySPCE,X,WSDRep);
        generateIndividualSamples = false;
        % if run out of memory, we will generate the data at the individual level
    catch
        generateIndividualSamples = true;
    end
end

%% Evaluate the error metrics

% initialze the error metric structure
Metrics = struct;

for oo=1:Nout
    %% compute the negative log-likelihood
    if calcNllh
        % evaluate the coefficients for the expansion in Z
        [coefZ,Zdegree] = uq_SPCE_LatentPCECoeff(mySPCE,X,oo);
        
        % get the std of the noise term
        sigma = mySPCE.SPCE(oo).Sigma;
        
        % save the basis functions for the latent variable
        ZBasis.LatentDist = mySPCE.Internal.ED_Latent{oo}.Marginals;
        ZBasis.PolyTypes = mySPCE.SPCE(oo).Basis.PolyTypes(end);
        ZBasis.PolyTypesParams = mySPCE.SPCE(oo).Basis.PolyTypesParams(end);
        ZBasis.MaxDegrees = Zdegree(end);
        
        % perform numerical integration to evaluate the negative loglikelihood
        switch lower(IntMethod)
            % apply the matlab integration function
            case 'matlabint'
                ZBasis.ZDegree = Zdegree;
                nllh = uq_SPCE_NLogLikelihood_MatlabInt(Y(:,oo,:),coefZ,sigma,ZBasis);
                % apply quadrature
            case 'quadrature'
                [intZ,WZ]=uq_quadrature_nodes_weights_gauss(Nint,ZBasis.PolyTypes,ZBasis.PolyTypesParams);
                phiZ = permute(uq_eval_univ_basis(intZ,ZBasis),[1,3,2]);
                nllh = uq_SPCE_NLogLikelihood_Quadrature(Y(:,oo,:),coefZ,sigma,phiZ(:,Zdegree+1),WZ);
                % apply the sampling method specified by the user
            otherwise
                intZ = uq_getSample(mySPCE.Internal.ED_Latent{oo},Nint,IntMethod);
                phiZ = permute(uq_eval_univ_basis(intZ,ZBasis),[1,3,2]);
                nllh = uq_SPCE_NLogLikelihood_Quadrature(Y(:,oo,:),coefZ,sigma,phiZ(:,Zdegree+1));
        end
        Metrics(oo).NLoglikelihood = sum(nllh);
    end
    
    %% Compute the Wasserstein distance
    if calcWSD 
        Metrics(oo).WSD = nan(Nval,1);
        if ~generateIndividualSamples
            for ix = 1:Nval
                Metrics(oo).WSD(ix) = uq_TwoSamplesWasserstein(Ysamples(ix,oo,:),Y(ix,oo,:),p,calcMethod);
            end
            Metrics(oo).NormalizedWSD = mean(Metrics(oo).WSD.^p)/mean(abs( reshape(Y(:,oo,:),Nval*R,1) - mean(reshape(Y(:,oo,:),Nval*R,1)) ).^p);
        end
    end
end

% compute the Wasserstein distance if samples should be generated at
% individual levels
if calcWSD && generateIndividualSamples
    for ix = 1:Nval
        Ysamples = uq_evalModel(mySPCE,X(ix,:),WSDRep);
        for oo = 1:Nout
             Metrics(oo).WSD(ix) = uq_TwoSamplesWasserstein(Ysamples(1,oo,:),Y(ix,oo,:),p,calcMethod);
        end
    end
    % compute the normalized WSD
    for oo=1:Nout
        Metrics(oo).NormalizedWSD = mean(Metrics(oo).WSD.^p)/mean(abs(squeeze(Y(:,oo,:))-mean(Y(:,oo,:),'all')).^p);
    end
end


end