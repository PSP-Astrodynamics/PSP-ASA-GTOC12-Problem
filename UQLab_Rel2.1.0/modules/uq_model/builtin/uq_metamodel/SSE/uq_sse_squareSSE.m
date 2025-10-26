function obj = uq_sse_squareSSE(obj)
%UQ_SSE_SQUARESSE transforms SSE to its square and recomputes all involved
% polynomials

% retrieve PCEs
FlPCEs = obj.FlatPCEs;

% loop over PCEs and square
parfor ii = 1:length(FlPCEs)
     uqlab 
    currPCE = FlPCEs(ii);
    
    % square project
    FlPCEs(ii) = squareSSE(currPCE);
end

obj.FlatPCEs = FlPCEs;
end


%% UTILITY
function newPCE = squareSSE(currPCE)
% check if curr PCE has nonzero coefficients
if all(currPCE.PCE.Coefficients == 0)
    % just use old PCE
    newPCE = currPCE;
else
    % square and project
    [BASIS,COEFFICIENTS] = efficientSquareRegression(currPCE);
    % prepare mergedPCEOpts
    mergedPCEOpts.Input = currPCE.Internal.Input;
    mergedPCEOpts.PCE.Basis.PolyTypes = currPCE.PCE.Basis.PolyTypes;

    % Create new predictor with BASIS and COEFFICIENTS
    mergedPCEOpts.Type = 'Metamodel';
    mergedPCEOpts.MetaType = 'PCE';
    mergedPCEOpts.Method = 'Custom';

    % assign BASIS and COEFFICIENTS
    mergedPCEOpts.PCE.Basis.Indices = BASIS;
    mergedPCEOpts.PCE.Coefficients = COEFFICIENTS;

    % create mergedPCE
    newPCE = uq_createModel(mergedPCEOpts,'-private');
end
end

function [BASIS,COEFFICIENTS] = efficientSquareRegression(origPCE)
% efficient projection for PCEs with sparse interaction
% init
metaOptsCurr.Type = 'Metamodel';
metaOptsCurr.MetaType = 'PCE';
metaOptsCurr.Method = 'OLS';% Quadrature
metaOptsCurr.Display = 0; %turn off diplay

% get parent basis
relevIDs = abs(origPCE.PCE.Coefficients) > 0;
origBasis = origPCE.PCE.Basis.Indices(relevIDs,:);
origCoeffs = origPCE.PCE.Coefficients(relevIDs,:);

% init BASIS and COEFFICIENTS
BASIS = [];
COEFFICIENTS = [];

% precompute arbitrary basis for performance
maxDegree = 23;%max(max(origBasis))*2; % times 2 because we will square the polynomials
for ii = 1:size(origBasis,2)
    % check if current marginal is arbitrary
    if strcmpi(origPCE.PCE.Basis.PolyTypes,'arbitrary')
        % if arbitrary
        PrecompBasis.PolyTypes{ii} = 'arbitraryPrecomp';
        % get marginal and precompute
        MarginalCurr = origPCE.Internal.Input.Marginals(ii);
        [PrecompBasis.PolyTypesAB{ii}, PrecompBasis.PolyCustom{ii}] = ...
            uq_PCE_initialize_arbitrary_basis(MarginalCurr,'stieltjes','polynomials',maxDegree+1);
    else
        % not arbitrary
        PrecompBasis.PolyTypes{ii} = origPCE.PCE.Basis.PolyTypes{ii};
        PrecompBasis.PolyTypesAB{ii} = origPCE.PCE.Basis.PolyTypesAB{ii};
        PrecompBasis.PolyCustom{ii} = [];
    end
end

% reorganize basis functions into sets of basis functions with same
% non-zero elements
zeroBasis = origBasis == 0;
[~,~,id] = unique(zeroBasis,'rows'); % find identical rows

