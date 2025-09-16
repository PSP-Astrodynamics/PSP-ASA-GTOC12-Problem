function pass = uq_randomfield_test_cov_convergence( level )
% PASS = uq_RF_exponential_1D: test for 1D gaussian analytical function
% .



eps = 1e-12;
RFMethods = {'EOLE'};
% Initialize test:
pass = 1;
evalc('uqlab');


%% INPUT
% values taken from the default phimecasoft example
% Define the RFINPUT model.
RFInput.Type = 'RandomField';
RFInput.RFType = 'Gaussian';
RFInput.DiscScheme = 'EOLE' ;
RFInput.Mesh = linspace(0,10,200)';

RFInput.Corr.Family = 'exponential';
RFInput.Corr.Length = 2 ;

RFInput.Mean = 1 ;
RFInput.Std = 1 ;

N = [20 50 75 100 200 300 400];
P = [5 10 20 30 50 60];

err = NaN*ones(length(N),length(P)) ;
%% RF module
for ii = 1 : length(N)
    for jj = 1:length(P)
        
        RFInput.EOLE.CovMesh = linspace(0,10,N(ii))';

        RFInput.ExpOrder = P(jj) ;
        
        if P(jj) < N(ii)
            evalc('myRF = uq_createInput(RFInput)');
            
            X = uq_getSample(1e4) ;
            
            estimated_cov = cov(X);
            
            CorrOptions = myRF.Internal.Corr ;
            analytical_cov = RFInput.Std.^2 ...
                * uq_eval_Kernel(RFInput.Mesh,RFInput.Mesh,RFInput.Corr.Length,CorrOptions) ;
%             figure; imagesc(analytical_cov - estimated_cov); colorbar
            matN(ii,jj) = N(ii);
            matP(ii,jj) = P(jj) ;
            err(ii,jj) = max(max(analytical_cov - estimated_cov)) ;            
        end
        
    end
    
end


figure(1) ;
imagesc(err,'AlphaData',~isnan(err)) ;
colorbar ;
x = get(gca,'XLim') ;
h = range(x)/length(P) ;
x = linspace(x(1),x(end),length(P)+1)  ;
x = x + h/2 ; 
set(gca, 'XTick', x(1:end-1));
set(gca, 'XTickLabel', P);

y = get(gca,'YLim') ;
h = range(y)/length(P) ;
y = linspace(y(1),y(end),length(N)+1) ;
y = y + h/2 ; 
set(gca, 'YTick', y(1:end-1));
set(gca, 'YTickLabel', N);

set(gca, 'FontName' ,'Calibri',  'FontSize', 18);
xlabel ('$P$','interpreter','latex')
ylabel ('$N$','interpreter','latex')
close(figure(1)) ;
end
