function Results = uq_SPCE_calculate_regression(current_model,indices,MeanOptions)
% Results = UQ_PCE_CALCULATE_COEFFICIENTS_REGRESSION(CURRENT_MODEL):
%     build the stochastic polynomial chaos expansions of CURRENT_MODEL for
%     given indices and mean fitting options using maximum likelihood for
%     the coefficient estimation and cross-validation for the sigma
%     selection

% get current output and latent variable indices
current_output = current_model.Internal.Runtime.current_output;
current_latent = current_model.Internal.Runtime.current_latent;

% get display level
DisplayLevel = current_model.Internal.Display;
% whether to standardize the data
Standardize = current_model.Internal.SPCE.Standardize;

%% save important information for the subsequent optimizatoin
SPCEOpt.current_latent = current_latent;
SPCEOpt.IntMethod = current_model.Internal.SPCE.IntMethod;
SPCEOpt.(SPCEOpt.IntMethod) = current_model.Internal.SPCE.(SPCEOpt.IntMethod);
SPCEOpt.Sigma = current_model.Internal.SPCE.Sigma;
SPCEOpt.DisplayLevel = DisplayLevel;

%% Standardize the data
Y = current_model.ExpDesign.Y(:,current_output);
if Standardize
    muY = mean(Y(:));
    stdY = std(Y(:),1);
    Y = (Y-muY)./stdY;
    if uq_isnonemptyfield(SPCEOpt.Sigma,'Value')
        SPCEOpt.Sigma.Value = SPCEOpt.Sigma.Value/stdY;
    end
end

%% fit the mean function
if ~current_model.Internal.SPCE.MeanReg.separateFit
    MeanOptions.ExpDesign.Y = mean(Y,3);
    MeanPCE = uq_createModel(MeanOptions,'-private');
    MeanPCE = MeanPCE.PCE;
    loo = MeanPCE.Error.LOO*var(mean(Y,3),1,1);
else
    if DisplayLevel>1
        fprintf('Fit the mean function...');
    end
    MeanPCE = current_model.Internal.SPCE.Mean.PCE(current_output);
    loo = current_model.Internal.SPCE.Mean.Error(current_output).LOO*var(mean(Y,3),1,1);
    if DisplayLevel>1
        fprintf('Mean function estimation completed.');
    end
end
% get the leave-one-out error of the mean fit
R = size(Y,3);
if R==1
    EVarYX = loo;
else
    EYYx = mean(Y(:,1,2:end).*cumsum(Y(:,1,1:end-1),3),3)/R;
    EVarYX = mean(Y(:).^2) - mean(EYYx);
    loo =  loo + (R-1)/R*EVarYX;
end

%% arrange multi-indices

% retrieve the nonzero coefficients and multi-indices associated with the
% mean function.
MeanCoeff = MeanPCE.Coefficients;
NonZeroCoefind = MeanCoeff~=0;
MeanCoeff = MeanCoeff(NonZeroCoefind);
MeanInd = MeanPCE.Basis.Indices(NonZeroCoefind,:);
NmeanBasis = sum(NonZeroCoefind);
% if the data is standardized, the constant term must be included
if ~ismember(zeros(1,size(MeanInd,2)),MeanInd,'rows') && Standardize && ~isempty(MeanInd)
    MeanInd = [zeros(1,size(MeanInd,2));MeanInd];
    MeanCoeff = [0; MeanCoeff];
    NmeanBasis = NmeanBasis+1;
end

% update the extended multi-indices
indicesNonMean = indices(:,end)~=0;
indicesNonMean = indices(indicesNonMean,:);
% sort the nonzero degrees
[latentDeg,arrangeInd]=sort(full(indicesNonMean(:,end)),'ascend');
% gather all the multi-indices and sort them by the degree of the latent
% variable
indices = [MeanInd,zeros(size(MeanInd,1),1);indicesNonMean(arrangeInd,:)];

%% Save the information about the latent variable
ZBasis = struct;
% calculate the degrees and the associated indices of the basis
if isempty(latentDeg)
    degreeIncInd = [];
