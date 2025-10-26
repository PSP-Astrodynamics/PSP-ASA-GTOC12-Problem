function uq_SSE_print(SSEModel, outArray, varargin)
% UQ_SSE_PRINT(SSEMODEL,OUTARRAY): pretty print information on the
%     SSE object in SSEMODEL for the specified set of output components
%     OUTARRAY (default: OUTARRAY = 1).
%
%     UQ_SSE_PRINT(SSEMODEL,OUTARRAY,'EXPANSIONDETAILS') additionally
%     prints the expansion details
%
% See also: UQ_PCE_DISPLAY,UQ_KRIGING_PRINT,UQ_PRINT_UQ_METAMODEL

%% Consistency checks and command line parsing
if ~exist('outArray', 'var') || isempty(outArray)
    outArray = 1;
    if length(SSEModel.SSE) > 1
        warning('The selected SSE has more than 1 output. Only the 1st output will be printed');
        fprintf('You can specify the outputs you want to be displayed with the syntax:\n')
        fprintf('uq_display(SSEModule, OUTARRAY)\nwhere OUTARRAY is the index of desired outputs, e.g. 1:3 for the first three\n\n')
    end
end
if max(outArray) > length(SSEModel.SSE)
    error('Requested output range is too large') ;
end

%% parsing the residual command line
% initialization
PRINT_EXPANSIONDETAILS = false;

if nargin > 2
    parse_keys = {'expansionDetails'};
    parse_types = {'f'};
    [uq_cline, varargin] = uq_simple_parser(varargin, parse_keys, parse_types);
    % 'expansionDetails' option additionally prints the expansion details
    if strcmp(uq_cline{1}, 'true')
        PRINT_EXPANSIONDETAILS = true;
    end
end


for ii = 1:length(outArray)
    % Retrieve output index
    oo = outArray(ii);
    % Extract some useful parameters
    M = length(SSEModel.Internal.Input.Marginals);
    currSSE = SSEModel.SSE(oo);
    % count number of expansions
    NumExp = 0;
    for nn = 1:numnodes(currSSE.Graph)
        if ~isempty(currSSE.Graph.Nodes.expansions{nn})
            NumExp = NumExp + 1;
        end
    end
    NumLevel = max(currSSE.Graph.Nodes.level)+1;
    NumRef = max(currSSE.Graph.Nodes.ref)+1;
    NED = length(currSSE.ExpDesign.Y);
    ExpansionType = currSSE.ExpOptions.MetaType;
    AbsWRE = SSEModel.Error(oo).AbsWRE;
    
    % Is relative error evailable
    if ~isempty(SSEModel.Error(oo).RelWRE)
        PRINT_RELERROR = true;
        RelWRE = SSEModel.Error(oo).RelWRE;
    else
        PRINT_RELERROR = false;
    end
    
    % Are moments available
    if isfield(SSEModel.SSE(oo).Moments, 'Mean') && isfield(SSEModel.SSE(oo).Moments, 'Var')
        PRINT_MOMENTS = true;
        Mean = SSEModel.SSE(oo).Moments.Mean;
        StdDev = sqrt(SSEModel.SSE(oo).Moments.Var);
    else
        PRINT_MOMENTS = false;
    end
    
    % Is validation error available
    if isfield(SSEModel.Error(oo),'Val')
        PRINT_VALERROR = true;
    else
        PRINT_VALERROR = false;
    end
    
    % Print
    % General SSE information
    fprintf('\n%%-------- Stochastic spectral embedding output --------%%\n');
    fprintf('   # input variables:                 %13.1i\n', M);
    fprintf('   # expansions:                      %13.1i\n', NumExp);
    fprintf('   # levels:                          %13.1i\n', NumLevel);
    fprintf('   # refinement steps:                %13.1i\n', NumRef);
    fprintf('   # full model evaluations:          %13.1i\n', NED);
    fprintf('\n');
    fprintf('   Error estimates\n'); 
    fprintf('      Abs. weighted expansion error:  %13.4f\n', AbsWRE);
    if PRINT_RELERROR || PRINT_MOMENTS
    fprintf('      Rel. weighted expansion error:\n');
    end
    if PRINT_RELERROR
    fprintf('         With sample variance:        %13.4f\n', RelWRE);
    end
    if PRINT_MOMENTS 
    fprintf('         With SSE variance:           %13.3f\n', AbsWRE/(StdDev^2));
    end
    if PRINT_VALERROR     
    RelVal = SSEModel.Error(oo).Val;
    fprintf('      Rel. validation error:          %13.3f\n', RelVal);
    end
    
    if PRINT_MOMENTS
    fprintf('\n');
    fprintf('   Moments\n');      
    fprintf('      Mean value:                     %13.4f\n',Mean);
    fprintf('      Standard deviation:             %13.4f\n',StdDev);
    fprintf('      Coef. of variation:             %13.3f%%\n',StdDev/abs(Mean)*100);   
    end
    
    if PRINT_EXPANSIONDETAILS
    fprintf('%%------------------------------------------------------%%\n');
    % local expansion information
    fprintf('   Local expansion (%s) information: \n',ExpansionType);
    for ee = 1:NumExp  
    currExpansion = currSSE.Expansions(ee);
    fprintf('      %s #%i:\n', ExpansionType, ee);
    fprintf('         experimental design size:    %13.1i\n', currExpansion.ExpDesign.NSamples);
    if strcmpi(ExpansionType,'pce')
    fprintf('         Maximal degree:              %13.1i\n', max(currExpansion.PCE.Basis.Degree));
    %Error measures
    PCEMethod = currExpansion.Options.Method;
    switch lower(PCEMethod)
    case {'ols','lars','omp','sp'}
    fprintf('         LOO error:                   %13.4e%%\n', currExpansion.Error.LOO);
    case {'bcs'}
    fprintf('         k-fold CV error:             %13.4e%%\n', currExpansion.Error.LOO);
    case {'quadrature'}
    fprintf('         Quadrature error:            %13.4e%%\n', currExpansion.Error.normEmpError);
    end
    end
    end
    end
    fprintf('%%------------------------------------------------------%%\n');
end
end