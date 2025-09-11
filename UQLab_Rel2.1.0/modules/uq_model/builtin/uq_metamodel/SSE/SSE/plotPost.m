function plotPost(Handle,Conj)
%add correct distribution to plot
nDim = size(Handle,1);

for ii = 1:nDim
    %get current marginal
    VarCurr = Conj.posteriorCovariance(ii,ii);
    MeanCurr = Conj.posteriorMean(ii);
    
    %set current axis
    axes(Handle{ii,ii});
    
    %plot
    hold on
    nPoints = 100; xLimCurr = xlim;
    xDummy = linspace(xLimCurr(1),xLimCurr(2),nPoints);
    plot(xDummy, normpdf(xDummy,MeanCurr,VarCurr^0.5))
end
end

