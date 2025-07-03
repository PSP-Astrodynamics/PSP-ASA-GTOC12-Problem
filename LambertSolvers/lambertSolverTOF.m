function TOF_solutions = lambertSolverTOF(a, c, s, mu)
    %LAMBERTSOLVERP Find times of flight for possible Lambert arcs with a specified semimajor axis
    %   Given chord and semiperimeter of space triangle find the times of
    % flight for possible Lambert arcs with a specified semimajor axis

    % Define alpha0 and beta0
    alpha0 = 2 * asin(sqrt(s ./ (2 * a)));  % radians
    beta0 = 2 * asin(sqrt((s - c) ./ (2 * a)));  % radians

    % Define hyperbolic alpha, beta
    alphaH = 2 * asinh(sqrt(s / (2 * a))); 
    betaH = 2 * asinh(sqrt((s - c) / (2 * a)));

    % Define the four equations
    TOF1A = a^(3/2) * (alpha0 - sin(alpha0) - (beta0 - sin(beta0))) / sqrt(mu);
    TOF1B = a^(3/2) * (2*pi - (alpha0 - sin(alpha0)) - (beta0 - sin(beta0))) / sqrt(mu);
    TOF2A = a^(3/2) * (alpha0 - sin(alpha0) + beta0 - sin(beta0)) / sqrt(mu);
    TOF2B = a^(3/2) * (2*pi - (alpha0 - sin(alpha0)) + (beta0 - sin(beta0))) / sqrt(mu);
    TOF1P = (1/3)*sqrt(2/mu)*(s^(3/2)-(s-c)^(3/2));
    TOF2P = (1/3)*sqrt(2/mu)*(s^(3/2)+(s-c)^(3/2));
    TOF1H = abs(a)^(3/2) * (sinh(alphaH) - alphaH - (sinh(betaH) - betaH)) / sqrt(mu);
    TOF2H = abs(a)^(3/2) * (sinh(alphaH) - alphaH + (sinh(betaH) - betaH)) / sqrt(mu);
    
    % answer key: [1A; 1B; 2A; 2B]
    TOF_solutions = {'1A', '1B', '2A', '2B', '1P', '2P', '1H', '2H'; TOF1A, TOF1B, TOF2A, TOF2B, TOF1P, TOF2P, TOF1H, TOF2H};
  
end