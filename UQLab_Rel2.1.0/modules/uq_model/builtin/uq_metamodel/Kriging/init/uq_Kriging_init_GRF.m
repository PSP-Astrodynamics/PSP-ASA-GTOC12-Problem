function Options = uq_Kriging_init_GRF(current_model,Options)
%UQ_KRIGING_INIT_GRF processes the opts. related to the Gaussian random field.
%
%   Options = uq_Kriging_init_GRF(current_model,Options) parses the
%   specification of the Gaussian random field specified in the structure
%   Options and update the current_model. The function returns the options
%   not parsed by the function.
%
%   Side-effect:
%   The function will change the current state of current_model,
%   by adding the valid options related to the Gaussian random field
%   to the fields of the current_model.
%
%   See also uq_Kriging_initialize, uq_Kriging_helper_get_DefaultValues.

%%
% Specify the default options for the GRF (that may differ from the
% random field module

% Default discretization method is EOLE
GRFDefaults.DiscScheme = 'EOLE' ;

% Defaults for EOLE
GRFDefaults.EOLE.Sampling = 'LHS' ;
GRFDefaults.EOLE.SPC = 20 ;

% Defaults for KL
GRFDefaults.KL.SPC = 20 ;
GRFDefaults.KL.Sampling = 'LHS' ;

% If the dimension is larger than 1, use a pre-defined sample size
if size(current_model.ExpDesign.X,2)> 2
    GRFDefaults.EOLE.NSamples = 2000 ;
    GRFDefaults.KL.NSamples = 2000 ;
end

% Domain is given w.r.t. the ED
myrange = range(current_model.ExpDesign.X);
GRFDefaults.Domain = [min(current_model.ExpDesign.X)-0.1*myrange ; max(current_model.ExpDesign.X)+0.1*myrange] ;
% Default energy ratio, i.e., explained variance
GRFDefaults.EnergyRatio = 0.9995 ;

%%
%% Options for creating a GP random field
[isTrajectory,Options] = uq_process_option(...
    Options, 'isTrajectory',false,{'logical', 'double'});

if isTrajectory.Invalid
    msg = sprintf('Invalid GP isTrajectory option. Using the default: %s instead.',...
        isTrajectory.Value);
    EVT.Type = 'W';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:kriging:init:gpisTrajectory_override';
    uq_logEvent(current_model, EVT);

end
current_model.Internal.isTrajectory = isTrajectory.Value ;

if current_model.Internal.isTrajectory && current_model.Internal.Runtime.Nout > 1
    error('Kriging resampling is available only for scalar outputs. \n');
end
%%
% If the isTrajectory is not enabled by the user, then do not process the
% Gaussian random field related option
if current_model.Internal.isTrajectory == 0
    return ;
end

%%
% Process the remaining of the random field options if the option is
% enabled
if current_model.Internal.isTrajectory

    if ~isfield(Options,'GRF')
        % Assign all the default options
        current_model.Internal.GRF = GRFDefaults ;
    else


        % Parse the discretization scheme - Default is empty and will
        [GRFDisc, Options.GRF] = uq_process_option(Options.GRF,'DiscScheme', ...
            GRFDefaults.DiscScheme,{'char','string'});

        if GRFDisc.Invalid
            msg = sprintf('Invalid GRF DiscScheme');
            EVT.Type = 'W';
            EVT.Message = msg;
            EVT.eventID = 'uqlab:kriging:init:gprf_discscheme_override';
            uq_logEvent(current_model, EVT);
        end

        if ~any(strcmpi(GRFDisc.Value,{'eole','kl'}))
            error('The provided random field discretization scheme is unknown!');
        end

        current_model.Internal.GRF.DiscScheme = GRFDisc.Value ;
        


        %%
        switch lower(current_model.Internal.GRF.DiscScheme)

            case 'eole'

                % Parse the number of points per correlation length for EOLE
                if isfield(Options.GRF, 'EOLE')
                    EOLEopts.EOLE = Options.GRF.EOLE;
                else
                    EOLEopts.EOLE = struct;
                end

                % Number of points per correlation length
                SPC = uq_process_option(EOLEopts.EOLE,'SPC',GRFDefaults.EOLE.SPC, 'double');
                % missing & invalid
                if SPC.Invalid
                    error('RF: The Number of samples per correlation length type is invalid')
                end
                % assign second level to first level
                current_model.Internal.GRF.EOLE.SPC = SPC.Value ;

                % Remove the option if it was provided by the user
                if isfield(Options.GRF,'EOLE') & isfield(Options.GRF.EOLE, 'SPC')
                    Options.GRF.EOLE = rmfield(Options.GRF.EOLE, 'SPC');
                end


                if isfield(Options.GRF,'EOLE') && isempty(fieldnames(Options.GRF.EOLE))
                    Options.GRF = rmfield(Options.GRF,'EOLE');
                end


            case 'kl'

                % Parse the same for KL if EOLE is not used
                if isfield(Options.GRF, 'KL')
                    KLopts.KL = Options.GRF.KL;
                else
                    KLopts.KL = struct;
                end

                % Number of points per correlation length
                SPC = uq_process_option(KLopts.KL,'SPC',GRFDefaults.KL.SPC, 'double');
                % missing & invalid
                if SPC.Invalid
                    error('RF: The Number of samples per correlation length type is invalid')
                end
                % assign second level to first level
                current_model.Internal.GRF.KL.SPC = SPC.Value ;
                % Remove the option if it was provided by the user
                if isfield(Options.GRF,'KL') & isfield(Options.GRF.KL, 'SPC')
                    Options.GRF.KL = rmfield(Options.GRF.KL, 'SPC');
                end
                

                if isfield(Options.GRF,'KL') && isempty(fieldnames(Options.GRF.KL))
                    Options.GRF = rmfield(Options.GRF,'KL');
                end
        end

        %%
        % Parse the domain - Default is empty and will
        [GRFDomain, Options.GRF] = uq_process_option(Options.GRF,'Domain', ...
            GRFDefaults.Domain,'double');

        if size(GRFDomain.Value) ~= size(GRFDefaults.Domain)
            error('The size of the domain is inconsistent with the built GP model');
        end
        if GRFDomain.Invalid
            msg = sprintf('Invalid GRF domain. Using bounds defined by the ED instead.');
            EVT.Type = 'W';
            EVT.Message = msg;
            EVT.eventID = 'uqlab:kriging:init:gprf_domain_override';
            uq_logEvent(current_model, EVT);
        end

        %%
        % Scale te domain similarly to the Kriging scaling
        U = uq_Kriging_helper_Scaling_XtoU(GRFDomain.Value, current_model);

        % Passed the (scaled) domain to the random field module
        current_model.Internal.GRF.Domain = U ;

        %%
        % Parse the energy ratio (default value for Kriging is larger than
        % the one in the random field module)
        [GRFER, Options.GRF] = uq_process_option(Options.GRF, ...
            'EnergyRatio', GRFDefaults.EnergyRatio,'double');

        if GRFER.Invalid
            msg = sprintf('Invalid GRF energy ratio');
            EVT.Type = 'W';
            EVT.Message = msg;
            EVT.eventID = 'uqlab:kriging:init:gprf_energyratio_override';
            uq_logEvent(current_model, EVT);
        end

        if GRFER.Value <= 0 || GRFER.Value > 1
            error('The energy ratio should be larger than 0 and smaller or equal to 1');
        end

        current_model.Internal.GRF.EnergyRatio = GRFER.Value ;


        %%
        % Parse the mesh, if provided by the user
        if isfield(Options.GRF,'Mesh')
            [GRFMesh, Options.GRF] = uq_process_option(Options.GRF,'Mesh');
            if size(GRFMesh.Value,2) ~= size(current_model.ExpDesign.U,2)
                error('The size of the mesh is inconsisent with the dimension of the Kriging Experimental Design');
            end
            current_model.Internal.GRF.Mesh = GRFMesh.Value ;
        end

        %%
        % Parse all the remaining options if given by the user
        if ~isempty(fieldnames(Options.GRF))
            [GRFOptions, Options] = uq_process_option(Options,'GRF');
            % Add all the remaining options in the GRF structures
            if ~isempty(GRFOptions.Value)
                f = fieldnames(GRFOptions.Value);
                for ii = 1:length(f)
                    current_model.Internal.GRF.(f{ii}) = GRFOptions.Value.(f{ii}) ;
                end
            end


        end

        % Remove the GRF options
        if isfield(Options,'GRF')
            Options = rmfield(Options, 'GRF');
        end
    end

end

end
