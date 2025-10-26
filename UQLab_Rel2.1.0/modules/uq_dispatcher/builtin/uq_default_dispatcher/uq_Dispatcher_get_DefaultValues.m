function DefaultValues = uq_Dispatcher_get_DefaultValues(optionName)
%UQ_KRIGING_HELPER_GET_DEFAULTVALUES returns Kriging metamodel default options values.
%
%   DefaultValues = uq_Kriging_helper_get_DefaultValues(optionName) returns
%   the default values for the options optionName used to create
%   Kriging metamodel.
%
%   See also uq_Kriging_initialize, uq_Kriging_initialize_custom,
%   uq_Kriging_initialize_trend, uq_Kriging_helper_process_Display,
%   uq_Kriging_helper_process_Regression.

%% Remote Separator
%remoteSystem = current_dispatcher.Internal.Credential.RemoteSystem;


%switch lower(remoteSystem)
%    case {'linux','unix'}
%        remoteSep = '/';
%    otherwise
%        remoteSep = '\';
%end

%% Return default values for the requested options
switch lower(optionName)
    case 'remotesep'
        DefaultValues = '/';
end

end
