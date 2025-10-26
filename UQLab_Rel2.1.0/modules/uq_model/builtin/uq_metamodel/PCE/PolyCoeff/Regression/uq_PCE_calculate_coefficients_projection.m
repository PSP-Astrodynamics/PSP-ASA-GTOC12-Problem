function success = uq_PCE_calculate_coefficients_projection(current_model)
% SUCCESS = UQ_PCE_CALCULATE_COEFFICIENTS_PROJECTION(CURRENT_MODEL):
%     Calculate the polynomial chaos coefficients of CURRENT_MODEL via
%     quadrature-based projection.
%
% See also: UQ_PCE_CALCULATE_COEFFICIENTS_REGRESSION

%% INITIALIZATION AND CONSISTENCY CHECKS
% initializing the output status to 0
success = 0;

% let's check the model is of type "uq_metamodel"
if ~strcmp(current_model.Type, 'uq_metamodel')
    error('Error: uq_metamodel cannot handle objects of type %s', current_model.Type);
end

%% Retrieve the relevant options from the Framework
% which output are we calculating?
current_output = current_model.Internal.Runtime.current_output;
% relevant options
PCEOptions = current_model.Internal.PCE(current_output);

% detect if the calculation is level-adaptive
if numel(PCEOptions.Degree) > 1
    % switch the degree to an array
    current_model.Internal.PCE(current_output).DegreeArray = PCEOptions.Degree;
    current_model.Internal.PCE(current_output).Degree = current_model.Internal.PCE(current_output).DegreeArray(1);
    current_model.Internal.PCE(current_output).DegreeEarlyStop = 1;
    current_model.Internal.Runtime.degree_index = 1;
end

% automatically set the quadrature level to the polynomial level
if ~isfield(current_model.Internal.PCE(current_output).Quadrature, 'Level')
    current_model.Internal.PCE(current_output).Quadrature.Level = ...
        current_model.Internal.PCE(current_output).Degree + 1;
end

% current maximum degree. It is set to the first value of Degree array, 
% even for a non basis adaptive scheme
MaxDegree = max(PCEOptions.Degree(1));

% Get the truncation strategy
Truncation = current_model.Internal.PCE(current_output).Basis.Truncation;

%% Generating the set of polynomial indices
% Run metamodelling on the non-constant variables
M = current_model.Internal.Runtime.MnonConst;


%% Switching between projection experimental designs (but do it only once for all the outputs!):
if current_output == 1
    switch lower(current_model.Internal.PCE(current_output).Quadrature.Type)
        case {'full', 'smolyak'}
            % collecting the experimental design points
            [current_model.ExpDesign.X, current_model.ExpDesign.U, current_model.ExpDesign.W] = uq_getExpDesignSample(current_model);
            
            % Due to the isoprobabilistic transform some points are
            % infinite or NaN. We treat them by setting their weight for the
            % quadrature to 0 and setting them also to 0 so they are
            % disregarded in the computation.
            if any(isinf(current_model.ExpDesign.X))
                if current_model.Internal.Display>1
                    warning(['Some of the quadrature nodes are invalid and they are skipped.']);
                end
                infidx = find(any(isinf(current_model.ExpDesign.X)'));
                
                current_model.ExpDesign.X(infidx,:) = zeros(...
                    length(infidx),length(current_model.ExpDesign.X(1,:)));
                
                current_model.ExpDesign.W(infidx) = 0;
            end
            % evaluating the model on the points
            [current_model.ExpDesign.Y] = uq_eval_ExpDesign(current_model);
            Nout = current_model.Internal.Runtime.Nout;
        otherwise % bail out
            error('Could not find the specified projection method "%s"!!', current_model.Internal.Method);
    end

    % initialize the projection for all of the output components if we are
    % calculating component #1
    for oo = 1:Nout
        current_model.Internal.PCE(oo) = current_model.Internal.PCE(1);
        current_model.PCE(oo).Basis.PolyTypes = current_model.PCE(1).Basis.PolyTypes;
    end
end

%% Creating and evaluating the poly basis and the design matrix
% index generation with successive Knuth H and L algorithms, and truncation scheme.
current_model.PCE(current_output).Basis.Indices = ...
    uq_generate_basis_Apmj(0:MaxDegree, M, Truncation);

% as well as the evaluation of the univariate polynomials up to degree MaxDegree on the
% experimental design
univ_p_val = uq_PCE_eval_unipoly(current_model);
% the design matrix
Psi = uq_PCE_create_Psi(current_model.PCE(current_output).Basis.Indices, univ_p_val);

%% QUADRATURE-BASED ESTIMATION OF THE COEFFICIENTS
[Coefficients, Error] = ...
    uq_PCE_quadrature(Psi, current_model.ExpDesign.Y(:,current_output),current_model.ExpDesign.W);

current_model.PCE(current_output).Coefficients = Coefficients;
current_model.Error(current_output).normEmpError = Error;

%% Output 
success = 1;
