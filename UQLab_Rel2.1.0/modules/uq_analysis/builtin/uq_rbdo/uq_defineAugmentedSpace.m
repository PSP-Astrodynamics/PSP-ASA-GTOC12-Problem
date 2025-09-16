function results = uq_defineAugmentedSpace(current_analysis)

Options = current_analysis.Internal ;

sd = length(curent_analysis.Internal.DesVar) ;
alpha = current_analysis.Internal.AugSpace.alpha ;

% Bounds of the augmented space in the case of
for ii = 1:sd
    if strcmp(current_analysis.Desvar(ii).Type, 'deterministic')
        xmin(ii) = Options.Bounds(1,ii) ;
        xmax(ii) = Options.Bounds(2,ii) ;
    elseif strcmp(current_analysis.Desvar(ii).Type, 'Gaussian')
        if strcmp(Options.DesVar(ii).DispersionMeasure,'Std')
            Std = Options.DesVar(ii).Std ;
            xmin(ii) = icdf('normal',alpha_AugSpa/2, Options.Bounds(1,ii), Std ) ;
            xmax(ii) = icdf('normal',1 - alpha_Aug/2, Options.Bounds(2,ii), Std ) ;
        elseif strcmp(Options.DesVar(ii).DispersionMeasure,'CoV')   
            StdMin = Options.DesVar(ii).CoV * Options.BoundSpace(1,ii) ;
            StdMax = Options.DesVar(ii).CoV * Options.BoundSpace(2,ii) ;
            xmin(ii) = icdf('normal',alpha_AugSpa/2, Options.Bounds(1,ii), StdMin ) ;
            xmax(ii) = icdf('normal',1 - alpha_Aug/2, Options.Bounds(2,ii), StdMax ) ;
        else 
            % The user must have defined either Std or CoV. Proper checking
            % must have been made before
        end
    end
end

if isfield(Options.EnvVar)
    sz = Options.EnvVar.size ;
    for ii = 1: sz
        muz = Options.EnvVar(ii).mean ;
        if isfield (Options.EnvVar(ii),'Std')
            Std = Options.EnvVar(ii).Std ;
        else
            Std = muz * Options.EnvVar(ii).CoV ;
        end
        if strcmp( Options.EnvVar(ii).Type,'Gaussian' )
            if isfield(Options, 'Parameters')
                mu = Options.Parameters(1,1) ;
                Std = Options.Parameters(1,2) ;
            elseif isfield(Options, 'Moments' )
                mu = Options.Moments(1,1) ;
                Std = Options.Moments(1,2) ;
            else
                fprintf('\n Wrong definition of the inputs\n') ; % This cannot happen as checking is made earlier in UQLAB
            end
            zmin(ii) = icdf('normal',alpha_AugSpa/2, mu, Std ) ;
            zmax(ii) = icdf('normal',1 - alpha_Aug/2, mu, Std ) ;
        elseif strcmp( Options.EnvVar(ii).Type, 'Uniform' )
            
            if isfield(Options, 'Parameters')
                a = Options.Parameters(1,1) ;
                b = Options.Parameters(1,2) ;
            elseif isfield(Options, 'Moments' )
                a  = Options.Moments(1,1) - sqrt(3) * Options.Moments(1,2);
                b  = Options.Moments(1,1) + sqrt(3) * Options.Moments(1,2);
            else
                fprintf('\n Wrong definition of the inputs\n') ; % This cannot happen as checking is made earlier in UQLAB
            end           
            zmin(ii) = a ; % For uniform distribution, the bound of the space is that of the distribution
            zmax(ii) = b ;
        else
            fprintf('\n Error: The specified disribution is not defined within UQLAB.\n') ;
        end
    end
end

end


