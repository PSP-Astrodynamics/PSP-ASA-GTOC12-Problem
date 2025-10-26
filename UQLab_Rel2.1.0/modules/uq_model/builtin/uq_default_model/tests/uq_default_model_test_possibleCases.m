function pass = uq_default_model_test_possibleCases( level )
% UQ_DEFAULT_MODEL_TEST_POSSIBLECASES tests representative of possible 
% supported cases of mfiles
%
% See also: UQ_TESTFNC_MFILEDEF_MULTIOUTPUT, UQ_TESTFNC_MFILEDEF_PARAMPOLY

% parameters
Nval = 1e3;
eps = 1e-14;

if nargin < 1
    level = 'normal'; 
end
fprintf(['\nRunning: |' level '| uq_default_model_test_possibleCases...\n']);

uqlab('-nosplash')

if strcmpi(level, 'normal')
    
    % create an input
    [inputopts.Marginals(1:5).Type] = deal('uniform') ;
    [inputopts.Marginals(1:5).Parameters] = deal([-pi pi]) ;
    % create the input
    myInput = uq_createInput( inputopts);
    
    
    
    %% CASE 1 : typical model with params , vectorized
    % create the model
    modelopts.Parameters = rand(1,5);
    modelopts.mFile = 'uq_testfnc_mfileDef_parampoly';
    
    myModel = uq_createModel(modelopts);
    
    % validate the output
    Xval = uq_getSample(Nval);
    Ytrue = Xval * modelopts.Parameters' ;
    Yval = uq_evalModel(myModel,Xval);
    
    pass = max(abs(Ytrue-Yval))< eps;
    
    %% CASE 2 : typical model with params, NOT vectorized
    modelopts.isVectorized = 0;
    
    myModel = uq_createModel(modelopts);
    
    % validate the output
    Yval = uq_evalModel(myModel,Xval);
    pass = pass & (max(abs(Ytrue-Yval))< eps);
    
    %% CASE 3 : typical model with params, vectorized, multiple outputs
    clear modelopts ;
    modelopts.isVectorized = 0;
    modelopts.mFile = 'uq_testfnc_mfileDef_multiOutput';
    
    myModel = uq_createModel(modelopts);
    
    % validate the output
    Ytrue1 = Xval;
    Ytrue2 = Xval.^2;
    [Yval1, Yval2] = uq_evalModel(myModel,Xval);
    
    pass = pass & (max(abs(Ytrue1(:)-Yval1(:)))< eps) & ...
        (max(abs(Ytrue2(:)-Yval2(:)))< eps);
    
    
    %% CASE 4 : (STRING) anonymous function
    clear modelopts ;
    modelopts.mString = '@(X) sum(X.^2,2)';
    modelopts.isVectorized = true;
    myModel = uq_createModel(modelopts);
    
    % validate the output
    Ytrue = sum(Xval.^2, 2);
    
    Yval = uq_evalModel(myModel,Xval);
    
    pass = pass & (max(abs(Ytrue(:)-Yval(:)))< eps);
    
    
    %% CASE 5 : (STRING) anonymous function WITH PARAMETERS
    clear modelopts ;
    modelopts.mString = '@(X,p) sum(p{1}*X.^2 + p{2},2)';
    modelopts.Parameters = {2, 3};
    modelopts.isVectorized = true;
    myModel = uq_createModel(modelopts);
    
    % validate the output
    Ytrue = sum(2*Xval.^2 + 3, 2);
    
    Yval = uq_evalModel(myModel,Xval);
    
    pass = pass & (max(abs(Ytrue(:)-Yval(:)))< eps);
    
    
    
    %% CASE 6 : (HANDLE) no parameters
    clear modelopts ;
    Xval = rand(500,3);
    
    Ytrue = uq_ishigami(Xval);
    
    modelopts.mHandle = @uq_ishigami ;
    
    myModel = uq_createModel(modelopts);
    
    % validate the output
    Yval = uq_evalModel(myModel,Xval);
    
    pass = pass & (max(abs(Ytrue(:)-Yval(:)))< eps);
    
