function u = uq_sampleU(N, M, options)
%UQ_SAMPLEU(N, M, options) returns N samples from the M-dimensional
%uniform space [0,1]. The structure 'options' can be used to set some
%additional options, namely:
%
%   Options.Method : allows to specify the sampling method. Possible
%   values are 'MC' (default), 'grid', 'LHS', 'simpleLHS', 'Sobol',
%   'Halton'
%   Options.LHSiterations : allows to specify the number of different LHS
%   designs that are going to be created (Options.Method = 'LHS')

%% set some default values of not specified otherwise
if ~exist('options', 'var')
    options.Method = 'MC';
    options.LHSiterations = 5;
elseif ~isfield(options, 'LHSiterations')
    options.LHSiterations = 5;
end

switch lower(options.Method)
    case {'regular', 'grid', 'meshgrid'}
        % generate a regular mesh with N points in each direction
        utmp = repmat(linspace(0,1,N).',1, M);
        rhsstr = 'ndgrid(';
        lhsstr = '[';
        for ii=1:M
            % to generate the final mesh
            lsubstr = sprintf('tmpUi{%d},', ii);
            lhsstr = sprintf('%s %s', lhsstr, lsubstr);
            
            rsubstr = sprintf('utmp(:, %d),', ii);
            rhsstr = sprintf('%s %s',rhsstr, rsubstr);
            
        end
        % remove the trailing comma and add the rest of the comvec command
        rhsstr = [rhsstr(1:end-1) ');'];
        lhsstr = [lhsstr(1:end-1) ']'];
        eval([lhsstr ' = ' rhsstr]);
        u = zeros(numel(tmpUi{1}), M);
        for ii = 1:M
            dimensions = ndims(tmpUi{ii}):-1:1;
            tmpUi{ii} = permute(tmpUi{ii}, dimensions);
            u(:,ii) = reshape(tmpUi{ii}, [],1);
        end
    case 'mc'
        % standard Monte Carlo sampling
        u = rand(N, M);
    case 'lhs'
        % Latin Hypercube Sampling
        % add the LHSiterations if not provided
        if ~isfield(options, 'LHSiterations') || isempty(options.LHSiterations)
            options.LHSiterations = 5;
        end
        u = uq_lhs(N, M, 0, options.LHSiterations);
    case 'simplelhs'
        % Simple version of Latin Hypercube Sampling that does one
        % iteration
        u = uq_lhs(N, M,2);
    case 'sobol'
        % create the Sobol-set generator if it doesn't exist
        if ~isfield(options, 'SobolGen') || isempty(options.SobolGen)
            options.SobolGen = sobolset(M);
            options.SobolGen.Skip = 1;
        end
        % produce the Sobol sequence - based samples
        u = options.SobolGen(1:N,:);
    case 'halton'
        %create the Halton-set generator if it doesn't exist
        if ~isfield(options, 'HaltonGen') || isempty(options.HaltonGen)
            options.HaltonGen = haltonset(M);
            % scramble the sequence
            options.HaltonGen = scramble( options.HaltonGen,'RR2');
            options.HaltonGen.Skip = 1;
        end
        % produce the Halton sequence - based samples
        u = options.HaltonGen(1:N,:);
    otherwise
        error('The required type of u sampling is not defined. Please choose one of the following: MC, LHS, Sobol,Halton.')
end

