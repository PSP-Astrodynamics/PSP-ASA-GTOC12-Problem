function uq_UQLink_helper_verifyProcessedX(action, X, processedX)
%UQ_UQLINK_HELPER_VERIFYPROCESSEDXY verifies the size of processed X.

switch action
    
    case 'default'
        % Nothing to verify
        
    case 'recover'
        % Check the consistency of the processed X w.r.t X
        if ~isequal(X,processedX)
            error(['The given ''X'' differs from the previously saved ',...
            '''uq_ProcessedX''!'])
        end
    
    case 'resume'
        % Check the consistency of the processed X w.r.t X
        
        % the number of processed X must be smaller than the initial X
        processedN = size(processedX,1);
        totalN = size(X,1);
        if totalN < processedN
            error(['The size of the given ''X'' is inconsistent with ',...
                '''uq_ProcessedX'' from the recovery source!'])
        end
        
        % the value processed so far must also be equal
        if ~isequal(X(1:processedN,:),processedX)
            error(['The processed part of the given ''X'' differs ',...
                'from the previously saved ''uq_ProcessedX''!'])
        end
    
    otherwise
        error('action *%s* is not recognized.',action)

end

end
