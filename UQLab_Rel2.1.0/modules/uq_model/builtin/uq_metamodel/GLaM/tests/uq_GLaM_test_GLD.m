function pass = uq_GLaM_test_GLD( level )
% UQ_GLAM_TEST_GLD(LEVEL)
% 
% Summary:  
%   Tests for the fit of generalized lambda distribution
%
%   
%% start a new session
rng(100,'twister')
pass=true;

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
    
end
switch level
    case 'normal'
        %
    otherwise
        %
end
fprintf(['\nRunning: |' level '| uq_GLaM_test_GLD...\n']);

%% set tolerance
Threlam1 = 0.2;
Threlam2 = 0.05;
ThreNLLh = 1e-2;

%% get reference lambda values
lambda=[0,1,0.14,0.14;
        1,0.5,-0.1,0.4;
       ];

Nl = size(lambda,1);

Nmc = 200;
data = zeros(Nmc,Nl);
lambdaFit1 = zeros(Nl,4);

%% fit the generalized lambda distribution
Nllh = zeros(1,Nl);
Nllh1= zeros(1,Nl);
for il=1:Nl
    u=rand(Nmc,1);
    data(:,il)=uq_GLD_quantile(u,lambda(il,:));
    Nllh(il) = uq_GLD_NLogLikelihood(data(:,il),lambda(il,:));
    lambdaFit1(il,:)=uq_GLD_fit(data(:,il),'MLE');
    Nllh1(il) = uq_GLD_NLogLikelihood(data(:,il),lambdaFit1(il,:));
end

ErLam1=max(abs(lambdaFit1-lambda));
ErNllh1 = max(abs((Nllh1-Nllh)./Nllh));
if max(ErLam1)<Threlam1||ErNllh1<ThreNLLh
    pass = pass & true;
else
    pass = false;
end


%% split data
Nsplit=2;
Nf=Nmc/Nsplit;
Y=zeros(Nsplit,Nl,Nf);
for il=1:Nl
    for is=1:Nsplit
        Y(is,il,:) = data(Nf*(is-1)+1:Nf*is,il);
    end
end
X=linspace(0,1,Nsplit)';

inputOpt.Marginals(1).Type = 'Uniform';
inputOpt.Marginals(1).Parameters = [-0.1,1.1];
myInput = uq_createInput(inputOpt);

%% build replication-based model
metaopts.Type = 'metamodel';
metaopts.MetaType = 'GLaM';
metaopts.Input = myInput ;
metaopts.Lambda(1).Degree=0;
metaopts.Lambda(2).Degree=0;
metaopts.Lambda(3).Degree=0;
metaopts.Lambda(4).Degree=0;

metaopts.Method = 'RepJoint';
metaopts.ExpDesign.X = X;
metaopts.ExpDesign.Y = Y;
myGLaM=uq_createModel(metaopts,'-private');

% evaluate lambda
lambdaFit2=uq_GLaM_evalLambda(myGLaM,0.5);
lambdaFit2 = permute(lambdaFit2,[2,3,1]);

% evaluate negative loglikelihood
Nllh2= zeros(1,Nl);
for il = 1:Nl
    Nllh2(il) = uq_GLD_NLogLikelihood(data(:,il),lambdaFit2(il,:));
end

% evaluate errors
ErLam2=max(abs(lambdaFit2-lambda));
ErLam3=max(abs(lambdaFit2-lambdaFit1));
ErNllh2 = max(abs((Nllh2-Nllh)./Nllh));

if (max(ErLam2)<Threlam1&&max(ErLam3)<Threlam2)||ErNllh2<ThreNLLh
    pass = pass & true;
else
    pass = false;
end
%% build full regression model

metaopts.Method = 'FullReg';
myGLaM=uq_createModel(metaopts);

% evaluate lambda
lambdaFit3=uq_GLaM_evalLambda(myGLaM,0.5);
lambdaFit3 = permute(lambdaFit3,[2,3,1]);

% evaluate negative loglikelihood
Nllh3= zeros(1,Nl);
for il = 1:Nl
    Nllh3(il) = uq_GLD_NLogLikelihood(data(:,il),lambdaFit3(il,:));
end

% evaluate errors
ErLam4=max(abs(lambdaFit3-lambda));
ErLam5=max(abs(lambdaFit3-lambdaFit1));
ErNllh3 = max(abs((Nllh2-Nllh)./Nllh));

if (max(ErLam4)<Threlam1&&max(ErLam5)<Threlam2)||ErNllh3<ThreNLLh
    pass = pass & true;
else
    pass = false;
end

try
    uq_display(myGLaM);
    close gcf;
    uq_display(myGLaM,'lambda');
    close gcf;
catch
    pass = false;
end

if pass == 0
    ErrStr = '\nError in uq_GLaM_test_GLD\n';
    error(ErrStr);
end
end