function [delta_i,joint_pdf,class_prob_tot] = uq_borgonovo_index(X,Y,Options)
% [DELTA_I,JOINT_PDF,CLASS_PROB_TOT] = UQ_BORGONOVO_INDEX(X,Y,OPTIONS)
% calculates the Borgonovo index DELTA_I of input X_i (= X(:,i)). The
% function also returns the joint PDF values in JOINT_PDF and the
% probability of X_i falling into one of its classes CLASS_PROB_TOT.
%
% See also: UQ_BORGONOVO_INDICES


%% Initialization
% The input variable for which we will calculate the index
vvar = Options.variable;

% The values of Xi are also the integration points for the outer integral
% for delta_i:
Xi = X(:,vvar);

% Available samples
N = length(Y);


%% Create function handles for inner integration
% Create the inner integration function based on the chosen method
switch Options.Method
    case 'cdfbased'
        % In this case, we create a function handle, that accepts the
        % conditional and the unconditional CDF, finds their
        % zero-crossings, and computes the inner integral using the
        % formulas in Liu & Homma (2009).
        
        % The empirical CDF of the unconditional:
        [ecdf_y.y_cdf , ecdf_y.y_cdf_x] = ecdf(Y);
        
        % A kernel  smoother estimate of the un-conditional PDF at all the
        % points:
        [smooth_y.y] = ksdensity(Y,ecdf_y.y_cdf_x);
        
        % The "inner_integration" function handle will be used to compute
        % the conditionals. The points used for the conditional are simply
        % the points defined by the indices "subids".
        inner_integration = @(y1,y2,subids) uq_borgonovo_inner_CDFbased(y1,y2,subids,Y,Xi,smooth_y,ecdf_y);
    case 'histbased'
        % In case it's 'histbased' we just subtract the values  of the
        % hists from each other
        inner_integration = @(y1,y2,subids) sum(abs(y1-y2));
end

% Decide how to calculate the probability of Xi being in a certain class:
if ~isfield(Options,'XMarginal')
    % In the absence of information on the Marginals:
    expectation_eval = @(xi_inds) sum(xi_inds)/N;
else
    % When Marginals are available:
    marginal = Options.XMarginal;
    expectation_eval = @(xi_inds) uq_all_cdf(max(Xi(xi_inds)),marginal)-...
        uq_all_cdf(min(Xi(xi_inds)),marginal);
end


%% Managing computational options

nbins_x = Options.nbins_x;
h_overlap = Options.h_overlap;

% Calculate the amount of samples per class without overlap.
h = round(N/nbins_x);

% Calculate the amount of samples per class with overlap
s = round(h*(1-h_overlap));
% And make sure it's smaller than the bin width
if s > h
    fprintf('\n\nError: s > h - samples would have been skipped! Please specify some window\n step size ''s'' that is lower than h!\n');
    error('While managing the computational options')
end

%% Estimate the pdf of Y with a simple histogram

uncond_hist_vals = cell(1,nbins_x);
if isnumeric(Options.nbins_y)
    [uncond_hist_vals_onevalue,edges_pdf] = ...
        uq_histcounts(Y,Options.nbins_y,'Normalization','probability');
    uncond_hist_vals = cell(1,nbins_x);
    for cclass = 1:nbins_x
        uncond_hist_vals{cclass} = uncond_hist_vals_onevalue;
    end
else
    % it will have to be set separately for each class. This happens after
    % the conditional binning, value: 'auto'
end

%% Calculate the classes (edges) for different binning strategies and overlap

class_edges = uq_binSamples(Xi, nbins_x, Options.BinStrat, h_overlap);

if h_overlap ~= 0
    class_edges_low = class_edges(:,1);
    class_edges_up = class_edges(:,2);
end


%% Go through the classes
% Determine which samples belong to each class, and get the
% conditional histogram values and the probability of Xi being
% in this class
class_samples_idx = cell(1,nbins_x);
Xi_class = cell(1,nbins_x);
cond_hist_vals = cell(1,nbins_x);
class_prob_tot = zeros(1,nbins_x);
Y_lim = [min(Y),max(Y)];


