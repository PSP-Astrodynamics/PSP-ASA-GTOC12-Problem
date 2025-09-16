function J = uq_SVC_calc_SpanLOO(current_model)

warning('off','MATLAB:nearlySingularMatrix') ;

% Get the current output being calculated
current_output = current_model.Internal.Runtime.current_output ;
% Non-constant index
nonConst = current_model.Internal.Runtime.nonConstIdx ;
% Retrieve the training points (U = X in the reduced space)
X = current_model.ExpDesign.U(:,nonConst) ;
Y = current_model.ExpDesign.Y(:,current_output) ;
%Size of the ED
N = length(X);

% Save these results for use in uq_calc_SpanLOO
alpha = current_model.Internal.Runtime.alpha ;
exitflag = current_model.Internal.Runtime.exitflag ;
lambda = current_model.Internal.Runtime.lambda ;
K = current_model.Internal.Runtime.K ;

if exitflag < 0  % Error in the optiization problem
    J = realmax; % Set an arbitraty large LOO error
    return;
end

% Current value of the penaly term C
C = current_model.Internal.Runtime.C ;

% Find the set support vectors: Indices and their number
% First, precision up to which alpha are compared to 0 and C
alpha_cutoff = current_model.Internal.SVC(1).Alpha_CutOff ;
Isv = find( alpha >=  max(alpha) * alpha_cutoff ) ;
Nsv = length(Isv);
% When using Linear penalization differentiate the bounded vectors from the
% unbounded ones
if strcmpi( current_model.Internal.SVC(current_output).Penalization , ...
        'linear')
    % Unbounded support vectors: Indices and numbers
    Iusv = find( alpha >= max(alpha) * alpha_cutoff & ...
        alpha < C * (1 - alpha_cutoff) ) ;
    Nusv = length(Iusv);
    
    % Bounded support vectors: Indices and numbers
    Ibsv = find( alpha >= C * ( 1 - alpha_cutoff ) ) ;
    Nbsv = length(Ibsv);
end

% Get the bias
if isempty(lambda)
    % lambda empty that means we are using the solver of fitcsvm
    bias = current_model.Internal.Runtime.bias ;
else
    bias = lambda.eqlin(1) ;
end

% Get/Compute the Gram matrix, reduced to the set of support vectors
if any( strcmpi(current_model.Internal.SVC(1).QPSolver, ...
        {'smo','isda','l1qp'}) )
    % This means K was not computed. Compute it now, but this compute the
    % matrix only with the support vectors
    KernelOptions = current_model.Internal.Runtime.Kernel ;
    evalK_handle =  KernelOptions.Handle ;
    theta = current_model.Internal.Runtime.Kernel.Params ;
    K = evalK_handle( X(Isv,:), X(Isv,:), theta, KernelOptions);
else
    % The kernel matrix was retrieved directly after computed the alpha
    % using quadprog --> Now retain only the terms corresponding to the
    % support vector
    K = K(Isv,Isv);
end


% Get coefficients of the SVC expansion, only those corresponding to the
% support vectors
restricted_alpha = alpha(Isv,:) ;
beta = restricted_alpha.*Y(Isv,:);
% Compute the prediction on the training set.
Yval = transpose(beta) * K + bias ;

% Compute the product between the orginal and the predicted response on the
% training points: The SVC model has been evaluated only on the SVs but
% this doesn't matter as there is no misclassification for points that are
% not support vectors!, so recompose the whole set artificially
% First create a vector with all ones
YtimesYval = ones(N,1) ;
% Then update only the lines corresponding to the support vectors
YtimesYval(Isv,:) = Y(Isv,:).*sign(Yval)' ;

% Compute new indices of support vectors
% Update the support vectors indices, now 1...Nsv as all points of the
% Gram matrix belong to the support vectors set
newIsv = 1:Nsv ;
% Is it better to use is member rather than re-calculating those indices as
% done earlier ????
if strcmpi( current_model.Internal.SVC(current_output).Penalization , ...
        'linear')
    newIusv = find(ismember(Isv,Iusv));
    newIbsv = find(ismember(Isv,Ibsv)) ;
end


