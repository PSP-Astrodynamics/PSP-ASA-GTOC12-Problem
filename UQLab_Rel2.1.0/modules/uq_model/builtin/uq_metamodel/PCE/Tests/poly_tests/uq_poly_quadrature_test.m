function [success] = uq_poly_quadrature_test(maxdeg,randrepeats)
% SUCCESS = UQ_POLY_QUADRATURE_TEST(MAXDEG,RANDREPEATS):
%     tests the quadrature routines by the definition of Gaussian quadrature:
%     <f,P_n> = sum_{i=1}^{n} f(u_i) * w_i

% In case there is a single failure the test will fail:
% whole test will fail:
condition = true;

if ischar(maxdeg)
    if strcmpi(maxdeg,'normal')        
        maxdeg=10;
        randrepeats = 2;
    elseif strcmpi(maxdeg,'detailed')
        maxdeg = 10;
        randrepeats = 2;
    end
end

if ~exist('maxdeg', 'var')
    maxdeg = 10;
end

% controls how many times to run the test with random inputs for 
% beta and gamma parameters:
if ~exist('randrepeats', 'var')
    randrepeats = 2;
end

% since different distributions have different bounds we need to integrate 
% over we keep the bounds in a simple matrix:
bounds = [-inf, inf; -1 1; 0 1; 0 Inf];

for kk = 1:randrepeats

    betaparams = [(4-2*(rand-1)), (6-2*(rand-1)), 0, 1];

    gammaparams = [1 , (4 + (2*(rand-1)))];

    distributions = {@(x) uq_gaussian_pdf(x,[0,1]), ...
                     @(x) uq_uniform_pdf(x,[-1,1]),...
                     @(x) uq_beta_pdf(x,betaparams),...
                     @(x) uq_gamma_pdf(x,gammaparams)};

    % integration for the value-based poly evaluations
    for ii = 1:maxdeg
        hhandle{ii}   = @(x) uq_eval_hermite(ii,x,1);
        lhandle{ii}   = @(x) uq_eval_legendre(ii,x,1);
        jhandle{ii}   = @(x) uq_eval_jacobi(ii,x,betaparams,1);
        laghandle{ii} = @(x) uq_eval_laguerre(ii,x,gammaparams,1);
    end

    cellresults = cell(4,1);

    polyhandles = { hhandle,...
                    lhandle,...
                    jhandle,...
                    laghandle};

    types = {'hermite',...
             'legendre',...
             'jacobi',...
             'laguerre'};
    quadparms = {[],...
                 [],...
                 betaparams,...
                 gammaparams};

    for distr = 1:2

        for ii = 1:(maxdeg)

            % It is definately symmetric so I calculate
            % only the upper diagonal of the gram matrix:

            % construct a handle to use for an approximate evaluation of the integral:
            inthandle = @(x) polyhandles{distr}{ii}(x')' .* distributions{distr}(x);
            matl_integration = quadgk(inthandle, bounds(distr,1), bounds(distr,2));

            % We can find the normalization easilly from the recurrence relation:
            [AB] = uq_poly_rec_coeffs(ii,types{distr},cell2mat(quadparms{distr}));

            %find the quadrature rules:
            [Ui,Wi] = uq_quadrature_nodes_weights_gauss(ii,{types{distr}},quadparms{distr});

            quadr_integration = polyhandles{distr}{ii}(Ui)' * Wi;
            
            %check that the quadrature rules give the correct integral:
            deviation = abs(matl_integration - quadr_integration);

            % If we have a deviation larger than 1e-14 then flag the test 
            % as failed. We have a flexible limit due to the expected 
            % Matlab integration inaccuracy.
            if(deviation > (1e-14))
                condition = false;
            end
            
        end

    end

end

success = condition;