for cclass = 1:nbins_x
    clear class_tot_hist_edges;
        
    % Get the classes
    % Find the indices of the Xi that belong to the bin:
    if h_overlap == 0 % no overlap
        class_samples_idx{cclass} = (Xi>=class_edges(cclass))&(Xi<class_edges(cclass+1));
    else % with overlap
        class_samples_idx{cclass} = (Xi>=class_edges_low(cclass))&(Xi<class_edges_up(cclass));
    end
    if sum(class_samples_idx{cclass}) == 0
        continue;
    end
    
    % Calculate the probability of Xi being in this class
    class_prob_tot(cclass) = expectation_eval(class_samples_idx{cclass});    
    
    % The samples of Xi that are in each class
    Xi_class{cclass} = Xi(class_samples_idx{cclass});
    % Select the values of corresponding responses. These are Y|X_i
    Yi_class = Y(class_samples_idx{cclass});
    
    % Get the conditional histogram values
    if isnumeric(Options.nbins_y) % with the given amount of bins
        cond_hist_vals{cclass} = uq_histcounts(Yi_class,edges_pdf,'Normalization','probability');
    
    elseif strcmpi(Options.nbins_y,'auto') % with edges that make sense for the amount of samples in the class
        [cond_hist_vals{cclass},classbinedges] = uq_histcounts(Yi_class,'BinLimits',Y_lim,'Normalization','probability');
        uncond_hist_vals{cclass} = uq_histcounts(Y,classbinedges,'Normalization','probability');        
    end
        
end

%% Build cond histogram matrix for pcolor in display if nbins_y wasn't set

% In case there is no .nbins_y provided, the conditional histograms might
% have different amounts of bins (resulting in cells of different lengths).
% In order to plot, they need the same length: here we choose the minimum
% amount of bins any cond histogram has and use that for every class.
if ~isnumeric(Options.nbins_y)
    nx = nbins_x;
    % Get the amount of bins of each conditional histograms (cellfun enters
    % each cell of cond_hist_vals)
    ylengths = cellfun(@(x) length(x), cond_hist_vals);
    % And get the longest
    ny = min(ylengths);
    % limit it to 100 to make it look nice
    if ny>100
        ny=100;
    end
    if nx>100
        nx=100;
    end
    joint_pdf = zeros(nx,ny);
    
    % Get the edges
    [~,edges] = uq_histcounts(Y,ny,'Normalization','probability');
    % make histograms of each class with these edges
    for cclass = 1:nx
        % Select the values of corresponding responses. These are Y|X_i
        Yi_class = Y(class_samples_idx{cclass});
        joint_pdf(cclass,:) = uq_histcounts(Yi_class,edges,'Normalization','probability');
    end
else
    joint_pdf = vertcat(cond_hist_vals{:});
end

%% Results assignment

% In case we have overlap, the class_prob is incorrect, since we count some
% samples twice. Correct by dividing by the total amount of used samples:
if h_overlap ~= 0
    % Total amount of used samples
    N_tot_used_samples = sum(cellfun(@(x) numel(x), Xi_class)); % sum up the amount of values in each cell of Xi_class
    % Correction
    class_prob_tot = class_prob_tot.*N./N_tot_used_samples;
end

% Now calculate the inner integral of each class and multiply
% by its normalized probability
sigmas = zeros(nbins_x,1);
for cclass=1:nbins_x
    innerint = inner_integration(cond_hist_vals{cclass},uncond_hist_vals{cclass},class_samples_idx{cclass});
    % compute the product of the prob. of x_i falling into that class times
    % the classes value (=integral)
    sigmas(cclass) = class_prob_tot(cclass)*innerint;
end

% Sum the terms --> E[...] and multiply by 0.5 to get BORGONOVOS DELTA
delta_i = 0.5*sum(sigmas);

end