else
    degreeIncInd = find([diff(latentDeg);1]);
end
if NmeanBasis>0    
    ZBasis.ZDegree = [0;latentDeg(degreeIncInd)];
    ZBasis.ZDegreeIndices = [0;NmeanBasis;NmeanBasis+degreeIncInd];    
else
    ZBasis.ZDegree = latentDeg(degreeIncInd);
    ZBasis.ZDegreeIndices = [0;degreeIncInd];    
end
ZBasis.ZDegreeIndices = [1+ZBasis.ZDegreeIndices(1:end-1),ZBasis.ZDegreeIndices(2:end)];

ZBasis.PolyTypes = current_model.Internal.SPCE.Basis.LatentPolyTypes(current_latent);
ZBasis.PolyTypesParams = current_model.Internal.SPCE.Basis.LatentPolyTypesParams(current_latent);
ZBasis.PolyTypesAB = current_model.Internal.SPCE.Basis.LatentPolyTypesAB(current_latent);
ZBasis.LatentDist = current_model.Internal.ED_LatentDist.Marginals(current_latent);
ZBasis.MaxDegrees = current_model.Internal.SPCE.Basis.maxLatentDeg;

%% prepare the multivariate basis functions
XBasis = struct;
[IndicesX,~,XBasis.uniqueBasisToindices] = unique(indices(:,1:end-1),'rows');
XBasis.PsiX = uq_PCE_create_Psi(IndicesX,current_model.Internal.SPCE.phiX);

%% compute the initial points
Nbasis = size(indices,1);
coeff0 = zeros(Nbasis,1);
% fill in the mean coefficients
if NmeanBasis>0
    coeff0(1:NmeanBasis) = MeanCoeff;    
end
% random initialze the rest
randomIni = randn(Nbasis-NmeanBasis,1);
randomIni = randomIni/norm(randomIni)*sqrt(EVarYX);
coeff0(NmeanBasis+1:end) = randomIni;

%% initialize sigma values

% find upper and lower bounds to search for sigma
sigmax = sqrt(EVarYX);
sigmin = 0.1*sigmax;

% early stop, by default it is set to true
EarlyStop = true;

% If the sigma values are provided
if uq_isnonemptyfield(SPCEOpt.Sigma,'Value')
    % no need to optimize sigma
    OptimSigma = false;    
    % if only a single sigma is given
    if length(SPCEOpt.Sigma.Value)==1
        % no need to run cv
        needSelection = false;
        % the target value is small than sigmax
        if SPCEOpt.Sigma.Value<sigmax
            % generate a regular grid to guide the optimization
            N_ini = 5;
            logsigma_ini = linspace(log(sigmax),log(SPCEOpt.Sigma.Value),N_ini+1);
            logsigma_ini(end)=[];
        else
            % the target value is smaller or equal to sigmax
            % no need to guide
            N_ini = 0;
            logsigma_ini = [];
        end
        
    % if multiple sigma values are given
    else
        % the early stop should be turned off
        EarlyStop = false;
        % need CV for model seletction
        needSelection = true;
        % set initial values
        logsigma_ini = sort(log(SPCEOpt.Sigma.Value),'descend');
        N_ini = length(logsigma_ini);
    end
   
% if the sigma values are not given    
else
    % need to optimize sigma
    OptimSigma = true;    
    % need CV to select the starting point
    needSelection = true;    
    % generate the grid for searching
    N_ini = 10;
    logsigma_ini = linspace(log(sigmax),log(sigmin),N_ini);
end

