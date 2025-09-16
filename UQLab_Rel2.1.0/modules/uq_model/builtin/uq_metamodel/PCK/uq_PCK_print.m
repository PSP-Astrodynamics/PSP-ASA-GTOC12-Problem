function uq_PCK_print(PCKRGModel, outArray, varargin)
%This function prints a summary of the PC-Kriging model

numel_Print_limit = 5; % the limit of elements that can be printed


%% Consistency checks and command line parsing
if ~exist('outArray', 'var') || isempty(outArray)
    outArray = 1;
    if length(PCKRGModel.PCK) > 1
        warning('The selected PC-Kriging metamodel has more than 1 output. Only the 1st output will be printed');
        fprintf('You can specify the outputs you want to be displayed with the syntax:\n')
        fprintf('uq_print(PCKRGModel, OUTARRAY)\nwhere OUTARRAY is the index of desired outputs, e.g. 1:3 for the first three\n\n')
    end
end
if max(outArray) > length(PCKRGModel.PCK)
    error('Requested output range is too large') ;
end

%% parsing the residual command line
% initialization
if nargin > 2
    parse_keys = {'beta', 'theta','F','optim','trend','gp','GP','R'};
    parse_types = {'f', 'f','f', 'f','f', 'f','f','f'};
    [uq_cline, varargin] = uq_simple_parser(varargin, parse_keys, parse_types);
    % 'beta' option additionally prints beta
    beta_flag = strcmp(uq_cline{1}, 'true');

    % 'theta' option additionally prints beta
    theta_flag = strcmp(uq_cline{2}, 'true');
    
    % 'F' option additionally prints the information matrix
    F_flag = strcmp(uq_cline{3}, 'true');
       
    % 'optim' option additionally prints extensive optimization results
    % report
    optim_flag = strcmp(uq_cline{4}, 'true');
    
    % 'trend' option additionally prints extensive trend-related report
    % report
    trend_flag = strcmp(uq_cline{5}, 'true');
    
    % 'gp' option additionally prints extensive GP-related report
    % report
    gp_flag = any(strcmp({uq_cline{6},uq_cline{7}}, 'true'));
    
    % 'R' option additionally prints R matrix
    R_flag = strcmp(uq_cline{8}, 'true');
    
        
    flagWasSet = beta_flag | theta_flag | F_flag | optim_flag | ...
        trend_flag | gp_flag | R_flag;
else
    flagWasSet = false;
end

%% Produce the fixed header
fprintf('\n%%--------------- PC-Kriging metamodel ---------------%%\n');
fprintf('\tObject Name:\t\t%s\n', PCKRGModel.Name);

%% If some flag(s) print out the specified elements
if flagWasSet
    
    for ii =  1 : length(outArray)
        current_output = outArray(ii);
        if length(outArray) > 1
            fprintf('--- Output #%i:\n', current_output);
        end
    end
    
    if beta_flag
            fprintf('\n\tRegression Coefficients (beta):\n')
            fprintf('%s\n', ...
                add_leadingChars(uq_sprintf_mat(PCKRGModel.Kriging(current_output).beta) ,...
                sprintf('\t\t\t\t\t') ));
    end
    
    if F_flag
        fprintf('\nInformation matrix (F):\n')
        fprintf('%s\n', ...
            add_leadingChars(uq_sprintf_mat(PCKRGModel.Internal.Kriging(current_output).Trend.F) ,...
            sprintf('\t\t\t\t\t') ));
    end
   
    if R_flag
        fprintf('\nCorrelation matrix (R):\n')
        fprintf('%s\n', ...
            add_leadingChars(uq_sprintf_mat(PCKRGModel.Internal.Kriging(current_output).GP.R) ,...
            sprintf('\t\t\t\t\t') ));
    end
    
    
   if theta_flag
            fprintf('\n\tHyperparameter values (theta):\n')
            fprintf('%s\n', ...
                add_leadingChars(uq_sprintf_mat(PCKRGModel.Kriging(current_output).theta) ,...
                sprintf('\t\t\t\t\t') ));
    end

    if trend_flag
        % TODO
    end
    
    if gp_flag
        % TODO
    end
    
    if optim_flag
        % TODO
    end
    
    fprintf('%%--------------------------------------------------%%\n');
    return
end


%% Produce the default printout

M = PCKRGModel.Internal.Runtime.M;
fprintf('\tInput Dimension:\t%i\n', M);
fprintf('\n\tExperimental Design\n')
fprintf('\t\tSampling:\t%s\n', PCKRGModel.ExpDesign.Sampling)
fprintf('\t\tX size:\t\t[%s]\n', [num2str(size(PCKRGModel.ExpDesign.X,1)),'x',num2str(size(PCKRGModel.ExpDesign.X,2))])
fprintf('\t\tY size:\t\t[%s]\n', [num2str(size(PCKRGModel.ExpDesign.Y,1)),'x',num2str(size(PCKRGModel.ExpDesign.Y,2))])

