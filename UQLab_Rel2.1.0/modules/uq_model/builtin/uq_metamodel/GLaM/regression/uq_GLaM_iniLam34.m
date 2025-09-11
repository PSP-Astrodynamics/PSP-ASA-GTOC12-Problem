function [Coef,IC] = uq_GLaM_iniLam34(Psi,Coef0,transform,Y,infCrit,enforceGradient,Display)
if nargin<5
    infCrit='NLogLikelihood';
end
if nargin<6
    enforceGradient=false;
end

% get the number of data
N_data = length(Y);

%% get initial guesses for lambda3 and lambda4
lb3=-0.2;ub3=0.5;
lb4=-0.2;ub4=0.5;
lam34Add = [0.14,0.14];
N0 = 10;
iniLam34=[];
ii = 0;
while isempty(iniLam34)&&ii<10
    iniLam34 = lhsdesign(N0-size(lam34Add,1),2);
    iniLam34(:,1) = iniLam34(:,1)*(ub3-lb3)+lb3;
    iniLam34(:,2) = iniLam34(:,2)*(ub4-lb4)+lb3;
    iniLam34 = [lam34Add;iniLam34];
    lambda3inv = uq_GLaM_evalTransform(transform{3},iniLam34(:,1),true);
    lambda4inv = uq_GLaM_evalTransform(transform{4},iniLam34(:,2),true);
    ind = isnan(lambda3inv)|isnan(lambda4inv);
    iniLam34(ind,:)=[];
    lambda3inv(ind,:)=[];
    lambda4inv(ind,:)=[];
    ii=ii+1;
end
if isempty(iniLam34)
    error('Unable to find feasible points for lambda3 and lambda4');
end
N0 = size(iniLam34,1);
%% make sure that Psi contains enough information
Psi{3}=ones(N_data,1);
Psi{4}=Psi{3};

%% set options for the optimization
only34 = false;
issparse = false(1,4);
onlyGradient = true;
optMethod = 1;
verbose = 'off';
if Display>1
    verbose = 'iter';
end
%%
lam1 = uq_GLaM_evalTransform(transform{1},Psi{1}*Coef0{1});
lam2 = uq_GLaM_evalTransform(transform{2},Psi{2}*Coef0{2});
Coef = Coef0;
Coef{3}=iniLam34(1,1);
Coef{4}=iniLam34(1,2);
coefarray=cat(1,Coef{:});

bestscore = inf;
IC=[];
early_stop = true;
i_earlystop = 1;
N_earlystop = 3;
earlyDiff = 0.05;

for i_ini=1:N0
    if ~ismember(iniLam34(i_ini,:),lam34Add,'rows')
        % check lower bound
        if iniLam34(i_ini,1)>0 && any(lam1-1./lam2./iniLam34(i_ini,1)>Y)
            continue
        end
        % check upper bound
        if iniLam34(i_ini,2)>0 && any(lam1+1./lam2./iniLam34(i_ini,2)<Y)
            continue
        end
    end
    % get the initial guess
    Coef_ini = Coef0;
    Coef_ini{3}=lambda3inv(i_ini);
    Coef_ini{4}=lambda4inv(i_ini);
    % fit the model
    [Coef_new,~,method_new,IC_new] = uq_GLaM_fit_coefficients(Y,Psi,Coef_ini,transform,optMethod,verbose,issparse,only34,onlyGradient);
    
    % if the optimum must have zero gradient
    if enforceGradient&&method_new~=1        
        N1 = sum(Coef_ini{1}~=0)-1;
        N2 = sum(Coef_ini{2}~=0)-1;
        NN=[N1,N2];
        frac = [0.5,0.5];
        ii=2;
        while method_new~=1
            if NN(1)==1&&NN(2)==1
                break
            elseif NN(1)==1
                ii = 2;
            elseif NN(2)==1
                ii = 1;
            elseif NN(1)<N1*frac(1)&&NN(2)>N2*frac(2)
                ii=2;
            elseif NN(1)>N1*frac(1)&&NN(2)<N2*frac(2)
                ii=1;
            elseif NN(1)>N1*frac(1)&&NN(2)>N2*frac(2)
                ii=mod(ii,2)+1;
            else
                N1 = N1*frac(1);
                N2 = N2*frac(2);
            end
            Coeftmp = Coef_ini;Coeftmp{1}(1)=0;Coeftmp{2}(1)=0;
            temp = abs(Coeftmp{ii});
            temp(temp==0)=max(abs(temp));
            [~,jj] = min(temp);
            Coef_ini{ii}(jj)=0;
            NN(ii) = NN(ii)-1;
            [Coef_new,~,method_new,IC_new] = uq_GLaM_fit_coefficients(Y,Psi,Coef_ini,transform,optMethod,verbose,issparse,only34,onlyGradient);
        end
    end
    if ~enforceGradient||method_new==1
        coefnewarray=cat(1,Coef_new{:});
        isSimilar = compareCoef(coefnewarray,coefarray,earlyDiff);
        if isSimilar
            i_earlystop = i_earlystop+1;
        end
        if bestscore>IC_new.(infCrit) 
            bestscore = IC_new.(infCrit);
            Coef = Coef_new;
            coefarray=coefnewarray;
            IC = IC_new;
            if ~isSimilar
                i_earlystop = 1;
            end
        end
    end
    if early_stop&&i_earlystop>N_earlystop
        break
    end
end

if isinf(bestscore)
    error('Unable to find a feasible starting points, please decrease the polynomial complexity associated with lambda1 and lambda2');
end

end

function isSimilar = compareCoef(coefnewarray,coefarray,diffThre)
% initialize
isSimilar = false;

%check whether the same basis is used
indnew = coefnewarray~=0;
ind = coefarray~=0;
isSameBasis = isequal(indnew,ind);

% if so
if isSameBasis
    % we check the difference in the coefficients
    coefnewarray = coefnewarray(indnew);
    coefarray = coefarray(ind);
    isSimilar = norm((coefnewarray-coefarray)./coefarray,Inf)<diffThre;
end
    
end
