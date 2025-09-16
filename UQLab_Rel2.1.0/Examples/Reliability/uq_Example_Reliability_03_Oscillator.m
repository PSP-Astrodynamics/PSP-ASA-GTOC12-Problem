%% RELIABILITY: DAMPED OSCILLATOR
%
% This example showcases the application of various reliability analysis
% methods in UQLab to a damped oscillator problem.
%
% For details, see:
% Dubourg et al. (2013).
% Metamodel-based importance sampling for structural reliability
% analysis. Probalistic Engineering Mechanics, 44, 47-57.
% <https://doi.org/10.1016/j.probengmech.2013.02.002 DOI:10.1016/j.probengmech.2013.02.002>

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace,
% set the random number generator for reproducible results,
% and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% Consider a two-degree-of-freedom oscillator, which consists of two masses
% connected by springs and dampers, as described in Dubourg et al. (2013).
% 
% The limit state function compares the maximum force affecting
% on the secondary spring to the force capacity of the secondary spring:
% 
% $$g(\mathbf{x}) = F_s - p k_s \left[ \pi \frac{S_0}{4\zeta_s\omega_s^3} 
% \frac{\zeta_a \zeta_s}{\zeta_p \zeta_s (4\zeta_a^2+\theta^2) + \gamma\zeta_a^2}  
% \frac{(\zeta_p\omega_p^3+\zeta_s\omega_s^3)\omega_p}{4\zeta_a\omega_a^4} \right]^{1/2}$$
% 
% where:
% 
% * $\omega_p = \sqrt{k_p/m_p}$, $\quad \omega_s=\sqrt{k_s/m_s}$
% * $\gamma = m_p/m_s$, $\omega_a = 1/2(\omega_p+\omega_s)$
% * $\zeta_s=1/2(\zeta_p+\zeta_s)$, $\theta=(\omega_p-\omega_s)/\omega_a$
% * $p = 3$ (the peak factor)
% 
% The computation of the limit state function is carried out
% by the function |uq_DampedOscillator(X)| supplied with UQLab.
% The input parameters of this function are gathered into the vector |X|
% in the following order:
%
% # $m_p$: primary mass
% # $m_s$: secondary mass
% # $k_p$: stiffness of the primary spring
% # $k_s$: stifness  of the secondary spring 
% # $\zeta_p$: primary damping ratio
% # $\zeta_s$: secondary damping ratio
% # $S_0$: intensity of the white noise excitation. 
% # $F_s$: force capacity of the secondary spring

%% 
% Create a MODEL object using the function file:
ModelOpts.mFile = 'uq_DampedOscillator';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts);

%%
% Type |help uq_DampedOscillator| for information on the model structure 
% as well as the description of each variable.

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of eight independent lognormal
% random variables.
%
% Define an INPUT object using the following marginals:
InputOpts.Marginals(1).Name = 'mp';  %Primary mass
InputOpts.Marginals(1).Type = 'Lognormal';
InputOpts.Marginals(1).Moments = 1.5*[1 0.1];

InputOpts.Marginals(2).Name = 'ms';  % Secondary mass
InputOpts.Marginals(2).Type = 'Lognormal';
InputOpts.Marginals(2).Moments = 0.01*[1 0.1];

InputOpts.Marginals(3).Name = 'kp';  % Primary spring stiffness
InputOpts.Marginals(3).Type = 'Lognormal';
InputOpts.Marginals(3).Moments = 1*[1 0.2];

InputOpts.Marginals(4).Name = 'ks';  % Secondary spring stiffness
InputOpts.Marginals(4).Type = 'Lognormal';
InputOpts.Marginals(4).Moments = 0.01*[1 0.2];

InputOpts.Marginals(5).Name = 'zp';  % Primary damping ratio
InputOpts.Marginals(5).Type = 'Lognormal';
InputOpts.Marginals(5).Moments = 0.05*[1 0.4];

