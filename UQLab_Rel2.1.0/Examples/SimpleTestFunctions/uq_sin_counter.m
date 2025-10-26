function varargout = uq_sin_counter(X)
% UQ_SIN_COUNTER is just the sinus: Y = sin(X), 
% When called uq_sin_counter('count') it will return how many times it was called and
% if called with the syntax uq_sin_counter('reset') it will set to 0 the number of model evaluations
%
% See also: UQ_TEST_STRESS_FORMSORM, UQ_TEST_STRESS_MC

% define a global variable
persistent ModelEvalsCounter;

if isempty(ModelEvalsCounter)
    ModelEvalsCounter = 0;
end

% Check the request:
if ischar(X)
	switch X
		case 'count'	
			varargout{1} = ModelEvalsCounter;
			return

		case 'reset'
			ModelEvalsCounter = 0;
			return

		otherwise
			error('uq_sin_counter called with unknown option "%s"', X);

	end
end

%% Regular call
% If it gets to this point, it was a normal call.
% Increase the number of model evaluations and return Y = sin(X).

N = size(X, 1);

ModelEvalsCounter = ModelEvalsCounter + N;

varargout{1} = sin(X);


