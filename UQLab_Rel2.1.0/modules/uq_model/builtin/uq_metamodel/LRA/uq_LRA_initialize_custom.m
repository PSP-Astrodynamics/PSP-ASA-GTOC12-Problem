function success = uq_LRA_initialize_custom( current_model, Options)
% Initialize an LRA with known coefficients
success = 0;

if ~isfield(Options, 'LRA')
    error('Custom LRA has been defined, but no LRA field is defined in the options!')
end

customLRA = Options.LRA;

% check that the basis is there
if ~isfield(customLRA, 'Basis')
    error('Custom LRA has been defined, but no Basis was specified!')
end


if ~isfield(customLRA, 'Coefficients')
    error('Custom LRA has been requested, but no coefficients have been defined!')
end



% For consistency, since the 'Method' is passed in the metaoptions
% and the metaoptions pass to the current_model.Internal field, the
% Internal field now also contains the computation method:
current_model.Internal.Method = 'custom';

% now we have all of the necessary ingredients. Let's add whatever
% is necessary to create the PCE model.
% add the PCE field in the output
uq_addprop(current_model, 'LRA');
current_model.LRA =  customLRA;


% Don't allow custom LRA when input has not been defined:
if isfield(Options, 'Input') && ~isempty(Options.Input)
    current_model.Internal.Input = uq_getInput(Options.Input);
else
    error('You have not determined an input module! Custom LRA is not allowed when an input module is not specifically defined in order to prevent bugs.');
end

% add the remaining runtime arguments that may be needed
M = length(current_model.Internal.Input.Marginals);
current_model.Internal.Runtime.M = M;
current_model.Internal.Runtime.nonConstIdx = 1:M;
current_model.Internal.Runtime.MnonConst = M;
current_model.Internal.Runtime.Nout = length(current_model.LRA);
current_model.Internal.Runtime.isCalculated = true;
current_model.Internal.Runtime.current_output = 1;


% loop over the dimensions and check that coefficients and basis
% have the same dimensions. In case the recurrence terms have not 
% been calculated, calculate them and set them to the Basis
% object.
for oo = 1:length(current_model.LRA)
    if length(current_model.LRA(oo).Coefficients.b) ~= current_model.LRA(oo).Basis.Rank || ...
            length(current_model.LRA(oo).Coefficients.z) ~= current_model.LRA(oo).Basis.Rank
        error('Custom LRA has been requested, but the number of Coefficients is inconsistent with the number of basis elements for output component %d', oo);
    end
    
    if ~isfield(current_model.LRA(oo).Basis,'PolyTypesAB')
        [current_model] = uq_initialize_uq_metamodel_univ_basis(current_model,Options,oo);
    end
    
    if ~isfield(Options.LRA(oo) , 'Moments')
        % Add moments to custom LRA:
        b = current_model.LRA(oo).Coefficients.b;
        z_all = current_model.LRA(oo).Coefficients.z;
        R = length(current_model.LRA(oo).Coefficients.b);
        [meanLRA, varLRA] = uq_LRA_moments(M,R,z_all,b);
        current_model.LRA(oo).Moments.Mean = meanLRA;
        current_model.LRA(oo).Moments.Var = varLRA;
    end
    
    if ~isfield(Options.LRA(oo).Basis,'Degree')
        error('The degree of the LRA should also be defined in the LRA.Basis.Degree field!');
    else
        current_model.LRA(oo).Basis.Degree = Options.LRA(oo).Basis.Degree;
    end
end


current_model.Options.Degree = size(current_model.LRA(1).Coefficients.z{1},1)-1;


success = 1;