%% fit the model
if needSelection
    
    % calculate for a grid of sigmas to search for a good starting point
    lhcv = nan(N_ini,1);
    coeftemp = repmat(coeff0,[1,N_ini]);
    iid = 1;
    for ii = 1:N_ini
        if ii ==1
            coeff_ini = coeff0;
        else
            coeff_ini = coeftemp(:,ii-1);
        end
        
        % Perform CV for the given sigma
        [lhcvtmp,coeftemp(:,ii)] = uq_SPCE_CVScore(Y,coeff_ini,logsigma_ini(ii),XBasis,ZBasis,SPCEOpt);
        lhcv(ii) = mean(lhcvtmp);
        
        % Update the cv score
        if lhcv(ii)<lhcv(iid)
            iid = ii;
        end
        
        % if two consecutive update does not improve the value, stop
        % earlier
        if EarlyStop && ii - iid >2
            % update the information
            lhcv = lhcv(1:ii);
            N_ini = ii;
            break;
        end
    end
    
    % find local optima
    icv = find(islocalmax(-lhcv),1,"last");
    
    % if no local peak is found
    if isempty(icv)
        if lhcv(1)<lhcv(end)
            icv = 2;
            Nev = 3;
        else
            icv = N_ini;
            Nev = N_ini;
        end
        
    % The location of the last peak is the initial guess for sigma.    
    else
        % retrieve the index of the last local optima
        Nev = icv+1;       
    end
    
    % save the model evaluation for further CV
    lsig = logsigma_ini(Nev);
    usig = logsigma_ini(1);
    iniX.logs = logsigma_ini(1:Nev)';
    inicv = lhcv(1:Nev);       
    
    % if no optimization is needed or the difference is small
    if ~OptimSigma || max(lhcv)-min(lhcv)<1e-3
        % find the optimal points
        [~,id] = min(lhcv);
        coeff_ini = coeftemp(:,id);
        logsigma = logsigma_ini(id);
        IC.CV = lhcv(id);
    
    % optimize sigma
    else
        coeff_ini = coeftemp(:,icv);
        logs = optimizableVariable('logs',[lsig,usig]);
        iniX = struct2table(iniX);
        
        % verbose
        verbose = max(DisplayLevel-1,0);
        
        % additional runs (at most 10 additional runs)
        Nev = Nev + 10;
        results = bayesopt(@(x) mean(uq_SPCE_CVScore(Y,coeff_ini,x.logs,XBasis,ZBasis,SPCEOpt)),logs,...
        'MaxObjectiveEvaluations',Nev,'InitialX',iniX,'InitialObjective',inicv,...
        'IsObjectiveDeterministic',true,'PlotFcn', [],'Verbose',verbose);
        IC.CV = results.MinObjective;
        logsigma = results.XAtMinObjective.logs;
    end
    
    % save the starting points
    coeff0 = coeff_ini;
    sigma = exp(logsigma);

% if no selection is needed
else
    coeff_ini = coeff0;
    for ii = 1:N_ini
        sigtmp = exp(logsigma_ini(ii));
        [coeff_ini,~] = uq_SPCE_optimize_NLogLikelihood(Y,coeff_ini,sigtmp,XBasis,ZBasis,SPCEOpt);
    end
    % save the starting points
    coeff0 = coeff_ini;
    sigma = SPCEOpt.Sigma.Value;
end

% refit the coefficients with all the data
[coeffnew,IC.Nloglikelihood] = uq_SPCE_optimize_NLogLikelihood(Y,coeff0,sigma,XBasis,ZBasis,SPCEOpt);

% if no CV selection was performed before, compute the CV score
if ~needSelection
    IC.CV = mean(uq_SPCE_CVScore(Y,coeffnew,log(sigma),XBasis,ZBasis,SPCEOpt));
end

%% calculate information criteria
N_data = numel(Y);

% if the data are standardized, we need to transform them back
if Standardize
    sigma = sigma*stdY;
    coeffnew = coeffnew*stdY;
    ind = all(~indices,2);
    coeffnew(ind) = coeffnew(ind)+muY;
    IC.Nloglikelihood = IC.Nloglikelihood + N_data*log(stdY);
    IC.CV = IC.CV + N_data*log(stdY);
end
        
IC.BIC = 2*IC.Nloglikelihood + sum(coeffnew~=0)*log(N_data);
IC.AIC = 2*IC.Nloglikelihood + sum(coeffnew~=0)*2;

%% Save the results
Results.LatentType = ZBasis.LatentDist.Type;
Results.LatentParam = ZBasis.LatentDist.Parameters;
Results.Indices = indices;
Results.Coefficients = coeffnew;
Results.Sigma = sigma;
Results.IC = IC;
end