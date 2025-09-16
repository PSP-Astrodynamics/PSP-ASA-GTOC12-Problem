function PCEModel = uq_LRA_to_PCE(model)
% PCEMODEL = UQ_LRA_TO_PCE(MODEL)
% Creates a full-basis PCE uq_model from an LRA uq_model

for oo=1:length(model.LRA)
    LRAModel = model.LRA(oo);

    % The number of input dimensions
    M = size(LRAModel.Coefficients.z{1},2);

    % The maximum order along each direction (currently only the same maximum
    % order of the univariate basis is allowed along all dimension.)
    p = size(LRAModel.Coefficients.z{1},1);

    % construct a set of indices for PCE.
    % The are the sum of the Kroneker products of the zeta coefficients scaled
    % by beta for all ranks:
    coefficients = uq_LRA_kron_ranks(LRAModel);

    % pre-allocate the PCE index coefficients:
    spinds = zeros(length(coefficients),M);

    % A tensor object is not available in standard matlab and this makes it
    % difficult to manage the coefficients. However, we can deduce the tensor
    % indices every coefficient relates to manually. There is a more efficient
    % way to do that, but the most intuitively straightforward way is taking
    % advantage that:
    %
    % M=1              M=m             M=M
    % [1 1 1] x ... x [0 1 2] x ... x [1 1 1]
    % 
    % returns the orders of the polynomials for input 'm'. That directly gives
    % us a set of indices that are consistent with UQLab convention.
    for dimension_idx = 1:M
        % The PCE indices that correspond to the LRA are constructed again with
        % Kroneker products (inds_pce_tot_M will be a vector).
        inds_pce_tot_M =1;

        for k=1:M
            if k==dimension_idx
                inds_pce_M = (0:(p-1));
            else
                inds_pce_M = ones(1,p);
            end
            inds_pce_tot_M = kron(inds_pce_M,inds_pce_tot_M);
        end
        sp_inds(:,dimension_idx) = inds_pce_tot_M;
    end

    % "Boilerplate" code for Custom PCE:
    predopts.Type = 'Metamodel';
    predopts.MetaType = 'PCE';
    predopts.Method = 'Custom';

    % specify the same input as for the LRA
    predopts.Input = model.Internal.Input;

    % specify the basis for the PCE
    PCEBasis.Indices = sparse(sp_inds);
    PCEBasis.PolyTypes = model.LRA(1).Basis.PolyTypes;
    PCEBasis.PolyTypesParams= model.LRA(1).Basis.PolyTypesParams;
    predopts.PCE(oo).Basis = PCEBasis;
    predopts.PCE(oo).Coefficients = coefficients;
end
PCEModel = uq_createModel(predopts,'-private');