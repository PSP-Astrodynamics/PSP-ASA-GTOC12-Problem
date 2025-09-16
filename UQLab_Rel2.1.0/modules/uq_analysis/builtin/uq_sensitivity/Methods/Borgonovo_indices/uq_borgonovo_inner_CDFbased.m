function result = uq_borgonovo_inner_CDFbased(y0,y_cond0,subids,Y,Xi,y_smooth,ecdf_y)
% results = UQ_BORGONOVO_INNER_CDFBASED(y,y_cond)
%   Performs CDF based integration of the abs(y-y_cond) with the method
%   described in
%     
%   Qiao Liu, Toshimitsu Homma (2009) - "A new computational method of a 
%      moment-independent uncertainty importance measure"
%   
%   The y and y_cond values for the initial implementation, are assumed to 
%   be frequencies of realizations of y and y|xi in uniformly spaced bins.

% Retrieve the empirical CDF of y:
y_cdf = ecdf_y.y_cdf;
y_cdf_x = ecdf_y.y_cdf_x;
if isempty(subids)
    % An empty sub-index means that the user discretized the Xi dimension
    % badly. Return a warning about that!
    warning('An empty class was encountered! This is an indication that you should use a smaller number classes (C_m).');
    result = 0;
    return;
end
% conditional
[y_cond_cdf, y_cond_x] = ecdf(Y(subids));

% Smooth the density of the conditional:
[y_cond] = ksdensity(Y(subids),y_cdf_x);
y = y_smooth.y;
% The y-points where we estimate the density.
xi = y_cdf_x;

% find zero crossings:
y_crossings = uq_zerocrossings(y-y_cond);

Fi_cond = zeros(length(y_crossings),1);
Fi_ucond = zeros(length(y_crossings),1);

% Get the CDF values of the conditional and unconditional distributions at
% the crossing points
for kk=1:length(y_crossings)
    % Find the index of the crossing in the empirical CDF:
    ycdfcond_idx = find(y_cond_x>=xi(round(y_crossings(kk))));
    ycdf_idx = find(y_cdf_x>=xi(round(y_crossings(kk))));
    % If the PDF of the sub-sample (conditional) does not overlap with the
    % PDF of the un-conditional, then we know that Fi_cond = 1:
    if isempty(ycdfcond_idx)
        Fi_cond(kk) = 1;
    else
        Fi_cond(kk) = y_cond_cdf(ycdfcond_idx(1));
    end
    Fi_ucond(kk) = y_cdf(ycdf_idx(1));
end    


% Get the CDF differences at these points
Delta = (-Fi_ucond+Fi_cond);
% And set the first element to be positive
if Delta(1)<0
    Delta = -1.*Delta;
end

% Calculate formula (1.61) (summation after Homma)

switch length(Delta)
    case 1
        d_i = abs(2*Delta(1));
    otherwise
        % Multiply with alternating +/-1
        Delta = Delta .* ((-1).^(0:(length(Delta)-1)))';
        
        % Sum the terms and multiply by 2
        d_i = 2*(sum(Delta(1:end)));
end

% DDelta = diff(Delta);
% 
% switch length(Delta)
%     case 1
%         d_i = abs(2*Delta(1));
%     otherwise
%         try
% 	       DDelta = DDelta .* ((-1).^(0:(length(DDelta)-1)))';
%         catch 
%             disp('oops!')
%         end
%         d_i = 2*(sum(DDelta(1:end)));
% end

result = abs(d_i);