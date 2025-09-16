function uq_print_uq_rbdo(module, outidx, varargin)
% UQ_PRINT_UQ_RBDO(module, outidx, varargin)
%     defines the behavior of the uq_print function for uq_rbdo
%     objects.
% 
% See also: UQ_DISPLAY_UQ_RBDO

%% CONSISTENCY CHECKS
if ~strcmp(module.Type, 'uq_rbdo')
   fprintf('uq_print_uq_rbdo only operates on UQ_RBDO objects!') 
end

Results = module.Results(end);

%% COMMAND LINE PARSING
% default to printing only values for the first output variable
if ~exist('outidx', 'var')
    outidx = 1;
end

%%
%for each index in OUTIDX 
for oo = outidx

%% display the reliability method
fprintf('\n')
fprintf('\n%%---------------------------------- RBDO ----------------------------------%%\n\n');
% Optimal cost
curline1 = [];
fprintf('%%------------------ Optimal cost\n');
CoLabel{1,1} = 'Fstar' ;
CoLabel{2,1} = sprintf('%.4e',Results.Fstar) ; 
uq_printTable(CoLabel) ;
% curline1 = sprintf('%s%-17s',curline1,'Fstar:');
% curline1 = sprintf('%s\t%-12.4e',curline1,Results.Fstar);
% fprintf([curline1, '\n'])


% Optimal design
% curline1 = [];
% curline1 = sprintf('%s%-16s\t',curline1,'dstar');
% Put a loop because somehow sprintf does not work well with vectors
% May not be the most efficient way of proceeding. Need fix later

% for ii = 1:length(Results.Xstar)
% curline1 = sprintf('%s%-12.4e',curline1,Results.Xstar(ii));
% end
fprintf('\n%%------------------ Optimal design\n');
Labels = cell(2, length(Results.Xstar) );
for ii = 1:length(Results.Xstar)
    Labels{1,ii} = module.Internal.Input.DesVar(ii).Name ;
    Labels{2,ii} = sprintf('%.4e',Results.Xstar(ii)) ;
end
% fprintf([curline1, '\n']) ;
uq_printTable(Labels) ;

fprintf('\n%%------------------ Constraints at solution\n');
switch lower(module.Internal.Method)
    case {'ria'}
        constraint_label = 'beta';
    case {'sora', 'sla', 'decoupled', 'mono-level', 'deterministic', 'pma'}
        constraint_label = 'G';
        
    case 'two-level'
        constraint_label = 'beta';
        switch lower(module.Internal.Reliability.Method)
            case {'mcs','is','subset','form','sorm'}
                switch lower(module.Internal.Optim.ConstraintType)
                    case 'pf'
                        constraint_label = 'Pf';
                    case 'beta'
                        constraint_label = 'beta';
                end
            case 'qmc'
                constraint_label = 'q' ;
            case 'iform'
                constraint_label = 'G' ;
        end
        
    case 'qmc'
        constraint_label = 'q';
        
end

if isfield(Results.History,'GlobalOptim')
    iterGO = length(Results.History.GlobalOptim.Score) ;
    
    % Check if the solution comes from the local or the lobal part of the
    % hybrid optimizer
    if Results.Fstar == Results.History.LocalOptim.Score(end)
        constraints = Results.History.Constraints(end,:) ;
    else
        % The last recorded solution of CMA-ES is not necessarily the
        % optimal solution so assign actual solution properly
        if strcmpi(module.Internal.Optim.Method,{'hccmaes'})
            constraints = Results.History.Constraints(module.Results.output.NewBestPoint(end),:) ;
        else
            constraints = Results.History.Constraints(iterGO,:) ;
        end
    end
else
    % The last recorded solution of CMA-ES is not necessarily the
    % optimal solution so assign actual solution properly
    if strcmpi(module.Internal.Optim.Method,{'ccmaes'})
        constraints = Results.History.Constraints(module.Results.output.NewBestPoint(end),:) ;
    else
        constraints = Results.History.Constraints(end,:) ;
    end
end

CoLabel = cell(2,length(constraints)) ;
for ii = 1:length(constraints)
    CoLabel{1,ii} = sprintf('%s_%s',constraint_label,num2str(ii));
    CoLabel{2,ii} = sprintf('%.4e',constraints(ii)) ;
end
uq_printTable(CoLabel) ;

% RBDO method
fprintf('\n%%------------------ Method\n');

switch lower(module.Internal.Method)
    case 'two-level'
        switch lower(module.Internal.Reliability.Method)
            case {'mc','mcs'}
                fprintf('RBDO Method:\t\tTwo-level with Monte Carlo simulation\n');
            case 'subset'
                fprintf('RBDO Method:\t\tTwo-level with subset simulation\n');
            case {'is', 'importance sampling'}
                fprintf('RBDO Method:\t\tTwo-level with subset simulation\n');
            otherwise
                % None of the above reliability methods
                fprintf('RBDO Method:\t\tTwo-level approach\n');
        end
    case 'ria'
        fprintf('RBDO Method:\t\tReliability index approach (RIA)\n');
    case 'pma'
        fprintf('RBDO Method:\t\tPerformance measure approach (PMA)\n');
    case 'sora'
        fprintf('RBDO Method:\t\tSequential optimization and reliability assessment (SORA)\n');
    case 'sla'
        fprintf('RBDO Method:\t\tSingle loop approach (SLA)\n');
    case 'qmc'
        fprintf('RBDO Method:\t\tQuantile Monte Carlo approach (QMC)\n');
    otherwise
        fprintf('RBDO Method:\t\t%s', module.Internal.Method) ;
