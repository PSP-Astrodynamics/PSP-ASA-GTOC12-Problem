function uq_print_uq_inversion(module)
% UQ_PRINT_UQ_INVERSION pretty prints the results of an inverse analysis
%    carried out with the Bayesian inversion module of UQLab.
%
%    UQ_PRINT_UQ_INVERSION(MODULE) if postprocessing of MODULE has been
%    carried out using the uq_postProcessInversionMCMC function, this
%    information is incorporated into the printed information.
%
% See also: UQ_DISPLAY_UQ_INVERSION, UQ_POSTPROCESSINVERSIONMCMC

%% CONSISTENCY CHECKS
if ~strcmp(module.Type, 'uq_inversion')
    error('uq_print_uq_inversion only operates on objects of type ''Inversion''')
end

% switch if custom likelihood
if module.Internal.customLikeli
    CUSTOM_LIKELI = true;
else
    CUSTOM_LIKELI = false;
end

%% INITIALIZE
% Check which post processed arrays are available
if isfield(module.Results,'PostProc')
    if isfield(module.Results.PostProc,'MPSRF')
        MPSRF_avail = true;
        MPSRF = module.Results.PostProc.MPSRF;
    else
        MPSRF_avail = false;
    end
    if isfield(module.Results.PostProc,'PointEstimate')
        pointEstimate_avail = true;
        pointParam = module.Results.PostProc.PointEstimate.X;
        pointParamType = module.Results.PostProc.PointEstimate.Type;
    else
        pointEstimate_avail = false;
    end
    if isfield(module.Results.PostProc,'Percentiles')
        percentiles_avail = true;
        posterior_stats = [module.Results.PostProc.Percentiles.Mean; module.Results.PostProc.Percentiles.Var];
        percentiles = module.Results.PostProc.Percentiles.Values;
        probabilities = module.Results.PostProc.Percentiles.Probabilities;
    else
        percentiles_avail = false;
    end
    if isfield(module.Results.PostProc,'Dependence')
        dependence_avail = true;
        correlationMatrix = module.Results.PostProc.Dependence.Corr;
    else
        dependence_avail = false;
    end
    if isfield(module.Results.PostProc,'Evidence')
        evidence_avail = true;
        evidence = module.Results.PostProc.Evidence(end);
    else
        evidence_avail = false;
    end
else
    %nothing is available
    dependence_avail = false;
    MPSRF_avail = false;
    pointEstimate_avail = false;
    percentiles_avail = false;
    evidence_avail = false;
end

if ~CUSTOM_LIKELI
    %Get number of model and discrepancy parameters
    MDiscrepancy = nnz(module.Internal.paramDiscrepancyID);
    MModel_nonConst = module.Internal.nNonConstModelParams;
    MModel_Const = numel(module.Internal.ModelConstInfo.idConst);
    nDataGroups = module.Internal.nDataGroups;
    nForwardModels = module.Internal.nForwardModels;
else
    MModel_nonConst = length(module.Internal.FullPrior.Marginals);
end
Solver = module.Internal.Solver;

% get labels for parameters
for ii = 1:length(module.Internal.FullPrior.Marginals)
    currLabel = module.Internal.FullPrior.Marginals(ii).Name;
    % assign to container
    paramLabels{ii} = currLabel;
end

% maximum number of matrix print outputs
NMaxMatrixOut = 6;


%% Printing to the console
%  Display
fprintf('\n%%----------------------- Inversion output -----------------------%%\n');
if CUSTOM_LIKELI
    fprintf('   User-specified likelihood used \n');
