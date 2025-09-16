function H = uq_subsetsim_display( module, idx, varargin )
% UQ_SUBSETSIM_DISPLAY visualizes the analysis and results of subset
% simulation
% 
% See also: UQ_DISPLAY_UQ_RELIABILITY

% initialize figure handle container
H = {};

%check whether the model evaluations were stored
if module.Internal.SaveEvaluations
    
    %for each index
    for oo = idx
        if length(idx) > 1
            figTitle = sprintf('SubsetSim: Samples in each subset, output #%d', oo);
        else
            figTitle = 'SubsetSim: Samples in each subset';
        end           
        %display the samples of each subset in 1- and 2-dimensional cases
        switch length(module.Internal.Input.Marginals)
            % Scatter plots of the subset sample for 2-dimensional problems
            case 2
                H{end+1} = uq_figure('Name', figTitle);
                hold on
                ax = gca;
                uq_formatDefaultAxes(ax)
                % NOTE: 'hold on' command in R2014a does not cycle through
                % the color order so it must be set manually. 
                colorOrder = get(ax,'ColorOrder');
                for ii = 1:length(module.Results.History(oo).q)
                    % Cycle through color but periodically reset
                    % when the maximum number of colors is reached.
                    jj = max(mod(ii, size(colorOrder,1)), 1);
                    uq_plot(...
                        module.Results.History(oo).X{ii}(:,1),...
                        module.Results.History(oo).X{ii}(:,2),...
                        'o',...
                        'MarkerSize', 3,...
                        'MarkerFaceColor', colorOrder(jj,:),...
                        'Color', colorOrder(jj,:))
                end
                hold off
                % Set axes labels and title
                xlabel('$\mathrm x_1$') 
                ylabel('$\mathrm x_2$')
                title('\textrm SubsetSim - Samples in each subset')
                
            % Plot the subsets in a histogram for 1-dimensional problems
            case 1
                H{end+1} = uq_figure('Name', figTitle);
                X = cell2mat(module.Results.History(oo).X);
                for ii=1:size(X,2)
                     subsetText = sprintf("Subset %d",ii);
                     uq_histogram(X(:,ii),'normalized',false,'DisplayName',subsetText), hold on
                end      
                hold off
                xlabel('$\mathrm x$')
                title('SubsetSim - Samples in each subset')
                if size(X,2) > 1 && size(X,2) < 15
                    uq_legend
                elseif size(X,2) >= 15
                    warning("Legend not displayed because the number of subsets is too large.")
                else 
                    % no need to display legend for 1 subset only
                end
            otherwise
                %plot nothing for more than 2 dimensions
                
         end % switch dimensions
        
    end % for oo
    
end %if model evaluations
