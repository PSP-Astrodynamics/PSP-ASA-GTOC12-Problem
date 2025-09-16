function [Lmean,Lvar] = uq_GLD_mean_var(lam,trunc)

if nargin==1
    ind1 = find(lam(:,3)<-1);
    ind2 = find(lam(:,4)<-1);
    NN=size(lam,1);
    ind3=setdiff(1:NN,ind1);
    ind3=setdiff(ind3,ind2);
    
    Lmean = zeros(NN,1);
    Lmean(ind1) = inf;
    Lmean(ind2) = inf;
    Lmean(ind3)=lam(ind3,1)-1./lam(ind3,2).*(1./(1+lam(ind3,3))-1./(1+lam(ind3,4)));
    
    ind1 = find(lam(:,3)<-0.5);
    ind2 = find(lam(:,4)<-0.5);
    ind3=setdiff(1:NN,ind1);
    ind3=setdiff(ind3,ind2);
    
    Lvar = zeros(NN,1);
    Lvar(ind1) = inf;
    Lvar(ind2) = inf;
    v1=1./(lam(ind3,3).*(lam(ind3,3)+1))-1./(lam(ind3,4).*(lam(ind3,4)+1));
    v2=1./(lam(ind3,3).^2.*(2*lam(ind3,3)+1))+1./(lam(ind3,4).^2.*(2*lam(ind3,4)+1))...
        -2./(lam(ind3,3).*lam(ind3,4)).*beta(lam(ind3,3)+1,lam(ind3,4)+1);
    Lvar(ind3)=(v2-v1.^2)./(lam(ind3,2).^2);
    
