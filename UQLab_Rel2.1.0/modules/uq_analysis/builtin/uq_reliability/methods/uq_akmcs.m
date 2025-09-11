function [Results] = uq_akmcs(CurrentAnalysis)
% [Results] = UQ_AKMCS(CurrentAnalysis) computes an adaptive Kriging Monte
%     Carlo simulation
% 
% References:
%
%     Echard, B., N. Gayton, and M. Lemaire (2011). AK-MCS: an active learning reliability method
%     combining Kriging and Monte Carlo simulation. Structural Safety 33(2), 145–154.
%
% See also: UQ_MC, UQ_KRIGING_CALCULATE_COEFFICIENTS

Options = CurrentAnalysis.Internal;
nonConst = Options.Input.nonConst;


%% Check initial experimental design for meta-model
if isfield(Options.AKMCS.IExpDesign, 'X') && isfield(Options.AKMCS.IExpDesign, 'G')
    Options.AKMCS.IExpDesign.N = length(Options.AKMCS.IExpDesign.X(:,1));
    CurrentAnalysis.Internal.AKMCS.IExpDesign.N = Options.AKMCS.IExpDesign.N;
    NIExpDesign = 0;
else if isfield(Options.AKMCS.IExpDesign, 'X')
        Options.AKMCS.IExpDesign.G = uq_evalLimitState(Options.AKMCS.IExpDesign.X, Options.Model, Options.LimitState, Options.HPC.MC);
        Options.AKMCS.IExpDesign.N = length(Options.AKMCS.IExpDesign.X(:,1));
        CurrentAnalysis.Internal.AKMCS.IExpDesign.N = Options.AKMCS.IExpDesign.N;
        NIExpDesign = Options.AKMCS.IExpDesign.N;
    else
        Options.AKMCS.IExpDesign.X = uq_getSample(Options.Input, Options.AKMCS.IExpDesign.N, Options.AKMCS.IExpDesign.Sampling);
        Options.AKMCS.IExpDesign.G = uq_evalLimitState(Options.AKMCS.IExpDesign.X, Options.Model, Options.LimitState, Options.HPC.MC);
        NIExpDesign = Options.AKMCS.IExpDesign.N;
    end
end

%% Initiate the adaptive Kriging
% metaopts
if isfield(Options.AKMCS, Options.AKMCS.MetaModel)
    metaopts = Options.AKMCS.(Options.AKMCS.MetaModel);
end
metaopts.Type = 'Metamodel';
metaopts.MetaType = Options.AKMCS.MetaModel;
metaopts.Input = Options.Input ;

% specify the Kriging display options
if ~isfield(metaopts, 'Display')
    if Options.Display == 2
        metaopts.Display = 2;
    else
        metaopts.Display = 0;
    end
end

%learning function
LFfunction = str2func(['uq_LF_', Options.AKMCS.LearningFunction]);

%convergence function
Convfunction = str2func(['uq_akmcs_',Options.AKMCS.Convergence]);

% convergence in MCS
if isfield(Options.Simulation, 'TargetCoV') && ~isempty(Options.Simulation.TargetCoV);
    % The method will stop when TargetCoV is reached
    CoVThreshold = true;
    TargetCoV = Options.Simulation.TargetCoV;
else
    CoVThreshold = false;
end

%alpha for confidence bounds
alpha = Options.Simulation.Alpha;

%number of response values
Nout = size(Options.AKMCS.IExpDesign.G,2);

