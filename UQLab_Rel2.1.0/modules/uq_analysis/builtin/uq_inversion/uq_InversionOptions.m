% UQ_INVERSIONOPTIONS displays a helper for the main options needed to
%   create a Bayesian inversion analysis in UQLab.
%
%   UQ_INVERSIONOPTIONS displays the main options needed by the command
%   <a href="matlab:help uq_createAnalysis">uq_createAnalysis</a> to create a Bayesian inversion ANALYSIS object
%   in UQLab.
%
%   See also: uq_createAnalysis, uq_getAnalysis, uq_listAnalyses, uq_selectAnalysis 

fprintf('Quickstart guide to the UQLab Bayesian Inversion Module\n')
fprintf('\n')

fprintf('In the UQLab software, Bayesian Inversion ANALYSIS objects are\n')
fprintf('created by the command:\n')
fprintf('\n')
fprintf('    myBayesianAnalysis = uq_createAnalysis(BAYESIANOPTIONS)\n')
fprintf('\n')
fprintf('The options are specified in the BAYESIANOPTIONS structure.\n')
fprintf('\n')

fprintf('Example: to create a Bayesian inverse analysis with MYFORWARDMODEL,\n')
fprintf('MYPRIORDISTRIBUTION, and MYDATA, type:\n')
fprintf('\n')
fprintf('    BAYESIANOPTIONS.Type = ''Inversion'';\n')
fprintf('    BAYESIANOPTIONS.ForwardModel = MYFORWARDMODEL;\n')
fprintf('    BAYESIANOPTIONS.Prior = MYPRIORDISTRIBUTION;\n')
fprintf('    BAYESIANOPTIONS.Data = MYDATA;\n')
fprintf('    myBayesianAnalysis = uq_createAnalysis(BAYESIANOPTIONS)\n')
fprintf('\n')

fprintf('To graphically display the analysis results, type:\n')
fprintf('\n')
fprintf('    uq_display(myBayesianAnalysis)\n')
fprintf('\n')

fprintf('By default, the discrepancy model between the MYFORWARDMODEL predictions\n')
fprintf('and the supplied MYDATA is assumed to be independent identically\n')
fprintf('distributed (iid) Gaussian with an unknown variance.\n')
fprintf('\n')

fprintf('By default, the analysis is conducted with the affine invariant\n')
fprintf('ensemble sampler MCMC algorithm. Available samplers are:\n')
fprintf('\n')
fprintf('    %-15s - %s\n', '''MH''', 'Metropolis-Hastings')
fprintf('    %-15s - %s\n', '''AM''', 'Adaptive Metropolis')
fprintf('    %-15s - %s\n', '''HMC''', 'Hamiltonian Monte Carlo')
fprintf('    %-15s - %s\n', '''AIES''', 'Affine invariant ensemble sampler')
fprintf('\n')

fprintf(['Please refer to the Bayesian Inversion Module User Manual ',...
    '(<a href="matlab:uq_doc(''Inversion'',''html'')">HTML</a>,'...
    '<a href="matlab:uq_doc(''Inversion'',''pdf'')">PDF</a>)\n'])
fprintf('for more detailed information on the available options.\n')
fprintf('\n')