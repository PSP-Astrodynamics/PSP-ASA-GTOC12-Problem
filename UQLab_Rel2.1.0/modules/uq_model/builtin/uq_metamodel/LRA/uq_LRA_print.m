function uq_LRA_print(LRAModel,outArray, varargin)
% uq_LRA_print(Coefs, Basis)
% Print information about the computed LRA model

%% Consistency checks and command line parsing
if ~exist('outArray', 'var') || isempty(outArray)
    outArray = 1;
    if length(LRAModel.LRA) > 1;
        warning('The selected LRA has more than 1 output. Only the 1st output will be printed');
        fprintf('You can specify the outputs you want to be displayed with the syntax:\n')
        fprintf('uq_display(LRAModule, OUTARRAY)\nwhere OUTARRAY is the index of desired outputs, e.g. 1:3 for the first three\n\n')
    end
end
if max(outArray) > length(LRAModel.LRA)
    error('Requested output range is too large') ;
end

%% parsing the residual command line
% initialization
coeff_flag = false;
TOL = 1e-2;

if nargin > 2
    parse_keys = {'coefficients', 'tolerance'};
    parse_types = {'f', 'p'};
    [uq_cline, varargin] = uq_simple_parser(varargin, parse_keys, parse_types);
    % 'coefficients' option additionally prints the coefficients
    if strcmp(uq_cline{1}, 'true')
        coeff_flag = true;
    end
    
    % 'tolerance' option sets the default tolerance to plot coefficients
    if ~strcmp(uq_cline{2}, 'false')
        TOL = uq_cline{2};
    end

end


for ii = 1:length(outArray)

    % Retrieve information about the LRA

    NInp = length(LRAModel.Internal.Input.nonConst);
        
    % Assuming orthonormality, the mean and std can be computed analytically 
    % from the LRA coefficients:

    
    Mean = LRAModel.LRA(ii).Moments.Mean;
    StdDev = sqrt(LRAModel.LRA(ii).Moments.Var);
    
    % Retrieve the computational options:
    comp_options = LRAModel.Internal.ComputationalOpts.FinalLRA;
    
    M = length(LRAModel.Internal.Input.Marginals);
    
    %  Display
    fprintf('\n%%------------ Canonical LRA output ------------%%\n');
    fprintf('   Number of input variables:  %8i\n', M);
    fprintf('   Full model evaluations:     %8i\n', LRAModel.ExpDesign.NSamples);
    fprintf('   Degree of polynomials used: %8i\n', LRAModel.LRA(ii).Basis.Degree);
    fprintf('   Rank:                       %8i\n', LRAModel.LRA(ii).Basis.Rank);
    fprintf('   Correction Step: \n');
    fprintf('       Regression Method:      %8s\n',comp_options.CorrStep.Method);
    fprintf('   Updating Step: \n');
    fprintf('       Regression Method:      %8s\n',comp_options.UpdateStep.Method);
    fprintf('   CVError:                      %8.4e\n',LRAModel.Error(ii).SelectedCVScore);
    if isfield(LRAModel.Error,'Val')
        fprintf('   Validation error:             %8.4e\n',LRAModel.Error(outArray(ii)).Val);
    end
    fprintf('   Mean value:                 %8.4f\n',Mean);
    fprintf('   Standard deviation:         %8.4f\n',StdDev);
    fprintf('   Coef. of variation:         %8.3f%%\n',StdDev/abs(Mean)*100);
    fprintf('%%------------------------------------------------%%\n');
    
    if coeff_flag
       uq_LRA_printCoeff(LRAModel,TOL, outArray(ii));
    end
end


function uq_LRA_printCoeff(LRAModel, TOL, outidx)
% post_process_print_coefs(Coefs, Basis)
% Pretty-print the chaos coefficients for interpretation
%

if ~exist('TOL', 'var')
    TOL = 1e-2;
end

error('Printing of LRA coefficients is not yet implemented.');