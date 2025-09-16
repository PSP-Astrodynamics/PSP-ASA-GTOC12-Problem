function success = uq_GLaM_initialize_transform(current_model,DEFAULTLam)
%% Initialize the transform function for the lambda's

success = 0;
if nargin<2
    DEFAULTLam(1).Transform.Type = 'identity';
    DEFAULTLam(2).Transform.Type = 'exp';
    DEFAULTLam(3).Transform.Type = 'identity';
    DEFAULTLam(4).Transform.Type = 'identity';
end


Lambda = current_model.Internal.Lambda;
TransformList = cell(1,4);

ll = length(current_model.Internal.Lambda);
for ilam=1:4
    % initialze the transform
    if ilam>ll||~uq_isnonemptyfield(current_model.Internal.Lambda(ilam),'Transform')
        Lambda(ilam).Transform = DEFAULTLam(ilam).Transform;
    else
        Optilam = current_model.Internal.Lambda(ilam);
        [Transform, Optilam] = uq_process_option(Optilam,'Transform', DEFAULTLam(ilam).Transform, 'struct');
        if Transform.Invalid
            error('Transform must be a structure!') ;
        else
            Lambda(ilam).Transform = Transform.Value;
        end
    end
    
    % get the function
    if ~uq_isnonemptyfield(Lambda(ilam).Transform,'funStr')
        funcStr = sprintf('uq_GLaM_transform_%s%s',lower(Lambda(ilam).Transform.Type));
    end
    if ~exist([funcStr,'.m'],'file')
        error(['The transform function ',Transform.Type,' does not exist!']);
    end
    Lambda(ilam).Transform.FuncStr = funcStr;
    TransformList{ilam} = Lambda(ilam).Transform;
end

current_model.Internal.Lambda = Lambda;
current_model.Internal.tFunc = TransformList;

success = 1;
end