% loop over basis rows
for ii = 1:max(id)
    for jj = ii:max(id) % start loop at ii
        % get first and second subBasis
        firstBases = origBasis(id == ii,:);
        firstCoeff = origCoeffs(id == ii);
        secondBases = origBasis(id == jj,:);
        secondCoeff = origCoeffs(id == jj);
        
        % get curr subBasis
        maxBasis = max(firstBases,[],1) + max(secondBases,[],1);
        nonConst = maxBasis > 0;
        % non const id
        nonConstId = find(nonConst);
        maxBasis = maxBasis(1,nonConst);
        
        % check if all nonConst
        if any(nonConst)
            % at least one basis is non-constant
            % create dummy PCE input
            rowPCEInputOpts.Marginals = origPCE.Internal.Input.Options.Marginals(nonConst);
            rowPCEInput = uq_createInput(rowPCEInputOpts,'-private');

            % create dummy PCEs 
            firstRowPCE = createRowPCE(rowPCEInput, nonConst, PrecompBasis, firstBases, firstCoeff);
            secondRowPCE = createRowPCE(rowPCEInput, nonConst, PrecompBasis, secondBases, secondCoeff);
            % take product
            modelOpts.mHandle = @(x) uq_evalModel(firstRowPCE,x).*uq_evalModel(secondRowPCE,x);
            productPCE = uq_createModel(modelOpts,'-private');
            
            % create custom basis
            maxDegreeCurr = sum(maxBasis);
            custBasis = uq_generate_basis_Apmj(0:maxDegreeCurr, sum(nonConst));
            % get relevant IDs and reduce basis
            relevIDs = all(custBasis <= maxBasis,2);
            custBasis = custBasis(relevIDs,:);
            
            % recompute by taking product of the two row PCEs
            metaOptsCurr.Input = rowPCEInput;
            metaOptsCurr.Degree = max(sum(custBasis,2)); % ATTENTION, use sum
            metaOptsCurr.TruncOptions.Custom = custBasis;
            metaOptsCurr.FullModel = productPCE;
            for kk = 1:sum(nonConst)
                metaOptsCurr.PolyTypesAB{kk} = PrecompBasis.PolyTypesAB{nonConstId(kk)};
                metaOptsCurr.PolyCustom{kk} = PrecompBasis.PolyCustom{nonConstId(kk)};
            end
            metaOptsCurr.PolyTypes = PrecompBasis.PolyTypes(nonConst);
            
            % adaptively increase sample size until error threshold is met
            X = uq_getSample(rowPCEInput,1e4);
            Yold = uq_evalModel(productPCE,X);
            nIncrease = 100; errorThresh = 0.01;
            for mm = 1:nIncrease
                % increase sample size
                % set size of experimental design
                metaOptsCurr.ExpDesign.NSamples = size(custBasis,1)*mm;
                
                % project new PCE
                newPCE = uq_createModel(metaOptsCurr,'-private');

                % verify accuracy
                Ynew = uq_evalModel(newPCE,X);
                currError = mean((Yold-Ynew).^2)/var(Yold);

                if currError < errorThresh
                    % assign to obj
                    myRowPCE = newPCE;   
                    break
                end
            end
            
            % warn
            if mm == nIncrease
                warning('Could not find suitable squared representation below specified error threshold!')
            end
            
            % store resulting 
            relevIDs = abs(myRowPCE.PCE.Coefficients) > 0;
            squaredCoefficients = myRowPCE.PCE.Coefficients(relevIDs);
            squaredBasis = myRowPCE.PCE.Basis.Indices(relevIDs,:);
            squaredBasis_full = zeros(size(squaredBasis,1),size(firstBases,2));
            squaredBasis_full(:,nonConst) = squaredBasis;

            % sort basis
            [squaredBasis_full, idSort] = sortrows(squaredBasis_full);
            squaredCoefficients = squaredCoefficients(idSort);
        else
            % all bases are constant - just analytically compute square
            squaredBasis_full = zeros(1,size(firstBases,2));
            squaredCoefficients = firstCoeff*secondCoeff;
        end
        
        % double if jj > ii to avoid double looping
        if jj > ii
            squaredCoefficients = squaredCoefficients*2;
        end

        % check if basis exists and extend or add
        if ~isempty(BASIS)
            % BASIS is not empty
            matchedIndices_full = ismember(BASIS,squaredBasis_full,'rows');
            matchedIndices_child = ismember(squaredBasis_full,BASIS,'rows');

            % add existing basis coefficients
            COEFFICIENTS(matchedIndices_full) = ...
                COEFFICIENTS(matchedIndices_full) + squaredCoefficients(matchedIndices_child);

            % create new basis entries for non-existing bases
            BASIS = [BASIS; squaredBasis_full(~matchedIndices_child,:)];
            COEFFICIENTS = [COEFFICIENTS; squaredCoefficients(~matchedIndices_child)];

            % sort
            [BASIS, idSort] = sortrows(BASIS);
            COEFFICIENTS = COEFFICIENTS(idSort);
        else
            % BASIS is empty - use child
            BASIS = squaredBasis_full;
            COEFFICIENTS = squaredCoefficients;
        end
    end
end
end

function myRowPCE = createRowPCE(rowPCEInput,nonConst,PrecompBasis, currBases, currCoeffs)
% init dummy PCE
rowPCEOpts.Type = 'Metamodel';
rowPCEOpts.MetaType = 'PCE';
rowPCEOpts.Method = 'Custom';

% assign input
rowPCEOpts.Input = rowPCEInput;

% non const id
nonConstId = find(nonConst);

% create row PCE
for kk = 1:sum(nonConst)
    rowPCEOpts.PolyTypesAB{kk} = PrecompBasis.PolyTypesAB{nonConstId(kk)};
    rowPCEOpts.PolyCustom{kk} = PrecompBasis.PolyCustom{nonConstId(kk)};
end
rowPCEOpts.PCE.Basis.PolyTypes = PrecompBasis.PolyTypes(nonConst);
rowPCEOpts.PCE.Basis.Indices = currBases(:,nonConst);
rowPCEOpts.PCE.Coefficients = currCoeffs;
myRowPCE = uq_createModel(rowPCEOpts,'-private');
end