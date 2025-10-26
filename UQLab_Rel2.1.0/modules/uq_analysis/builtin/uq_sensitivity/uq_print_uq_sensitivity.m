function uq_print_uq_sensitivity(module, outidx, varargin)
% UQ_PRINT_UQ_SENSITIVITY(MODULE,OUTIDX,VARARGIN): print a user-friendly
%     summary of the results in the sensitivity object in MODULE for
%     the output variables specified in OUTIDX (default: OUTIDX=1).
%
% See also: UQ_DISPLAY_UQ_SENSITIVITY

%% CONSISTENCY CHECKS
if ~strcmp(module.Type, 'uq_sensitivity')
   fprintf('uq_print_uq_sensitivity only operates on objects of type ''uq_sensitivity''') 
end

%% COMMAND LINE PARSING
% default to printing only values for the first output variable
if ~exist('outidx', 'var')
    outidx = 1;
end

%% Execute the relevant print function depending on the argument
Method = module.Internal.Method;
switch lower(Method)
    case  'correlation'
        print_correlation(module, outidx, varargin{:});
    case  'perturbation'
        print_perturbation(module, outidx, varargin{:});
    case  'cotter'
        print_cotter(module, outidx, varargin{:});
    case  'src'
        print_src(module, outidx, varargin{:});
    case  'morris'
        print_morris(module, outidx, varargin{:});
    case  'sobol'
        print_sobol(module, outidx, varargin{:});
	case 'borgonovo'
        print_borgonovo(module, outidx, varargin{:});
    case  'ancova'
        print_ancova(module, outidx, varargin{:});
    case  'kucherenko'
        print_kucherenko(module, outidx, varargin{:});
    otherwise
        try eval(sprintf('uq_sensitivity_print_%s(module, outidx, varargin{:});', lower(Method)));
        catch me
            fprintf('The current sensitivity method ''%s'' is not recognized as a printable one.\n', lower(Method));
            display(module);
        end
end



%% Correlation method
function print_correlation(module, outidx, varargin)
% collect the relevant information
CorrIDX = module.Results(end).CorrIndices;
RankCorrIDX = module.Results(end).RankCorrIndices;
VarNames = module.Results(end).VariableNames;
Cost = module.Results(end).Cost;

for oo = outidx
    fprintf('-------------------------------------------\n')
    fprintf('Correlation-based sensitivity indices:\n')
    fprintf('-------------------------------------------\n')
    print_table(VarNames, CorrIDX(:,oo));
    
    fprintf('\n-------------------------------------------\n')
    fprintf('Rank-Correlation-based sensitivity indices:\n')
    fprintf('-------------------------------------------\n')
    print_table(VarNames, RankCorrIDX(:,oo));
    
    fprintf('Total cost (model evaluations): %d\n\n', Cost);
end
    
    
%% Perturbation method
function print_perturbation(module, outidx, varargin)
% collect the relevant information
Sensitivity = module.Results(end).Sensitivity;
VarNames = module.Results(end).VariableNames;
Cost = module.Results(end).Cost;

for oo = outidx
    fprintf('-------------------------------------------\n')
    fprintf('Perturbation-based sensitivity indices:\n')
    fprintf('-------------------------------------------\n')
    print_table(VarNames, Sensitivity(:,oo));
    fprintf('-------------------------------------------\n')
end

%% Standard Regression Coefficients
function print_src(module, outidx, varargin)
% collect the relevant information
SRCIDX = module.Results(end).SRCIndices;
SRRCIDX = module.Results(end).SRRCIndices;
VarNames = module.Results(end).VariableNames;
Cost = module.Results(end).Cost;

for oo = outidx
    fprintf('-------------------------------------------\n')
    fprintf('Standard Regression sensitivity indices:\n')
    fprintf('-------------------------------------------\n')
    print_table(VarNames, SRCIDX(:,oo));
    
    fprintf('\n-------------------------------------------\n')
    fprintf('Standard Rank-Regression sensitivity indices:\n')
    fprintf('-------------------------------------------\n')
    print_table(VarNames, SRRCIDX(:,oo));
    fprintf('-------------------------------------------\n')
end


%% Cotter method
function print_cotter(module, outidx, varargin)
% collect the relevant information
CotterIndices = module.Results(end).CotterIndices;
VarNames = module.Results(end).VariableNames;
Cost = module.Results(end).Cost;
for oo = outidx
    fprintf('-------------------------------------------\n')
    fprintf('Cotter sensitivity indices:\n')
    fprintf('-------------------------------------------\n')
    print_table(VarNames, CotterIndices(:,oo));
    fprintf('-------------------------------------------\n')
