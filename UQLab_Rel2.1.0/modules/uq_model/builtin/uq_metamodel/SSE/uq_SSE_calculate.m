function success = uq_SSE_calculate(currentModel)
% success = UQ_SSE_CALCULATE(CURRENTMODEL): calculates the SSE metamodel 
%     as specified in CURRENT_MODEL
%
% See also: 

success = 0; 

%% Input and consistency checks
% Check that the model is of type "uq_metamodel"
if ~strcmp(currentModel.Type, 'uq_metamodel')
    success = 0;
    error('Error: uq_metamodel cannot handle objects of type %s', currentModel.Type);
end

% Verbosity level
DisplayLevel = currentModel.Internal.Display;

%% Reporting
if DisplayLevel
fprintf('---           Calculating the SSE metamodel...           ---\n')
end

%% Get the number of output dimensions
Nout = size(currentModel.ExpDesign.Y,2);
currentModel.Internal.Runtime.Nout = Nout;

%% Calculate the SSE metamodel

% Cycle through each output
for oo = 1:Nout
    % Copy the necessary information about the SSE options to the multiple 
    % output dimensions 
    if Nout > 1
        if oo > 1
            % copy previous SSE structure
            currentModel.Internal.SSE(oo) = currentModel.Internal.SSE(oo-1);
        end
        
        if DisplayLevel
fprintf('---            ...for output component %d/%d...            ---\n',oo,Nout)
        end
    end    
       
    %% compute SSE for current output
    % Store the current output, used inside the calculation
    currentModel.Internal.Runtime.currentOutput = oo;

    currSSE = uq_SSE_calculate_single(currentModel);
    
    %% store SSE and experimental design 
    if oo == 1
        uq_addprop(currentModel,'SSE', currSSE);
    else
        currentModel.SSE(oo) = currSSE;
    end
    % Extract experimental design from sse object
    currExpDesign = currSSE.ExpDesign;
    
    %% Store errors
    % normalized empirical error
    if ~any(strcmpi(currExpDesign.Sampling,{'sequential','user'}))
        % disabled for sequential or user ED
        currentModel.Error(oo).normEmpErr = mean((currExpDesign.Y - evalSSE(currSSE, currExpDesign.X)).^2)/var(currExpDesign.Y); 
    end
    
    currentModel.Error(oo).AbsWRE = currSSE.Runtime.absWREEvolution(end); 
    if ~isempty(currSSE.Runtime.relWREEvolution)
        currentModel.Error(oo).RelWRE = currSSE.Runtime.relWREEvolution(end);
    else
        currentModel.Error(oo).RelWRE = [];
    end
end

% if sequential ED, update internal ED
if strcmpi(currExpDesign.Sampling,'sequential')
    currentModel.Internal.ExpDesign = currExpDesign;
    currentModel.ExpDesign = currExpDesign;
end

% Raise the flag that the metamodel has been calculated
currentModel.Internal.Runtime.isCalculated = true;

if DisplayLevel
    fprintf('---                Calculation finished!                 ---\n')
end

success = true;

end