elseif nargin>1
    N = size(lam,1);
    U = zeros(N,2);
    Uis1drow = false;
    
    if isfield(trunc,'norm')
        norm = trunc.norm;
    else
        norm = true;
    end
    
    % get truncation information    
    % the truncated value is given
    if isfield(trunc,'value')        
        if length(trunc.value)==1
            Y = ones(N,1)*trunc.value;
            switch lower(trunc)
                case 'lower'
                    U(:,1) = 0;
                    U(:,2) = uq_GLD_DistributionFunc(lam,Y,'cdf');                    
                case 'upper'
                    U(:,1) = uq_GLD_DistributionFunc(lam,Y,'cdf');
                    U(:,2) = 1;
            end
        elseif isequal(size(trunc.value),[N,1])
            switch lower(trunc)
                case 'lower'
                    U(:,1) = 0;
                    U(:,2) = uq_GLD_DistributionFunc(lam,trunc.value,'cdf');   
                case 'upper'
                    U(:,1) = uq_GLD_DistributionFunc(lam,trunc.value,'cdf');
                    U(:,2) = 1;
            end
        elseif isequal(size(trunc.value),[1,2])
            Y = [ones(N,1)*trunc.value(1);ones(N,1)*trunc.value(2)];
            U(:,1) = uq_GLD_DistributionFunc(lam,Y(:,1),'cdf');
            U(:,2) = uq_GLD_DistributionFunc(lam,Y(:,2),'cdf');
        elseif isequal(size(trunc.value),[N,2])
            U(:,1) = uq_GLD_DistributionFunc(lam,trunc.value(:,1),'cdf');
            U(:,2) = uq_GLD_DistributionFunc(lam,trunc.value(:,2),'cdf');
        else
            error('The dimension of truncated values is incorrect');
        end
    
    % if the u values are provided instead
    elseif isfield(trunc,'U')
        if size(trunc.U,1)==1&&size(trunc.U,2)>1
            Uis1drow  = true;
            U = trunc.U;
        elseif size(trunc.U,2)==1
            switch lower(trunc)
                case 'lower'
                    U(:,1) = 0;
                    U(:,2) = trunc.U;
                case 'upper'
                    U(:,1) = trunc.U;
                    U(:,2) = 1;
            end
        elseif isequal(size(trunc.U),[N,2])
            U = trunc.U;        
        else
            error('The dimension of truncated U values is incorrect');
        end
    end
    
    % define an auxilary function (for the mean)
    UnDInt1 = @(u) u.^(lam(:,3)+1)./(lam(:,3)+1)./lam(:,3) + (1-u).^(lam(:,4)+1)./(lam(:,4)+1)./lam(:,4);
    prob = diff(U,1,2);        
    % we calculate the truncated mean and variance within the
    % intervals [U(1),U(2)], [U(2),U(3)], [U(3),U(4)], ...
    if Uis1drow
        NU = length(U);
        % define an auxilary function (for the variance)
        auxbetainc = @(u) betainc(repmat(u,N,1),repmat(lam(:,3),1,NU)+1,repmat(lam(:,4),1,NU)+1).* beta(lam(:,3)+1,lam(:,4)+1);        
        UnDInt2 = @(u)u.^(2*lam(:,3)+1)./(2*lam(:,3)+1)./lam(:,3).^2 - ...
            2*auxbetainc(u)./lam(:,3)./lam(:,4)-...
            (1-u).^(2*lam(:,4)+1)./(2*lam(:,4)+1)./lam(:,4).^2;
        
        intSu = diff(UnDInt1(U),1,2);
        if norm
            % Calculate the mean 
            MeanPart12 = lam(:,1) - 1./lam(:,2)./lam(:,3) + 1./lam(:,2)./lam(:,4);
            ESu = bsxfun( @rdivide,intSu,prob );
            MeanPart34 = bsxfun( @rdivide,ESu,lam(:,2) );
            Lmean = bsxfun(@plus,MeanPart12,MeanPart34 );
            % Calculate the variance
            DIntSu2 = diff(UnDInt2(U),1,2);
            ESu2 =  bsxfun( @rdivide,DIntSu2,prob );
            Lvar = bsxfun(@rdivide,ESu2 - ESu.^2,(lam(:,2)).^2);
        elseif nargin==1
            % Calculate the mean 
            MeanPart12 = (lam(:,1) - 1./lam(:,2)./lam(:,3) + 1./lam(:,2)./lam(:,4)).*prob;
            Lmean = MeanPart12 + bsxfun(@rdivide,intSu,lam(:,2));
        else
            warning('If the truncated probability is not normalized, the variance is undefined');
            Lvar = NaN;
        end
        
    % we calculate the truncated mean and variance between U(:,1) and U(:,2)
    else
        % define an auxilary function (for the variance)
        UnDInt2 = @(u)u.^(2*lam(:,3)+1)./(2*lam(:,3)+1)./lam(:,3).^2 - ...
            2./lam(:,3)./lam(:,4).*betainc(u,lam(:,3)+1,lam(:,4)+1).*beta(lam(:,3)+1,lam(:,4)+1)-...
            (1-u).^(2*lam(:,4)+1)./(2*lam(:,4)+1)./lam(:,4).^2;
        intSu = UnDInt1(U(:,2))-UnDInt1(U(:,1));
        if norm
            % Calculate the mean 
            MeanPart12 = lam(:,1) - 1./lam(:,2)./lam(:,3) + 1./lam(:,2)./lam(:,4);
            ESu = intSu./prob;
            MeanPart34 = ESu./lam(:,2);
            Lmean = MeanPart12+MeanPart34;
            % Calculate the variance             
            ESu2 = (UnDInt2(U(:,2))-UnDInt2(U(:,1)))./prob;
            Lvar = (ESu2 - ESu.^2)./(lam(:,2)).^2;
        elseif nargin==1
            % Calculate the mean 
            MeanPart12 = (lam(:,1) - 1./lam(:,2)./lam(:,3) + 1./lam(:,2)./lam(:,4)).*prob;
            Lmean = MeanPart12+intSu./(lam(:,2));                   
        else
            warning('If not normalized, the variance is undefined');
            Lvar = NaN;
        end
    end
end
end