end

% Optimization
fprintf('\n%%------------------ Optimization\n');
% Algortihm
switch lower(module.Internal.Optim.Method)
    case 'sqp'
        fprintf('Algorithm:\t\t\tSequential quadratic programming (SQP)\n');
    case {'ip', 'interior-point'}
        fprintf('Algorithm:\t\t\tInterior-point (IP)\n');
    case {'ga'}
        fprintf('Algorithm:\t\t\tGenetic algorithm\n');
    case {'ccmaes'}
        fprintf('Algorithm:\t\t\tConstrained (1+1)-CMA-ES\n');
    case {'hga'}
        fprintf('Algorithm:\t\t\tHybrid genetic algorithm (HGA)\n');
    case {'hccmaes'}
        fprintf('Algorithm:\t\t\tHybrid constrained (1+1)-CMA-ES\n');
    otherwise
        fprintf('RBDO Method:\t\t%s', module.Internal.Optim.Method) ;
end

% Iterations
switch lower(module.Internal.Optim.Method)
    case {'sqp','ip','ccmaes'}
        if strcmpi(module.Internal.Method, 'sora')
            fprintf('Cycles:\t\t\t\t%u\n',Results.output.iterations);
        else
            fprintf('Iterations:\t\t\t%u\n',Results.output.iterations);
        end
    case 'ga'
            fprintf('Iterations:\t\t\t%u\n',Results.output.generations);
    case {'hga'}
        fprintf('Iterations:\t\t\t%u (global) + %u (local)\n',Results.output.GA.generations,Results.output.GRAD.iterations);
    case {'hccmaes'}
        fprintf('Iterations:\t\t\t%u (global) + %u (local)\n',Results.output.CCMAES.iterations,Results.output.GRAD.iterations);
    otherwise
        try
            fprintf('Iterations:\t\t\t%u\n',Results.output.iterations);
        catch
            % If the field .output.funccount does not exist. Mark ierations
            % as non-available (NA)
            fprintf('Iterations:\t\t\tNA\n');
        end
end

% Model evaluations - Use a try and catch statement
if ~strcmpi(module.Internal.Optim.Method,'ga')
    if length(Results.ModelEvaluations) == 1
        fprintf('Model evaluations:\t%u\n',Results.ModelEvaluations);
    else
        for jj = 1: length(Results.ModelEvaluations)
            fprintf('Model evaluations output #%u:\t%u\n',jj, Results.ModelEvaluations(jj));
        end
    end   
else
    % If the field .Results.ModelEvaluations does not exist, Mark
    % model evalation as non-available (NA)
    fprintf('Model evaluations:\tNA\n');
end

% Exitflag
switch lower(module.Internal.Optim.Method)
    case {'sqp','ip','ga','ccmaes'}
        fprintf('Exit message:\t\t%s\n',Results.exitMsg);
    case {'hga'}
        fprintf('Exit message:\t\tGlobal: %s \nLocal: %s\n',Results.exitMsg.GA,Results.exitMsg.GRAD);
    case {'hccmaes'}
        fprintf('Exit message:\t\tGlobal: %s \nLocal: %s\n',Results.exitMsg.CCMAES,Results.exitMsg.GRAD);
    otherwise
        try
            fprintf('Exit message:\t\t\t%s\n',Results.exitMsg);
        catch
            % If the field .exitflagt does not exist. Mark ierations
            % as non-available (NA)
            fprintf('Exit flag:\t\t\tNA\n');
        end
end

% Surrogate
if module.Internal.Runtime.Metamodel
fprintf('\n%%------------------ Surrogate\n');
% Type
switch lower(module.Internal.Metamodel.Type)
    case 'kriging'
        fprintf('Type:\t\t\t\tKriging \n');
    case {'pck'}
        fprintf('Type:\t\t\t\tPC-Kriging \n');
    case {'pce'}
        fprintf('Type:\t\t\t\tPCE \n');
    case {'svr'}
        fprintf('Type:\t\t\t\tSVR \n');
    case {'svc'}
        fprintf('Type:\t\t\t\tSVC \n');
    case {'lra'}
        fprintf('Type:\t\t\t\tLRA \n');
    otherwise
        fprintf('Type:\t\t\t\t%s \n', module.Internal.Metamodel.Type) ;
end

% Size: Number of calls to the original model
fprintf('ED size:\t\t\t%u\n',Results.OriginalModelCalls);

end
fprintf('\n%%--------------------------------------------------------------------------%%\n');
fprintf('\n')

end 