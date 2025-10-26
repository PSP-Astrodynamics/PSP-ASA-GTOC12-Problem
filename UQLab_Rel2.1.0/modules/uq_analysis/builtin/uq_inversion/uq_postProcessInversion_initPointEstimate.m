function [pointEstimate, pointEstimate_flag, pointParamIn, results] = uq_postProcessInversion_initPointEstimate(input, default, results, nDim)
% helper function to initialize point estimate
%
% See also: UQ_POSTPROCESSINVERSIONMCMC, UQ_POSTPROCESSINVERSIONSSLE

% init
pointParamIn = {};

% check input
if ((ischar(input) || isnumeric(input)) && ~strcmp(input, 'false')) || iscell(input)
    pointEstimate_flag = true;    
    % take care of non cell case and place inside cell
    if ~iscell(input)
        % only single given
        pointEstimate{1} = input;
        if strcmpi(pointEstimate{1},'none')
            pointEstimate_flag = false;
            % and remove possibly existing point estimate
            if isfield(results,'PostProc')
                if isfield(results.PostProc,'PointEstimate')
                    results.PostProc = rmfield(results.PostProc,'PointEstimate');
                end
            end
        end
    else
        pointEstimate = input;
    end
    
    % loop over cell entries and check if they are supported
    for pp = 1:length(pointEstimate)
        % check value of pointEstimate
        if isnumeric(pointEstimate{pp})
            pointParamIn{pp} = pointEstimate{pp};
            pointEstimate{pp} = 'custom';
            % check size of supplied point estimate
            if size(pointParamIn{pp}) ~= nDim
                error('Supplied custom point estimate does not match the problem dimensions.')
            end
        elseif length(pointEstimate) > 1 && strcmpi(pointEstimate{pp},'none')
            error(['To remove point estimates, don''t pass ''',pointEstimate{pp},''' inside cell array'])
        elseif ~strcmpi(pointEstimate{pp},'mean') && ~strcmpi(pointEstimate{pp},'map') && ~strcmpi(pointEstimate{pp},'none')
            error(['Point estimate ''',pointEstimate{pp},''' not supported'])
        end
    end
else
    pointEstimate_flag = default.pointEstimate_flag;
    pointEstimate = default.pointEstimate;
end

end