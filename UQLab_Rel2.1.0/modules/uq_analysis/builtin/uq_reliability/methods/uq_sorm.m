function Results = uq_sorm(current_analysis)
% RESULTS = UQ_SORM(CURRENT_ANALYSIS):
%     perform a SORM analysis of the object CURRENT_ANALYSIS
% 
% See also: UQ_FORM, UQ_HESSIAN

Options = current_analysis.Internal;

% Retrieve also the model and input modules:
CurrentModel = Options.Model;
CurrentInput = Options.Input;

% Find the nonConst marginals:
nonConst = ~ismember(lower({current_analysis.Internal.Input.Marginals.Type}),{'constant'});
nonConstIdx = find(nonConst);
constIdx = find(~nonConst);

% The display option
Display = Options.Display;

% Define the limit state function
limit_state_fcn = @(X) uq_evalLimitState(X, CurrentModel, Options.LimitState, Options.HPC.SORM);

% Initialize the design point and the reliability index
Ustar = [];
BetaHL = [];
Xstar = [];

% First, we check if FORM was already performed:
if isprop(current_analysis,'Results') && ~isempty(current_analysis.Results);
    if iscell(current_analysis.Results)
        ResultsFORM = current_analysis.Results(end);
    else
        ResultsFORM = current_analysis.Results;
        current_analysis.Results = [];
    end
    
    % In case FORM results are already available
    if isfield(ResultsFORM,'Ustar') && isfield(ResultsFORM,'BetaHL')
        if Display > 0
            fprintf('\nSORM: Using results from previous FORM analysis.');
        end
        Ustar = ResultsFORM.Ustar;
        BetaHL = ResultsFORM.BetaHL;
        Xstar = ResultsFORM.Xstar;
    end
end

% Start FORM and gather Ustar
if isempty(Ustar) || isempty(BetaHL) || isempty(Xstar)
    if Display > 0
        fprintf('\nSORM: FORM Results not found');
        fprintf('\nSORM: Starting FORM to search for the design point...');
    end
    ResultsFORM = uq_form(current_analysis);
    Ustar = ResultsFORM.Ustar;
    Xstar = ResultsFORM.Xstar;
    BetaHL = ResultsFORM.BetaHL;
end

%% SORM
% Create a multivariate standard normal distribution:
M = length(CurrentInput.Marginals) ;
[StandardMarginals(1:M).Type] = deal('Gaussian') ;
[StandardMarginals(1:M).Parameters] = deal([0,1]) ;
StandardCopula.Type = 'Gaussian';
StandardCopula.Parameters = eye(M);

% We need to somehow instruct UQLab to ignore the constant dimensions in 
% the transformation. We set them to constants with 1:
[StandardMarginals(constIdx).Type] =  deal('Constant');
[StandardMarginals(constIdx).Parameters] = deal(1);


% Transform from standard space to physical space
transform = @(U) uq_GeneralIsopTransform(U, StandardMarginals, StandardCopula, CurrentInput.Marginals, CurrentInput.Copula);

% Limit state function on the standard normal space
std_limit_state = @ (X) limit_state_fcn(transform(X));

%% Analysis for each output dimension
NOuts = length(BetaHL);
AllUstar = Ustar;
TotalModelEvaluations = 0;
curv = zeros(NOuts,M);
for oo = 1:NOuts
    % Store Alpha (unit vector pointing to Ustar)
    Ustar = AllUstar(:, :, oo);
    Alpha = Ustar/BetaHL(oo);
    
    % Get the rotation matrix using Gram-Schmidt:
    [Rot, NewBase]= uq_gram_schmidt(Alpha(find(nonConst)));
     
    % Gradient on Ustar
    [GradientUstar, g_Ustar, GradientEvaluations, GradientDesign]= ...
        uq_gradient(Ustar,std_limit_state,Options.Gradient.Method, Options.Gradient.Step, Options.Gradient.h, CurrentInput.Marginals);
    % reshape output to be used for further use
    if length(size(GradientUstar)) == 3
        GradientUstar = permute(GradientUstar,[3,2,1]);
    else
        GradientUstar = GradientUstar(1,:,:)';
    end
    
    % Get the Hessian on the point:
    % The hessian computation should take into account that there might be
    % constants. In the gradient computation constants are inferred from
    % the Marginals but in the case of Hessian (in order not to break other
    % parts of the code), I keep the signature the same and add the
    % non-constant indices as a field of std_limit_state:
    std_limit_state_struct.handle = std_limit_state;
    std_limit_state_struct.nonConst = nonConst;
    if isfield(current_analysis.Internal, 'Gradient') ...
            &&isfield(current_analysis.Internal.Gradient, 'h')
        [H, HessianEvals, HessianDesign] = uq_hessian(Ustar, std_limit_state_struct, [], current_analysis.Internal.Gradient.h);
    else
        [H, HessianEvals, HessianDesign] = uq_hessian(Ustar, std_limit_state_struct);
    end
    AllHessians(:,:,oo) = H;
    
    % Compute the matrix A:
    Mnc = sum(nonConst);
    
    A = NewBase*H(find(nonConst),find(nonConst))*NewBase'/(2*norm(GradientUstar,2));
    
    A = A(1:Mnc - 1, 1:Mnc - 1);
    
    % Find the curvatures:
    Curvatures = -2*eig(A);
    
    if any(Curvatures >= 1)
        fprintf('\nWarning: Found curvatures >= 1. This means that FORM did not converge to the actual design point.\n');
    end
    
    % save curvatures
    curv(oo,nonConst(1:end-1))=Curvatures(:);
    
    %% Compute the SORM failure probabilities
    % Hohenbichler's formula:
    CDFminusBeta(oo) = uq_gaussian_cdf(-BetaHL(oo),[0 1]);
    RatioCDFPDF(oo) = uq_gaussian_pdf(-BetaHL(oo),[0,1])/CDFminusBeta(oo);
    HohenbichlerVec = 1./sqrt(1 - RatioCDFPDF(oo)*Curvatures);
    PfSORM(oo) = CDFminusBeta(oo)*prod(HohenbichlerVec);
    
    % Breitung's formula:
    BreitungVec = 1./sqrt(1 - BetaHL(oo)*Curvatures);
    PfSORMBreitung(oo) = CDFminusBeta(oo)*prod(BreitungVec);
    
    TotalModelEvaluations = TotalModelEvaluations + HessianEvals + GradientEvaluations;
end

%% Save the results:
Results = ResultsFORM;
Results.History(1).FORMEvals = ResultsFORM.ModelEvaluations;
Results.ModelEvaluations = Results.ModelEvaluations + TotalModelEvaluations;
Results.PfSORM = PfSORM;
Results.PfSORMBreitung = PfSORMBreitung;
Results.BetaSORM = -icdf('normal', PfSORM, 0, 1);
Results.BetaSORMBreitung = -icdf('normal', PfSORMBreitung, 0, 1);
Results.Curvatures = curv;
if Options.SaveEvaluations
    for oo = 1:length(Results.History)
    Results.History(oo).X = [Results.History(oo).X; GradientDesign.X ; HessianDesign.X];
    Results.History(oo).G = [Results.History(oo).G; GradientDesign.Y(:,oo);  HessianDesign.Y(:,oo)];
    end
end
for oo = 1:NOuts
    Results.History(oo).Hessian = AllHessians(:,:,oo);
end
Results.PfFORM = Results.Pf;


if Display > 0
    fprintf('\nSORM: Finished.\n ');
end