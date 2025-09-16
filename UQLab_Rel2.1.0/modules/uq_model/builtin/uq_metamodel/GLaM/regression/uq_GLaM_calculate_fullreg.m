function [Coef,IC,Results] = uq_GLaM_calculate_fullreg(Psi,Y,coef0,transform,OptimMethod,Options)
FullLambda = [3,4];

if isfield(Options,'FullLambda')
    FullLambda = Options.FullLambda;
end

verbose='off';
if Options.Display>1
    verbose = 'iter';
end
%%
inival = 1e-10;
for ilam=FullLambda
    id_non0=coef0{ilam}==0;
    coef0{ilam}(id_non0)=inival;
end
%% set option for the optimizations
only34=false;
issparse=[false,false,false,false];
enforceGradient=true;
%% fit the model
[Coef,~,~,IC] = uq_GLaM_fit_coefficients(Y,Psi,coef0,transform,OptimMethod,verbose,issparse,only34,enforceGradient);

% return options
Results = Options;
Results.FullLambda = FullLambda;
end

