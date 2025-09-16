function uq_print_uq_randomfield( inputObj, varargin)
% UQ_PRINT_UQ_RANDOMFIELD prints out information about a random field object

%%
% Check if there is an explained variance/energy ratio:
evcomputed = 0 ;
if isfield(inputObj.Internal.Runtime,'TraceCorr')
cumulated_eigs = sum(inputObj.RF.Eigs)/inputObj.Internal.Runtime.TraceCorr ;
evcomputed = 1 ;
else
    if isfield(inputObj.Internal.Runtime,'EigsFull')
        cumulated_eigs = sum(inputObj.RF.Eigs)/sum(inputObj.Internal.Runtime.EigsFull) ;
        evcomputed = 1 ;
    else
        cumulated_eigs = cumsum(inputObj.RF.Eigs) ;
    end
end

% Compute the mean variance error
Vmean = mean(inputObj.RF.VarError);

%% 
% Pretty print then

fprintf('------------------- Random Field properties ------------------\n') ;
fprintf('Input object name        : %s\n', inputObj.Name) ;
fprintf('Random field type        : %s\n', inputObj.Internal.RFType) ;
fprintf('Discretization scheme    : %s\n' , inputObj.Internal.DiscScheme) ;
fprintf('Autocorrelation family   : %s\n' , inputObj.Internal.Corr.Family) ;
fprintf('Expansion order          : %2.0d\n', inputObj.RF.ExpOrder) ;
fprintf('Average error variance   : %.2e\n', Vmean) ;
if evcomputed
fprintf('Explained variance       : %.4f\n', cumulated_eigs) ;
end
%% done!
fprintf('--------------------------------------------------------------\n') ;

end 