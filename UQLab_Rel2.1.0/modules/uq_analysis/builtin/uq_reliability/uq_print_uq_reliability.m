function uq_print_uq_reliability(module, outidx, varargin)
% UQ_PRINT_UQ_RELIABILITY(module, outidx, varargin)
%     defines the behavior of the uq_print function for uq_reliability
%     objects.
%
% See also: UQ_DISPLAY_UQ_RELIABILITY

%% CONSISTENCY CHECKS
if ~strcmp(module.Type, 'uq_reliability')
    fprintf('uq_print_uq_reliability only operates on UQ_RELIABILITY objects!')
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
    fprintf('---------------------------------------------------\n')
    if strcmp(module.Internal.Method, 'mc'); fprintf('Monte Carlo simulation\n'); end
    if strcmp(module.Internal.Method, 'is'); fprintf('Importance Sampling\n'); end
    if strcmp(module.Internal.Method, 'sorm'); fprintf('FORM/SORM\n'); end
    if strcmp(module.Internal.Method, 'form'); fprintf('FORM\n'); end
    if strcmp(module.Internal.Method, 'subset'); fprintf('Subset simulation\n'); end
    if strcmpi(module.Internal.Method, 'akmcs'); fprintf('AK-MCS\n'); end
    if strcmpi(module.Internal.Method, 'alr'); fprintf('Active learning reliability\n'); end
    if strcmpi(module.Internal.Method, 'inverseform'); fprintf('Inverse FORM\n'); end
    if strcmpi(module.Internal.Method, 'sser'); fprintf('Stochastic spectral embedding-based reliability\n'); end
    if strcmpi(module.Internal.Method, 'ls'); fprintf('Line sampling\n'); end
    if strcmpi(module.Internal.Method, 'bls'); fprintf('Bayesian line sampling\n'); end

    fprintf('---------------------------------------------------\n')
    
    
    %% Display the MONTE CARLO, SUBSET SIMULATION, AK-MCS, IMPORTANCE SAMPLING, or SSER results
    if strcmp(module.Internal.Method, 'mc') || strcmp(module.Internal.Method, 'is')...
            || strcmp(module.Internal.Method, 'subset') || strcmpi(module.Internal.Method, 'akmcs')  ...
            || strcmpi(module.Internal.Method, 'alr') || strcmpi(module.Internal.Method, 'sser') ...
            || strcmpi(module.Internal.Method, 'ls') || strcmpi(module.Internal.Method, 'bls')
        %Failure probability (Pf)
        curline1 = [];
        curline1 = sprintf('%s%-17s',curline1,'Pf');
        curline1 = sprintf('%s%-17.4d',curline1,Results.Pf(oo));
        fprintf([curline1, '\n'])
        
        %Reliability index (Beta)
        curline1 = [];
        curline1 = sprintf('%s%-17s',curline1,'Beta');
        curline1 = sprintf('%s%-17.4f',curline1,Results.Beta(oo));
        fprintf([curline1, '\n'])
        
        %Coefficient of variation
        curline1 = [];
        curline1 = sprintf('%s%-17s',curline1,'CoV');
        curline1 = sprintf('%s%-17.4g',curline1,Results.CoV(oo));
        fprintf([curline1, '\n'])
        
        %Model evaluations
        curline1 = [];
        curline1 = sprintf('%s%-17s',curline1,'ModelEvaluations');
        curline1 = sprintf('%s%-17i',curline1,sum(Results.ModelEvaluations));
        fprintf([curline1, '\n'])
        
        %Confidence bounds for Pf
        curline1 = [];
        curline1 = sprintf('%s%-17s',curline1,'PfCI');
        curline1 = [curline1, '['];
        curline1 = sprintf('%s%-10.4e %-10.4e',curline1,Results.PfCI(oo,1),Results.PfCI(oo,2));
        curline1 = [curline1, ']'];
        fprintf([curline1, '\n'])
        
        %Confidence bounds for Beta
        curline1 = [];
        curline1 = sprintf('%s%-17s',curline1,'BetaCI');
        curline1 = [curline1, '['];
        curline1 = sprintf('%s%-10.4e %-10.4e',curline1,Results.BetaCI(oo,1),Results.BetaCI(oo,2));
        curline1 = [curline1, ']'];
        fprintf([curline1, '\n'])
        
    end
    
    if (strcmpi(module.Internal.Method, 'akmcs') || ...
            strcmpi(module.Internal.Method, 'alr') ) && ...
            isfield(Results.History(oo),'PfLower')
        % PFplus and PFminus
        curline1 = [];
        curline1 = sprintf('%s%-17s',curline1,'PfMinus/Plus');
        curline1 = [curline1, '['];
        curline1 = sprintf('%s%-10.4e %-10.4e',curline1,[Results.History(oo).PfLower(end) Results.History(oo).PfUpper(end)]);
        curline1 = [curline1, ']'];
        fprintf([curline1, '\n'])
        
    end
    
    %% display the FORM/SORM results
    if strcmp(module.Internal.Method, 'sorm') || strcmp(module.Internal.Method, 'form') || strcmp(module.Internal.Method, 'inverseform')
        
        %Pf
        curline1 = [];
        curline1 = sprintf('%s%-17s',curline1,'Pf');
        curline1 = sprintf('%s%-17.4d',curline1,Results.Pf(oo));
        fprintf([curline1, '\n'])
        %Beta
        curline1 = [];
        curline1 = sprintf('%s%-17s',curline1,'BetaHL');
        curline1 = sprintf('%s%-17.4f',curline1,Results.BetaHL(oo));
        fprintf([curline1, '\n'])
        
        
        if isfield(module.Results, 'G')
            %PFFORM
            curline1 = [];
            curline1 = sprintf('%s%-17s',curline1,'G(Ustar)');
            curline1 = sprintf('%s%-17.4d',curline1,Results.G(oo));
            fprintf([curline1, '\n'])
        end
        
        if isfield(module.Results, 'PfSORM')
            %PFFORM
            curline1 = [];
            curline1 = sprintf('%s%-17s',curline1,'PfFORM');
            curline1 = sprintf('%s%-17.4d',curline1,Results.PfFORM(oo));
            fprintf([curline1, '\n'])
            
            %PfSORM
            curline1 = [];
            curline1 = sprintf('%s%-17s',curline1,'PfSORM');
            curline1 = sprintf('%s%-17.4d',curline1,Results.PfSORM(oo));
            fprintf([curline1, '\n'])
            
            %Pf
            curline1 = [];
            curline1 = sprintf('%s%-17s',curline1,'PfSORMBreitung');
            curline1 = sprintf('%s%-17.4d',curline1,Results.PfSORMBreitung(oo));
            fprintf([curline1, '\n'])
        end
        
        %Model evaluations
        curline1 = [];
        curline1 = sprintf('%s%-17s',curline1,'ModelEvaluations');
        curline1 = sprintf('%s%-17i',curline1,Results.ModelEvaluations);
        fprintf([curline1, '\n'])
        
        %Variables, Ustar, Xstar, Importance factors
        fprintf('---------------------------------------------------\n')
        curline1 = [];
        curline2 = [];
        curline3 = [];
        curline4 = [];
        curline1 = sprintf('%s%-17s',curline1,'Variables');
        curline2 = sprintf('%s%-17s',curline2,'  Ustar');
        curline3 = sprintf('%s%-17s',curline3,'  Xstar');
        curline4 = sprintf('%s%-17s',curline4,'  Importance');
        
        for ii = 1 : size(Results.Ustar,2)
            curline1 = sprintf('%s%-12s',curline1,module.Internal.Input.Marginals(ii).Name);
            curline2 = sprintf('%s%-12.6f',curline2,Results.Ustar(:,ii,oo));
            curline3 = sprintf('%s%-12.2d',curline3,Results.Xstar(:,ii,oo));
            curline4 = sprintf('%s%-12.6f',curline4,Results.Importance(oo,ii));
        end
        
        curline1 = [curline1 '\n'];
        curline2 = [curline2 '\n'];
        curline3 = [curline3 '\n'];
        curline4 = [curline4 '\n'];
        
        fprintf([curline1 curline2 curline3 curline4]);
        
    end
    
    %% end the display
    fprintf('---------------------------------------------------\n')
    fprintf('\n')
    
end