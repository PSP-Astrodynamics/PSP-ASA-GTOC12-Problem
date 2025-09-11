%% RELIABILITY: TIME VARIANCE
%
% In this example, UQLab is used to compute the outcrossing rate $\nu^+$
% in a non-stationary time-variant reliability problem
% using the so-called PHI2 method.
% 
% For details, see:
% Sudret, B. (2008). 
% Analytical derivation of the outcrossing rate in time-variant reliability
% problems. Structure and Infrastructure Engineering, 4 (5), 353-362
% (Section 5).
% <https://doi.org/10.1080/15732470701270058 DOI:10.1080/15732470701270058>

%% 1 - THEORY

%% 1.1 Problem statement
%
% The limit state function is defined as the difference between a degrading
% resistance $r(t) = R - b\, t$ and a time-varying load $S(t)$:
% 
% $$g(t, R, S) = R-bt-S(t)$$
%
% where: 
%
% * $R$: the resistance, modeled by a Gaussian random variable
%        of mean value $\mu_R$ and standard deviation $\sigma_R$ 
% * $b$: (deterministic) deterioration rate of the resistance
% * $t$: time
% * $S(t)$: time-varying stress, which is modeled by a stationary
%           Gaussian process of mean value $\mu_S$,
%           standard deviation $\sigma_S$ and square-exponential
%           autocorrelation function $\rho_S(t) = \exp(- (t/\ell)^2)$
%
%% 1.2 PHI2 Method
%
% The outcrossing rate from the safe to the failure domain is then defined
% by:
% 
% $$\nu^+(t) =\lim_{\Delta t \rightarrow 0}  \frac{P[(g(t)>0)\cap (g(t+\Delta t)\leq 0)]}{\Delta t}$$
% 
% The limit state functions at two different times can be written as 
% $g(t) = R-bt-S_1$ and $g(t+\Delta t) = R-b(t+\Delta t)-S_2$, where the
% two stress variables $S_1$ and $S_2$ are correlated:
%
% $$\rho_{S_1,S_2} = \exp(- (\Delta t/\ell)^2)$$
% 
% THE PHI2 method solves two FORM analysis at time instant $t$ and
% $t+\Delta t$, then estimates the outcrossing rate from the parallel
% system probability of failure defined above:
%
% $$\nu^+_{PHI2}(t) = \frac{\Phi_2(\beta(t), -\beta(t+ \Delta t ), -\alpha(t) \cdot \alpha(t+\Delta t))}{\Delta t}$$
%
% where:
%
% * $\beta(t)$ (resp. $\beta(t+ \Delta t)$): the time-invariant
%   Hasofer-Lind reliability index at time instant t (resp. $t+ \Delta t$)
% * $\alpha(t)$: unit vector to the design point in the standard
%   normal space.

%% 1.3 Analytical reference solution
%
% According to Sudret (2008), for the example under consideration,
% an analytical expression of the outcrossing rate can be derived:
% 
% $$\nu^+(t) = \omega_0 \Psi\left( \frac{-b}{\omega_0 \sigma_S} \right) \frac{\sigma_S}{\sqrt{\sigma_R^2+\sigma_S^2}}\ \varphi\left(  \frac{\mu_R-bt-\mu_S}{\sqrt{\sigma_R^2+\sigma_S^2}} \right)$$
% 
% where:
%
% * $\omega_0$ is the cycle rate defined as
%   $\omega_0^2= - \rho_S''(0) = \sqrt{2}/\ell$, 
% * $\Psi(x) = \varphi(x) - x \Phi(-x)$, and $\varphi$ and $\Phi$ are
%   the PDF and CDF values of a standard Gaussian variable. 
% 
% In this example, pairs of FORM analyses are carried out at different time
% instants so as to compute the outcrossing rate as a function of time.
% The PHI2 solution is compared to the analytical solution.
% Note that another Eq.(41) of Sudret (2008) is implemented
% in this example.
% The more stable Eq. (40) of the same reference could be also used.

%% 2 - INITIALIZE UQLAB
%
% Clear all variables from the workspace,
% set the random number generator for reproducible results,
% and initialize the UQLab framework:
clearvars
rng(1,'twister')
uqlab

%% 3 - APPLICATION 
%
% Assume the following:
%
% * Resistance: $\mu_R=5$, $\sigma_R = 0.3$
% * Stress: $\mu_S = 3$, $\sigma_S = 0.5$
% * Deterioration rate $b=0.01$
% * Time $t$ = [0:1:50], $\Delta t =10^{-3}$
% * Squared exponential correlation model with correlation length of $\ell=10$
muR = 5; sigmaR = 0.3;
muS = 3; sigmaS = 0.5;
b = 0.01;
t = 0;
deltat = 0.001;
l = 10;

%%
% The assumptions above lead to a correlation between $S_1$ and $S_2$ of 
rho_12 = exp(-deltat^2/l^2); 

%% 
% and a cycle rate of 
omega_0 = sqrt(2/l^2);

%%
% Then, the analytical outcrossing rate is (Sudret, 2008, Eq.(46)):
PSI = @(x) normpdf(x) - x.* normcdf(-x);
v = omega_0 * PSI(-b/(omega_0*sigmaS)) * (sigmaS/sqrt(sigmaR^2+sigmaS^2)) *...
    normpdf((muR-b*t-muS)/sqrt(sigmaR^2+sigmaS^2));

%% 4 - PROBABILISTIC INPUT MODEL
%
% In order to account for the correlation of $S_1$ and $S_2$,
% define a three-dimensional input vector as follows:
InputOpts.Marginals(1).Name = 'R';  % resistance
InputOpts.Marginals(1).Type = 'Gaussian';
InputOpts.Marginals(1).Parameters = [muR sigmaR];

