function [Coef,IC,waldStat,lmStat,FW] = uq_GLaM_stepwise_forward(Y,Psi,Coef,transform,OptmMethod,IC,waldStat,lmStat,Options)
% forward enrichment of the basis
% Y: output vector
% Psi: cell array(1*4) of the basis functions evaluated on the input values
% Coef: initial coefficients
% IC: values of the information criteria
% waldStat: statistics related to the Wald-test
% lmStat: statistics related to the Lagrange-multiplier-test
% Options: options of the forward step

%% set default values

% lambda's to be considered
lambda=3:4;
% whether force to switch to another lambda after a forward step
alter = false;
% whether early stop
early_stop = true;
N_stop = 4;% number of failures to terminate the iteration
% stat threshold
statThre = 3;
% display level
DisplayLevel = 0;


if isfield(Options,'lambda')
    lambda = sort(Options.Lambda,'ascend');
end
if isfield(Options,'SelectCrit')
    infcrit = Options.SelectCrit;
end
if isfield(Options, 'alter')
    alter = Options.alter;
end
if isfield(Options, 'early_stop')
    early_stop = Options.early_stop;
end
if isfield(Options, 'statThre')
    statThre = Options.statThre;
end
if isfield(Options, 'N_stop')
    N_stop = Options.N_stop;
end
if isfield(Options, 'Display')
    DisplayLevel = Options.Display;
end
if DisplayLevel>1
    verbose = 'iter';
else
    verbose = 'off';
end

%% Initialization

% get forward lambda's
lmonly34 = isempty(setdiff(lambda,[3,4]));

% starting indices to be enriched
startIndices = [1,1,2,2];

% get the initial candidate lambda's and the indices
[lopoverlam,CandInd]=uq_GLaM_stepwise_getLambdaAndIndices(lambda,lmStat,statThre,startIndices,'descend');

if ~isempty(lopoverlam)
    ilam=lopoverlam(1);
    i_stop = 0;
end

% track the procedure
FW = struct;
FW.Name = 'Forward enrichement';
FW.Lambda = [];
FW.basis = [];
FW.SelectCrit = infcrit;
FW.IC=[];
FW.performed = [];

%%
% setup options
inival = 1e-10;
issparse = [false,false,false,false];
onlyGradient = true;

while ~isempty(lopoverlam)
    if DisplayLevel>1
        fprintf('Enrich lambda%d...\n',ilam);
    end
    
    Coef_new = Coef;
    Coef_new{ilam}(CandInd{ilam}(1))=inival;
    [Coef_new,~,~,IC_new,wald_new,lm_new] = uq_GLaM_fit_coefficients(Y,Psi,Coef_new,transform,OptmMethod,verbose,issparse,lmonly34,onlyGradient);
    if ~iscell(lm_new)
        break;
    end
    
    % register operations
    FW.Lambda = [FW.Lambda,ilam];
    FW.basis = [FW.basis,CandInd{ilam}(1)];
    FW.IC = uq_appendStructure(FW.IC,IC_new,'array');
    
    % if improve: update
    if IC_new.(infcrit)<IC.(infcrit)
        if DisplayLevel>1
            fprintf(['The enrichment improves ',infcrit,'\n']);
        end
        Coef = Coef_new;
        waldStat = wald_new;
        lmStat = lm_new;
        IC = IC_new;
        i_stop = 0;
        FW.performed = [FW.performed,true];
        
        % update the loop parameters
        [lopoverlam,CandInd]=uq_GLaM_stepwise_getLambdaAndIndices(lambda,lmStat,statThre,startIndices,'descend');
        
        % if alter, we force the next enrichment to be different from
        % the current one
        if alter
            loplam = lopoverlam(lopoverlam~=ilam);
        else
            loplam = lopoverlam;
        end
        if ~isempty(loplam)
            ilam=loplam(1);
        end
    else
        if DisplayLevel>1
            fprintf(['The enrichment does not improve ',infcrit,'\n']);
        end
        
        FW.performed = [FW.performed,false];
        
        % early stop
        i_stop=i_stop+1;
        if early_stop&&i_stop==N_stop
            break
        else
            % get the next basis 
            CandInd{ilam}(1) = [];
            if isempty(CandInd{ilam})
                lopoverlam=lopoverlam(lopoverlam~=ilam);
            end
            
            mlocal = -inf;
            for ii = lopoverlam
                if ~isempty(CandInd{ii}) && lmStat{ii}(CandInd{ii}(1))>mlocal
                    mlocal= lmStat{ii}(CandInd{ii}(1));
                    ilam = ii;
                end
            end
        end
%         
    end
%     
end
%     

end