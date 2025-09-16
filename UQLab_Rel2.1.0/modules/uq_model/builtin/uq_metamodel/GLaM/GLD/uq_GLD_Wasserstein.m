function discrepancy = uq_GLD_Wasserstein(lambda,samples,p,calcMethod,U)
%% Compute the Wasserstein distance of order p between generalized lambda distributions and samples
% lambda: the parameters for the GLDs
% samples: samples to compare with
% p: order of the Wasserstein distance
% calcMethod: the method to compute the Wasserstein distance (WSD) 
%             1. 'quantile': the wasserstein distance is calcualted based on the empirical quantile 
%                specified by U. By default, u=0.0005:0.01:0.9995. 
%             2. 'mixed': a mixed way to compute the Wasserstein distance
%                based on mean, standard deviation and quantile correlations.
%                See: Schefzik, R. et al. Fast identification of differential distributions in
%                single-cell RNA-sequencing data with waddR. Bioinformatics, 37:3204–3211.
%             3. 'ot': the exact semi-discrete Wasserstein distance (based on optimal transport) is calculated.
%                See: Solomon, J. (2018). Optimal transport on discrete
%                domains. AMS Short Course on Discrete Differential Geometry.
%                     


% defaut order
if nargin<3
    p=2;
end

% default calculation method
if nargin<4
    if p==2
        calcMethod = 'ot';
    else
        calcMethod = 'quantile';
    end
end

% set default empirical quantiles
if nargin<5
    U = 0.0005:0.001:0.9995;
end

if p~=2 && ~strcmpi(calcMethod,'quantile')
    error(['Only the quantile method is available for the Wasserstein distance of order ',num2str(p)]);
end

% retrieve data informations
Nl = size(lambda);
Ndim = length(Nl);
Nl = Nl(1);

Ns = size(samples,1);
Nout = size(samples,2);

% check dimension
% Only a single lambda is given in a row vector 
% and one sample (column vector) is given, 
% transform lambda and samples to the right format (3d array)
if isequal(size(lambda),[1,4]) && isequal(size(samples),[Ns,1])
    samples = samples';

% the lambda are given as a matrix of N*4
% and the samples are given as a matrix of N*R, 
% There is only one Nout
elseif Nl==Ns && size(lambda,2)==4 && size(lambda,3)==1 && size(samples,3)==1
    Nout = 1;
    
elseif Nl~=Ns
    error('The dimension is not consistent');
end

discrepancy = zeros(Nl,Nout);
for oo=1:Nout
    if Ndim>2
        sampleoo = permute(samples(:,oo,:),[1,3,2]);
        lamoo = permute(lambda(:,oo,:),[1,3,2]);
    else
        sampleoo = samples;
        lamoo = lambda;
    end
    
    Nsamples = size(sampleoo,2);
    
    % choose different method
    switch lower(calcMethod)
        
        % WSD based on empirical quantiles
        case 'quantile'
            quantref = quantile(sampleoo,U,2);
            quantLam = uq_GLD_quantile(U,lamoo);
            discrepancy(:,oo) = (mean(abs((quantref-quantLam)).^p,2))^(1/p);
            
        % WSD based on mean, std, and quantile correlations    
        case 'mixed'
            [muLam,sLam] = uq_GLD_mean_var(lamoo);
            sLam = sqrt(sLam);
            mus = mean(sampleoo,2);
            sigmas = std(sampleoo,0,2);
            quantref = quantile(sampleoo,U,2);
            quantLam = uq_GLD_quantile(U,lamoo);
            rhou=zeros(Nl,1);
            for in = 1:Nl
               rhou(in) = corr(quantref(in,:)',quantLam(in,:)');
            end
            
            discrepancy(:,oo)= sqrt( (mus-muLam).^2+(sigmas-sLam).^2+2*sigmas.*sLam.*(1-rhou) );
        
        % exact semi-discrete WSD calculation
        case 'ot'
            trunc.norm = 'true';
            trunc.U = (0:Nsamples)/Nsamples;
            [Lmean,Lvar] = uq_GLD_mean_var(lamoo,trunc);
            samples_sorted = sort(sampleoo,2);
            discrepancy(:,oo) = sqrt( mean((samples_sorted - Lmean).^2 + Lvar, 2) );
            
%             for in=1:Nl
%                 [hatcdf,y]=ecdf(sampleoo(in,:));
%                 trunc.U = hatcdf';
%                 [Lmean,Lvar] = uq_GLD_mean_var(lamoo(in,:),trunc);
%                 discrepancy(in,oo) = sqrt( ((y(2:end)' - Lmean).^2 + Lvar)*diff(hatcdf) );
%             end

    end
end



end