%% Combination rule
fprintf('\n\tCombination\n')
fprintf('\t\tMode:\t\t\t%s\n', PCKRGModel.Internal.Mode);
if strcmpi(PCKRGModel.Internal.Mode, 'optimal')
    fprintf('\t\tComb. crit.:\t%s\n', PCKRGModel.Internal.CombCrit);
end

%%
for ii =  1 : length(outArray)
    current_output = outArray(ii);
    if length(outArray) > 1
        fprintf('--- Output #%i:\n', current_output);
    end
    %% Trend
    fprintf('\n\tTrend\n')
    fprintf('\t\tType:\t\t%s\n', 'orthogonal polynomials')
    fprintf('\t\tNo. polys:\t%i\n', PCKRGModel.Internal.NumberOfPoly)
    
    %% GP
    fprintf('\n\tGaussian Process\n')
    % Check whether a user defined or the default eval_R is used:
    CorrHandle = PCKRGModel.Internal.Kriging(current_output).Internal.Kriging.GP.Corr.Handle;
    if strcmp(char(CorrHandle), 'uq_Kriging_eval_R')
        if PCKRGModel.Internal.Kriging(current_output).Internal.Kriging.GP.Corr.Isotropic
            corrIsotropy = 'isotropic';
        else
            corrIsotropy = 'anisotropic';
        end
        fprintf('\t\tCorr. Type:\t\t%s(%s)\n', PCKRGModel.Internal.Kriging(current_output).Internal.Kriging.GP.Corr.Type,corrIsotropy)
        fprintf('\t\tCorr. family:\t%s\n', PCKRGModel.Internal.Kriging(current_output).Internal.Kriging.GP.Corr.Family)
        fprintf('\t\tsigma^2:\t\t%s\n', PCKRGModel.Internal.Kriging(current_output).Internal.Kriging.GP.sigmaSQ)
        switch lower(PCKRGModel.Internal.Kriging(current_output).Internal.Kriging.GP.EstimMethod)
            
            case 'ml'
                fprintf('\tEstimation method:\t%s\n', 'Maximum-Likelihood')
            case 'cv'
                fprintf('\tEstimation method:\t%s\n', 'Cross-Validation')
        end
    else
        % If it is a user-defined handle just show the handle for now
        fprintf('\t\tCorr. Handle:\t%s\n', func2str(CorrHandle))
    end
    %% Optimization
    fprintf('\n\tHyperparameters\n')
    theta = PCKRGModel.PCK(current_output).theta ;
    %     fprintf('\t\ttheta:\t\t[%s]\n', ...
    %         [num2str(size(theta,1)),'x',...
    %         num2str(size(theta,2))])
    fprintf('\t\ttheta:\t\t[%s]\n', uq_sprintf_mat(theta))
    switch lower(PCKRGModel.Internal.Kriging(current_output).Internal.Kriging.Optim.Method)
        
        case 'hga'
            fprintf('\tOptim. method:\t\t%s\n', 'Hybrid Genetic Algorithm' )
        case 'ga'
            fprintf('\tOptim. method:\t\t%s\n', 'Genetic Algorithm' )
        case 'bfgs'
            fprintf('\tOptim. method:\t\t%s\n', 'BFGS' )
        case 'sade'
            fprintf('\tOptim. method:\t\t%s\n', 'Self-Adaptive Differential Evolution' )
        case 'de'
            fprintf('\tOptim. method:\t\t%s\n', 'Differential Evolution' )
        otherwise
            fprintf('\tOptim. method:\t\t%s\n', ...
                PCKRGModel.Internal.Kriging(current_output).Internal.Kriging.Optim.Method)
    end
    
    
    
    fprintf('\n\tLeave-one-out error:\t%13.7e\n\n', ...
        PCKRGModel.Error(current_output).LOO);
    if isfield(PCKRGModel.Error,'Val')
        fprintf('\tValidation error:\t\t%13.7e\n\n', ...
            PCKRGModel.Error(outArray(ii)).Val);
    end
    
end

fprintf('%%--------------------------------------------------%%\n');


end


function str = add_leadingChars(str, chars , omitLast)

if nargin < 3
    omitLast = 1;
end

str = [chars str] ;

ind = strfind(str, sprintf('\n')) ;

if omitLast
    ind = ind(1:end-1);
end


nCh = length(chars) ;
nCh_tot = 0;
for ii = ind
    str = [str(1 : ii+nCh_tot), chars, str(ii+nCh_tot+1 : end) ] ;
    nCh_tot = nCh_tot + nCh;
end


end