else
    %% SLOW TEST: run all possible combinations
    parameterCases = {[7 0.1], []};
    vectorizedCases = [0 1];
    typeCases = {'mFile', 'mHandle', 'mString'};
    trueModelCases = {'uq_ishigami', 'uq_ishigami_various_outputs'};
    % Find all possible cases 
    allCombs = uq_findAllCombinations(...
        1:length(parameterCases),...
        1:length(vectorizedCases),...
        1:length(typeCases),...
        1:length(trueModelCases));
    
    
    % create an input
    [inputopts.Marginals(1:3).Type] = deal('uniform') ;
    [inputopts.Marginals(1:3).Parameters] = deal([-pi pi]) ;
    % create the input
    myInput = uq_createInput( inputopts);
    Xval = uq_getSample(500) ;
    
    trueY{1} = uq_ishigami(Xval);
    trueY{2} = uq_ishigami_various_outputs(Xval);
    
    pass = 1;
    for ii = 1 : length(allCombs)
        clear modelopts;
        modelopts.Parameters = parameterCases{allCombs(ii,1)};
        modelopts.isVectorized = vectorizedCases(allCombs(ii,2));
        
        switch typeCases{allCombs(ii,3)}
            case 'mFile'
                
            modelopts.mFile = trueModelCases{allCombs(ii,4)} ;

            case 'mHandle'
                if isempty(modelopts.Parameters)
                    modelopts.mHandle = str2func(trueModelCases{allCombs(ii,4)});
                else
                    switch trueModelCases{allCombs(ii,4)}
                        case 'uq_ishigami'
                            modelopts.mHandle = @(X,P) uq_ishigami(X,P);
                        case 'uq_ishigami_various_outputs'
                            modelopts.mHandle = @(X,P) uq_ishigami_various_outputs(X,P);
                    end
                end
                
            case 'mString'
                if isempty(modelopts.Parameters)
                    
                    switch trueModelCases{allCombs(ii,4)}
                        case 'uq_ishigami'
                            modelopts.mString = ...
                                '@(X) sin(X(:,1)) + 7*(sin(X(:,2)).^2) + 0.1*(X(:,3).^4).* sin(X(:,1))';
                        case 'uq_ishigami_various_outputs'
                            modelopts.mString = ...
                                ['@(X) [sin(X(:,1)) + 7*(sin(X(:,2)).^2) + 0.1*(X(:,3).^4).* sin(X(:,1)),', ...
                                '100*X(:, 1).^3,',...
                                'sin(X(:,1)) + 7*(sin(X(:,2)).^2) + 0.1*(X(:,3).^4).* sin(X(:,1))]'];
                    end

                else
                    switch trueModelCases{allCombs(ii,4)}
                        case 'uq_ishigami'
                            modelopts.mString = ...
                                '@(X,P) sin(X(:,1)) + P(1)*(sin(X(:,2)).^2) + P(2)*(X(:,3).^4).* sin(X(:,1))';
                        case 'uq_ishigami_various_outputs'
                            modelopts.mString = ...
                                ['@(X,P) [sin(X(:,1)) + P(1)*(sin(X(:,2)).^2) + P(2)*(X(:,3).^4).* sin(X(:,1)),', ...
                                '100*X(:, 1).^3,',...
                                'sin(X(:,1)) + P(1)*(sin(X(:,2)).^2) + P(2)*(X(:,3).^4).* sin(X(:,1))]'];
                    end
                    
                end
            otherwise
                error('Internal self-test error!');
        end
        myModel = uq_createModel(modelopts);
        Yval = uq_evalModel(myModel,Xval);

        Ytrue = trueY{allCombs(ii,4)} ;

        pass = pass & (max(abs(Ytrue(:)-Yval(:)))< eps);
    end
    
end
