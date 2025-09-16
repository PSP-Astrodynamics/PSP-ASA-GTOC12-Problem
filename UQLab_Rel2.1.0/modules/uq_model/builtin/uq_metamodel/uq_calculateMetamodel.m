function success = uq_calculateMetamodel(current_model, varargin)
% SUCCESS = uq_calculateMetamodel(CURRENT_MODEL): entry point for the
%     calculation of the metamodel object in CURRENT_MODEL. This function runs
%     the required functions to calculate a metamodel based on their type
%     (e.g., calculate coefficients for PCE, run hyperparameter optimization
%     for Kriging, etc.). 
%
% See also UQ_PCE_CALCULATE_COEFFICIENTS, UQ_KRIGING_CALCULATE_COEFFICIENTS

%% Argument retrieval and check
if ~strcmp(current_model.Type, 'uq_metamodel')
    error('Error: uq_metamodel cannot handle objects of type %s', current_model.Type);
end

%% Run the proper calculation function depending on the specified metamodel type
switch lower(current_model.MetaType)
    case 'pce'
        success = uq_PCE_calculate_coefficients(current_model);
    case 'lra'
        success = uq_LRA_calculate_coefficients(current_model);
    case 'kriging'
        success = uq_Kriging_calculate(current_model);
   case 'pck'
        success = uq_PCK_calculate_coefficients(current_model);
    case 'dicekriging'
        success = uq_DiceKriging_calculate_coefficients(current_model);
    case 'svr'
        success = uq_SVR_calculate_coefficients(current_model);
    case 'svc'
        success = uq_SVC_calculate_coefficients(current_model);
    case 'sse'
        success = uq_SSE_calculate(current_model);
    case 'glam'
        success = uq_GLaM_calculate(current_model);
    case 'spce'
        success = uq_SPCE_calculate(current_model);
end

if success
   current_model.Internal.Runtime.isCalculated = 1; 
end
