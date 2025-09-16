function Results = uq_shapley_indices_ApproxRe(current_analysis)
% RESULTS = UQ_SHAPLEY_INDICES(ANALYSISOBJ) produces the Shapley importance
% indices. They distribute higher order (i.e. interaction) indices fairly
% between the input variables. The indices are computed using the
% implementation of the Kucherenko indices, which also work for dependent
% inputs.

% See also: UQ_SENSITIVITY,UQ_INITIALIZE_UQ_SENSITIVITY,
%           UQ_KUCHERENKO_INDICES

%% GET THE OPTIONS
Options = current_analysis.Internal;

% Current model
CurrentModel = Options.Model;

% Verbosity
Display = Options.Display;

% Number of variables:
M = Options.M;

% Input object
myInput = Options.Input;
if  all(~strcmpi(myInput.Copula.Type,{'Independent','Gaussian'})) % SHOULD BE DONE IN INITIALIZATION!
    error('Cannot compute sensitivity indices for copula of type "%s"', myInput.Copula.Type)
end

%% CHECK THE COST FUNCTION

% Preallocate cell arrays for all variables
VarIdx = cell(1,M);
AllOrders = cell(1,M);

% Check the chosen cost function
CostFun = Options.IndexOpts.Type;
switch lower(CostFun)
    case 'varexp' % first order effect
        calcCostFun = @(opts,subset) uq_closed_sens_index(opts,subset);
    case 'expvar' % total effect
        calcCostFun = @(opts,subset) uq_total_sens_index(opts,subset);
end


%% FIND THE SUBSETS TO CALCULATE THE COST FUNCTION FOR
% depends on the computation strategy
switch Options.Shapley.CompStrat
    case 'cost'
        % do something?
        
    case 'perms'
        nperm = Options.Shapley.nPerm;
        
        % create 'nperm' random permutations. One permutation per row.
        myPerms = zeros(nperm,M);
        for pp = 1:nperm
            myPerms(pp,:) = randperm(M);
        end
        
        % check for duplicate rows
        % if the unique matrix (no repeated rows) is shorter, resample
        % missing rows
%         while true
%             [myPerms_unique,~,~] = unique(myPerms,'rows','stable');
%             if size(myPerms_unique,1) == size(myPerms,1)
%                 break;
%             end
%             % add missing rows to the end
%             for pp = size(myPerms_unique,1)+1 : size(myPerms,1)
%                 myPerms_unique(pp,:) = randperm(M);
%             end
%             % Assign the new permutations to myPerms and repeat the game
%             myPerms = myPerms_unique;
%         end
        
    case 'full'
        % Brute Force, let's go! Get all subsets.
        neededsubsets = uq_allSubsets(1:M);
        
end

%% Get into the random perms
shapley = zeros(M,1);
Cost = zeros(nperm,1);
for pperm = 1:nperm
    currentPerm = myPerms(pperm,:);
    % get all needed subsets
    neededsubsets = zeros(M);
    for mm = 1:M
        neededsubsets(mm,1:mm) = currentPerm(1:mm);
    end
    %% GET THE NEEDED COST FUNCTIONS
    subsetindices = zeros(M,1);
    indexcost = zeros(M,1);
    for ss = 1:M-1
        % get the indices of the subset
        idx = neededsubsets(ss,:);
        idx(~idx) = [];
        [subsetindices(ss),indexcost(ss),Options] = calcCostFun(Options, idx);
    end
    subsetindices(M) = 1;
    Cost(pperm) = sum(indexcost);
    
    %% CALCULATE THE SHAPLEY INDICES    
    switch Options.Shapley.CompStrat
        case 'cost'
            % to do / decide what to to
        case 'perms'
            % Go through currentPerm / neededsubsets & subsetindices
            for mm = 1:M
                % The caluclated delta_c will belong to variable currentPerm(mm)
                index = currentPerm(mm);
                if mm == 1
                    delta_c = subsetindices(mm);
                else
                    delta_c = subsetindices(mm)-subsetindices(mm-1);
                end
                shapley(index) = shapley(index) + delta_c;
            end
    end
    
end
shapley = shapley./nperm;

%% COLLECT THE INDICES IN THE RESULT STRUCTURE
Results.Shapley = shapley;

% Cost comes from the Kcuherenko index computation
Results.Cost = sum(Cost);

% Total Variance
Results.TotalVariance = Options.IndexOpts.TotalVariance;

if Display > 0
    fprintf('\nShapley: finished.\n');
end