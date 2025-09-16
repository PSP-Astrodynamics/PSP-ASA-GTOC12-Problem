function condDist = uq_createConditInput(dist,type,x)
% UQ_CREATECONDITINPUT creates a conditioned UQ_INPUT object.
%
%   CONDDIST = UQ_CREATECONDITINPUT(DIST, X, TYPE) returns the UQ_INPUT
%   object conditioned on X by TYPE.
%
%   See also: UQ_GETPROPOSAL

% Initialize
[nChains,nDim] = size(x);
condDist = cell(1,nChains);

switch type
    case 'mean'
        % create distribution with mean at x
        for ii = 1:nChains
            % modify distOpts
            distModOpt = dist.Options;
            for jj = 1:nDim
                currMarg = distModOpt.Marginals(jj);
                % remove parameter or moments field
                if isfield(currMarg,'Moments')
                    distModOpt.Options.Marginals(jj) = ...
                        rmfield(currMarg,'Moments');
                else
                    distModOpt.Options.Marginals(jj) = ...
                        rmfield(currMarg,'Parameters');
                end
                
                % take moments from supplied input object and exchange first
                % moment with x
                currSecondMoment = dist.Marginals(jj).Moments(2);
                distModOpt.Marginals(jj).Moments = [x(ii,jj),currSecondMoment];
            end
            
            % create object
            condDist{ii} = uq_createInput(distModOpt,'-private');
        end
    otherwise
        error('Conditioning type not supported!')
end