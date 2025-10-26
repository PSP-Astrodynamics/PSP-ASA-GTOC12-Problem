function success = uq_setDefaultSampling( varargin )
% UQ_SET_DEFAULT_SAMPLING sets the default sampling method for the given or
% currently selected input object
%
% uq_setDefaultSampling(SAMPLING) sets the default sampling method of the
% currently selected input object to SAMPLING
%
% uq_setDefaultSampling(INPUT, SAMPLING) sets the default sampling method of the
% INPUT object to SAMPLING

success = 0;
switch length(varargin)
    case 1 
        %the sampling method is only given
        sampling = varargin{1};
        current_input = uq_getInput;
    case 2 
        %the input object and the sampling method are given 
        current_input = uq_getInput(varargin{1});
        sampling = varargin{2};
    otherwise
        error('Error: The number of inputs given to uq_setDefaultSampling are incorrect!')
end
    
current_input.Sampling.DefaultMethod = sampling; 
success = 1;



