function uq_PCE_print(PCEModel, outArray, varargin)
% UQ_PCE_PRINT(PCEMODEL,OUTARRAY,VARARGIN): pretty print information on the
%     PCE object in PCEMODEL for the specified set of output components
%     OUTARRAY (default: OUTARRAY = 1).
%
% See also: UQ_PCE_DISPLAY,UQ_KRIGING_PRINT,UQ_PRINT_UQ_METAMODEL

%% Consistency checks and command line parsing
if ~exist('outArray', 'var') || isempty(outArray)
    outArray = 1;
    if length(PCEModel.PCE) > 1;
        warning('The selected PCE has more than 1 output. Only the 1st output will be printed');
        fprintf('You can specify the outputs you want to be displayed with the syntax:\n')
        fprintf('uq_display(PCEModule, OUTARRAY)\nwhere OUTARRAY is the index of desired outputs, e.g. 1:3 for the first three\n\n')
    end
end
if max(outArray) > length(PCEModel.PCE)
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


PCEType = PCEModel.Internal.Method;

for ii = 1:length(outArray)
    Coefs = PCEModel.PCE(outArray(ii)).Coefficients;
    Mean = Coefs(1);
    StdDev = sqrt(sum(Coefs(2:end).^2));
    
    M = length(PCEModel.Internal.Input.Marginals);
    
    %  Display
    fprintf('\n%%------------ Polynomial chaos output ------------%%\n');
    fprintf('   Number of input variables:    %i\n', M);
    fprintf('   Maximal degree:               %i\n', PCEModel.PCE(outArray(ii)).Basis.Degree);
    fprintf('   q-norm:                      %5.2f\n', PCEModel.PCE(outArray(ii)).Basis.qNorm);
    fprintf('   Size of full basis:           %i\n', length(PCEModel.PCE(outArray(ii)).Coefficients));
    fprintf('   Size of sparse basis:         %i\n', nnz(PCEModel.PCE(outArray(ii)).Coefficients));
    fprintf('   Full model evaluations:       %i\n', PCEModel.ExpDesign.NSamples);
    
    %Error measures
    switch lower(PCEType)
        case {'ols','lars','omp','sp'}
            fprintf('   Leave-one-out error:          %13.7e\n',PCEModel.Error(outArray(ii)).LOO);
            fprintf('   Modified leave-one-out error: %13.7e\n',PCEModel.Error(outArray(ii)).ModifiedLOO);
        case {'bcs'}
            fprintf('   k-fold CV error:              %13.7e\n',PCEModel.Error(outArray(ii)).LOO);
            fprintf('   Modified k-fold CV error:     %13.7e\n',PCEModel.Error(outArray(ii)).ModifiedLOO);
        case {'quadrature'}
            fprintf('   Quadrature error:          %13.7e\n',PCEModel.Error(outArray(ii)).normEmpError);
    end
    if isfield(PCEModel.Error,'Val')
        fprintf('   Validation error:             %13.7e\n',PCEModel.Error(outArray(ii)).Val);
    end
    
    fprintf('   Mean value:            %13.4f\n',Mean);
    fprintf('   Standard deviation:    %13.4f\n',StdDev);
    fprintf('   Coef. of variation:     %13.3f%%\n',StdDev/abs(Mean)*100);
    fprintf('%%--------------------------------------------------%%\n');
    
    if coeff_flag
       uq_PCE_printCoeff(PCEModel,TOL, outArray(ii));
    end
end


function uq_PCE_printCoeff(PCEModel, TOL, outidx)
% Pretty-print the chaos coefficients for interpretation


if ~exist('TOL', 'var')
    TOL = 1e-2;
end

CC = PCEModel.PCE(outidx).Coefficients;
Basis = full(PCEModel.PCE(outidx).Basis.Indices);

[P , M] = size(Basis);

% Build format of printing
MyFormat = '     [';
for i=1:M
    MyFormat = strcat(MyFormat, '%3i');
end
MyFormat= strcat(MyFormat, ']\t\t\t%12.7f\n');
fprintf('\n%%--- List of coefficients (sorted by amplitude) ---%%\n');
fprintf('     [ alpha_1   ...   alpha_M]\t\t  Coefficient\n');

% Print the coefficients according to the amplitude 
% and if they are greater than a threshold
[SortCoefs, ind] = sort(abs(CC),'descend');
TheStd = sqrt(sum(CC(2:end).^2));

for i=1:P
    cc = CC(ind(i));    
    if (abs(cc)> TOL*TheStd )
        tmp = Basis(ind(i),:);
        fprintf(MyFormat,tmp,cc);
    end
    
end