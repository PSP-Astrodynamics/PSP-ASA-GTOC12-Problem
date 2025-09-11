function myEEPCE = uq_PCE_createEEPCE(PCEModel,varargin)
% MYEEPCE = UQ_PCE_CREATEEEPCE(PCEMODEL,VARARGIN): function to create an
%     auxiliary PCE from the input PCEMODEL to visualize the elementary
%     effects of the underlying model. 
%
% See also: uq_PCE_displayEE

%% Initialization
% Argument checks
if ~isa(PCEModel, 'uq_model') || ~strcmpi(PCEModel.Type, 'uq_metamodel')    
    error('uq_PCE_createEEPCE only works with metamodels!');
end
% Specify the order of the elementary effects
EEOrder = 1;
if nargin > 1
    EEOrder = varargin{1};
end
% Calculate the elementary effects for the specified output component
current_output = 1;
if nargin > 2
    current_output = varargin{2};
end

%% Gather the information and generate a multidimensional custom PCE
PCE = PCEModel.PCE(current_output);
PCEIndices = PCE.Basis.Indices(PCE.Coefficients ~= 0,:);
PCECoefficients = PCE.Coefficients(PCE.Coefficients ~= 0);
PCEMean = PCE.Moments.Mean;
PolyTypes = PCE.Basis.PolyTypes;
PolyTypesParams = PCE.Basis.PolyTypesParams;
PolyTypesAB = PCE.Basis.PolyTypesAB;

% Dimensions of the basis indices
[P,M] = size(PCEIndices);

% Number of outputs depends on the number of input coordinates as well as
% on the requested order
NOut = nchoosek(M,EEOrder);

IRanks = full(sum(PCEIndices > 0, 2));
idx = find(IRanks == EEOrder);
subbasis = PCEIndices(idx,:) ;
Z = nchoosek(1:M, EEOrder) ;
EEPCE = struct([]);
for ii = 1:size(Z, 1)
    Zq = Z(ii,:) ;
    subsubbasis = subbasis(:, Zq) ;
    subidx = prod(subsubbasis, 2) > 0 ;
    sum_ind = idx(subidx);
    % Add the mean value of the PCE in the elementary effects
    EEPCE(ii).Basis.Indices = PCEIndices(sum_ind,:);
    EEPCE(ii).Coefficients = PCECoefficients(sum_ind);
    % put the zeroth order coefficient in the expansion
    
    EEPCE(ii).Basis.Indices = [sparse(zeros(1,M)); EEPCE(ii).Basis.Indices];
    EEPCE(ii).Coefficients = [PCEMean; EEPCE(ii).Coefficients];
    
    EEPCE(ii).Basis.PolyTypes = PolyTypes;
    EEPCE(ii).Basis.PolyTypesParams = PolyTypesParams;
    EEPCE(ii).Basis.PolyTypesAB = PolyTypesAB;
end

%% Prepare the output custom PCE
EEOpts.Type = 'Metamodel';
EEOpts.MetaType = 'PCE';
EEOpts.Method = 'Custom';
EEOpts.Input = PCEModel.Internal.Input;
EEOpts.PCE = EEPCE;
myEEPCE = uq_createModel(EEOpts, '-private');
myEEPCE.Internal.VarIdx = Z;
for ii = 1:M
    myEEPCE.Internal.VarNames{ii} = EEOpts.Input.Marginals(ii).Name;
end