InputOpts.Marginals(6).Name = 'zs';  % Secondary damping ratio
InputOpts.Marginals(6).Type = 'Lognormal';
InputOpts.Marginals(6).Moments = 0.02*[1 0.5];

InputOpts.Marginals(7).Name = 'S0';  % White noise intensity
InputOpts.Marginals(7).Type = 'Lognormal';
InputOpts.Marginals(7).Moments = 100*[1 0.1];

InputOpts.Marginals(8).Name = 'Fs';  % Force capacity of the second. spring
InputOpts.Marginals(8).Type = 'Lognormal';
InputOpts.Marginals(8).Moments = 15*[1 0.1];

%%
% Create an INPUT object based on the defined marginals:
myInput = uq_createInput(InputOpts);

%% 4 - RELIABILITY ANALYSIS
%
% Failure event is defined as $g(\mathbf{x}) \leq 0$.
% The failure probability is then defined as
% $P_f = P[g(\mathbf{x}) \leq 0]$.
%
% Reliability analysis is performed with the following methods:
%
% * Monte Carlo simulation (MCS)
% * Subset simulation
% * Importance sampling (IS)

%% 4.1 Monte Carlo simulation (MCS)
%
% Select the Reliability module and the Monte Carlo simulation (MCS)
% method:
MCSOpts.Type = 'Reliability';
MCSOpts.Method = 'MCS';

%% 
% Specify the sample size and the target coefficient of variation (CoV):
MCSOpts.Simulation.BatchSize = 5e3;
MCSOpts.Simulation.MaxSampleSize = 1e6;
MCSOpts.Simulation.TargetCoV = 5e-2;

%%
% Run the Monte Carlo simulation:
MCSAnalysis = uq_createAnalysis(MCSOpts);

%%
% Print out a report of the results:
uq_print(MCSAnalysis)

%%
% Create a graphical representation of the results:
uq_display(MCSAnalysis)

%% 4.2 Subset Simulation
%
% Select the Reliability module and the subset simulation method:
SubsetSimOpts.Type = 'Reliability';
SubsetSimOpts.Method = 'Subset';

%%
% Specify the sample size in each subset:
SubsetSimOpts.Simulation.BatchSize = 5e3;

%%
% Run the subset simulation:
SubsetSimAnalysis = uq_createAnalysis(SubsetSimOpts);

%%
% Print out a report of the results:
uq_print(SubsetSimAnalysis)

%% 4.3 Importance Sampling (IS)
%
% Select the Reliability module and the importance sampling (IS) method:
ISOpts.Type = 'Reliability';
ISOpts.Method = 'IS';

%%
% Specify the sample size and the target coefficient of variation (CoV):
ISOpts.Simulation.BatchSize = 200;
ISOpts.Simulation.MaxSampleSize = 1e4;
ISOpts.Simulation.TargetCoV = 5e-2;

%%
% Save the evaluations:
ISOpts.SaveEvaluations = 1;

%%
% Run the reliabity analysis with IS:
ISAnalysis = uq_createAnalysis(ISOpts);

%%
% Print out a report of the results:
uq_print(ISAnalysis)

%%
% Create a graphical representation of the results:
uq_display(ISAnalysis)

%% 4.4 Stochastic spectral embedding-based reliability (SSER)
%
% Select the Reliability module and the stochastic spectral embedding-based
% reliability (SSER) method:
SSEROpts.Type = 'Reliability';
SSEROpts.Method = 'SSER';

%% 
% Increase the number of sample points added at each refinement step
SSEROpts.SSER.ExpDesign.NEnrich = 50;
SSEROpts.SSER.ExpDesign.NSamples = 200;

%%
% Run the reliabity analysis with SSER:
SSERAnalysis = uq_createAnalysis(SSEROpts);

%%
% Print out a report of the results:
uq_print(SSERAnalysis)

%%
% Create a graphical representation of the results:
uq_display(SSERAnalysis)