%initial experimental design (the last ExpDesign of oo=1 will be used as
%start of oo=2
X = Options.AKMCS.IExpDesign.X;
g = Options.AKMCS.IExpDesign.G;

Nini = size(X,1);
%% Analysis for each output variable
for oo = 1:Nout
    % Initiate MCS
    MCSampleSize = Options.Simulation.BatchSize;
    MCSampling = Options.Simulation.Sampling;
    MCSample = uq_getSample(Options.Input, MCSampleSize, MCSampling);
    
    xcandidate = MCSample;
    
    NsamplesaddedTotal = 0;
    iteration = 0;
    
    EstimatePf = [];
    EstimatePfall = [];
    EstimatePfallp = [];
    EstimatePfallm = [];
    EstimateNsamplesAdded = [];
    NBatch = [];
    
    Nstart = size(X,1);
    
    %% Monte Carlo simulation
    while 1
        iteration = iteration + 1;
        NsamplesaddedBatch = 0;
        
        %% adaptive meta-modelling
        while 1
            
            
            % build meta-model
            metaopts.ExpDesign.X = X;
            metaopts.ExpDesign.Y = g(:,oo);
            myMetamodel = uq_createModel(metaopts, '-private');
            
            % predict MC responses (only the sample which are not contained in the Kriging yet
            [gmean, gs2] = uq_evalModel(myMetamodel, xcandidate);
            gs = sqrt(gs2);
            
            % evaluate learning function
            lf = LFfunction(gmean, gs);
            
            % select additional sample
            % the sample which maximizes the learning function value
            [~, indlf] = max(lf);
            xadded = xcandidate(indlf, :);
            
            % estimate the failure probability on the run
            EstimatePfall = [EstimatePfall, (sum(gmean <= 0) + sum(g(Options.AKMCS.IExpDesign.N+1:end,oo) <= 0))/MCSampleSize];
            EstimatePfallp = [EstimatePfallp, (sum(gmean - gs*norminv(1-alpha/2) <= 0) + sum(g(Options.AKMCS.IExpDesign.N+1:end,oo) <= 0))/MCSampleSize];
            EstimatePfallm = [EstimatePfallm, (sum(gmean + gs*norminv(1-alpha/2) <= 0) + sum(g(Options.AKMCS.IExpDesign.N+1:end,oo) <= 0))/MCSampleSize];
            EstimateNsamplesAdded = [EstimateNsamplesAdded, NsamplesaddedTotal];
            
            % max sample sizes reached?
            if NsamplesaddedBatch >= Options.AKMCS.MaxAddedSamplesInBatch; break; end
            if NsamplesaddedTotal >= Options.AKMCS.MaxAddedSamplesTotal; break; end
            
            % convergence criterion (evaluate only if at least one point is
            % added)
            CurrentAnalysis.Internal.Runtime.lf = lf;
            CurrentAnalysis.Internal.Runtime.gmean = gmean;
            CurrentAnalysis.Internal.Runtime.gs = gs;
            CurrentAnalysis.Internal.Runtime.g = g(:,oo);
            
            if NsamplesaddedTotal && Convfunction(CurrentAnalysis); break; end
            
            % add the selected sample to the experimental design
            gadded = uq_evalLimitState(xadded, Options.Model, Options.LimitState, Options.HPC.MC);
            X = [X; xadded];
            g = [g; gadded];
            xcandidate(indlf, :) = [];
            NsamplesaddedTotal = NsamplesaddedTotal + 1;
            NsamplesaddedBatch = NsamplesaddedBatch + 1;
            
            % Display
            if Options.Display > 0
                fprintf(['AK-MCS: ',num2str(NsamplesaddedTotal), ' samples added\n'])
                
                if Options.Display >= 3
                     % also print some diagnostics
                     fprintf('Current Pf estimate: %e (%e-%e)\n',EstimatePfall(end),EstimatePfallm(end),EstimatePfallp(end));
                     fprintf('Current beta estimate: %e (%e-%e)\n',-norminv(EstimatePfall(end)),-norminv(EstimatePfallp(end)),-norminv(EstimatePfallm(end)));
                    
                     % Plot convergence if Display >= 5
                     if Options.Display >= 5
                         % create a progress plot if not already there
                         if ~exist('AKMCS_Progress_plotPf', 'var')||~ishandle(AKMCS_Progress_plotPf)
                             AKMCS_Progress_plotPf = uq_figure;
                         end
                         
                         if ~exist('AKMCS_Progress_plotBeta', 'var')||~ishandle(AKMCS_Progress_plotPf)
                             AKMCS_Progress_plotBeta = uq_figure;
                         end
                         % select the figure and make the Pf plot
                         figure(AKMCS_Progress_plotPf);
                         cla;
                         plot(Nini+EstimateNsamplesAdded,EstimatePfall, 'k-', Nini+EstimateNsamplesAdded,EstimatePfallp, 'k--', Nini+EstimateNsamplesAdded,EstimatePfallm, 'k--', 'linewidth',1);
                         set(gca,'YScale','log')
                         xlabel('NTot')
                         ylabel('P_f')
                         drawnow;
                         
                         
                         figure(AKMCS_Progress_plotBeta);
                         cla;
                         plot(Nini+EstimateNsamplesAdded,-norminv(EstimatePfall), 'k-', Nini+EstimateNsamplesAdded,-norminv(EstimatePfallp), 'k--', Nini+EstimateNsamplesAdded,-norminv(EstimatePfallm), 'k--','linewidth',1);
                         xlabel('NTot')
                         ylabel('\beta')
                         drawnow;
                     end
                end
            end
            
        end %adaptive
        NBatch(iteration) = NsamplesaddedBatch;
        
        %% estimate failure probability
        EstimatePf(iteration) = (sum(gmean <= 0) + sum(g(Options.AKMCS.IExpDesign.N+1:end,oo) <= 0))/MCSampleSize;
        
        % estimate the covariance
        EstimateCoV(iteration) = sqrt((1-EstimatePf(iteration)) / EstimatePf(iteration) / MCSampleSize);
        
        
        % check again the maximum number of added samples
        if NsamplesaddedTotal >= Options.AKMCS.MaxAddedSamplesTotal; break; end
        

        
        % check convergence criterion
        if CoVThreshold && (EstimateCoV(iteration) <= TargetCoV)
            % Check if there is a Target CoV and if it is reached
            break
        end
        
        % check maximum number of MC samples
        if MCSampleSize >= Options.Simulation.MaxSampleSize; break; end
        
        %% prepare next iteration (enrich sample size)
        if MCSampleSize + Options.Simulation.BatchSize <= Options.Simulation.MaxSampleSize
            Sample = uq_enrichSample(MCSample, Options.Simulation.BatchSize, Options.Simulation.Sampling, Options.Input);
        else
            Sample = uq_enrichSample(MCSample, Options.Simulation.MaxSampleSize-MCSampleSize, Options.Simulation.Sampling, Options.Input);
        end
        MCSample = [MCSample; Sample];
        MCSampleSize = length(MCSample(:,1));
        xcandidate = [xcandidate; Sample];
        
    end %Monte Carlo simulation
    
    %% store the results
    Results.Pf(oo) = EstimatePf(iteration);
    Results.Beta(oo) = -icdf('normal',Results.Pf(oo),0,1);
    Results.CoV(oo) = EstimateCoV(iteration);
    Results.ModelEvaluations(oo) = NsamplesaddedTotal + NIExpDesign;
    Results.PfCI(oo,:) = Results.Pf(oo) * [1 + norminv(alpha/2)*Results.CoV(oo), 1 + norminv(1-alpha/2)*Results.CoV(oo)];
    Results.BetaCI(oo,:) = fliplr(-norminv(Results.PfCI(oo,:), 0, 1));
    Results.(myMetamodel.MetaType)(oo) = myMetamodel;
    
    Results.History(oo).Pf = EstimatePfall;
    Results.History(oo).PfUpper = EstimatePfallp;
    Results.History(oo).PfLower = EstimatePfallm;
    Results.History(oo).NSamples = EstimateNsamplesAdded;
    Results.History(oo).NInit = Nstart;
    if CurrentAnalysis.Internal.SaveEvaluations
        Results.History(oo).X = X;
        Results.History(oo).G = g;
        Results.History(oo).MCSample = MCSample;
    end
    
end %oo

%display the end of the algorithms
if Options.Display > 0
    fprintf('\n\nAK-MCS: Finished. \n')
end