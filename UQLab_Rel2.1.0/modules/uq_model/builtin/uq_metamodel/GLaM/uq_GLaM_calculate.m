function success = uq_GLaM_calculate(current_model)
success = 0;
%% argument and consistency checks
% let's check the model is of type "uq_metamodel"
if ~strcmp(current_model.Type, 'uq_metamodel')
    error('Error: uq_metamodel cannot handle objects of type %s', current_model.Type);
end


%% Display
DisplayLevel = current_model.Internal.Display ;


%% Generate the initial experimental design
% Get X
[current_model.ExpDesign.X,current_model.ExpDesign.U] = uq_getExpDesignSample(current_model);
% Get Y
current_model.ExpDesign.Y = uq_eval_ExpDesign(current_model,current_model.ExpDesign.X,current_model.ExpDesign.Replications,'evalTraj',current_model.ExpDesign.isTrajectory);
% Update the number of output variables of the model and store it
Nout = size(current_model.ExpDesign.Y, 2);
current_model.Internal.Runtime.Nout = Nout;

%%
switch lower(current_model.Internal.Method)
    case 'repjoint'
        if DisplayLevel
            fprintf('---   Building the generalized lambda metamodel by replication-based method...   ---\n')
        end
        uq_GLaM_calculate_repjoint(current_model);
    otherwise
        if DisplayLevel
            fprintf('---   Building the generalized lambda metamodel by regression...   ---\n')
        end
        uq_GLaM_calculate_regression(current_model);
end

if DisplayLevel
    fprintf('---                 Calculation finished!                           ---\n');
end
success = 1;
