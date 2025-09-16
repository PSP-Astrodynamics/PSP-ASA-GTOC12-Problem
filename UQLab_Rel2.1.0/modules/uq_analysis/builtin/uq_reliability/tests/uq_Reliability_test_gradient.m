function success = uq_Reliability_test_gradient(level)
% SUCCESS = UQ_RELIABILITY_TEST_GRADIENT(LEVEL):
%     Compute the gradient for the function:
%
%       f(x,y,z) = x^3 + x*y^2*z + 2*y + z/2 + 5
%
%     That is given by:
%
%       grad(f) = [3*x^2 + 2*y*z, x*z + 2, x*y^2 +1/2]
%
% See also: UQ_SELFTEST_UQ_RELIABILITY, UQ_GRADIENT

uqlab('-nosplash');
if nargin < 1
    level = 'normal'; 
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% Level dependent options
switch lower(level)
    case 'normal'
        NPoints = 50;
        Points = rand(NPoints, 3)*5;
        MeanValue(1:3) = 2.5;
    case 'slow'
        NPoints = 600;
        Points = zeros(NPoints, 3);
        Points(:, 1) = rand(NPoints, 1)*100;
        Points(:, 2) = rand(NPoints, 1)/1e3;
        Points(:, 3) = rand(NPoints, 1)*10;
        MeanValue = [50, 5e-4, 5];
end

success = 1;

GradientTypes = {'forward','backward','centred','centered','analytical_gradient(x)'};
FDSteps = {'absolute','relative'};
GivenH = 0.1;

% Define the functions/gradients to be tested:
target_handle = {@(x) exp_test(x), @(x) target_function2(x)};
GivenHandle = {@(x) exptest_gradient(x), @(x) analytical_gradient2(x)};
error_handle = {@(x) exp_error_vector(x), @(x) error_vector2(x)};

% For the FDStep 'relative' an input is required:
Input.Marginals(1).Name = 'x';
Input.Marginals(1).Type = 'Gaussian';
Input.Marginals(1).Moments = [MeanValue(1) 1];

Input.Marginals(2).Name = 'y';
Input.Marginals(2).Type = 'Gaussian';
Input.Marginals(2).Moments = [MeanValue(2) 3];

Input.Marginals(3).Name = 'z';
Input.Marginals(3).Type = 'Gaussian';
Input.Marginals(3).Moments = [MeanValue(3) 1];

Input.Copula.Type = 'Independent';
Input.Copula.Parameters = eye(3);

Input.Name = 'Input_test_gradient';
uq_createInput(Input);


%% Start calculating gradients
% Loop over the different functions:
for SelectedFunction = 1:length(target_handle)
    % Select the function, the analytical gradient and the function that
    % computes the error:
    target_function = target_handle{SelectedFunction};
    analytical_gradient = GivenHandle{SelectedFunction};
    error_vector = error_handle{SelectedFunction};
    
    % Loop over the different points where we want to compute the gradient:
    for point_counter = 1:size(Points, 1)
        Point = Points(point_counter, :);
        PointEvaluated = target_function(Point);
        
        % We know the function and the point, so we calculate the 
        % analytical gradient:
        [fx, fy, fz] = analytical_gradient(Point);
        RealGrad = [fx, fy, fz];
        
        % If the analytical values are Inf, skip this point:
        if any(isinf(RealGrad)) || any(isinf(PointEvaluated))
            fprintf('Gradient test: Point no. %d (of %d) skipped (Inf in analytical expression)\n', ...
                point_counter, NPoints);
            continue
        end
        
        % Loop over the different schemes (types):
        for type_counter = 1:length(GradientTypes)-1 % Last one does not require FDStep
            SelectedType = GradientTypes{type_counter};
            
            % Loop over the type of differences (relative or absolute)
            for step_counter = 1:length(FDSteps)
                FDStep = FDSteps{step_counter};
                DiffQuantity = GivenH;
                
                % First approximation, includes the known value of the
                % function on the point of interest:
                ApproxGrad = uq_gradient(...
                    Point, ...
                    target_function, ...
                    SelectedType, ...
                    FDStep, ...
                    DiffQuantity, ...
                    PointEvaluated, ...
                    Input.Marginals);
                
                % Same approximation, but now we do not include the already
                % evaluated point of interest:
                ApproxGrad2 = uq_gradient(...
                    Point, ...
                    target_function, ...
                    SelectedType, ...
                    FDStep, ...
                    DiffQuantity, ...
                    Input.Marginals);
                                
                % We must define an epsilon accordingly to the accuracy of 
                % the method:
                if strcmp(FDStep,'relative')
                    % growing function
                    TH = ...
                        (norm(DiffQuantity*MeanValue,'inf')/2)*...
                        error_vector(Point + DiffQuantity*MeanValue); 
                else
                    % growing function
                    TH = ...
                        (norm(DiffQuantity,'inf')/2)*...
                        error_vector(Point + GivenH); 
                end
                
                % Make the threshold a vector:
                THvec = TH*ones(length(RealGrad),1);
                
                % Check that Approximation 1 was successful:
                Ap1Success = ...
                    all(abs(ApproxGrad - RealGrad) < THvec);
                
                % Same for Approximation 2:
                Ap2Success = ...
                    all(abs(ApproxGrad2 - RealGrad) < THvec);
                
                % Update the success value of the method, only if the
                % previous 2 are OK:
                success = success*Ap1Success*Ap2Success;
                
                if success == 0
                    fprintf(' Fcn    : %s\n Point num: %g\n Type: %s \n Step: %s \n Approx1: %f   %f   %f\n Approx2: %f   %f   %f \n RealGrd: %f   %f   %f\n',...
                        func2str(target_handle{SelectedFunction}),point_counter,SelectedType,FDStep,ApproxGrad, ApproxGrad2,RealGrad);
                    fprintf('\n Point   : %e   %e   %e\n',Point);
                    fprintf('\n Err1   : %e   %e   %e\n Err2   : %e   %e   %e \n Eps    : %e   %e   %e\n',abs(RealGrad-ApproxGrad), abs(RealGrad-ApproxGrad2),TH);
                    return
                end
            end
        end
    end
end
fprintf('\nTest uq_test_gradient finished successfully!\n');

function [fx, fy, fz] = analytical_gradient2(X)
x = X(:, 1);
y = X(:, 2);
z = X(:, 3);
fx = 3*x.^2 + y.^2.*z;
fy = 2*y*x*z + 2;
fz = x.*y.^2 +1/2;

function Y = target_function2(X)
x = X(:, 1);
y = X(:, 2);
z = X(:, 3);
Y = x.^3 + y.^2.*x.*z + 2*y + z/2 + 5;

function Y = error_vector2(X)
x = X(:, 1);
z = X(:, 3);
fxx = 6*x;
fyy = 2*x.*z;
Y = [fxx, fyy, 0];

function Y = exp_test(X)
Y = exp(X(:, 1));

function [fx, fy, fz] = exptest_gradient(X)
fy = 0;
fz = 0;
fx = exp(X(:, 1));

function Y = exp_error_vector(X)
Y = [exp(X(:, 1)), 0, 0];