end

%% Morris method
function print_morris(module, outidx, varargin)
% collect the relevant information
MU = module.Results(end).Mu;
MUStar = module.Results(end).MuStar;
MSTD = module.Results(end).Std;
VarNames = module.Results(end).VariableNames;
Cost = module.Results(end).Cost;

for oo = outidx
    fprintf('--------------------------------------------------\n')
    fprintf('     Morris sensitivity indices:\n')
    fprintf('--------------------------------------------------\n')
    
    titleline =  '       ';
    muline =     'mu:    ';
    mustarline = 'mu*:   ';
    stdline =    'sigma: ';
    for ii = 1:length(MU(:,oo))
        titleline = sprintf('%s%-12s',titleline,VarNames{ii});
        muline = sprintf('%s%-12.6f',muline,MU(ii,oo));
        mustarline = sprintf('%s%-12.6f',mustarline,MUStar(ii,oo));
        stdline = sprintf('%s%-12.6f',stdline,MSTD(ii,oo));
    end
    fprintf([titleline '\n' muline '\n' mustarline '\n' stdline '\n']);
    fprintf('--------------------------------------------------\n')
end
fprintf('Total cost (model evaluations): %d\n\n', Cost);


%% Sobol' indices
function print_sobol(module, outidx, varargin)
% collect the relevant information
Results = module.Results(end);
VarIdx = Results.VarIdx;
VarNames = Results.VariableNames;
    
% loop over the components
for oo = outidx
    % determine which results are available
    if isfield(Results, 'Total')
        Total = Results.Total(:,oo);
    else
        Total = [];
    end
    if isfield(Results, 'FirstOrder')
        FirstOrder = Results.FirstOrder(:,oo);
    else
        FirstOrder = [];
    end
    if isfield(Results,'AllOrders') && length(Results.AllOrders) > 1
        SecondOrderSobol = Results.AllOrders{2}(:,oo);
    else
        SecondOrderSobol = [];
    end
    if ~Results.CoefficientBased
        Cost = Results.Cost;
    else
        % No additional cost is needed (maybe substitute with the size of the experimental design of the surrogate)
        Cost = 0;
    end
    
    % print
    if ~isempty(Total)
    fprintf('--------------------------------------------------\n')
    fprintf('     Total Sobol'' indices for output component %d\n', oo)
    fprintf('--------------------------------------------------')

    print_table(VarNames, Total);
    
    fprintf('--------------------------------------------------\n')
    end
    
    if ~isempty(FirstOrder)
    fprintf('--------------------------------------------------\n')
    fprintf('    First Order Sobol'' indices for output component %d\n', oo)
    fprintf('--------------------------------------------------')
    print_table(VarNames, FirstOrder);
    fprintf('--------------------------------------------------\n')
    end
    
    % print first few second order indices if available
    if ~isempty(SecondOrderSobol)
    fprintf('--------------------------------------------------\n')
    fprintf('    Second Order Sobol'' indices for output component %d\n', oo)
    fprintf('--------------------------------------------------')
    % first order them in descending order
    [SIndices, idx] = sort(SecondOrderSobol, 'descend');
    VIdx = VarIdx{2}(idx,:);
    VN = VarNames(VIdx);
    n = min(length(VN), 5);
    for ii = 1:n
        titles{ii} =  [VN{ii,:}];
    end
    print_table(titles, SIndices(1:n));
    fprintf('--------------------------------------------------\n')
    end

    fprintf('Total cost (model evaluations): %d\n\n', Cost);
end
function print_borgonovo(module, outidx, varargin)
% collect the relevant information
Results = module.Results(end);
nonConst = module.Internal.Input.nonConst;

if ~isfield(Results, 'Delta')
    fprintf('No results found!');
    display(module);
else
    % loop over the components
    for oo = outidx
        Delta = Results.Delta(:,oo);
        %VarIdx = Results.VarIdx;
        VarNames = Results.VariableNames(nonConst);
        fprintf('--------------------------------------------------\n')
        fprintf('     Borgonovo indices for output component %d\n', oo)
        fprintf('--------------------------------------------------')
        
        print_table(VarNames, Delta);
        
        fprintf('--------------------------------------------------\n')
        
    end
    fprintf('Total cost (model evaluations): %d\n\n', Results.Cost);    
end

