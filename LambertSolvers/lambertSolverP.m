function p_solution = lambertSolverP(a, c, s, r1, r2)
    %LAMBERTSOLVERP Find semilatus rectum for Lambert arcs with a specified semimajor axis
    %   Given a space triangle (c, r1, r2) find the semilatus rectum for 
    % Lambert arcs which have a specific semimajor axis

    % Principle values
    alpha0 = 2 * real(asin(sqrt(s / (2 * a))));  % radians
    beta0 = 2 * asin(sqrt((s - c) / (2 * a)));  % radians
    % Nonprinciple values
    alphaOther = 2 * pi - alpha0;
    betaOther = 2 * pi - beta0;

    % Calculate semilatus rectum p for each case
    pAB_1 = 4*a*(s-r1)*(s-r2)*(sin(0.5*(alpha0+beta0))^2)/c^2;
    pAB_2 = 4*a*(s-r1)*(s-r2)*(sin(0.5*(alpha0-beta0))^2)/c^2;
    pAB_1other = 4*a*(s-r1)*(s-r2)*(sin(0.5*(alphaOther+betaOther))^2)/c^2;
    pAB_2other = 4*a*(s-r1)*(s-r2)*(sin(0.5*(alphaOther-betaOther))^2)/c^2;

    % Package solution
    p_solution = {'pAB_1', 'pAB_2', 'pAB_1other', 'pAB_2other'; pAB_1, pAB_2, pAB_1other, pAB_2other};
end

