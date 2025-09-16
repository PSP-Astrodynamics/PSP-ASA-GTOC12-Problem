function Results = uq_LRA_sobol_indices(max_order, CurrentModel)
% UQ_LRA_SOBOL_INDICES:
% Compute the LRA based Sobol' indices.

if ~strcmp(CurrentModel.Type, 'uq_metamodel')
    error('Error, uq_getExpDesignSample is not defined for a model of type %s\n', CurrentModel.Type);
end


% compute the coefficients of the metamodel if they are not yet calculated
if ~CurrentModel.Internal.Runtime.isCalculated
    uq_calculateMetamodel(CurrentModel);
end

%% part 1: statistical moments analysis
Nout = CurrentModel.Internal.Runtime.Nout;
M = CurrentModel.Internal.Runtime.M;

% if no max_order is requested, we choose the maximum order of the polynomials
if ~exist('max_order', 'var')
    max_order = 2;
end

%% Part two: Sobol's sensitivity indices
%  based on Sobol, 1993

% Initialize the (cell) array containing the (total) Sobol indices.
sobol_cell_array = cell(max_order, 1) ;
total_sobol_array = zeros(M,Nout) ;
% Initialize the cell to store the names of the variables of the Sobol Idx.
VarIdx = cell(max_order,1);
TotalVariance = zeros(1, Nout);

% take the total Sobol' sensitivity indices for LRA:

% We only need to calculate the indices for non-constant input variables
nonConstIdx = CurrentModel.Internal.Input.nonConst;

% loop over the output variables
for oo = 1:Nout
    
    % This will return the PCE-type coefficients from LRA:
    aoo = uq_LRA_kron_ranks(CurrentModel.LRA(oo));
    
    TotalVariance(oo) = sum(aoo(2:end).^2);
    
    CurrentModel.Internal.Sensitivity.sobol_indices.sigma(oo) = ...
        sqrt(TotalVariance(oo)) ;

    % First and second order moments are readily available
    CurrentModel.Internal.Sensitivity.sobol_indices.mu(oo) = aoo(1);
    nzidx = find(aoo);
    % Set all the Sobol indices equal to zero if the presence of a null output.
    if isempty(nzidx)
        for i_order = 1:max_order
            sobol_cell_array{i_order}(:, oo) = 0 ;
        end
    else
        
        for i_order = 1:max_order
            Z = nchoosek(1:numel(nonConstIdx), i_order);
            for q = 1:size(Z, 1)
                Zq = Z(q,:) ;
                sob_idx = uq_LRA_Su_bar(Zq',CurrentModel.LRA(oo));
                sobol_cell_array{i_order}(q, oo) = sob_idx;
            end
            
            % Store the index of how the variables are selected. The values
            % in Z are from 1 - numel(nonConstIdx), therefore number only
            % the non-constant input variables. A transformation is needed:
            VarIdx{i_order} = arrayfun(@(x) nonConstIdx(x), Z);
            
            % Subtract corresponding indices of lower order:
            if i_order>1
                for prev_order = 1:(i_order-1)
                    for po = VarIdx{prev_order}'
                        for co = VarIdx{i_order}'
                            % Iterate over the index set of the current order
                            for curr_idx_set = co
                                % If the indices of the previous order
                                % match remove them:
                                if all(ismember(po,curr_idx_set))
                                    % retrieve the indices:
                                    co_idx = find(all(ismember(VarIdx{i_order},co),2));
                                    po_idx = find(all(ismember(VarIdx{prev_order},po),2));
                                    
                                    sobol_cell_array{i_order}(co_idx,oo) = ...
                                        sobol_cell_array{i_order}(co_idx,oo) - ...
                                        sobol_cell_array{prev_order}(po_idx,oo);

                                end
                            end
                        end
                    end
                end
            end
        end
        
        % Compute the TOTAL Sobol indices.
        for i_input = 1:numel(nonConstIdx)
%             i_input_idx = find(ismember(1:M,i_input));
            total_sobol_array(nonConstIdx(i_input),oo) = uq_LRA_Stot(i_input,CurrentModel.LRA);
        end
        
    end
end


%% assign the outputs
% find the non-constant variables
nonConstIdx = CurrentModel.Internal.Runtime.nonConstIdx;
CurrentModel.Internal.Sensitivity.VariableNames = {CurrentModel.Internal.Input.Marginals(nonConstIdx).Name};
CurrentModel.Internal.Sensitivity.sobol_indices.total_sobol_array = total_sobol_array;
CurrentModel.Internal.Sensitivity.sobol_indices.sobol_cell_array = sobol_cell_array;
if nargout > 0
    Results.AllOrders = sobol_cell_array;
    Results.Total = total_sobol_array;
    Results.FirstOrder = zeros(M,Nout);
    Results.FirstOrder(nonConstIdx,:) = sobol_cell_array{1};
    Results.TotalVariance = TotalVariance;
    Results.VarIdx = VarIdx;
    Results.VariableNames = {CurrentModel.Internal.Input.Marginals(nonConstIdx).Name};

end


