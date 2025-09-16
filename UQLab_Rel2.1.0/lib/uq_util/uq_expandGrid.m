function C = uq_expandGrid(varargin)

error(nargchk(1,Inf,nargin)) ;

NC = nargin ;

% check if we should flip the order
if ischar(varargin{end}) && (strcmpi(varargin{end},'matlab') || strcmpi(varargin{end},'john')),
    % based on a suggestion by JD on the FEX
    NC = NC-1 ;
    ii = 1:NC ; % now first argument will change fastest
else
    % default: enter arguments backwards, so last one (AN) is changing fastest
    ii = NC:-1:1 ;
end

% check for empty inputs
if any(cellfun('isempty',varargin(ii)))
    warning('ALLCOMB:EmptyInput','Empty inputs result in an empty output.') ;
    C = zeros(0,NC) ;
elseif NC > 1
    isCellInput = cellfun(@iscell,varargin) ;
    if any(isCellInput)
        if ~all(isCellInput)
            error('ALLCOMB:InvalidCellInput', ...
                'For cell input, all arguments should be cell arrays.') ;
        end
        % for cell input, we use to indices to get all combinations
        ix = cellfun(@(c) 1:numel(c), varargin,'un',0) ;

        % flip using ii if last column is changing fastest
        [ix{ii}] = ndgrid(ix{ii}) ;

        C = cell(numel(ix{1}),NC) ; % pre-allocate the output
        for k=1:NC
            % combine
            C(:,k) = reshape(varargin{k}(ix{k}),[],1) ;
        end
    else
        % non-cell input, assuming all numerical values or strings
        % flip using ii if last column is changing fastest
        [C{ii}] = ndgrid(varargin{ii}) ;
        % concatenate
        C = reshape(cat(NC+1,C{:}),[],NC) ;
    end
elseif NC==1
    C = varargin{1}(:) ; % nothing to combine

else % NC==0, there was only the 'matlab' flag argument
    C = zeros(0,0) ; % nothing
end

end
