function success = uq_buildInitialMetamodel( current_analysis )
% UQ_BUILDINITIALMETAMODEL builds an initial surrogate model that wll b
% eused later on as such for the RBDO

% Initialize success parameter
success = 0 ;

%% Metamodel options
% Retrieve all the options given to the metamodel. (The checking of the
% options will be done by the corresponding Metamodel module)
Options = current_analysis.Internal.Metamodel.(current_analysis.Internal.Metamodel.Type) ;

% Parse options
metaopts = Options ;

% Now some of the options will be added or overwritten if already given
% .Type option
if isfield(metaopts,'Type')
    warning('The given .Type metamodel option will be ignored!');
end
metaopts.Type = 'metamodel' ;

% .MetaType option
if isfield(metaopts,'MetaType')
    warning('The given .MetaType metamodel option will be ignored!');
end
metaopts.MetaType = current_analysis.Internal.Metamodel.Type ;

% .Input option
if isfield(metaopts, 'Input')
    warning('The given .Input metamodel option will be ignored! An augmented space will be bnuilt and used instead.');
end
% Select the appropriate Input object corresponding to the generalized
% augmented space
metaopts.Input = current_analysis.Internal.Optim.AugSpace.Input ;

% .FullModel option
if isfield(metaopts, 'FullModel')
        warning('The given .FullModel metamodel option will be ignored!');
end
% Select the Full model that will be used to build the surrogate model
metaopts.FullModel = current_analysis.Internal.LimitState.MappedModel ;

% Disable display related to metamodel building if the user did not
% expressely defined one
if ~isfield(metaopts, 'Display')
    metaopts.Display = 0;
end

%% Build the metamodel
if current_analysis.Internal.Display > 0
    fprintf('Building the surrogate model... \n') ;
end
current_analysis.Internal.Constraints.Model = uq_createModel( metaopts, '-private' ) ;
if current_analysis.Internal.Display > 0
    fprintf('Surrogate model successfully built!\n') ;
end

%% Exit with success
success = 1;

end