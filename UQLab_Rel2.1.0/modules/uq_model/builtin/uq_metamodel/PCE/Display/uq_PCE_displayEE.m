function uq_PCE_displayEE(myPCE, Order, CurOutput)
% UQ_PCE_DISPLAYEE(PCEMODEL,ORDER,CURRENT_OUTPUT): plot the elementary effects
%      for the specified PCEMODEL, up to interaction order ORDER for the
%      output component CURRENT_OUTPUT.


%% Command line parsing
% default to first order
if nargin < 2
    Order = 1;
end
% default to 1st output
if nargin < 3
    CurOutput = 1;
end

if length(CurOutput) > 1
    error('uq_PCE_displayEE only works for a single output conponent at a time');
end

alpha = 0.1;

if Order > 2
    error('uq_PCE_displayEE can only display elementary effects up to order 2');
end


%% Create the EEPCE
myEEPCE = uq_PCE_createEEPCE(myPCE, Order, CurOutput);

%% Collect all the necessary info for plotting
% Input: will be used to create the grids
myInput = myEEPCE.Internal.Input;

% Variable names: will be used to properly name the plots
VarNames = myEEPCE.Internal.VarNames;
VarIdx = myEEPCE.Internal.VarIdx;


%% Find plotting limits based on the input distributions
Marginals = myInput.Marginals;
M = length(Marginals);
bounds = nan(2,M);
% Substitute the infinite bounds with the 95% interquantile range
for ii = 1:M
    bounds(1,ii) = uq_all_invcdf(0,Marginals(ii));
    if isinf(bounds(1,ii))
        bounds(1,ii) = uq_all_invcdf(alpha/2,Marginals(ii));
    end
    bounds(2,ii) = uq_all_invcdf(1,Marginals(ii));
    if isinf(bounds(2,ii))
        bounds(2,ii) = uq_all_invcdf(1-alpha/2,Marginals(ii));
    end
end

%% Now create the necessary plots and model evaluations
% note: this works only in 1 or 2 dimensions
switch Order
    case 1
        NGrid = 10000;
        % create a 2x(ceil(M/2)) array of 1-dim subplots
        D = ceil(M/2);
        X = zeros(NGrid,M);
        for ii = 1:M
            X(:,ii) = sort(X(:,ii));
        end
        X = uq_getSample(myInput,NGrid,'Sobol');
        % evaluate the effects
        Y = uq_evalModel(myEEPCE,X);
        
        % set common Y axis limits to see relative importance
        yLimits = [min(Y(:)) max(Y(:))];

        % Now plot them
        for ii = 1:M
            %subplot(D,2,ii);
            fname = sprintf('ElementaryEffect_%i',ii);
            uq_figure('Name',fname,'filename',fname)
            uq_plot(X(:,ii),Y(:,ii),'.');
            xlabel(sprintf('$%s$',VarNames{ii}));
            ylabel(sprintf('$M_{%s}$',VarNames{ii}));
            axis tight
            ylim(yLimits);
        end
        
    case 2
        NGrid = 100;
        VarIdx = myEEPCE.Internal.VarIdx;
        NZ = size(VarIdx,1);
        Mbounds = mean(bounds);
        f = uq_figure; 
        D = ceil(NZ/2);
        
        for ii = 1:NZ
            % create a mesh for plotting
            x1 = linspace(bounds(1,VarIdx(ii,1)),bounds(2,VarIdx(ii,1)),NGrid);
            x2 = linspace(bounds(1,VarIdx(ii,2)),bounds(2,VarIdx(ii,2)),NGrid);
            [xx1, xx2] = meshgrid(x1,x2);
            % assemble the mesh in a useful vector. Set all the other
            % values to the midpoint between bounds
            X = repmat(Mbounds, numel(xx1),1);
            X(:,VarIdx(ii,:)) = [xx1(:) xx2(:)];
            % Now get the response of the elementary effects
            Y = uq_evalModel(myEEPCE, X);
            % and reshape stuff back for plotting
            yy = reshape(Y(:,ii), size(xx1));
            
            % And finally plot
            subplot(2,D,ii);
            surf(xx1,xx2,yy);
            shading interp
            axis tight
            
            xlabel(VarNames{VarIdx(ii,1)});
            ylabel(VarNames{VarIdx(ii,2)});
            zlabel(sprintf('$M_{%s%s}$', VarNames{VarIdx(ii,1)},VarNames{VarIdx(ii,2)}));
        end
end