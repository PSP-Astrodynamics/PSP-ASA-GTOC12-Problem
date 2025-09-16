function lambda = uq_GLaM_evalLambda(GLaModel,X,varargin)
%% Evaluate the lambda's for a given generalized lambda model
% GLaModel: the generalized lambda model 
% X: the data point to evaluate
% varargin: additional options related to truncations
%          *('TruncLambdai',[l,u]) the lambda_i is truncted within [a,b],
%           i.e., if its value is outside, it will be set to the value of 
%           the nearest bound.
%          *('TruncLambda',[l_1,u_1;l_2,u_2;l_3,u_3;l_4,u_4]) set the
%          bounds for lambda1-4 all together, and the i-th row corresponds
%          to the bounds for lambdai

%% parse the additional options
parse_keys = {'TruncLambda1','TruncLambda2','TruncLambda3','TruncLambda4','TruncLambda'};
parse_types = {'p','p','p','p','p'};
[parsed, ~] = uq_simple_parser(varargin, parse_keys, parse_types);

% set default truncation scheme
TruncLambda = repmat([-Inf,Inf],[4,1]);
TruncLambda(3:4,1) = -0.2; % lower bound for existence of fourth-order moment

% parse lambda1-4
for ilam = 1:4
    if ~strcmp(parsed{ilam},'false')
        TruncLambda(ilam,:) = parsed{ilam};
    end
end

% parse all the truncated values
if ~strcmp(parsed{5},'false')
    TruncLambda = parsed{5};
end

%%
% retrieve important informations
Ndata = size(X,1);
Nout = GLaModel.Internal.Runtime.Nout;

% pretend to be PCE
prePCE.PCE = GLaModel.GLaM;
prePCE.Internal = GLaModel.Internal;
prePCE.Options = GLaModel.Options;
prePCE.Internal.Runtime.Nout=4*Nout;

% make sure output 1 has the basis long enough for the highest degree
degrees = zeros(1,4);
for ilam = 1:4
    degrees(ilam) = prePCE.PCE(ilam).Basis.Degree;
end
[~, max_degree_idx] = max(degrees);

if max_degree_idx ~= 1
    prePCE.PCE(1).Basis.PolyTypesAB = prePCE.PCE(max_degree_idx).Basis.PolyTypesAB;
end

lam = uq_PCE_eval(prePCE,X);

lambda=zeros(Ndata,Nout,4);

lamOrder = [GLaModel.GLaM.Lambda];
for ilam=1:4
    % get the lambda indices
    ind = lamOrder==ilam;
    % evaluate lambda's
    lami = lam(:,ind);
    lami = uq_GLaM_evalTransform(GLaModel.GLaM(ilam).Transform,lami);
    
    % perform truncations
    lami = max(lami,TruncLambda(ilam,1));
    lami = min(lami,TruncLambda(ilam,2));
    
    % save the results
    lambda(:,:,ilam)=lami;
end
end

