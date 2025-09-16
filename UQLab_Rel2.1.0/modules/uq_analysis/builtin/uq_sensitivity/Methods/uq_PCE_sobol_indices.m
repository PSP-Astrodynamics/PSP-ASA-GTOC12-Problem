function Results = uq_PCE_sobol_indices(max_order, CurrentModel)
% RESULTS = UQ_PCE_SOBOL_INDICES(MAX_ORDER,PCMODEL): analytically calculate Sobol'
%     indices up to maximum order MAX_ORDER for the PCE model PCMODEL.
%
% See also: UQ_SOBOL_INDICES,UQ_SENSITIVITY
%

%% RETRIEVE INFORMATION FROM THE PCE MODEL

% make sure the model is of "uq_metamodel" type.
if ~strcmp(CurrentModel.Type, 'uq_metamodel')
    error('Error, uq_getExpDesignSample is not defined for a model of type %s\n', CurrentModel.Type);
end

% Process Bootstrap, if available in the PCE model
BootstrapFlag = false;
if isfield(CurrentModel.Internal, 'Bootstrap') 
    BOptions = CurrentModel.Internal.Bootstrap(1);
    if isfield(BOptions,'BPCE') && isa(BOptions.BPCE, 'uq_model')
       BootstrapFlag = true;
    end
end

% Input/Output size, statistical moments of the PCE
Nout = CurrentModel.Internal.Runtime.Nout;
M = CurrentModel.Internal.Runtime.M;

% if no max_order is requested, we choose the maximum order of the polynomials
if ~exist('max_order', 'var')
    max_order = 2;
end

% Variances
for oo = 1:Nout
    CurrentModel.Internal.Sensitivity.sobol_indices.sigma(oo) = norm(CurrentModel.PCE(oo).Coefficients(2:end),2);
end

%% Analytical Sobol's sensitivity indices
%  Based on Sudret, 2008

% Work only on non-constant variables
nonConst = CurrentModel.Internal.Input.nonConst;

% Initialize the (cell) array containing the (total) Sobol indices.
sobol_cell_array = cell(max_order, 1) ;
total_sobol_array = zeros(length(nonConst),Nout) ;

% Initialize the cell to store the names of the variables of the Sobol Idx.
VarIdx = cell(max_order,1);
TotalVariance = zeros(1, Nout);

% loop over the output variables
for oo = 1:Nout
    aoo = CurrentModel.PCE(oo).Coefficients ;
    TotalVariance(oo) = sum(aoo(2:end).^2);
    
    % First and second order moments are readily available
    CurrentModel.Internal.Sensitivity.sobol_indices.mu(oo) = aoo(1);
    nzidx = find(aoo) ;
    % Set all the Sobol indices equal to zero if the presence of a null output.
    if isempty(nzidx) % handle the case of a trivial PCE (all zero coefficients)
        for i_order = 1:max_order 
            Z = nchoosek(1:length(nonConst), i_order) ; % get the number of indices
            sobol_cell_array{i_order}(:, oo) = zeros(length(Z),1) ; % set them all to 0
        end
        % Otherwise compute them by summing well-chosen chaos coefficients.
    else
        nz_basis = CurrentModel.PCE(oo).Basis.Indices(nzidx,:) ;
        for i_order = 1:max_order
            idx = find(sum(nz_basis > 0, 2) == i_order) ;
            subbasis = nz_basis(idx,:) ;
            Z = nchoosek(1:length(nonConst), i_order) ;
            for q = 1:size(Z, 1)
                Zq = Z(q,:) ;
                subsubbasis = subbasis(:, Zq) ;
                subidx = prod(subsubbasis, 2) > 0 ;
                sum_ind = nzidx(idx(subidx)) ;
                sobol_cell_array{i_order}(q, oo) = full(sum(aoo(sum_ind).^2) ...
                    /  TotalVariance(oo)) ;
            end
            % Store the index of how the variables are selected. The values
            % in Z are from 1 - numel(nonConstIdx), therefore number only
            % the non-constant input variables. A transformation is needed:
            VarIdx{i_order} = arrayfun(@(x) nonConst(x), Z);
        end
        
        % Compute the TOTAL Sobol indices.
        for i_input = 1:length(nonConst)
            idx = nz_basis(:, i_input) > 0 ;
            total_sobol_array(i_input,oo) = full(sum(aoo(nzidx(idx)).^2) ...
                /  TotalVariance(oo) ) ;
        end
    end
end

%% Add the bootstrap bounds if requested/available
if BootstrapFlag
    for oo = 1:Nout
        BootstrapResults = uq_PCE_sobol_indices(max_order, CurrentModel.Internal.Bootstrap(oo).BPCE);
        % Total bootstrap
        B_Total = [BootstrapResults.Total]';
        [BT.CI, BT.ConfLevel, BT.Mean] = uq_Bootstrap_CI(B_Total, BOptions.Alpha);
        Bstr.Total.CI(:,oo,:) = BT.CI';
        Bstr.Total.Mean(:,oo) = BT.Mean;
        Bstr.Total.ConfLevel(:,oo) = BT.ConfLevel;
        % Every bootstrap order
        for ii = 1:max_order
            B_AllOrders{ii} = [BootstrapResults.AllOrders{ii}]';
            [BAO.CI, BAO.ConfLevel, BAO.Mean] = uq_Bootstrap_CI(B_AllOrders{ii}, BOptions.Alpha);
            if oo == 1
                Bstr.AllOrders{ii}.CI = zeros([size(B_AllOrders{ii},2) Nout 2]);
            end
            
            Bstr.AllOrders{ii}.CI(:,oo,:) = BAO.CI';
            Bstr.AllOrders{ii}.Mean(:,oo) = BAO.Mean;
            Bstr.AllOrders{ii}.ConfLevel(:,oo) = BAO.ConfLevel;     
        end
        Bstr.FirstOrder = Bstr.AllOrders{1};
        Bstr.BootstrapResults(oo) = BootstrapResults;
    end
end

%% assign the outputs
% find the non-constant variables
nonConstIdx = CurrentModel.Internal.Runtime.nonConstIdx;
CurrentModel.Internal.Sensitivity.VariableNames = {CurrentModel.Internal.Input.Marginals(nonConstIdx).Name};
CurrentModel.Internal.Sensitivity.sobol_indices.total_sobol_array = total_sobol_array;
CurrentModel.Internal.Sensitivity.sobol_indices.sobol_cell_array = sobol_cell_array;
if nargout > 0
    % Combine zero valued inputs (constant) with the computed ones
    Results.Total = zeros(M,Nout);
    Results.FirstOrder = zeros(M,Nout);
    
    Results.Total(nonConst,:) = total_sobol_array;
    Results.FirstOrder(nonConst,:) = sobol_cell_array{1};
    
    Results.AllOrders{1} = sobol_cell_array{1};
    Results.VarIdx{1} = (1:M)';
    for oo = 2:max_order
        Results.AllOrders{oo} = sobol_cell_array{oo};
    end
    
    Results.VarIdx = VarIdx;    
    
    Results.TotalVariance = TotalVariance;    
    Results.VariableNames = {CurrentModel.Internal.Input.Marginals(nonConstIdx).Name};

    % Add bootstrap results, if available
    if BootstrapFlag
        Results.Bootstrap = Bstr;
    end
end