function [ Results ] = uq_subsetsim( CurrentAnalysis )
% RESULTS = UQ_SUBSETSIM(CURRENTANALYSIS) performs a subset simulation 
%     analysis of CURRENTANALYSIS and stores the results on the "Results" 
%     struct.
% 
% See also: UQ_RELIABILITY, UQ_MCMC

Options = CurrentAnalysis.Internal;

% Keep track of constant marginals:
nonConst =  ~ismember(lower({Options.Input.Marginals.Type}),'constant');
nonConstIdx = find(nonConst);


%% Options for the MCMC
%general
mcmcopts.RW.propDistr = Options.Subset.Proposal;
mcmcopts.AcceptCrit.model = Options.Model;
mcmcopts.AcceptCrit.LimitState = Options.LimitState;
mcmcopts.AcceptCrit.Input = Options.Input;
mcmcopts.AcceptCrit.Componentwise = Options.Subset.Componentwise;


%% START SUBSET SIMULATION WITH MCS
% create an input vector in the SNS space for the distributions that are 
% not constant:
for kk = 1:length(nonConst)
    if nonConst(kk)
        iopts.Marginals(kk).Type = 'Gaussian';
        iopts.Marginals(kk).Parameters = [0,1];
    else
        iopts.Marginals(kk).Type = 'constant';
        iopts.Marginals(kk).Parameters = 1;
    end
end
Uinput = uq_createInput(iopts, '-private');
mcmcopts.AcceptCrit.SNS = Uinput;

%sample from that marginals
U0 = uq_getSample(Uinput,Options.Simulation.BatchSize, 'mc');

%compute the isoprobabilistic transform
X0 = uq_GeneralIsopTransform( U0, Uinput.Marginals, Uinput.Copula, Options.Input.Marginals, Options.Input.Copula );

%compute the computational model responses
if Options.Display > 1
   fprintf('Current subset: 1\n') 
end
[LSF0, Y0] = uq_evalLimitState(X0, Options.Model, Options.LimitState, Options.HPC.Enabled);
Nout = size(LSF0,2);

%compute the PDF values in the SNS
PDFeval0 = prod(normpdf(U0),2);

%% start the subset generation for each output variable
for oo = 1:Nout
ii = 1;
U = U0;
X = X0;
Y = Y0; 
LSF = LSF0;
PDFeval = PDFeval0;
q = [];
Pf = [];
p0 = Options.Subset.p0;
Nsubset = Options.Simulation.BatchSize;
Pfcond = [];
Xhistory = [];
Uhistory = [];
LSFhistory = [];
Yhistory = [];
PDFevalhistory = [];

