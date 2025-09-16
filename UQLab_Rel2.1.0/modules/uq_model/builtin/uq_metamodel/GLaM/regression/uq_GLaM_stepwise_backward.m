function [Coef,IC,waldStat,BW,lmStat] = uq_GLaM_stepwise_backward(Y,Psi,Coef,transform,OptmMethod,IC,waldStat,lmStat,Options)
% backward elimination of the basis
% Y: output vector
% Psi: cell array(1*4) of the basis functions evaluated on the input values
% Coef: initial coefficients
% IC: values of the information criteria
% waldStat: statistics related to the Wald-test
% lmStat: statistics related to the Lagrange-multiplier-test
% Options: options of the backward step

%% set default values

% get the data information
N_data = length(Y);

% lambda's to be considered
lambda=1:4;
% selection criterion
infcrit = 'BIC';

% whether force to switch to another lambda after a backward step
alter = false;
% whether early stop
early_stop = true;
N_stop = 4;% number of failures to terminate the iteration
% stat threshold
statThre = 10*log(N_data);
% display level
DisplayLevel = 0;


if nargout<5
    lmonly34 =true;
else
    lmonly34 = false;
    if isfield(options, 'lmonly34')
        lmonly34 = options.lmonly34;
    end
end

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

% starting indices to be enriched
startIndices = [2,2,2,2];

% get the initial candidate lambda's and the indices
[lopoverlam,CandInd]=uq_GLaM_stepwise_getLambdaAndIndices(lambda,waldStat,statThre,startIndices,'ascend');

if ~isempty(lopoverlam)
    ilam=lopoverlam(1);
    i_stop = 0;
end

% track the procedure
BW = struct;
BW.Name = 'Backward elimination';
BW.Lambda = [];
BW.basis = [];
BW.SelectCrit = infcrit;
BW.IC=[];
BW.performed = [];

%%
% setup options
issparse = [false,false,false,false];
% whether the optimization only use gradients-based method
onlyGradient = true;

while ~isempty(lopoverlam)
    if DisplayLevel>1
        fprintf('Eliminate a basis for lambda%d...\n',num2str(ilam));
    end
    
    Coef_new = Coef;
    Coef_new{ilam}(CandInd{ilam}(1))=0;
    if nargout<5
        [Coef_new,~,~,IC_new,wald_new] = uq_GLaM_fit_coefficients(Y,Psi,Coef_new,transform,OptmMethod,verbose,issparse,lmonly34,onlyGradient);
        lm_new = [];
    else
        [Coef_new,~,~,IC_new,wald_new,lm_new] = uq_GLaM_fit_coefficients(Y,Psi,Coef_new,transform,OptmMethod,verbose,issparse,lmonly34,onlyGradient);
    end
    if ~iscell(wald_new)
        break;
    end
    
    % register operations
    BW.Lambda = [BW.Lambda,ilam];
    BW.basis = [BW.basis,CandInd{ilam}(1)];
    BW.IC=uq_appendStructure(BW.IC,IC_new,'array');
    
    % if improve: update
    if IC_new.(infcrit)<IC.(infcrit)
        if DisplayLevel>1
            fprintf(['The elimination improves ',infcrit,'\n']);
        end
        
        Coef = Coef_new;
        waldStat = wald_new;
        lmStat = lm_new;
        IC = IC_new;
        i_stop = 0;
        BW.performed = [BW.performed,true];
        
        % update the loop parameters
        [lopoverlam,CandInd]=uq_GLaM_stepwise_getLambdaAndIndices(lambda,waldStat,statThre,startIndices,'ascend');
        
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
            fprintf(['The elimination does not improve ',infcrit,'\n']);
        end
        
        BW.performed = [BW.performed,false];
        
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
            
            mlocal = inf;
            for ii = lopoverlam
                if ~isempty(CandInd{ii}) && waldStat{ii}(CandInd{ii}(1))<mlocal
                    mlocal= waldStat{ii}(CandInd{ii}(1));
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


