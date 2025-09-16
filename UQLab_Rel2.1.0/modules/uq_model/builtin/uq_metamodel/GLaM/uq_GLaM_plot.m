function H = uq_GLaM_plot(GLaModel,X,outArray,varargin)
if ~GLaModel.Internal.Runtime.isCalculated
    fprintf(...
        ['GLaM object %s is not yet initialized!\n',...
        'Given Configuration Options:'],...
        GLaModel.Name);
    GLaModel.Options
    return
end

Nout = GLaModel.Internal.Runtime.Nout;
if ~exist('outArray','var')
    outArray = 1;  % By default, the first output component is plotted
    if Nout > 1
        msg = ['The selected GLaM metamodel has more than 1 output.',...
            ' Only the 1st output will be printed'];
        warning(msg)
        fprintf(...
            ['You can specify the outputs to be ',...
            'displayed with the syntax:\n'])
        fprintf(...
            ['uq_GLaM(GLaModel,X,OUTARRAY)\n',...
            'where OUTARRAY is the index of desired outputs, ',...
            'e.g. 1:3 for the first three\n\n'])
    end
end

if max(outArray) > Nout
    error('Requested output range is too large!')
end
%% Parse the residual input arguments
xprovided = false;
if ~isempty(varargin) && isnumeric(varargin{1})
    xplot = varargin{1};
    varargin{1}=[];
    xprovided = true;
end

if ~isempty(varargin)
    parse_keys = {'pdf','cdf','quantile','nolegend'};
    parse_types = {'f','f','f','f'};
    [uq_cline,~] = uq_simple_parser(varargin, parse_keys, parse_types);
    
    plotpdf =  strcmp(uq_cline{1},'true');
    plotcdf =  strcmp(uq_cline{2},'true');
    plotquantile = strcmp(uq_cline{3},'true');
    noLegend = strcmp(uq_cline{4},'true');
else
    plotpdf = true;
    plotcdf = false;
    plotquantile = false;
    noLegend = false;
end

%%
H = {};
lambda = uq_GLaM_evalLambda(GLaModel,X);
N = size(X,1);
linewidth = 1.5;

for oo = 1:length(outArray)
    currentOutput = outArray(oo);
    lamoo =  permute(lambda(:,currentOutput,:),[1,3,2]);
    legendHandles = [];
    pFormat = repmat('%1.2f,',1,size(X,2));
    pFormat(end)=[];
    pFormat=['$X=(',pFormat,')$'];
    validTxt = false;
    % plot PDF
    if plotpdf
        H{end+1}=uq_figure('name',sprintf('Output #%i (PDF)',currentOutput));
        legendTxt=cell(1,N);        
        hold on
        for ix = 1:N
            if xprovided
                yplot=uq_GLD_DistributionFunc(lamoo(ix,:),'pdf',xplot);
            else
                [yplot,xplot]=uq_GLD_DistributionFunc(lamoo(ix,:),'pdf');
            end
            h=uq_plot(xplot,yplot,'LineWidth',linewidth);
            legendHandles = [legendHandles;h(:)];
            legendTxt{ix}=sprintf(pFormat,X(ix,:));
        end
        hold off
        if ~noLegend
            uq_legend(legendHandles,legendTxt)
        end
        validTxt = true;
    end
    
    % plot cdf
    legendHandles = [];
    if plotcdf
        H{end+1}=uq_figure('name',sprintf('Output #%i (CDF)',currentOutput));
        if ~validTxt
            legendTxt=cell(1,N);
        end
        hold on
        for ix = 1:N
            if xprovided
                yplot=uq_GLD_DistributionFunc(lamoo(ix,:),'cdf',xplot);
            else
                [yplot,xplot]=uq_GLD_DistributionFunc(lamoo(ix,:),'cdf');
            end
            h=uq_plot(xplot,yplot,'LineWidth',linewidth);
            legendHandles = [legendHandles;h(:)];
            if ~validTxt
                legendTxt{ix}=sprintf(pFormat,X(ix,:));
            end
        end
        hold off
        if ~noLegend
            uq_legend(legendHandles,legendTxt)
        end
        validTxt = true;
    end
    
    legendHandles = [];
    if plotquantile
        H{end+1}=uq_figure('name',sprintf('Output #%i (quantile)',currentOutput));
        if ~validTxt
            legendTxt=cell(1,N);
        end
        hold on
        for ix = 1:N
            if xprovided
                yplot=uq_GLD_DistributionFunc(lamoo(ix,:),'quantile',xplot);
            else
                [yplot,xplot]=uq_GLD_DistributionFunc(lamoo(ix,:),'quantile');
            end
            h=uq_plot(xplot,yplot,'LineWidth',linewidth);
            legendHandles = [legendHandles;h(:)];
            if ~validTxt
                legendTxt{ix}=sprintf(pFormat,X(ix,:));
            end
        end
        hold off
        if ~noLegend
            uq_legend(legendHandles,legendTxt)
        end
    end
end
end

