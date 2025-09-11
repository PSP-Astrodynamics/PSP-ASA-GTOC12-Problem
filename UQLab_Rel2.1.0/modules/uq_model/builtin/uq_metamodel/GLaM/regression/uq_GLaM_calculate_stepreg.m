function [Coef,IC,Results] = uq_GLaM_calculate_stepreg(Psi,Y,Coef0,transform,OptmMethod,options)
% perform stepwise regression
% Psi: cell array of 1*4 containing the basis functions
% Y: data
% Coef0: starting coefficients
% transform: transform function applied to the PCE for the lambda's
% OptmMethod: optimization algorithm
% options: options for stepwise algorithm

%% set default values
DisplayLevel = options.Display;
stepwiseOrder = {'forward','backward'};
%%
if exist('options', 'var')
    % normalize the columns of Psi prior to running lars
    if isfield(options, 'Normalize')
        normalize = options.Normalize;
    end
    
    % in which order the stepwise algorithm is performed
    if isfield(options, 'stepwiseOrder')
        stepwiseOrder = options.stepwiseOrder;        
    end
end

if DisplayLevel>1
    verbose = 'iter';
else
    verbose = 'off';
end
%% set options for forward and backward steps
options.Forward.Display = DisplayLevel;
options.Backward.Display = DisplayLevel;

Results = options;
%% get necessary information from the data
N_data = length(Y);

%% normalize the basis functions
if normalize
    ll = cell(1,4);
    for ilam = 1:4
        ll{ilam} = vecnorm(Psi{ilam},2,1)/sqrt(N_data);
        Psi{ilam} = bsxfun(@rdivide, Psi{ilam}, ll{ilam});
        Coef0{ilam} = Coef0{ilam}.*ll{ilam}';
    end
end
%%
Noperation = length(stepwiseOrder);

% whether to report plm only related to lambda34
iniplmOnly34 = isempty(setdiff(options.Forward.Lambda,[3,4]));

% build the model with the inital value Coef0
onlyGradient = true;
issparse = [false,false,false,false];
[Coef,~,~,IC,pwald,plm] = uq_GLaM_fit_coefficients(Y,Psi,Coef0,transform,OptmMethod,verbose,issparse,iniplmOnly34,onlyGradient);

% find the location of the backward steps
backward_loc = strcmpi(stepwiseOrder,'backward');
ind = diff(backward_loc)<0;
% loop over the operations
for io = 1:Noperation
    
    % forward selection
    if ~backward_loc(io)
        if DisplayLevel>1
            fprintf('Perform forward enrichement...\n');
        end
        [Coef,IC,pwald,plm,FW] = uq_GLaM_stepwise_forward(Y,Psi,Coef,transform,OptmMethod,IC,pwald,plm,options.Forward);
        Results.Operations(io) = FW;
        if DisplayLevel>1
            fprintf('Forward enrichement completed.\n');
        end
    else
    % backward elimination
        if DisplayLevel>1
            fprintf('Perform backward elimination...\n');
        end
    
        if ~iniplmOnly34&&ind(io)&&io<Noperation
            options.Backward.plmonly34 = false;
            [Coef,IC,pwald,BW,plm] = uq_GLaM_stepwise_backward(Y,Psi,Coef,transform,OptmMethod,IC,pwald,plm,options.Backward);
        else
            [Coef,IC,pwald,BW] = uq_GLaM_stepwise_backward(Y,Psi,Coef,transform,OptmMethod,IC,pwald,plm,options.Backward);
        end
        Results.Operations(io) = BW;
        
        if DisplayLevel>1
            fprintf('Backward enrichement completed.\n');
        end
    end
end

%% recover the initial coefficients
if normalize
    for ilam = 1:4       
        Coef{ilam} = Coef{ilam}./ll{ilam}';
    end
end

end

