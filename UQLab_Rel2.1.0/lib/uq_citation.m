function uq_citation(module)
% UQ_CITATION display a proper citation of the different UQLab User Manuals
%
%   UQ_CITATION prints the reference to the basic UQLab reference paper.
%
%   UQ_CITATION('help') returns a list of available user manuals.
%
%   UQ_CITATION(MANUAL) displays bibliographical information about a 
%   particular UQLab module user manual specified in the MANUAL argument.
%
% See also uq_doc, uqlab.

if nargin == 0 || isempty(module)
   module = 'uqlab';
end

tabchar = sprintf('  ');
switch lower(module)

    case 'help'
        help uq_citation
        fprintf('\n')
        disp('  <a href="matlab:help uq_citation">uq_citation</a>(MANUAL) prints the reference to a specific UQLab user manual,');
        disp('  where MANUAL is one of the following:')
        fprintf('\n')
        disp('    ''<a href="matlab:uq_citation(''ALR'')">ALR</a>''          - UQLab user manual: Active learning reliability')
        disp('    ''<a href="matlab:uq_citation(''dispatcher'')">Dispatcher</a>''   - UQLab user manual: The HPC dispatcher module')
        disp('    ''<a href="matlab:uq_citation(''GLaM'')">GLaM</a>''    - UQLab user manual: Generalized lambda models (GLaM)')
        disp('    ''<a href="matlab:uq_citation(''inference'')">Inference</a>''    - UQLab user manual: Statistical inference')
        disp('    ''<a href="matlab:uq_citation(''input'')">Input</a>''        - UQLab user manual: The Input module')
        disp('    ''<a href="matlab:uq_citation(''inversion'')">Inversion</a>''    - UQLab user manual: Bayesian inference for model calibration and inverse problems')
        disp('    ''<a href="matlab:uq_citation(''Kriging'')">Kriging</a>''      - UQLab user manual: Kriging (Gaussian Process Modelling)')
        disp('    ''<a href="matlab:uq_citation(''LRA'')">LRA</a>''          - UQLab user manual: Canonical low rank approximations')
        disp('    ''<a href="matlab:uq_citation(''Model'')">Model</a>''        - UQLab user manual: The Model module')
        disp('    ''<a href="matlab:uq_citation(''PCE'')">PCE</a>''          - UQLab user manual: Polynomial Chaos Expansions')
        disp('    ''<a href="matlab:uq_citation(''PCK'')">PCK</a>''          - UQLab user manual: PC-Kriging')
        disp('    ''<a href="matlab:uq_citation(''RF'')">Random field</a>'' - UQLab user manual: Random fields')
        disp('    ''<a href="matlab:uq_citation(''RBDO'')">RBDO</a>''         - UQLab user manual: Reliability-based design optimization')
        disp('    ''<a href="matlab:uq_citation(''Reliability'')">Reliability</a>''  - UQLab user manual: Reliability analysis (Rare events estimation)')
        disp('    ''<a href="matlab:uq_citation(''Sensitivity'')">Sensitivity</a>''  - UQLab user manual: Sensitivity analysis')
        disp('    ''<a href="matlab:uq_citation(''SPCE'')">SPCE</a>''  - UQLab user manual: Stochastic polynomial chaos expansions (SPCE)')
        disp('    ''<a href="matlab:uq_citation(''SSE'')">SPCE</a>''  - UQLab user manual: Stochastic spectral embedding')
        disp('    ''<a href="matlab:uq_citation(''SVC'')">SVC</a>''          - UQLab user manual: Support vector machines for classification')
        disp('    ''<a href="matlab:uq_citation(''SVR'')">SVR</a>''          - UQLab user manual: Support vector machines for regression')
        disp('    ''<a href="matlab:uq_citation(''UQLib'')">UQLib</a>''        - UQLab user manual: UQLib')
        disp('    ''<a href="matlab:uq_citation(''UQLink'')">UQLink</a>''       - UQLab user manual: UQLink')

        fprintf('\n')

    case 'uqlab'
        disp('To cite UQLab in publications please use:')
        fprintf('\n');
        disp([tabchar, 'S. Marelli, and B. Sudret, UQLab: A framework for uncertainty quantification in Matlab,'])
        disp([tabchar, 'Proc. 2nd Int. Conf. on Vulnerability, Risk Analysis and Management (ICVRAM2014),'])
        disp([tabchar, 'Liverpool (United Kingdom), 2014, 2554-2563.']);
        fprintf('\n');

    case 'alr'
        disp('To cite the Active learning reliability manual in publications please use:');
        fprintf('\n');
        disp([tabchar, 'M. Moustapha, S. Marelli, and B. Sudret, UQLab user manual - Active learning reliability,']);
        disp([tabchar, 'Report UQLab-V2.1-117, Chair of Risk, Safety & Uncertainty Quantification,']);
        disp([tabchar, 'ETH Zurich, 2024.']);
        fprintf('\n');
        
    case 'dispatcher'
        disp('To cite the HPC dispatcher manual in publications please use:');
        fprintf('\n');
        disp([tabchar, 'D. Wicaksono, S. Marelli, and B. Sudret, UQLab user manual - The HPC dispatcher module,']);
        disp([tabchar, 'Report UQLab-V2.1-116, Chair of Risk, Safety & Uncertainty Quantification,']);
        disp([tabchar, 'ETH Zurich, 2024.']);
        fprintf('\n');

    case 'glam'
        disp('To cite the Generalized lambda models manual in publications please use:');
        fprintf('\n');
        disp([tabchar, 'N. Lüthen, X. Zhu, S. Marelli, and B. Sudret, UQLab user manual - Generalized lambda models,']);
        disp([tabchar, 'Report UQLab-V2.1-120, Chair of Risk, Safety & Uncertainty Quantification,']);
        disp([tabchar, 'ETH Zurich, 2024.']);
        fprintf('\n');

    case 'input'
        disp('To cite the Input manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'C. Lataniotis, E. Torre, S. Marelli, and B. Sudret, UQLab user manual - The Input module,'])
        disp([tabchar, 'Report UQLab-V2.1-102, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')
        
    case 'inference'
        disp('To cite the Inference manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'E. Torre, S. Marelli and B. Sudret, UQLab user manual - Statistical inference,'])
        disp([tabchar, 'Report UQLab-V2.1-114, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')

    case 'inversion'
        disp('To cite the Bayesian inversion manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'P.-R. Wagner, J. Nagel, S. Marelli, and B. Sudret, UQLab user manual - Bayesian inference for model calibration and inverse problems,'])
        disp([tabchar, 'Report UQLab-V2.1-113, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')

    case 'kriging'
        disp('To cite the Kriging manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'C. Lataniotis, D.Wicaksono, S. Marelli, and B. Sudret, UQLab user manual - Kriging (Gaussian process modeling),'])
        disp([tabchar, 'Report UQLab-V2.1-105, Chair of Risk, Safety & Uncertainty Quantification'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')

    case 'model'
        disp('To cite the Model manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'C. Lataniotis, S. Marelli, and B. Sudret, UQLab user manual - the Model module,'])
        disp([tabchar, 'Report UQLab-V2.1-103, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')
    
    case 'lra'
        disp('To cite the Low-Rank Approximations manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'K. Konakli, C. Mylonas, S. Marelli, and B. Sudret, UQLab user manual - Canonical low-rank approximations,'])
        disp([tabchar, 'Report UQLab-V2.1-108, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')

    case 'pce'
        disp('To cite the Polynomial Chaos Expansions manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'S. Marelli, N. Lüthen, and B. Sudret, UQLab user manual - Polynomial Chaos Expansions,'])
        disp([tabchar, 'Report UQLab-V2.1-104, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')
        
    case 'pck'
        disp('To cite the PC-Kriging manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'R. Schöbi, S. Marelli and B. Sudret, UQLab user manual - PC-Kriging,'])
        disp([tabchar, 'Report UQLab-V2.1-109, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')

    case 'sensitivity'
        disp('To cite the Sensitivity analysis manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'S. Marelli, C. Lamas, and B. Sudret, UQLab user manual - Sensitivity analysis,'])
        disp([tabchar, 'Report UQLab-V2.1-106, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')

    case 'rf'
        disp('To cite the Random field manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'M. Moustapha, N. Fajraoui, S. Marelli, and B. Sudret, UQLab user manual - Random fields,'])
        disp([tabchar, 'Report UQLab-V2.1-119, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')
        
    case 'rbdo'
        disp('To cite the RBDO manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'M. Moustapha, S. Marelli, and B. Sudret, UQLab user manual - Reliability-based design optimization,'])
        disp([tabchar, 'Report UQLab-V2.1-115, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')

    case 'reliability'
        disp('To cite the Structural Reliability analysis manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'S. Marelli, R. Schöbi, and B. Sudret, UQLab user manual - Structural reliability (Rare events estimation),'])
        disp([tabchar, 'Report UQLab-V2.1-107, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')
        
    case 'spce'
        disp('To cite the Stochastic polynomial chaos expansions manual in publications please use:');
        fprintf('\n');
        disp([tabchar, 'N. Lüthen, X. Zhu, S. Marelli, and B. Sudret, UQLab user manual - Stochastic polynomial chaos expansions,']);
        disp([tabchar, 'Report UQLab-V2.1-121, Chair of Risk, Safety & Uncertainty Quantification,']);
        disp([tabchar, 'ETH Zurich, 2024.']);
        fprintf('\n');

    case 'sse'
        disp('To cite the Stochastic spectral embedding manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'P.-R. Wagner, S. Marelli, and B. Sudret, UQLab user manual - Stochastic spectral embedding,'])
        disp([tabchar, 'Report UQLab-V2.1-118, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')


    case 'svr'
        disp('To cite the Support Vector Regression manual in publications please use:');
        fprintf('\n');
        disp([tabchar, 'M. Moustapha, C. Lataniotis, S. Marelli, and B. Sudret, UQLab user manual - Support vector machines for regression,']);
        disp([tabchar, 'Report UQLab-V2.1-111, Chair of Risk, Safety & Uncertainty Quantification,']);
        disp([tabchar, 'ETH Zurich, 2024.']);
        fprintf('\n');
        
    case 'svc'
        disp('To cite the Support Vector Classification manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'M. Moustapha, C. Lataniotis, S. Marelli, and B. Sudret, UQLab user manual - Support vector machines for classification,'])
        disp([tabchar, 'Report UQLab-V2.1-112, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')

    case 'uqlib'
        disp('To cite the UQLib manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'M. Moustapha, C. Lataniotis, P. Wiederkehr, P.-R. Wagner, D. Wicaksono, S. Marelli, and B. Sudret,'])
        disp([tabchar, 'UQLib user manual,'])
        disp([tabchar, 'Report UQLab-V2.1-201, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')

    case 'uqlink'
        disp('To cite the UQLink manual in publications please use:')
        fprintf('\n')
        disp([tabchar, 'M. Moustapha, S. Marelli, and B. Sudret, UQLab user manual - UQLink,'])
        disp([tabchar, 'Report UQLab-V2.1-110, Chair of Risk, Safety & Uncertainty Quantification,'])
        disp([tabchar, 'ETH Zurich, 2024.'])
        fprintf('\n')
        
    otherwise
        disp('Unknown module name!')
        fprintf('\n')
        uq_citation('help');

end