%% iterations among the subsets
while 1
    %estimate the failure probability
    Pf(ii) = sum(LSF(:,oo)<=0)/Nsubset;
    
    %store the history
    Xhistory{ii} = X;
    Uhistory{ii} = U;
    LSFhistory{ii} = LSF;
    Yhistory{ii} = Y;
    PDFevalhistory{ii} = PDFeval;
    
    %termination of the iterations due to convergence
    if Pf(ii) > p0
        if Options.Display > 0
        fprintf(['\nSubset simulation terminated with ', num2str(ii), ' generated subset(s).'])
        end
        Pfcond(ii) = Pf(ii);
        q(ii) = 0;
        break;
    end
    %termination of the iterations due to the maximum number of subsets
    if ii >= Options.Subset.MaxSubsets
        if Options.Display > 1
            fprintf(['Warning: Subset simulation does not converge in ',num2str(Options.Subset.MaxSubsets),' subsets. \n'])
        end
        Pfcond(ii) = Pf(ii);
        q(ii) = 0;
        break;
    end
    
    %display the progress
    if Options.Display > 1
        fprintf('Current subset: %d\n', ii+1)
    end
    
    %estimate the quantile
    q(ii) = quantile(LSF(:,oo), p0);
    Pfcond(ii) = p0;
    
    %and the seeds for the next MCMC
    [LSFsort, idxsort]= sort(LSF(:,oo));
    Q = U(idxsort(1:floor(p0*Nsubset)),:);
    QY = Y(idxsort(1:floor(p0*Nsubset)),:);
    QLSF = LSF(idxsort(1:floor(p0*Nsubset)),:);
    QPDF = PDFeval(idxsort(1:floor(p0*Nsubset)),:);
    
    %update the MCMC options
    mcmcopts.AcceptCrit.gi = q(ii);
    mcmcopts.Xseed = Q;
    
    %assign the acceptance criterion for the next subset
    mcmcopts.AcceptCrit.LSF = QLSF;
    mcmcopts.AcceptCrit.Y = QY;
    mcmcopts.AcceptCrit.oo = oo;
    
    %run MCMC
    [Umcmc, PDFmcmc, Runtime] = uq_subsetsim_samples(Q, round((1 - p0)*Nsubset), mcmcopts); 
    U = [Q; Umcmc(1:(Nsubset-size(Q,1)),:)];
    X = uq_GeneralIsopTransform( U, Uinput.Marginals, Uinput.Copula, Options.Input.Marginals, Options.Input.Copula );
    PDFeval  = [QPDF; PDFmcmc(1:(Nsubset-size(Q,1)),:)];
    LSF = Runtime.LSF(1:Nsubset,:);
    Y = Runtime.Y(1:Nsubset,:);   
    
    %increase the counter
    ii = ii + 1;
    
end  

%% Collect the results
%estimation of the failure probability
Results.Pf(oo) = p0^(ii-1)*Pf(end); 

%reliability index
Results.Beta(oo) = -norminv(Results.Pf(oo), 0, 1); 

%coefficient of variation estimate
Results.History(oo).delta2(1) = (1-Pfcond(1))/Pfcond(1)/Nsubset; 
gamma = 0;
for jj = 2:ii
    gamma(jj) = uq_computeGamma( LSFhistory{jj}, q(jj), Pfcond(jj), Options );
    Results.History(oo).delta2(jj) = (1-Pfcond(jj))/Pfcond(jj)/Nsubset*(1+gamma(jj));
end
Results.CoV(oo) = sqrt( sum(Results.History(oo).delta2) );
Results.History(oo).CoVIdeal = sqrt( sum((1-Pfcond)./Pfcond./Nsubset) );

%number of model evaluations (nominally)
Results.History(oo).ModelEvaluationsNom = ii*Nsubset; 

%number of model evaluations (effectively)
Results.ModelEvaluations(oo) = uq_evalLimitState('count');
uq_evalLimitState('reset');

%number of subsets
Results.NumberSubsets = ii;

%values of each iteration
Results.History(oo).q = q;
if CurrentAnalysis.Internal.SaveEvaluations
Results.History(oo).X = Xhistory;
Results.History(oo).U = Uhistory;
Results.History(oo).Y = Yhistory;
Results.History(oo).G = LSFhistory;
end
Results.History(oo).Pfcond = Pfcond;
Results.History(oo).gamma = gamma;

%compute the confidence bounds
alpha = Options.Simulation.Alpha;
Results.PfCI(oo,:) = Results.Pf(oo) * [1 + norminv(alpha/2)*Results.CoV(oo), 1 + norminv(1-alpha/2)*Results.CoV(oo)];
Results.BetaCI(oo,:) = fliplr(-norminv(Results.PfCI(oo,:), 0, 1)); 

%clear the runtime and temporarily stored data to not interfer with the
%other output dimensions
% This is modified for the case of multiple limit state functions
clear gamma idxsort Umcmc PDFmcmc myMCMC
% clear mcmcopts gamma idxsort Umcmc PDFmcmc myMCMC

end

%% display the end of the algorithms
if Options.Display > 0
    fprintf('\n\nSubset Simulation: Finished. \n')
end
