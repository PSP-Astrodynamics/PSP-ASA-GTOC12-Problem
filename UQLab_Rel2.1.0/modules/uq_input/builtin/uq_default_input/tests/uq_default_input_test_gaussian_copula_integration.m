function success = uq_default_input_test_gaussian_copula_integration(level)
% UQ_DEFAULT_INPUT_TEST_GAUSSIAN_COPULA_DENSITY_INTEGRATION(level):
%     Test that for any marginal defined, the integration of the copula gives
%     out one in a big 2D domain (the 2D integral should be 1).
%     

success = 1;
Distributions = {'gaussian', 'lognormal', 'gamma', 'student', 'beta', 'gumbel', 'uniform'};
rng(1);
% The test is successfull when the integration gives 1 - Integral < Threshold:

Threshold = 0.02;

% To avoid errors, we create random variables with mean in (10, 15) and
% standard deviation in (1, 2) and a random correlation coefficient

MeanX = 15 + 5*rand;
StdX = 1 + rand;
MeanY = 15 + 5*rand;
StdY = 1 + rand;

Rho = rand;


% For distributions defined in [0,1]
MeanX01 = 0.3 + 0.3*rand;
StdX01 = 0.01 + 0.09*rand;
MeanY01 = 0.3 + 0.3*rand;
StdY01 = 0.01 + 0.09*rand;
% By default, do not select this distribution:
Xin01 = false;
Yin01 = false;



% Define the copula:

Copula.Type = 'Gaussian';
Copula.Parameters = [1, Rho; Rho, 1];

Failed = false; % Flag to exit the loops if the test is not passed
Dev = 7; % Default deviation from the mean in the integration domain

for ii = 1:length(Distributions)
    for j = ii:length(Distributions) % Start in ii not to repeat combinations
        
        Marginals(1).Type = Distributions{ii};
        Marginals(2).Type = Distributions{j};
        
        switch Distributions{ii}
            case 'beta'
                Xin01 = true;
                Xmin = MeanX01 - Dev*StdX01;
                Xmax = MeanX01 + Dev*StdX01;
            case 'uniform'
                Xin01 = true;
                Xmin = MeanX01 - (sqrt(3)*StdX01 - 1e-10);
                Xmax = MeanX01 + (sqrt(3)*StdX01 - 1e-10);
            case 'lognormal'
                Xmin = max(1e-5, MeanX - Dev*StdX);
                Xmax = MeanX + Dev*StdX;
                
            case 'gumbel'
                Xmin = MeanX - 50*StdX;
                Xmax = MeanX + 50*StdX;
                
            case 'student'
                Xmin = MeanX - 20*StdX;
                Xmax = MeanX + 20*StdX;
                
            otherwise
                Xmin = MeanX - Dev*StdX;
                Xmax = MeanX + Dev*StdX;
        end
        
        switch Distributions{j}
            case 'beta'
                Yin01 = true;
                Ymin = MeanY01 - Dev*StdY01;
                Ymax = MeanY01 + Dev*StdY01;
            case 'uniform'
                Yin01 = true;
                Ymin = MeanY01 - (sqrt(3)*StdY01 - 1e-10);
                Ymax = MeanY01 + (sqrt(3)*StdY01 - 1e-10);
                
            case 'lognormal'
                Ymin = max(1e-5, MeanY - Dev*StdY);
                Ymax = MeanY + Dev*StdY;
                
            case 'gumbel'
                Ymin = MeanY - 50*StdY;
                Ymax = MeanY + 50*StdY;
                
            case 'student'
                Ymin = MeanY - 20*StdY;
                Ymax = MeanY + 20*StdY;
                
            otherwise
                Ymin = MeanY - Dev*StdY;
                Ymax = MeanY + Dev*StdY;
        end
        
        if Xin01
            Marginals(1).Moments = [MeanX01 StdX01];
        else
            Marginals(1).Moments = [MeanX StdX];
        end
        
        if Yin01
            Marginals(2).Moments = [MeanY01 StdY01];
        else
            Marginals(2).Moments = [MeanY StdY];
        end
        
        Xin01 = false;
        Yin01 = false;
        
        IOpts.Name = 'Test_Gaussian_Copula_Input';
        IOpts.Marginals = Marginals;
        IOpts.Copula = Copula;
        % Create a temporary input, to get the distribution parameters:
        TempInput = uq_createInput(IOpts, '-private');
        Marginals = TempInput.Marginals;
        Copula = TempInput.Copula;
        
        % Compute the integral
        integration_handle = @(x,y) copula_handle(x,y,TempInput);
        
        IntegralValue = integral2(integration_handle, Xmin, Xmax, Ymin, Ymax);
        
        %%%%%%%%%%%% Display the test results %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        fprintf('\nDistribution 1: %s\nDistribution 2: %s\n',Distributions{ii},Distributions{j});
        fprintf('Integral value: %g\n',IntegralValue');
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Remove the parameters and covaraiance for the next initialization
        Marginals = rmfield(Marginals,'Parameters');
        
        
        % Test:
        if 1 - IntegralValue > Threshold || IntegralValue > 1 + Threshold || isnan(IntegralValue)% Then the test failed
            Failed = true;
            break;
        end
    end
    if Failed % Exit the test
        success = 0;
        
        % Report the error:
        fprintf('\nuq_test_gaussian_copula_density_integration failed\n')
        fprintf('Distribution 1: %s\nDistribution 2: %s\n',Distributions{ii},Distributions{j});
        fprintf('Moments var. 1: %g, %g\n', Marginals(1).Moments);
        fprintf('Moments var. 2: %g, %g\n', Marginals(2).Moments);
        fprintf('Correlation   : %g\n', Rho);
        fprintf('Integral value: %g\n',IntegralValue');
        
        %Exit:
        break;
    end
    
end

if success
    fprintf('\nSUCCESS: uq_test_gaussian_copula_density_integration finished successfully!\n')
end

function Values = copula_handle(x,y,tmpInput)
% The results value should be a matrix such that Value(i,j) =
% copula_pdf(x(i,j), y(i,j)). Therefore, the matrix are reshaped in order
% to evaluate the function vectorized:

[InputRows, InputCols] = size(x);

Chunk = [reshape(x,InputRows*InputCols, 1), reshape(y, InputRows*InputCols, 1)];

RowValues = uq_evalPDF(Chunk,tmpInput);

RowValues(isnan(RowValues)) = 0;
isposinf = all([isinf(RowValues), sign(RowValues) == 1], 2);
isneginf = all([isinf(RowValues), sign(RowValues) == -1], 2);
RowValues(isposinf) = 0;
RowValues(isneginf) = 0;

Values = reshape(RowValues, InputRows, InputCols);