%% ANCOVA indices
function print_ancova(module, outidx, varargin)
% collect the relevant information
Results = module.Results(end);

if ~isfield(Results, 'FirstOrder')
    fprintf('No results found!');
    display(module);
else
    VarNames = Results.VariableNames;
    % No additional cost is needed (maybe substitute with the size of the experimental design of the surrogate)
    Cost = 0;
    
    for oo = outidx % loop over different outputs
        First = Results.FirstOrder(:,oo);
        Uncorrelative = Results.Uncorrelated(:,oo);
        Interactive = Results.Interactive(:,oo);
        Correlative = Results.Correlated(:,oo);
        
        Collection = [First.'; Uncorrelative.'; Interactive.'; Correlative.'];
    
        % Now for the table
        fprintf('--------------------------------------------------\n')
        fprintf('     ANCOVA indices for output component %d\n', oo)
        fprintf('--------------------------------------------------')
        print_table_ancova(VarNames, Collection);
        fprintf('--------------------------------------------------\n')
    end
    fprintf(['Total cost (model evaluations): %d\n\n'], module.Results.Cost);
end


%% Kucherenko indices
function print_kucherenko(module, outidx, varargin)
% collect the relevant information
Results = module.Results(end);

if ~isfield(Results, 'Total')
    fprintf('No results found!');
    display(module);
else
    % loop over the components
    for oo = outidx
        Total = Results.Total(:,oo);
        FirstOrder = Results.FirstOrder(:,oo);
        
        VarNames = Results.VariableNames;
        fprintf('--------------------------------------------------\n')
        fprintf('  Total Kucherenko indices for output component %d\n', oo)
        fprintf('--------------------------------------------------')
        
        print_table(VarNames, Total);
        
        fprintf('--------------------------------------------------\n')
        
        fprintf('--------------------------------------------------\n')
        fprintf('  First Order Kucherenko indices for output component %d\n', oo)
        fprintf('--------------------------------------------------')
        print_table(VarNames, FirstOrder);
        fprintf('--------------------------------------------------\n')
        
        if isfield(Results.Cost, 'Metamodel')
            fprintf('Total cost (model evaluations):\t %d for the analysis\n\t\t\t\t\t\t\t   + %d for the metamodel\n\n', 0, Results.Cost);
        else
            fprintf('Total cost (model evaluations): %d\n\n', Results.Cost);
        end
    end
end%% Table printing
function print_table(titles, values)
n = length(titles);
if n ~= length(values)
    error('Length of title and list of values must be the same!')
end

% now for the printing
fprintf('\n');
curline1 = [];
curline2 = [];
for ii = 1:n
    curline1 = sprintf('%s%-12s',curline1,(titles{ii}(titles{ii} ~= '\')));
    curline2 = sprintf('%s%-12.6f',curline2,values(ii));
end
curline1 = [curline1 '\n'];
curline2 = [curline2 '\n'];
fprintf([curline1 curline2]);


%% ANCOVA table printing
function print_table_ancova(titles, values)
n = length(titles);
if n ~= size(values,2)
    error('Length of title and list of values must be the same!')
end

% now for the printing
fprintf('\n');
curline1 = [];
curline2 = [];
curline3 = [];
curline4 = [];
curline5 = [];

IndexCol = {'Indices' 'S' 'S^U' 'S^I' 'S^C'};

for ii = 1:(n+1)
    if ii == 1
        curline1 = sprintf('%s%-12s',curline1,IndexCol{1});
        curline2 = sprintf('%s%-12s',curline2,IndexCol{2});
        curline3 = sprintf('%s%-12s',curline3,IndexCol{3});
        curline4 = sprintf('%s%-12s',curline4,IndexCol{4});
        curline5 = sprintf('%s%-12s',curline5,IndexCol{5});
    else
        curline1 = sprintf('%s%-12s',curline1,(titles{ii-1}(titles{ii-1} ~= '\')));
        curline2 = sprintf('%s%-12.3f',curline2,values(1,ii-1));
        curline3 = sprintf('%s%-12.3f',curline3,values(2,ii-1));
        curline4 = sprintf('%s%-12.3f',curline4,values(3,ii-1));
        curline5 = sprintf('%s%-12.3f',curline5,values(4,ii-1));
    end
end
curline1 = [curline1 '\n'];
curline2 = [curline2 '\n'];
curline3 = [curline3 '\n'];
curline4 = [curline4 '\n'];
curline5 = [curline5 '\n'];
fprintf([curline1 curline2 curline3 curline4 curline5]);