InputOpts.Marginals(2).Name = 'S_1';  % Gaussian process at t
InputOpts.Marginals(2).Type = 'Gaussian';
InputOpts.Marginals(2).Parameters = [muS sigmaS];

InputOpts.Marginals(3).Name = 'S_2';  % Gaussian process at t+Delta_t
InputOpts.Marginals(3).Type = 'Gaussian';
InputOpts.Marginals(3).Parameters = [muS sigmaS];

%% 
% The computed correlation coefficient is used:
InputOpts.Copula.Type = 'Gaussian';
InputOpts.Copula.Parameters = [1 0 0; 0 1 rho_12; 0 rho_12 1];

%%
% Create an INPUT object based on the defined marginals and copula:
myInput = uq_createInput(InputOpts);

%% 5 - LIMIT STATE FUNCTION
%
% The limit state function returns a two-dimensional output related to:
%
% $$g_1(\mathbf{x}) = R-b\, t - S_1 ,\quad g_2(\mathbf{x}) = R-b\, (t+\Delta t) - S_2$$
%
% where $\mathbf{x} = \{R, S_1, S_2\}$ is the vector of input variables.

%%
% Define the limit state function using a string
% in a vectorized expression.
% The values of time instants are passed as parameters P(1) and P(2):
LSOpts.mString = ['[(X(:,1)-',num2str(b),'*P(1)-X(:,2)) X(:,1)-',...
    num2str(b),'*P(2)-X(:,3) ]'];
LSOpts.Parameters = [t t+deltat];

%%
% Create a MODEL object of the limit state function:
myLimitState = uq_createModel(LSOpts);

%% 6 - RELIABILITY ANALYSIS
%
% A FORM analysis is conducted to estimate the two failure probabilities at
% time instants $t$ and $t+\Delta t$. Note that FORM can carry out several
% analysis related to each output limit state function in a single call.
%
% Select FORM as the reliability analysis method:
FORMOpts.Type = 'Reliability';
FORMOpts.Method = 'FORM';

%%
% Run the FORM analysis:
myFORM = uq_createAnalysis(FORMOpts);

%% 7 - ESTIMATION OF THE OUTCROSSING RATE
%
% Using the same equations as in
% |UQ_EXAMPLE_RELIABILITY_04_PARALLELSYSTEM|, the parallel system failure
% probability can be estimated as follows:
betaS1 = myFORM.Results.BetaHL(1);
betaS2 = myFORM.Results.BetaHL(2);

alpha1 = -myFORM.Results.Ustar(:,:,1) / betaS1;
alpha2 = myFORM.Results.Ustar(:,:,2) / betaS2;

B = [-betaS1; betaS2];
R = [ 1                 alpha1*alpha2'
      alpha1*alpha2'    1             ];
Pf_FORM = mvncdf(-B, [0;0], R);

%%
% And finally, compute the outcrossing rate:
v_FORM = Pf_FORM / deltat;

%% 8 - COMPARISON TO THEORETICAL RESULTS
%
fprintf('-------------------------------------\n')
fprintf('Outcrossing rate (t=0)\n')
fprintf('Theoretical       : %11.4e\n',v)
fprintf('FORM approximation: %11.4e\n',v_FORM)
fprintf('-------------------------------------\n')

%% 9 - EVOLUTION IN TIME OF THE OUTCROSSING RATE
%
% Set time varying between $t = 0$ and $t = 50$
% and compute the analytical outcrossing rate for each time instant:
tt = 0:1:50;
vv = omega_0 * ...
    PSI(-b/(omega_0*sigmaS)) * (sigmaS/sqrt(sigmaR^2+sigmaS^2)) *...
    normpdf((muR-b*tt-muS)/sqrt(sigmaR^2+sigmaS^2));

%%
% Use the same limit state function and FORM options as before:
LSiOpts = LSOpts;
FORMiOpts = FORMOpts;
FORMiOpts.Display = 0;

%%
% Compute the approximated outcrossing rate by the PHI2 method
% at each time instant:
vv_FORM = zeros(length(tt),1);  % Initialize variable
for ii = 1:length(tt)
    LSiOpts.Parameters = [tt(ii) tt(ii)+deltat];
    myLimitStatei = uq_createModel(LSiOpts);
    myFORMi = uq_createAnalysis(FORMiOpts);
    betaS1i = myFORMi.Results.BetaHL(1);
    betaS2i = myFORMi.Results.BetaHL(2);
    alpha1i = -myFORMi.Results.Ustar(:,:,1) / betaS1i  ;
    alpha2i = myFORMi.Results.Ustar(:,:,2) / betaS2i ;
    Bi = [-betaS1i; betaS2i];
    Ri = [ 1                 alpha1i*alpha2i'
        alpha1i*alpha2i'    1             ];
    Pf_FORMi = mvncdf(-Bi, [0;0], Ri);
    vv_FORM(ii) = Pf_FORMi / deltat;
end

%% 
% Plot the outcrossing rate as a function of time 
% (analytical versus PHI2 values):
uq_figure
uq_plot(...
    tt, vv,...
    tt(1:2:end), vv_FORM(1:2:end), 'o')
xlim([0 50])
ylim([0 9e-4])
set(gca, 'XTick', 0:10:50, 'YTick', 0:1e-4:1e-3)
uq_legend('Analytical result','PHI2 approximation')
xlabel('t')
ylabel('$\mathrm{\nu^+}$')
