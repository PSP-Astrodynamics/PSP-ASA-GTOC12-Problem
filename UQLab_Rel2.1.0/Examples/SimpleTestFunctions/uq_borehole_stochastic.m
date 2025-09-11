function Y = uq_borehole_stochastic(X,R)
% Y = uq_borehole_stochastic(X) returns the value of the water flow Y through a
% borehole, described by 8 variables: rw, r, Tu, Hu, Tl, Hl, L, Kw, which
% are divided into two groups based on their nature
%
% The values of the first set can be accessed: X = [rw, Hu, Kw]
% rw 	-	radius of borehole (m)
% Hu 	-	potentiometric head of upper aquifer (m)
% Kw 	-	hydraulic conductivity of borehole (m/yr)

% The values of the second set cannot be accessed, i.e., they are latent
% variables, which make the simulator stocahstic
% r 	-	radius of influence (m)
% Tu 	-	transmissivity of upper aquifer (m^2/yr)
% Tl 	-	transmissivity of lower aquifer (m^2/yr)
% Hl 	-	potentiometric head of lower aquifer (m)
% L 	-	length of borehole (m)
%
% For more info, please refer to: Luethen, N. et al. (2023). A spectral surrogate 
% model for stochastic simulators computed from trajectory samples. Computer Methods 
% in Applied Mechanics and Engineering, 406:115875.
% 
% See also: UQ_BOREHOLE,
%           UQ_EXAMPLE_GLAM_02_stochasticBorehole

% If number of replications are not specified, 
% it is set to 1
if nargin<2
    R=1;
end

% Retrieve the input variables
rw = X(:, 1);
Hu = X(:, 2);
Kw = X(:, 3);
% Get the number of samples
N = size(X,1);

% Define the latent variables
% Radius of influence (m)
IOpts.Marginals(1).Name = 'r';  
IOpts.Marginals(1).Type = 'Lognormal';
IOpts.Marginals(1).Parameters = [7.71, 1.0056];
% Transmissivity of the upper aquifer (m^2/yr)
IOpts.Marginals(2).Name = 'Tu'; 
IOpts.Marginals(2).Type = 'Uniform';
IOpts.Marginals(2).Parameters = [63070, 115600];
% Transmissivity of the lower aquifer (m^2/yr)
IOpts.Marginals(3).Name = 'Tl'; 
IOpts.Marginals(3).Type = 'Uniform';
IOpts.Marginals(3).Parameters = [63.1, 116];
% Potentiometric head of the lower aquifer (m)
IOpts.Marginals(4).Name = 'Hl'; 
IOpts.Marginals(4).Type = 'Uniform';
IOpts.Marginals(4).Parameters = [700, 820];
% Length of the borehole (m)
IOpts.Marginals(5).Name = 'L';  
IOpts.Marginals(5).Type = 'Uniform';
IOpts.Marginals(5).Parameters = [1120, 1680];

% Create the latent object
myLatent = uq_createInput(IOpts,'-private');

% Sample the latent space
xi = uq_getSample(myLatent,N*R);
r = reshape(xi(:,1),N,1,R);
Tu = reshape(xi(:,2),N,1,R);
Tl = reshape(xi(:,3),N,1,R);
Hl = reshape(xi(:,4),N,1,R);
L = reshape(xi(:,5),N,1,R);

% Evaluate the model
Logrrw = log(bsxfun(@rdivide,r,rw));
Numerator = 2*pi*Tu.*bsxfun(@minus,Hu,Hl);
Denominator = Logrrw.*(1 + (2*L.*Tu)./(Logrrw.*bsxfun(@times, rw.^2,Kw)) + Tu./Tl);

Y = Numerator./Denominator;