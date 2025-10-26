function Y = uq_sin_outputs_counter(X, module)
% UQ_SIN_OUTPUTS_COUNTER works in the same way as uq_sin_counter, but it has three outputs:
% The three response variables are:
% y1 = sin(X), 
% y2 = X + 0.5,
% y3 = sin(X).
%
% See also: UQ_TEST_RELIABILITY_MANY_OUTPUTS

persistent ModelEvalsCounterOutputs;

if isempty(ModelEvalsCounterOutputs)
    ModelEvalsCounterOutputs = 0;
end

% Check the request:
if ischar(X)
	switch X
		case 'count'	
			varargout{1} = ModelEvalsCounterOutputs;
			return

		case 'reset'
			ModelEvalsCounterOutputs = 0;
			return

		otherwise
			error('uq_sin_outputs_counter called with unknown option "%s"', X);

	end
end

%% Regular call
% If it gets to this point, it was a normal call.
% Increase the number of model evaluations and return Y = sin(X).

N = size(X, 1);

ModelEvalsCounterOutputs = ModelEvalsCounterOutputs + N;

Y(:, 1) = sin(X);
Y(:, 2) = X + 0.5;
Y(:, 3) = sin(X);

varargout{1} = Y;