else
    fprintf('   Number of calibrated model parameters:         %i\n', MModel_nonConst);
    fprintf('   Number of non-calibrated model parameters:     %i\n\n', MModel_Const);
    fprintf('   Number of calibrated discrepancy parameters:   %i\n\n', MDiscrepancy);
    
    % loop over data groups
    fprintf('%%------------------- Data and Discrepancy');
    for ii = 1:nDataGroups
        dataCurr = module.Internal.Data(ii).y;
        discrCurr = module.Internal.Discrepancy(ii);
        MOMap = module.Internal.Data(ii).MOMap;
        % data group info
        fprintf('\n');
        fprintf('%%  Data-/Discrepancy group %i:\n', ii);
        fprintf('   Number of independent observations:            %i\n\n', size(dataCurr,1));
        % discrepancy group info
        fprintf('   Discrepancy:\n');
        fprintf('      Type:                                       %s\n', discrCurr.ParamType);
        fprintf('      Discrepancy family:                         %s\n', discrCurr.ParamFamily);
        %parameters inferred or known
        if discrCurr.ParamKnown == 1
            fprintf('      Discrepancy parameters known:               Yes\n\n');
        else
            fprintf('      Discrepancy parameters known:               No\n\n');
        end
        %display associated model output
        fprintf('   Associated outputs:\n');
        for jj = 1:nForwardModels
            if any(MOMap(1,:)==jj)
                fprintf('      Model %i: \n', jj);
                assocOutput = MOMap(2,MOMap(1,:)==jj);
                fprintf('         Output dimensions:                       %i\n', assocOutput(1));
                if length(assocOutput) > 1
                    showNumber = [1,diff(assocOutput,2)~=0,1]; %always show first and last
                    for kk = 2:length(assocOutput)
                        if showNumber(kk)~=0
                            fprintf('                                                  %i\n', assocOutput(kk));
                        elseif showNumber(kk-1)~=0
                            fprintf('                                                  to\n');
                        end
                    end
                    fprintf('\n');
                end
            end
        end
    end
    fprintf('\n');
end

% solver
fprintf('%%------------------- Solver\n');
fprintf('   Solution method:                               %s\n\n', Solver.Type);
switch lower(Solver.Type)
    case {'mcmc'}
        durationString = sprintf('%02d:%02d:%02d',...
            fix(mod(module.Results.Time, [0 3600 60]) ./ [3600 60 1]));
        fprintf('   Algorithm:                                     %s\n',Solver.MCMC.Sampler);
        fprintf('   Duration (HH:MM:SS):                           %s\n',durationString);
        fprintf('   Number of sample points:                       %.2e\n\n',numel(module.Results.Sample(:,1,:)));
end

%% Print Postprocessing results
%% first just the statistics of the posterior
if percentiles_avail
    fprintf('%%------------------- Posterior Marginals\n');
    TStr(1,:) = {'Parameter', 'Mean', 'Std',sprintf('(%.3g-%.3g) Quant.',probabilities(1),probabilities(end)),'Type'};
    for mm = 1:length(paramLabels)
        if mm <= MModel_nonConst
            PT = 'Model';
        else
            PT = 'Discrepancy';
        end
        TStr(mm+1,:) = {paramLabels{mm} posterior_stats(1,mm) sqrt(posterior_stats(2,mm)) sprintf('(%2.2g - %2.2g)',percentiles(1,mm), percentiles(end,mm)),PT};
    end
    uq_printTable(TStr)
    fprintf('\n');
end

%%
if evidence_avail
fprintf('%%------------------- Evidence\n');
fprintf('   Evidence:                                      %s\n\n', evidence);
end

if pointEstimate_avail
    fprintf('%%------------------- Point estimate\n');


    clear TStr;
    TStr(1,:) = {'Parameter'};
    % labels
    for ii = 1:size(pointParam{1},2)
        TStr(ii+1,1) = {paramLabels{ii}};
    end
    % actual parameters
    for pp = 1:length(pointParam)
        TStr(1,end+1) = pointParamType(pp);
        % take care of multiple parameters (custom)
        nParams = size(pointParam{pp},1);
        if nParams > 1
            % fill with param type
            TStr(1,end + nParams-1) = pointParamType(pp);
        end
        for ii = 1:size(pointParam{pp},2)
            for jj = 1:size(pointParam{pp},1)
                TStr(ii+1,end - nParams + jj) = {pointParam{pp}(jj,ii)};
            end
        end
    end
    % parameter type
    TStr(1,end+1) = {'Parameter Type'};
    for ii = 1:size(pointParam{1},2)
        if ii <= MModel_nonConst
            TStr(ii+1,end) = {'Model'};
        else
            TStr(ii+1,end) = {'Discrepancy'};
        end
    end
    uq_printTable(TStr)
    fprintf('\n');
