function myMarginals = uq_initialize_marginals(iOpts)
% Marginals = uq_initialize_marginals(iOpts):
%     Given a structure iOpts that defines marginals to be possibly 
%     inferred, fills iOpts.Marginals by assigning defaults.
%     Returns the initialized Marginals

InferCriterMargs_def = 'AIC';
if isfield(iOpts, 'Inference') && isfield(iOpts.Inference, 'Criterion')
    InferCriterMargs_def = iOpts.Inference.Criterion;
end

% Define InferData, the cell array that contains the data for inference.
% InferData{ii} is used for inference of marginal ii.
InferData = {};
if isfield(iOpts, 'Inference') && isfield(iOpts.Inference, 'Data')
    if isa(iOpts.Inference.Data, 'double')
        M = size(iOpts.Inference.Data, 2);
        for ii = 1:M
            InferData{ii} = iOpts.Inference.Data(:,ii);
        end
    elseif isa(iOpts.Inference.Data, 'cell')
        InferData = iOpts.Inference.Data;
    else
        error('iOpts.Inference.Data must contain either an array or a cell')
    end
end
% ...Add/overwrite with inference data specified under Marginals.Inference
if isfield(iOpts, 'Marginals')
    for ii = 1: length(iOpts.Marginals)
        if isfield(iOpts.Marginals, 'Inference') && isfield(...
                iOpts.Marginals(ii).Inference, 'Data')
            x = iOpts.Marginals(ii).Inference.Data;
            if ~isempty(x) || length(InferData) < ii
                InferData{ii} = x;
            end
        elseif length(InferData) < ii
            InferData{ii} = [];
        end
    end
end
        
if ~isfield(iOpts, 'Marginals')
    if ~isfield(iOpts, 'Inference')
        error('iOpts must have at least one of the fields .Inference or .Marginals')
    elseif ~isfield(iOpts.Inference, 'Data')
        error('IOpts.Inference.Data missing')
    else
        X = iOpts.Inference.Data;
        M = size(X, 2);
        myMarginals = struct();
        
        for ii = 1:M
            myMarginals(ii).Type = 'auto';
            myMarginals(ii).Parameters = 'auto';
            myMarginals(ii).Inference.Criterion = InferCriterMargs_def;
            myMarginals(ii).Inference.Data = InferData{ii};
            if isfield(iOpts.Inference, 'ParamBounds')
                myMarginals(ii).Inference.ParamBounds = ...
                    iOpts.Inference.ParamBounds;
            end
            if isfield(iOpts.Inference, 'ParamGuess')
                myMarginals(ii).Inference.ParamGuess = ...
                    iOpts.Inference.ParamGuess;
            end
        end
    end
else
    M = length(InferData);
    for ii = 1:M
        if length(iOpts.Marginals) < ii
            myMarginals(ii).Type = 'auto';
            myMarginals(ii).Parameters = 'auto';
            myMarginals(ii).Bounds = [];
            myMarginals(ii).Inference.Criterion = InferCriterMargs_def;
            myMarginals(ii).Inference.Data = InferData{ii};
            if uq_isfield(iOpts, 'Inference.ParamBounds')
                myMarginals(ii).Inference.ParamBounds = ...
                    iOpts.Inference.ParamBounds;
            end
            if uq_isfield(iOpts, 'Inference.ParamGuess')
                myMarginals(ii).Inference.ParamGuess = ...
                    iOpts.Inference.ParamGuess;
            end
        else
            if uq_isnonemptyfield(iOpts.Marginals(ii), 'Name')
                myMarginals(ii).Name = iOpts.Marginals(ii).Name;
            else
                myMarginals(ii).Name = sprintf('X%d', ii);
            end

            if uq_isnonemptyfield(iOpts.Marginals(ii), 'Type')
                myMarginals(ii).Type = iOpts.Marginals(ii).Type;
            else
                myMarginals(ii).Type = 'auto';
            end
            
            if isfield(iOpts.Marginals(ii), 'Options')
                myMarginals(ii).Options = iOpts.Marginals(ii).Options;
            end
                
            if uq_isnonemptyfield(iOpts.Marginals(ii), 'Parameters')
                myMarginals(ii).Parameters=iOpts.Marginals(ii).Parameters;
            else
                myMarginals(ii).Parameters = 'auto';
            end

            if isfield(iOpts.Marginals(ii), 'Bounds')
                myMarginals(ii).Bounds = iOpts.Marginals(ii).Bounds;
            end

            if uq_isnonemptyfield(iOpts.Marginals(ii), 'Inference.Criterion') 
                myMarginals(ii).Inference.Criterion = ...
                    iOpts.Marginals(ii).Inference.Criterion;
            elseif must_be_inferred(myMarginals(ii))
                myMarginals(ii).Inference.Criterion = InferCriterMargs_def;
            end
            
            if uq_isnonemptyfield(iOpts.Marginals(ii), 'Inference.Data')
                myMarginals(ii).Inference.Data = ...
                    iOpts.Marginals(ii).Inference.Data;
            elseif must_be_inferred(myMarginals(ii))
                myMarginals(ii).Inference.Data = InferData{ii};
            end
            
            if uq_isnonemptyfield(iOpts.Marginals(ii), 'Inference.ParamBounds')
                myMarginals(ii).Inference.ParamBounds = ...
                    iOpts.Marginals(ii).Inference.ParamBounds;
            elseif isfield(iOpts, 'Inference') && ...
                        uq_isnonemptyfield(iOpts.Inference, 'ParamBounds')
                myMarginals(ii).Inference.ParamBounds = ...
                    iOpts.Inference.ParamBounds;
            end
            
            if uq_isnonemptyfield(iOpts.Marginals(ii), 'Inference.ParamGuess') 
                myMarginals(ii).Inference.ParamGuess = ...
                    iOpts.Marginals(ii).Inference.ParamGuess;                
            elseif uq_isnonemptyfield(iOpts, 'Inference.ParamGuess')
                myMarginals(ii).Inference.ParamGuess = ...
                    iOpts.Inference.ParamGuess;
            end           
        end    
    end
end

end

% Other functions

function pass = must_be_inferred(marginal)
    pass = ~(...
        isa(marginal.Type, 'char') && ~strcmpi(marginal.Type, 'auto') ...
        && ((isfield(marginal, 'Parameters') && ...
             ~isempty(marginal.Parameters) &&...
             ~isa(marginal.Parameters, 'char')) || ...
            (isfield(marginal, 'Moments') && ...
            ~isempty(marginal.Moments) &&...
            ~isa(marginal.Moments, 'char'))));
end