switch lower ( current_model.Internal.Runtime.EstimMethod )
    
    case 'spanloo'
        
        switch lower( current_model.Internal.SVC(current_output).Penalization )
            case 'linear'
                
                % Now compute the span estimate of the LOO error
                if Nusv == 0  % Degenerate case Nusv = 0
                    % If no UBSVs, LOO = training error
                    J = mean(YtimesYval < 0);
                else
                    Ksv = [ [ K(newIusv,newIusv) ones(Nusv,1) ] ; [ ones(1,Nusv) 0 ] ];
                    % If the matrix is not well conditioned, use pinv
                    % instead of inv
                    if rcond(Ksv) < 1e-8 % 1e-8 is quite an arbitrary value, should come up with a better justified threshold
                        invKsv = pinv(Ksv);
                    else
                        invKsv = inv(Ksv);
                    end
                    
                    Span = zeros(N,1);
                    % Span of unbounded support vectors
                    tmp = diag(invKsv);
                    Span(Iusv) = 1./tmp(1:Nusv);
                    % Span of the bounded support vectors, if any
                    if Nbsv > 0
                        V = [ K(newIusv,newIbsv); ones(1,Nbsv) ];
                        Span(Ibsv) = diag(K(newIbsv,newIbsv)) - diag(V'*invKsv*V); % Eq.
                    end
                    
                    % Span estimate of the LOO error
                    J = mean ( ( (YtimesYval) - alpha.*Span ) < 0 ) ;
                end
                
            case 'quadratic'
                
                % Compute Ktilde
                vectorC = 1/C * ones(Nsv,1) ;
                K = K + diag(vectorC) ;
                Ksv = [ [ K ones(Nsv,1) ] ; [ ones(1,Nsv) 0 ] ] ;
                % If the matrix is not well conditioned, use pinv
                % instead of inv
                if rcond(Ksv) < 1e-8 % 1e-8 is quite an arbitrary value, should come up with a better justified threshold
                    invKsv = pinv(Ksv) ;
                else
                    invKsv = inv(Ksv) ;
                end
                
                % Span of the support vectors
                Span = zeros(N,1);
                tmp = diag(invKsv);
                Span(Isv) = 1./tmp(1:Nsv);
                
                % Span estimate of the LOO error
                J = mean ( (YtimesYval) - alpha.*Span < 0 ) ;
        end
        
        
    case 'smoothloo'
        
        if Nsv == 0  % Degenerate case
            J = realmax; % Set the LOO to an arbitrary large value
        else
            % Add 1/C in the diagonal of K to obtain Ktilde
            vectorC = (1./C)*ones(Nsv,1);
            Ktilde = K + diag(vectorC);
            
            % Smoothing parameter - Specific option for Smooth LOO
            eta = current_model.Internal.SVC(1).SmoothLOO.eta ;
            vectorD = (eta./alpha(Isv)) ;
            Dtilde = [ [diag(vectorD) zeros(Nsv,1) ] ; [ zeros(1,Nsv) 0 ] ];
            M = [ [ Ktilde ones(Nsv,1) ] ; [ ones(1,Nsv) 0 ] ];
            Mtilde = M + Dtilde ;
            
            % If the matrix is not well conditioned, use pinv
            % instead of inv
            if rcond(Mtilde) < 1e-8 % 1e-8 is quite an arbitrary value, should come up with a better justified threshold
                invMtilde = pinv(Mtilde);
            else
                invMtilde = inv(Mtilde);
            end
            
            tmp = diag(invMtilde);
            Span = zeros(N,1) ;
            Span(Isv,:) = 1./tmp(1:Nsv) - vectorD ;
            
            % Compute the actual smoothed out estimated LOO error
            J = 1/N * length( find(alpha.*Span > 1) );  % According to Chapelle et al. 2002 p. 138 -Note from 16.03.2018 - Checked and the two formulations, here and above of J are equivalent YtimesYval is always equal to 1 for non support vectors...
            
        end
        
        
end

% Now in UQLab, it is not the LOO error that is directly optimized but a
% slightly modified function that allows to select the model with the least
% support vectors among models with same LOO error (This is due to the fact
% that the LOO for SVC is a step function - the ratio of misclassified
% point )
J = J * N + Nsv/N ;
% Cmax = current_model.Internal.SVC(1).Optim.Bounds(2,1) ;
% J = J * N + C/Cmax ;

warning on verbose ;

end