end

if dependence_avail
    if ~CUSTOM_LIKELI
        % plot correlation matrix (model)
        % get important parameters
        currCorrMatrix = correlationMatrix(1:MModel_nonConst, 1:MModel_nonConst);
        printIdx = getPrintIdx(currCorrMatrix, NMaxMatrixOut);
        if MModel_nonConst > 1
            if MModel_nonConst > NMaxMatrixOut
                fprintf('%%------------------- Correlation matrix, %d most important (model parameters)\n',NMaxMatrixOut);
            else
                fprintf('%%------------------- Correlation matrix (model parameters)\n');  
            end
            modelParamLabels = paramLabels(printIdx);
            uq_printMatrix(currCorrMatrix(printIdx,printIdx),modelParamLabels,modelParamLabels)
            fprintf('\n');
        end

        % plot correlation matrix (discrepancy)
        if MDiscrepancy > 1
            % get important parameters
            currCorrMatrix = correlationMatrix(MModel_nonConst+1:end,MModel_nonConst+1:end);
            printIdx = getPrintIdx(currCorrMatrix, NMaxMatrixOut);
            if size(currCorrMatrix,1) > NMaxMatrixOut
                fprintf('%%------------------- Correlation matrix, %d most important (discrepancy parameters)\n',NMaxMatrixOut);
            else
                fprintf('%%------------------- Correlation matrix (discrepancy parameters)\n');  
            end
            discrepancyParamLabels = paramLabels(MModel_nonConst+printIdx);
            uq_printMatrix(currCorrMatrix(printIdx,printIdx),discrepancyParamLabels,discrepancyParamLabels)
            fprintf('\n');
        end
    else
        % plot correlation matrix
        if MModel_nonConst > 1
            currCorrMatrix = correlationMatrix(1:MModel_nonConst,1:MModel_nonConst);
            printIdx = getPrintIdx(currCorrMatrix, NMaxMatrixOut);
            if MModel_nonConst > NMaxMatrixOut
                fprintf('%%------------------- Correlation matrix, %d most important (model parameters)\n',NMaxMatrixOut);
            else
                fprintf('%%------------------- Correlation matrix (model parameters)\n');  
            end 
            modelParamLabels = paramLabels(printIdx);
            uq_printMatrix(currCorrMatrix(printIdx,printIdx),modelParamLabels,modelParamLabels)
            fprintf('\n');
        end
    end
end

% gelman rubin
if MPSRF_avail
    fprintf('%%------------------- Convergence\n');
    fprintf('   Gelman-Rubin MPSRF:                            %d\n', MPSRF);
end
fprintf('\n\n');
end

function printIdx = getPrintIdx(printMatrix, NMaxMatrixOut)
% Determine the print indices for the matrix output, this function makes
% sure that the highest absolute values of printMatrix are included in the 
% displayed matrix
if size(printMatrix,1) <= NMaxMatrixOut
    printIdx = 1:size(printMatrix,1);
else
    tempCorrMatrix = abs(tril(printMatrix,-1));
    printIdx = [];
    while length(printIdx) < NMaxMatrixOut
        % get maximum in matrix and overwrite with 0
        [~,currMaxLinIdx] = max(tempCorrMatrix(:));
        [iIdx, jIdx] = ind2sub(size(tempCorrMatrix), currMaxLinIdx);
        tempCorrMatrix(iIdx, jIdx) = 0;
        printIdx = unique([printIdx, iIdx, jIdx]);
    end
    printIdx = sort(printIdx);
end
end