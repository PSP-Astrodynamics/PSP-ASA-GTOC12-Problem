function [SampleRF, xi] = uq_getRFSample( current_input, varargin )
% UQ_GETGRFSAMPLE: gets samples of the random field defined in
% current_input. In case, of translation non-Gaussian RFs, the translation
% is carriedout also within this function (e.g., when using a lognormal
% random field)
%
% INPUT:
%   - current_input: Random field object
%   - varargin{1}: Number of samples N (by default 1)
%   - varargin{2}: Sampling method (by default 'MC')
%   - varargin{3:end} - Name pair values including 'lhsiterations','Mesh'
%
% OUTPUT:
%   - SampleRF: Sample trajectories vector of size N x m, where m is the
%   number of points in the discretization mesh
%   - xi: Standard Gaussian random variables vector of size N x M, where M
%   is the expansion order

LHSiterations_default = 5 ;

%% 1. Initialization

% Number of inputs
nargs = length(varargin);

% Get/Define the number of samples to generate
if ~nargs
    error('Number of samples not specified. Usage: uq_getSample(N)');
end
N = varargin{1};

% Assign MC as default Sampling - Value will be changed later if nargs > 1
Sampling = 'MC' ;

% Assign an empty vector to the mesh - If no mesh has been provided by the
% user when calling uq_getSample, then the default or internal Mesh will be
% used for sampling
Mesh = [] ;


if nargs > 1
    % if the second argument is not a mesh - has to be the sampling 
    % technique then
    if ~strcmpi(varargin{2},'mesh')
        Sampling = varargin{2};
        % Default LHS iterations
        if strcmpi(Sampling,'lhs')
            LHSiterations = LHSiterations_default ;
        end
        % Get the optional parameters that have been entered in terms of
        % name pair values
        if nargs > 2
        nameValuePairs = varargin(3:end);
        end

    else
        Sampling = 'MC';
        nameValuePairs = varargin(2:end);

    end
end

% Parse the other name-pair values which could be the mesh and/or the
% number of iterations in case of LHS
if nargs > 2
     nameValuePairs(1:2:end) = lower(nameValuePairs(1:2:end));
    NumberofOptions = length(nameValuePairs)/2;

    for ii = 1:NumberofOptions
        switch nameValuePairs {2*(ii-1)+1}
            case 'lhsiterations'
                parseKey = {'lhsiterations'};
                parseType = {'p'};

                % Now parse the additional options
                [optInput,~] = uq_simple_parser(nameValuePairs, parseKey, parseType);
                % 'iterations' option
                if ~strcmp(optInput{1},'false')
                    LHSiterations = optInput{1};
                    if ~isscalar(LHSiterations)
                        error('iterations must be a scalar value.')
                    end
                else
                    LHSiterations = 5;
                end

            case 'mesh'
                parseKey = {'mesh'};
                parseType = {'p'};

                % Now parse the additional options
                [optInput,~] = uq_simple_parser(nameValuePairs, parseKey, parseType);
                % Assign the 'Mesh' option
                Mesh = optInput{1};

                if ~ismatrix(Mesh)
                    error('Mesh should be a vector or matrix.')
                end
                % Also check that the size is consistent
                if size(Mesh,2) ~= size(current_input.RF.CovMesh,2)
                    error('The size of the provided mesh is inconsistent with the defined random field.');
                end

        end
    end
end

%% 2. Gaussian random field

% Generate standard Gaussian random samples to build the trajectories
if strcmpi(Sampling,'lhs')
    xi = uq_getSample(current_input.UnderlyingGaussian, N, Sampling,...
        'LHSiterations',LHSiterations);
else
    xi = uq_getSample(current_input.UnderlyingGaussian, N, Sampling);
end

% Transform the standard Gaussian samples into random field trajectories
if isempty(Mesh)
    SampleRF = uq_RF_Xi_to_X(current_input,xi) ;
else
    SampleRF = uq_RF_Xi_to_X(current_input,xi,Mesh) ;
end


%% 3. Translation non-Gaussian random field (if any)

% If the user has specified another marginal type carry out
% point-by-point isoprobabilistic transformation with the moments
% maintained.
if ~strcmpi(current_input.Internal.RFType,'gaussian')
    SampleRF = uq_translateRF_FromGaussian(SampleRF,current_input, ...
        current_input.Internal.RFType);
end

end

