function [Y,Ymean,Ystd] = uq_SPCE_eval(SPCEModel,X,varargin)
%% evaluate the stochastic polynomial chaos expansion
% ----- Input -----
% SPCEModel: SPCE model
% X: the input to evaluate
% varargin: additional options
%           varargin{1}: if this is a positive integer, it corresponds to the number of replications
%           ('evalTraj'): evaluate the trajectory, i.e., the same values of the latent 
%           and noise variables across different values of the input
%           ('LatentSampleMethod',Method): sampling the latent variable
%           using the specified Method 
% ----- Output -----
% Y: generated samples for X
% Ymean: the conditional mean at X
% Ystd: the conditional standard deviation at X

%% parse replications
R = 1;
if ~isempty(varargin)
    if isnumeric(varargin{1})
        if length(varargin{1})==1 && varargin{1}>0 && varargin{1}-round(varargin{1})==0
            R = varargin{1};
        else
            error('The number of replications should be a positive integer.');
        end
        varargin{1}=[];
    end
end

%% parse the other options
parse_keys = {'evalTraj','LatentSampleMethod'};
parse_types = {'p','p'};
[parsed, ~] = uq_simple_parser(varargin, parse_keys, parse_types);

% the user does not specify the option of trajectories
if strcmp(parsed{1},'false')
    % we set by default not calculating trajectories
    evalTraj = false;
else
% the user specifies option of trajectories
    evalTraj = parsed{1};
end

% the user does not specify the sampling method
if strcmp(parsed{2},'false')
    % we set by default MC sampling strategy for the latent variable
    LatentSampleMethod = 'MC';
else
% the user specifies option of latent sampling method
    LatentSampleMethod = parsed{2};
end
%% retrieve information
NED = size(X,1);

Nout = SPCEModel.Internal.Runtime.Nout;
Y = zeros(NED,Nout,R);

if nargout>1
    Ymean = zeros(NED,Nout);
    Ystd = zeros(NED,Nout);
end

AuxPCEOpt.Type = 'Metamodel';
AuxPCEOpt.MetaType = 'PCE';
AuxPCEOpt.Method = 'Custom';

for oo = 1:Nout
    % build auxiliary PCE object combining both the input the latent
    % variable for model evaluation
    extendedInput = uq_mergeInputs(SPCEModel.Internal.Input,SPCEModel.Internal.ED_Latent{oo},'-private');
    AuxPCEOpt.Input = extendedInput;
    AuxPCEOpt.PCE.Basis = SPCEModel.SPCE(oo).Basis;
    AuxPCEOpt.PCE.Coefficients = SPCEModel.SPCE(oo).Coefficients;
    AuxPCE = uq_createModel(AuxPCEOpt,'-private');
    
    % if trajectories are desired, keep the same values of the latent and noise
    % variables
    if evalTraj        
        Z = uq_getSample(SPCEModel.Internal.ED_Latent{oo},R,LatentSampleMethod);
        Z = kron(Z,ones(NED,1));
        noise = randn(1,1,R)*SPCEModel.SPCE(oo).Sigma;
    
    % otherwise, simply sample the latent and noise variables
    else        
        Z = uq_getSample(SPCEModel.Internal.ED_Latent{oo},NED*R,LatentSampleMethod);
        noise = randn(NED,1,R)*SPCEModel.SPCE(oo).Sigma;
    end
    
    Y(:,oo,:)=reshape(uq_evalModel(AuxPCE,[repmat(X,R,1),Z]),[NED,1,R]) + noise;
    
    % compute the mean and standard deviation at X
    if nargout>1 
        [coefZ,Zdegree] = uq_SPCE_LatentPCECoeff(SPCEModel,X,oo);
        meanInd = Zdegree==0;
        if any(meanInd)
            Ymean(:,oo) = coefZ(meanInd,:);
        end

        Ystd(:,oo) = sqrt(SPCEModel.SPCE(oo).Sigma^2 + sum(coefZ(~meanInd,:).^2,1));
    end
end

end

