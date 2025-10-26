function uq_SPCE_print(SPCEModel, outArray, varargin)
% UQ_SPCR_PRINT(GLaM,OUTARRAY,VARARGIN): pretty print information on the
%     stochastic polynomial chaos metamodel for the specified set of output components
%     OUTARRAY (default: OUTARRAY = 1).
%
% See also: UQ_PCE_PRINT, UQ_SPCE_DISPLAY,UQ_KRIGING_PRINT,UQ_PRINT_UQ_METAMODEL

%% Consistency checks and command line parsing
if ~exist('outArray', 'var') || isempty(outArray)
    outArray = 1;    
end

if max(outArray) > length(SPCEModel.SPCE)
    error('Requested output range is too large') ;
end

%% parsing the residual command line
% initialization
coeff_flag = false;
TOL = 1e-2;

if nargin > 2
    parse_keys = {'coefficients', 'tolerance'};
    parse_types = {'f', 'p'};
    [uq_cline, ~] = uq_simple_parser(varargin, parse_keys, parse_types);
    % 'coefficients' option additionally prints the coefficients
    if strcmp(uq_cline{1}, 'true')
        coeff_flag = true;
    end
    
    % 'tolerance' option sets the default tolerance to plot coefficients
    if ~strcmp(uq_cline{2}, 'false')
        TOL = uq_cline{2};
    end

end


SPCEType = SPCEModel.Internal.Method;
for ii = 1:length(outArray)    
    Coefs = SPCEModel.SPCE(outArray(ii)).Coefficients;
    NotMeanInd = any(SPCEModel.SPCE(outArray(ii)).Basis.Indices,2);
    Mean = Coefs(~NotMeanInd);
    StdDev = sqrt(sum(Coefs(NotMeanInd).^2));
    
    M = length(SPCEModel.Internal.Input.Marginals);

    %  Display
    fprintf('\n%%------------ Stochastic polynomial chaos expansion output ---------------%%\n');
    fprintf('   Number of input variables:            %i\n', M);
    LatentDist = SPCEModel.SPCE(outArray(ii)).Latent;
    fprintf(['   Latent variable: %s distribution with parameters [ ',repmat('%2.2f ',1,length(LatentDist.Parameters)), ']\n'],...
        LatentDist.Type,LatentDist.Parameters);
    fprintf('   Maximal degree:                       %i\n', SPCEModel.SPCE(outArray(ii)).Basis.Degree);
    fprintf('   Size of basis:                        %i\n', length(SPCEModel.SPCE(outArray(ii)).Coefficients));
    fprintf('   Full model evaluations:               %i ED points with %i replications\n', SPCEModel.ExpDesign.NSamples,SPCEModel.ExpDesign.Replications);
    
    if strcmpi(SPCEType,'custom')
        fprintf('   The model is built upon the custom specification.\n');
    else
        fprintf('   k-fold CV negative loglikelihood:     %13.7e\n',SPCEModel.Error(outArray(ii)).CV);
        fprintf('   AIC:                                  %13.7e\n',SPCEModel.Error(outArray(ii)).AIC);
        fprintf('   BIC:                                  %13.7e\n',SPCEModel.Error(outArray(ii)).BIC);
    end
    
    %Error measures
    if uq_isnonemptyfield(SPCEModel.Error,'Val')&&uq_isnonemptyfield(SPCEModel.Error.Val,'NormalizedWSD')
        fprintf('   Validation normalized Wasserstein distance: %13.7e\n',SPCEModel.Error(outArray(ii)).Val.NormalizedWSD);
    end
    
    fprintf('   Mean value:                    %13.4f\n',Mean);
    fprintf('   Standard deviation:            %13.4f\n',StdDev);
    fprintf('   Coef. of variation:            %13.3f%%\n',StdDev/abs(Mean)*100);
    
    if coeff_flag
        uq_SPCE_printCoeff(SPCEModel,TOL,outArray(ii));
    end
        
    fprintf('%%-------------------------------------------------------------------------%%\n');
        
end

end

function uq_SPCE_printCoeff(SPCEModel, TOL, outidx)
% Pretty-print the chaos coefficients for interpretation


if ~exist('TOL', 'var')
    TOL = 1e-2;
end

CC = SPCEModel.SPCE(outidx).Coefficients;
Basis = full(SPCEModel.SPCE(outidx).Basis.Indices);

[P , M] = size(Basis);

% Build format of printing
MyFormat = '   [%i';
for i=2:M
    MyFormat = strcat(MyFormat, '%3i');
end
MyFormat= strcat(MyFormat, ']\t\t\t\t%23.7f\n');
fprintf('   List of coefficients (sorted by amplitude):\n');
fprintf('   [alpha_1   ...   alpha_M(latent)]\t Coefficient\n');

% Print the coefficients according to the amplitude 
% and if they are greater than a threshold
[~, ind] = sort(abs(CC),'descend');
TheStd = sqrt(sum(CC(2:end).^2));

for i=1:P
    cc = CC(ind(i));
    if (abs(cc)> TOL*TheStd )
        tmp = Basis(ind(i),:);
        fprintf(MyFormat,tmp,cc);
    end
    
end
end

