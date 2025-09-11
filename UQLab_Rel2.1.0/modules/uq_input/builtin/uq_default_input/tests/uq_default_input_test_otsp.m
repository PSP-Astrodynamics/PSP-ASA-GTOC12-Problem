function pass = uq_default_input_test_otsp(level)
%     Test the open travelling salesman problem solver on different test 
%     cases

    if nargin < 1
        level = 'normal'; % TBD: Time that the tests will take
    end
    fprintf(['\nRunning: |' level '| uq_default_input_test_otsp...\n']);

    pass = 1;
    rng(100)

    % Test for d=8 and d=12; if d<=10, all pathes are tested; otherwise,
    % a stochastic genetic algorithm is used
    for d = [8, 13]
        % xy: points along line x=y
        xy = [linspace(0,1,d)', linspace(0,1,d)'];

        % Randomly permute coordinates; NewIdx is also the correct solution
        NewIdx = randperm(d); 
        xy(NewIdx,:) = xy;
        minDist = sqrt(2);  % length of correct shortest path

        % Solve problem without fixing the first and last nodes
        maxIter = 1e4;
        config = struct('xy', xy, 'fixed', false, 'maxIter', maxIter);
        res = uq_open_travelling_salesman_problem(config);
        pass = pass && (all(res.bestPath == NewIdx) || ...
                        all(res.bestPath == NewIdx(end:-1:1)));
        pass = pass && (abs(res.minDist - minDist) <= 10*eps);

        % If genetic algorithm was used, make additional checks: maxIter 
        % not exceeded and minDist never increased
        if d > 10
           pass = pass && (res.totIter <= maxIter);
           pass = pass && all(diff(res.History.minDist)<=0);
        end
        
        % Solve the problem by fixing the first and last nodes; check that 
        % the found path starts and ends at those nodes
        config = struct('xy', xy, 'fixed', true);
        res = uq_open_travelling_salesman_problem(config);
        pass = pass && (all(res.bestPath([1 d]) == [1 d]));
    end
    
end
