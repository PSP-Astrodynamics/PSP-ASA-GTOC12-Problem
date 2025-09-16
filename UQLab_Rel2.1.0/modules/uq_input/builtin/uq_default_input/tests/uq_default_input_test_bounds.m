function pass = uq_default_input_test_bounds( level )
% pass = UQ_DEFAULT_INPUT_TEST_BOUNDS(LEVEL): validation test for the
% bounded (truncated) distributions functionality of the default input module
%
% Summary:
% Some bounds are specified for a random vector with various marginal
% distributions and then these bounds are validated from the samples that
% are drawn using that random vector definition

%% initialize test
evalc('uqlab');
if nargin < 1
    level = 'normal'; 
else
    if ~strcmpi(level,'normal')
       level = 'extended'; 
    end
end
fprintf(['\nRunning: |' level '| uq_default_input_test_bounds...\n']);

pass = 1;

%% parameters
N = 1e4;
switch lower(level)
    case 'normal'
        %% Perform the test, level = normal
        % Define some marginal distributions
        Input.Marginals(1).Type = 'Uniform' ;
        Input.Marginals(1).Parameters = [1 , 3] ;
        Input.Marginals(1).Bounds = [-2 ,2 ] ;
        TrueBounds(1,:) = [1,2];
        Input.Marginals(2).Type = 'Gaussian' ;
        Input.Marginals(2).Parameters = [0 , 0.5] ;
        Input.Marginals(2).Bounds = [-3, 2 ] ;
        TrueBounds(2,:) = [-3,2];
        Input.Marginals(3).Type = 'Uniform' ;
        Input.Marginals(3).Parameters = [1 , 2] ;
        Input.Marginals(3).Bounds = [1 , 2] ;
        TrueBounds(3,:) = [1,2];
        Input.Marginals(4).Type = 'Gaussian' ;
        Input.Marginals(4).Parameters = [0 , 2] ;
        Input.Marginals(4).Bounds = [-2 , 2 ] ;
        TrueBounds(4,:) = [-2,2];
        
        % case 1 : Independent copula
        Input.Copula.Type = 'Independent' ;
        uq_createInput(Input);
        X = uq_getSample(N, 'Sobol');
        pass = pass & all(max(X.',[],2) <= TrueBounds(:,2)) ;
        pass = pass & all(min(X.',[],2) >= TrueBounds(:,1)) ;
        % case 2 : Gaussian copula
        Input.Copula.Type = 'Gaussian' ;
        S = rand(4) ;
        S = S' * S ;
        s = sqrt(diag(S));
        C = diag(1./s)*S*diag(1./s) ;
        Input.Copula.Parameters = C ;
        Input.Copula.Parameters(logical(eye(4))) = 1;
        X = uq_getSample(N, 'Sobol');
        pass = pass & all(max(X.',[],2) <= TrueBounds(:,2)) ~= 0;
        pass = pass & all(min(X.',[],2) >= TrueBounds(:,1)) ~= 0;

    case 'extended'
        %% Perform the test, level = extended
        
        builtinMarginals = uq_getAvailableMarginals;
        TrueBounds= zeros(length(builtinMarginals),2);
        for ii = 1 : length(builtinMarginals)
            Input.Marginals(ii).Type = builtinMarginals{ii};
            switch lower(builtinMarginals{ii})
                case 'student'
                    Input.Marginals(ii).Parameters = 1 ;
                    Input.Marginals(ii).Bounds = [1, 2];
                    TrueBounds(ii,:) = [1, 2];
                case 'triangular'
                    Input.Marginals(ii).Parameters = [1 , 3, 2] ;
                    Input.Marginals(ii).Bounds = [1, 2];
                    TrueBounds(ii,:) = [1, 2];
                case 'beta'
                    Input.Marginals(ii).Parameters = [1 , 2, 0, 4] ;
                    Input.Marginals(ii).Bounds = [1, 2];
                    TrueBounds(ii,:) = [1, 2];
                otherwise
                    Input.Marginals(ii).Parameters = [1 , 2] ;
                    Input.Marginals(ii).Bounds = [1, 2];
                    TrueBounds(ii,:) = [1, 2];
            end
        end
        
        % case 1 : Independent copula
        Input.Copula.Type = 'Independent' ;
        uq_createInput(Input);
        X = uq_getSample(N, 'Sobol');
        pass = pass & all(max(X.',[],2) <= TrueBounds(:,2)) ;
        pass = pass & all(min(X.',[],2) >= TrueBounds(:,1)) ;
        % case 2 : Gaussian copula
        Input.Copula.Type = 'Gaussian' ;
        S = rand(4) ;
        S = S' * S ;
        s = sqrt(diag(S));
        C = diag(1./s)*S*diag(1./s) ;
        Input.Copula.Parameters = C ;
        Input.Copula.Parameters(logical(eye(4))) = 1;
        X = uq_getSample(N, 'Sobol');
        pass = pass & all(max(X.',[],2) <= TrueBounds(:,2)) ~= 0;
        pass = pass & all(min(X.',[],2) >= TrueBounds(:,1)) ~= 0;

    otherwise
        error('Unknown level value!')
end
