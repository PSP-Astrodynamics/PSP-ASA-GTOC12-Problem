function [lopoverlam,CandInd]=uq_GLaM_stepwise_getLambdaAndIndices(lambda,StatVal,statThre,startIndices,sortMethod)

% initialize the output lambda
lopoverlam=[];

% initialize the indices of the candidate basis
CandInd=cell(1,4);

for ii=lambda
    switch(lower(sortMethod))
        case 'descend'
            CandInd{ii}=find(StatVal{ii}(startIndices(ii):end)>statThre);
        case 'ascend'
            CandInd{ii}=find(StatVal{ii}(startIndices(ii):end)<statThre);
        otherwise
            error('Unrecognized sort method');
    end
    if ~isempty(CandInd{ii})
        CandInd{ii}=CandInd{ii}+startIndices(ii)-1;
        [~,temp] = sort(StatVal{ii}(CandInd{ii}),sortMethod);
        CandInd{ii} = CandInd{ii}(temp);
        lopoverlam=[lopoverlam,ii];
    end
end
nlam=length(lopoverlam);
mm=zeros(1,nlam);
for ii=1:nlam
    mm(ii)= StatVal{lopoverlam(ii)}(CandInd{lopoverlam(ii)}(1));
end
[~,temp] = sort(mm,sortMethod);
lopoverlam = lopoverlam(temp);
end