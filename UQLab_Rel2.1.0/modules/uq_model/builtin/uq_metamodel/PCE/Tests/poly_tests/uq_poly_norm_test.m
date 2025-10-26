function pass = uq_poly_norm_test(maxdeg,randrepeats)
% PASS = UQ_POLY_NORM_TEST(MAXDEG,RANDREPEATS):
%    test for orthonormality of value based (recurrence relation) 
%    polynomial implementations.
%  
%  Settings:
%    'MAXDEG'        the maximum degree considered
%    'RANDREPEATS'   the number of repeats with random parameters 
%                    (for Jacobi and Laguerre)
%
%  Details:
%    Orthonormal polynomials $\pi_n(x)$ satisfy 
%    $ < \pi_n , \pi_m>_{\mathbf{f}} = \delta_{nm} $.
%
%    This test asserts through numerical integration for the value based 
%    polynomials that this relation is satisfied. Since the Jacobi and 
%    Laguerre polynomials are defined with respect to the beta and gamma
%    distribution parameters the parameters are chosen randomly and the 
%    tests are repeated a number of times.

condition = true;

if ischar(maxdeg)
    if strcmpi(maxdeg,'normal')
        maxdeg = 10;
        randrepeats = 2;
    elseif strcmpi(maxdeg,'detailed')
        maxdeg = 10;
        randrepeats = 2;
    else
        error(sprintf('Unknown input parameter: %s' , maxdeg));
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

%since different distributions have different bounds 
%I need to integrate over I keep the bounds in a simple matrix:
bounds = [-inf, inf; -1 1; 0 1; 0 Inf];

% The polynomial names:
polynames = {'Hermite','Legendre','Jacobi','Laguerre'};

% The distribution names:
distrnames = {'Gaussian','Uniform','Beta', 'Gamma'};

for kk = 1:randrepeats

    betaparams = [(4-2*(rand-1)), (6-2*(rand-1)), 0, 1];

    gammaparams = [1 , (4 + (2*(rand-1)))];

    distributions = {@(x) uq_gaussian_pdf(x,[0,1]), ...
                     @(x) uq_uniform_pdf(x,[-1,1]),...
                     @(x) uq_beta_pdf(x,betaparams),...
                     @(x) uq_gamma_pdf(x,gammaparams)};

    % integration for the value-based poly evaluations
    % build a set of polynomials up to a maximum degree
    for ii = 1:maxdeg
        hhandle{ii} = @(x) uq_eval_hermite(ii,x,1);
        lhandle{ii} = @(x) uq_eval_legendre(ii,x,1);
        jhandle{ii} = @(x) uq_eval_jacobi(ii,x,betaparams,1);
        laghandle{ii} = @(x) uq_eval_laguerre(ii,x,gammaparams,1);
    end

    % since I expect the polynomials to be orthonormal 
    % according to their respective inner products
    % this should turn out to be a cell array of 
    % 4 identity matrices
    cellresults = cell(4,1);

    polyhandles = { hhandle,...
                    lhandle,...
                    jhandle,...
                    laghandle};

    for distr = 1:4
        reslts = zeros(maxdeg,maxdeg);
        for ii = 1:(maxdeg)
            %It is definitely symmetric so I calculate
            %only the upper diagonal of the gram matrix:
            for jj = ii:(maxdeg)
                polyhandle = @(x) polyhandles{distr}{ii}(x') .* polyhandles{distr}{jj}(x');
                inthandle = @(x) polyhandle(x)' .* distributions{distr}(x);
                reslts(ii,jj) = integral(inthandle, bounds(distr,1), bounds(distr,2));
            end
        end

        %check that we got an identity for a gram matrix:
        current_test = max(max(reslts - eye(maxdeg))) < 1e-10 ;

        if ~current_test
            msg1 = sprintf('The values for the %s polynomials are not orthonormal w.r.t. the %s distribution up to degree %s !' , polynames{distr},distrnames{distr},int2str(maxdeg)); 
            switch lower(polynames{distr})
                case 'jacobi'
                    msg2 = sprintf('\nparameters: [ %d , %d , 0 , 1]' , betaparams(1), betaparams(2));
                case 'laguerre'
                    msg2 = sprintf('\nparameters: [ %d , %d ]' , gammaparams(1),gammaparams(2));
                otherwise
                    msg2 = '';
            end
            disp(strcat(msg1,msg2));
        end
        condition = condition && (current_test);
    end
end

pass = condition;
