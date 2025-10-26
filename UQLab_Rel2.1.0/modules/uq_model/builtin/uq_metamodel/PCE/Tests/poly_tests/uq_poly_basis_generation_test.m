function success = uq_poly_basis_generation_test(n)
% SUCCESS = UQ_POLY_BASIS_GENERATION_TEST(n):
% simple non-regression test for polynomial basis generation.
% 
% Input:
%
%   'n'  Range of case studies to be run or 'normal' in order to run the
%        first 3 case studies.
%

pass = 1;       % Condition for passing test

if ~exist('n', 'var')
    n = 0;
end

if ischar(n)
    % I expect 'normal' for n...
    if strcmpi(n,'normal')
        n=0:2;
    else
        n=0:3;
    end
end


% number of input variables
M = 10;
% maximum order of the Polynomials
P = 5;
% size of the experimental design
N = 1000;

% q-norm index:
q = 0.75;

% Iterate through the requested case studies:
for case_study=n

    disp('Generating the experimental design and evaluating the corresponding univariate polynomials');
    tic
    % type of polynomials (0 = Legendre, 1 = Hermite)
    switch case_study
        case 0
            TYPES = ones(1, M);
        case 1
            TYPES = ones(1, M);
        case 2
            TYPES = zeros(1, M);
        case 3 % Ishigami functions are all legendre
            TYPES = zeros(1, M);
            q = 0.75;
        otherwise
            TYPES = zeros(1, M);
            q = 0.75;

    end

    % different polynomials expect different inputs
    X = zeros(N,M);
    univ_p_val = zeros(N,M, P+1);
    % evaluating the univariate polynomials in the experimental design
    for i = 1:M
        switch TYPES(i)
            case 0
                X(:,i) = 2*(0.5-rand(1, N)); % we also generate the experimental design at this stage (random grid)
                univ_p_val(:,i,:) = uq_eval_legendre(max(P), X(:,i));
            case 1
                X(:,i) = randn(1, N);
                univ_p_val(:,i,:) = uq_eval_hermite(max(P), X(:,i));
        end
    end
    toc
    disp('Evaluating the model');
    tic
    % ok, now let's consider that our model, in our experimental design, is a product of a few
    % coefficients, say:

    %Y = -12 + X(:,1) + 1*X(:,2) + 8*(0.5*(3*X(:,3).^2 - 1)) + 1*X(:,3) + 2*(X(:,1).*X(:,2));
    switch case_study
        case 0 % standard test case
            Y = univ_p_val(:,1,3) + 2*univ_p_val(:,1,3) +...
                3 + 11*2*univ_p_val(:,1,2).*univ_p_val(:,1,2) +...
                univ_p_val(:,2,2)+univ_p_val(:,3,3)+univ_p_val(:,4,1)+ ...
                univ_p_val(:,5,4)+univ_p_val(:,6,3)+univ_p_val(:,7,2)+...
                univ_p_val(:,8,3)+univ_p_val(:,9,4)+univ_p_val(:,10,2);
        case 1 % Hermite polynomials benchmark from Bruno
            X1 = X(:,1)+2;
            X2 = X(:,2)+3;
            X3 = X(:,3);
            Y = 1 + X1 + 2*X2 + X1.*X2 + X3.^3;
        case 2 % Lagrange polynomials benchmark from Bruno
            % isoprob transform:
            X1 = (X(:,1) + 1)/2;
            X2 = X(:,2);
            X3 = X(:,3)*sqrt(3);
            Y = 1 - sqrt(3) + 2*sqrt(3) * X1 + 5*sqrt(7) * X2.^3 +3*sqrt(5) *(X2.^2).*X3;
        case 3
            XX = X*pi;
            Y = uq_ishigami(XX);
    end

    % now let's evaluate our nice polynomials (full basis, no cuts)
    toc 

    disp('Calculating the index set');
    tic
    options.qNorm = q;
    [alphas] = uq_generate_basis_Apmj(0:P,M,options);
    toc

    disp('Generating the Psi matrix')
    tic
    PP = size(alphas,1);


    % Creating the regression Psi matrix
    Psi = ones(N, PP);
    fprintf('\nSize of Psi: %s\n\n', num2str(size(Psi)));
    tic

    for mm = 1:M
        idx = abs(alphas(:,mm))>0;
        Psi(:,idx) = Psi(:,idx) .* squeeze(univ_p_val(:, mm, alphas(idx,mm)+1));
    end

    fprintf('Elapsed time for creating the Psi matrix: %d s\n\n', toc);


    disp('Inverting the linear system of coefficients')

    % ok, now with the pseudoinverse
    PsiTPsi = transpose(Psi)*Psi;
    try
        if rcond(PsiTPsi) > 0.01
            % faster
            a = PsiTPsi\(transpose(Psi)*Y);
        else
            % stabler
            a = pinv(PsiTPsi) * transpose(Psi) * Y;
        end
    catch err
        warning('The test for polynomial basis generation could not complete.');
        rethrow(err);
    end

    fprintf('time needed for solving the linear system: %ds\n', toc);
    idx = find(abs(a) > .1);
    for ii = 1:length(idx)
        fprintf('Coefficient [%s] = %2.3f\n', num2str(full(alphas(idx(ii),:))),a(idx(ii)));
    end

    % give an error estimate
    metavalues = Psi*a;

    err_est = sqrt(mean((Y - metavalues).^2))/sqrt(mean(metavalues.^2));

    pass = pass & err_est<1e-10;
end

% return success if all tests pass (otherwise an error would have been
% thrown and success would be 0).
success = pass;