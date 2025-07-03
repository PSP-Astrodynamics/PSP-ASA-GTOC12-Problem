function a_solutions = lambertSolverSMA(TOF, c, s, mu)
    %LAMBERTSOLVERSMA Find the semimajor axes of possible Lambert arcs with a specified TOF
    %   Given chord and semiperimeter of space triangle find the semimajor  
    % axes for possible Lambert arcs with a specified time of flight

    % Define alpha0 and beta0
    alpha0 = @(a) 2 * asin(sqrt(s ./ (2 * a)));  % radians
    beta0 = @(a) 2 * asin(sqrt((s - c) ./ (2 * a)));  % radians

    % Define hyp alpha0 and beta0
    alphaH = @(a) 2 * asinh(sqrt(s ./ (2 * abs(a))));  % radians
    betaH = @(a) 2 * asinh(sqrt((s - c) ./ (2 * abs(a))));  % radians

    % Define the four equations
    lambert_eq1A = @(a) sqrt(mu) * TOF - a^(3/2) * (alpha0(a) - sin(alpha0(a)) - (beta0(a) - sin(beta0(a))));
    lambert_eq1B = @(a) sqrt(mu) * TOF - a^(3/2) * (2*pi - (alpha0(a) - sin(alpha0(a))) - (beta0(a) - sin(beta0(a))));
    lambert_eq2A = @(a) sqrt(mu) * TOF - a^(3/2) * (alpha0(a) - sin(alpha0(a)) + beta0(a) - sin(beta0(a)));
    lambert_eq2B = @(a) sqrt(mu) * TOF - a^(3/2) * (2*pi - (alpha0(a) - sin(alpha0(a))) + (beta0(a) - sin(beta0(a))));
    lambert_eq1H = @(a) sqrt(mu) * TOF - abs(a)^(3/2) * (sinh(alphaH(a)) - alphaH(a) - (sinh(betaH(a)) - betaH(a)));
    lambert_eq2H = @(a) sqrt(mu) * TOF - abs(a)^(3/2) * (sinh(alphaH(a)) - alphaH(a) + (sinh(betaH(a)) - betaH(a)));
    
    % Solve for 'a' using fzero for each equation
    a_guess = 10*s;
    
    % answer key: [1A; 1B; 2A; 2B; 1H; 2H]
    a_solutions = real([fsolve(lambert_eq1A, a_guess), fsolve(lambert_eq1B, a_guess),...
        fsolve(lambert_eq2A, a_guess), fsolve(lambert_eq2B, a_guess),...
        fsolve(lambert_eq1H, a_guess), fsolve(lambert_eq2H, a_guess)]);

    a_solutions = {'1A', '1B', '2A', '2B', '1H', '2H';...
        a_solutions(1),a_solutions(2),a_solutions(3),a_solutions(4),a_solutions(5),a_solutions(6)};
    
end