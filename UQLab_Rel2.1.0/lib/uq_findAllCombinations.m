function Res = uq_findAllCombinations(varargin)
%
% Find all the combinations of the features we want to try
% We have to execute these two commands:
% Cmd1:
% [X1, ..., XN] = ndgrid(1:length(varargin{1}), ..., 1:length(varargin{N}));

% Cmd2:
% Res = [X1(:), ..., XN(:)];

N = length(varargin);


if N == 1 % In this case, there is nothing to combine!
	Res = 1:length(varargin{1})';
	return
end


% Generate Cmd1:
Cmd1Left = ['[', sprintf('X%i, ', 1:N)];
Cmd1Left(end - 1:end) = '] ';

Cmd1Right = [' ndgrid(', sprintf('1:length(varargin{%i}), ', 1:N)];
Cmd1Right(end - 1:end) = ');';

Cmd1 = [Cmd1Left, '=', Cmd1Right];

% Generate Cmd2:
Cmd2 = ['[', sprintf('X%i(:), ', 1:N)];
Cmd2(end - 1:end) = '];';

% Evaluate the commands:
eval(Cmd1);
Res = eval(Cmd2);