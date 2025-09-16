function resultStruct = uq_open_travelling_salesman_problem(config)
% resultStruct = uq_open_travelling_salesman_problem(config)
%
%     Solves the Open Travelling Salesmen Problem (OTSP): finds the (near) 
%     shortest path through a set of nodes (cities) identified by their
%     coordinates or by their distance matrix. The path beginning and end 
%     can be either fixed (as the first and last nodes) or let vary.
%     If the path length has 10 or fewer nodes, the shortest path is found 
%     among all possible pathes. Otherwise, a genetic algorithm is used.
%
%     Details about the genetic algorithms:
%     * Select a number (default: 100) of random pathes to try
%     * For these current pathes, repeat:
%          1. Find best (=minimum length) path among current pathes
%          2. If it was the best since n^3 iterations (n=nr.nodes), stop 
%          3. Otherwise, if it was the best since n^2 iterations, replace 
%             the other pathes with new random ones
%          4. Randomly group current pathes into groups of 4 pathes each 
%          5. Determine best path in each group, and replace the other 3  
%             pathes random variations of the best path in the group
%          6. Update current patterns
%     
% INPUT:
% config: structure containing either one of the two mandatory fields:
%     - dmat: NxN matrix of node-to-node distances; or
%     - xy: Nxd matrix of node coordinates (floats), one row per node. 
%       Ignored if dmat is provided
%     Additional optional field:
%     - fixed: boolean. If true, the first and last nodes are fixed as 
%       path beginning/end, and only the intermediate stops vary.
%       Default: false
%     Additional optional fields (parameters of the genetic algorithm)
%     - popSize: scalar integer, number of initial randomly picked routes
%       (rounded up to a multiple of 4). 
%       Default: 100
%     - maxIter: scalar integer, number of algorithm iterations. 
%       Default: 5000
%     - seed: positive integer. Random number generator seed. Setting the
%       seed allows to replicate the results.
%       Default: -1 (no seed)
%       
%     NOTE: all fields are case sensitive
%
% OUTPUT:
% resultStruct: structure with the following fields (in addition to a 
%    record of the options used to run the algorithm)
%     - bestPath: integer array; shortest path found by the algorithm
%     - minDist: scalar float; total distance of shortest path
%     - History: structure with fields .bestPath (array maxIter x N) and
%       .minDist (array maxIter x 1) showing the progress from first to
%       last iteration
%
% EXAMPLES:
%     % Pass a random set of 30 XY coordinates
%     config = struct('xy', rand(30,2));
%     resultStruct = uq_open_travelling_salesman_problem(config);
%
%     % Pass a random set of 30 XYZ coordinates. Fix first and last nodes
%     config = struct('xy',rand(30,3), 'fixed', true);
%     resultStruct = uq_open_travelling_salesman_problem(config);
%
%     % Change the default parameters of the genetic algorithm
%     userConfig = struct('popSize', 200, 'maxIter', 1e4);
%     resultStruct = uq_open_travelling_salesman_problem(userConfig);

    fixed_default = false;
    
    % Extract or build distance matrix dmat
    if isfield(config, 'dmat')
        dmat = config.dmat;
        N = size(dmat,1);
    elseif isfield(config, 'xy')
        xy = config.xy;
        N = size(config.xy,1);
        a = meshgrid(1:N);
        dmat = reshape(sqrt(sum((xy(a,:)-xy(a',:)).^2,2)),N,N);
    end
    
    % Determine whether the problem has fixed start and end nodes or not
    if isfield(config, 'fixed') 
        fixed = config.fixed;
        if ~any(fixed == [0,1])
            error('fixed must be either true (1) or false (0)')
        end
    else
        fixed = fixed_default;
    end
    
    n = N - 2*fixed; % number of non-fixed nodes: N-2 if fixed, N otherwise

    if n <= 10 % if nr.nodes <= 10, solve all possibilities
        
        % Determine all pathes P of non-fixed nodes
        flex_nodes = 1+fixed : N-fixed;
        P = perms(flex_nodes); % all pathes throguh non-fixed nodes
        nr_perms = size(P, 1); % number of permutations
        P = [ones(nr_perms, fixed), P, N*ones(nr_perms, fixed)]; % all pathes
        
        % Find length of each path
        for ii = 1:nr_perms
            O = P(ii, :);   % current order of nodes
            dmat_ii = dmat(O,O);  % sort rows&cols of dmat by order O
            s(ii) = sum(diag(dmat_ii, 1)); % path length = sum off-diagonal
        end

        [minDist, ii_min] = min(s);
        bestPath = P(ii_min,:);

        resultStruct.bestPath = bestPath;
        resultStruct.minDist = minDist;
        
    else % if nr.nodes > 10, use genetic algorithm
        newconfig = config; 
        newconfig.dmat = dmat;
        if isfield(newconfig, 'xy')
            newconfig = rmfield(newconfig, 'xy');
        end
%         newconfig.fixed = true;
        resultStruct = uq_open_travelling_salesman_problem_ga(newconfig); 
    end
end

function resultStruct = uq_open_travelling_salesman_problem_ga(config)
% resultStruct = uq_open_travelling_salesman_problem_ga(config)
%
%     Solves the Open Travelling Salesmen Problem (OTSP) using a Genetic 
%     Algorithm (GA). Finds the (near) shortest path through a set of nodes 
%     (cities) identified by coordinates or by their distance matrix.
%     The path's beginning and end can be either fixed (as the first and 
%     last nodes) or let vary.
%
    fixed_default = false;
    
    if isfield(config, 'fixed') 
        fixed = config.fixed;
        if ~any(fixed == [false, true])
            error('fixed must be either true (1) or false (0)')
        end
    else
        fixed = fixed_default;
    end
    
    if fixed
        config.fixed = true;
        resultStruct = uq_otsp_fixed_ga(config);
    else
        if isfield(config, 'dmat')
            dmat = config.dmat;
            N = size(dmat,1);
        elseif isfield(config, 'xy')
            xy = config.xy;
            N = size(config.xy,1);
            a = meshgrid(1:N);
            dmat = reshape(sqrt(sum((xy(a,:)-xy(a',:)).^2,2)),N,N);
            config = rmfield(config, 'xy');
        end

        DMAT = zeros(N+2);                       % DMAT: wrap zeros around 
        DMAT(2:end-1, 2:end-1) = dmat;           % distance matrix dmat

        config.dmat = DMAT;                      % use enlarged distance matrix
        resultStruct = uq_otsp_fixed_ga(config); % solve the TSP problem

        % lower node IDs in the results by 1 (the fictional start node)
        resultStruct.bestPath = resultStruct.bestPath(2:end-1) - 1;
        resultStruct.History.bestPath = ...
            resultStruct.History.bestPath(:, 2:end-1) - 1;       
    end
end


function resultStruct = uq_otsp_fixed_ga(config)
    % fixed OTSP solver that uses a genetic algorithm
    
    % Set defaults
    popSize_def = 100;
    maxIter_def = 5e3;
    seed_def = -1;
    
    % set number of variations
    nVar = 4;
    
    % Initialize default options
    if isfield(config, 'dmat')
        dmat = config.dmat;
        N = size(dmat,1);
        [nr,nc] = size(dmat);
        if N ~= nr || N ~= nc
            error('config.dmat must be a square matrix\n')
        end
        if ~all(all(dmat == dmat'))
            error('config.dmat must be symmetric')
        end
        
        if isfield(config, 'xy')
            warning('config.xy ignored (config.dmat used instead)')
        end
    elseif isfield(config, 'xy')
        xy = config.xy;
        N = size(xy,1);
        a = meshgrid(1:N);
        dmat = reshape(sqrt(sum((xy(a,:)-xy(a',:)).^2,2)),N,N);
    else
        error('Config fields dmat and xy both missing. Provide one.\n')
    end
        
    if isfield(config, 'popSize')
        popSize = config.popSize;
    else
        popSize = popSize_def;
    end
    
    if isfield(config, 'maxIter')
        maxIter = config.maxIter;
    else 
        maxIter = maxIter_def;
    end
            
    if isfield(config, 'seed')
        seed = config.seed;
    else 
        seed = seed_def;
    end
    
    % Throw warning if unrecognized fields are present in config
    config_fields = fieldnames(config);
    known_fields = {'xy', 'dmat', 'fixed', 'popSize', 'maxIter', 'seed'};
    for ff = 1:length(config_fields)
        field = config_fields{ff};
        if ~any(strcmp(field, known_fields))
            warning('Field "%s" not recognized. Check capitalization.\n', field)
        end
    end
                
    % Fix random number generator seed, if provided and >0 (default: -1)
    if seed >=0
        rng(seed);
    end
    
    % Randomly select popSize pathes. The final path will be selected among
    % these pathes and random variations thereof
    n = N - 2; % n: number of internal nodes (excluded first and last ones)
    popSize     = max(nVar,nVar*ceil(popSize(1)/nVar)); % round up 
    popRoute = zeros(popSize,n);         
    popRoute(1,:) = 2:N-1;
    for kk = 2:popSize
        popRoute(kk,:) = randperm(n) + 1;
    end
    
    % Run the genetic algorithm. Repeat maxIter times:
    % 1) evaluate the current routes and saves the best one
    % 2) group current routes in subgroups of nVar
    % 3) find best in each subgroup, and replaces remaining nVar-1 
    %    routes with random variations of the best one
    % 4) save these routes as new current routes for next iteration
    globalMin = Inf;
    totalDist = zeros(1, popSize);
    tmpPopRoute = zeros(nVar, n);
    newPopRoute = zeros(popSize, n);

    History = {};
    History.minDist = zeros(maxIter, 1);
    History.bestPath = zeros(maxIter, n);
    
    StayedSame = 0;
    for iter = 1:maxIter        
        % Evaluate all current routes
        for p = 1:popSize
            pRoute = popRoute(p,:);
            d = dmat(1,pRoute(1));    % Add Start Distance
            for k = 1:n-1
                d = d + dmat(pRoute(k),pRoute(k+1));
            end
            d = d + dmat(pRoute(n),N); % Add End Distance
            totalDist(p) = d;
        end
        
        % Find the best current route and corresponding minimum distance.
        % Also update the optimal path
        [minDist,index] = min(totalDist);
        if minDist < globalMin % if a new optimal path is found
            globalMin = minDist;
            bestPath = popRoute(index,:);
            StayedSame = 0;
        else
            StayedSame = StayedSame + 1;
        end                    % if no new optimal path is found
        History.minDist(iter) = globalMin;
        History.bestPath(iter,:) = bestPath;
        
        % If the otpimal path stayed the same for n^3 consecutive 
        % iterations, break the loop and stop the algorithm
        if StayedSame >= n^3 
            History.minDist = History.minDist(1:iter);
            History.bestPath = History.bestPath(1:iter, :);
        break
        % Otherwise, if the optimal path was the same for n^2 consecutive 
        % iterations, replace the other pathes in the population with 
        % completely new ones (instead of trying variations thereof)
        elseif iter>1 && StayedSame>0 && mod(StayedSame, n^2) == 0
            popRoute = zeros(popSize,n);         
            popRoute(1,:) = bestPath;
            for kk = 2:popSize
                popRoute(kk,:) = randperm(n) + 1;
            end
        % Otherwise, run the genetic algorithm
        else        
            % Genetic algorithm: group current routes into groups of nVar, find
            % best in each group, replace the other nVar-1 with variations of 
            % the best. These replace the current routes in the next iteration
            randomOrder = randperm(popSize);
            for p = nVar:nVar:popSize
                rtes = popRoute(randomOrder(p-nVar+1:p),:);
                dists = totalDist(randomOrder(p-nVar+1:p));
                [~,idx] = min(dists); 
                bestOfnVarRoutes = rtes(idx,:);
                routeInsertionPoints = sort(ceil(n*rand(1,2)));
                I = routeInsertionPoints(1);
                J = routeInsertionPoints(2);
                for k = 1:nVar % Generate New Solutions
                    tmpPopRoute(k,:) = bestOfnVarRoutes;
                    switch k
                        case 2 % invert "from I to J" -> "from J to I"
                            tmpPopRoute(k,I:J) = tmpPopRoute(k,J:-1:I);
                        case 3 % swap nodes I and J
                            tmpPopRoute(k,[I J]) = tmpPopRoute(k,[J I]);
                        case 4 % slide [I I+1 ... J] --> [I+1 ... J I]
                            tmpPopRoute(k,I:J) = tmpPopRoute(k,[I+1:J I]);
                        otherwise % Do Nothing
                    end
                end
                newPopRoute(p-nVar+1:p, :) = tmpPopRoute;
            end
        end
        popRoute = newPopRoute;    
    end
        
    % Append first and last nodes to best path
    bestPath = [1 bestPath N];
    History.bestPath = [...
        ones(iter, 1), History.bestPath, N*ones(iter,1)];
    
    % Return Output
    resultStruct = {};
    resultStruct.dmat = dmat;
    resultStruct.popSize = popSize;
    resultStruct.maxIter = maxIter;
    resultStruct.totIter = iter;
    resultStruct.bestPath = bestPath;
    resultStruct.minDist = minDist;
    resultStruct.History = History;
    if isfield(config, 'xy') && ~isfield(config, 'dmat')
        resultStruct.xy = xy;
    end   
    
end

