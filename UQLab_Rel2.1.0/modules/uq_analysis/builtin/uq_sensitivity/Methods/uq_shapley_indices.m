function Results = uq_shapley_indices(current_analysis)
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
        while true
            [myPerms_unique,~,~] = unique(myPerms,'rows','stable');
            if size(myPerms_unique,1) == size(myPerms,1)
                break;
            end
            % add missing rows to the end
            for pp = size(myPerms_unique,1)+1 : size(myPerms,1)
                myPerms_unique(pp,:) = randperm(M);
            end
            % Assign the new permutations to myPerms and repeat the game
            myPerms = myPerms_unique;
        end
        
        % Check which subsets need to be evaluated for those permutations.
        % To begin, list ALL subsets we get from the permutations. Store
        % them in a cell array since they have different lengths.
        allsubs = zeros(M*nperm,M);
        for pp = 1:nperm
            for mm = 1:M
                allsubs(M*(pp-1)+mm,1:mm) = myPerms(pp,1:mm);
            end
        end
        % now we check for multiple subsets. Since the sequence doesn't
        % matter. Kucherenko of [2 1 0] = Kucherenko of [1 2 0].
        sorted = sort(allsubs,2);
        [~,uniquerows,~] = unique(sorted,'rows');
        neededsubsets = allsubs(uniquerows,:);
        % those are the subsets for which the cost function needs to be
        % calcualted
        
    case 'full'
        % Brute Force, let's go! Get all subsets.
        neededsubsets = uq_allSubsets(1:M);
        
end

%% GET THE NEEDED COST FUNCTIONS

Cost = zeros(size(neededsubsets,1),1);

% % Rename the .CostFun field to .IndexOpts for the index calculation
% f = fieldnames(Options);
% v = struct2cell(Options);
% f{strcmpi('CostFun',f)} = 'IndexOpts';
% Options = cell2struct(v,f);

switch Options.Shapley.CompStrat
    case 'cost'
        % to do / decide what to to
    case {'perms','full'}
        subsetindices = zeros(size(neededsubsets,1),1);
        for ss = 1:size(neededsubsets,1)
            % get the indices of the subset
            idx = neededsubsets(ss,:);
            idx(~idx) = [];
            [subsetindices(ss),Cost(ss),Options] = calcCostFun(Options, idx);
        end
        
end

%% CALCULATE THE SHAPLEY INDICES

% storage preallocation for indices. One warm, comfy place for each index:)
shapley = zeros(M,1);

switch Options.Shapley.CompStrat
    case 'cost'
        % to do / decide what to to
    case 'perms'
        % calculate the cost function differences $\delta c$ in each
        % permutation
        % to do this we need to first check what differences we need for
        % each index. We can use allsubs for this.
        for mm = 1:M
            longsets = zeros(nperm,M);
            for ii = 1:nperm
                % search for X_mm in each row
                loc = find(myPerms(ii,:)==mm);
                longsets(ii,1:loc) = myPerms(ii,1:loc);
            end
            % save the longsets without variable X_mm
            shortsets = longsets;
            shortsets(shortsets==mm) = 0;
            
            % Get differences $\delta c$ (and the absolute value of the subset):
            delta_c = zeros(size(longsets,1),1);
            abs_u = delta_c;

            for ss = 1:nperm
                % for comparison, let's sort the rows, to have consistent
                % indices
                curr_longset = sort(longsets(ss,:));
                curr_shortset = sort(shortsets(ss,:));
                sorted = sort(neededsubsets,2);
                % the $\delta_c$ is the difference between the index of the
                % longset minus the index of the shortset. The indices are
                % stored in subsetindices at the same position as the
                % corresponding subsets are stored in neededsubsets
                try
                    delta_c(ss) = subsetindices(ismember(sorted,curr_longset,'rows')) - ...
                        subsetindices(ismember(sorted,curr_shortset,'rows'));
                catch % for shortset = [], delta = index(longset)-0
                    delta_c(ss) = subsetindices(ismember(sorted,curr_longset,'rows')); 
                end
                % also save the absolute value of the subset. HOWEVER, FOR
                % THE APPROXIMATION WE DON'T NEED IT
                abs_u(ss) = sum(curr_shortset~=0);
            end
            % Now we are ready to calculate the Shapley index for x_mm
%             summands = factorial(M-abs_u-1).*factorial(abs_u)./factorial(M).*delta_c;
%             shapley(mm) = sum(summands);
            shapley(mm) = sum(delta_c)/nperm;
        end
        
    case 'full'
        for mm = 1:M
            % select the subsets that include variable X_mm. We only choose
            % the rows, where column mm isn't zero
            longsets = neededsubsets(neededsubsets(:,mm)~=0,:);            
            % save the longsets without variable X_mm
            shortsets = longsets;
            shortsets(shortsets==mm) = 0;
            
            % Get differences $\delta c$ and the absolute value of the subset:
            delta_c = zeros(size(longsets,1),1);
            abs_u = delta_c;
            
            for ss = 1:size(longsets,1)
                curr_longset = longsets(ss,:);
                curr_shortset = shortsets(ss,:);
                % the $\delta_c$ is the difference between the index of the
                % longset minus the index of the shortset. The indices are
                % stored in subsetindices at the same position as the
                % corresponding subsets are stored in neededsubsets
                try
                    delta_c(ss) = subsetindices(ismember(neededsubsets,curr_longset,'rows')) - ...
                        subsetindices(ismember(neededsubsets,curr_shortset,'rows'));
                catch % for shortset = [], delta = index(longset)-0
                    delta_c(ss) = subsetindices(ismember(neededsubsets,curr_longset,'rows')); 
                end
                % also save the absolute value of the subset
                abs_u(ss) = sum(curr_shortset~=0);
            end
            % Now we are ready to calculate the Shapley index for x_mm
            summands = factorial(M-abs_u-1).*factorial(abs_u)./factorial(M).*delta_c;
            shapley(mm) = sum(summands);
        end
        
end



%% COLLECT THE INDICES IN THE RESULT STRUCTURE
Results.Shapley = shapley;

% Cost comes from the Kcuherenko index computation
Results.Cost = sum(Cost);

% Total Variance
Results.TotalVariance = Options.IndexOpts.TotalVariance;

if Display > 0
    fprintf('\nShapley: finished.\n');
end