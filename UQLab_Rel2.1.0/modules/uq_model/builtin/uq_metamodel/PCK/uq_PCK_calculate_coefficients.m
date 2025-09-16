function success = uq_PCK_calculate_coefficients(module)
% coefficients = UQ_PCK_CALCULATE_COEFFICIENTS: uqlab entry point to the
% calculation of the PCK coefficients. It results in a Kriging model with
% polynomial trend and a set of indices, such that the regular
% uq_Kriging_eval can be used for prediction

success = 0;


%% session retrieval, argument and consistency checks
if exist('module', 'var')
    current_model = uq_getModel(module);
else
    current_model = uq_getModel;
end


%% argument and consistency checks
% let's check the model is of type "uq_metamodel"
if ~strcmp(current_model.Type, 'uq_metamodel')
    error('Error: uq_metamodel cannot handle objects of type %s', current_model.Type);
end


%% Reporting
DisplayLevel = current_model.Internal.Display ;
if DisplayLevel
    fprintf('---   Calculating the PC-Kriging metamodel...                           ---\n')
end


%% Generate the initial experimental design
% Get X
current_model.ExpDesign.X = uq_getExpDesignSample(current_model);
% Get Y
current_model.ExpDesign.Y = uq_eval_ExpDesign(current_model,current_model.ExpDesign.X);
% Update the number of output variables of the model and store it
Nout = size(current_model.ExpDesign.Y, 2);
current_model.Internal.Runtime.Nout = Nout;


%% Generate a reduced experimental design ignoring the constants
% for X
Xred = current_model.ExpDesign.X(:,current_model.Internal.Input.nonConst);
if isempty(Xred)
    error('Only constants in the input model, no meta-modelling required.'); 
end

% Generate a corresponding reduced input space without constant variables
RedInput = uq_remove_constants_from_input(...
    current_model.Internal.Input,true);
current_model.Internal.RedInput = RedInput;

%% Generate the trend for PC-Kriging
switch current_model.Internal.TrendMethod
    case 'user' % when the trend is defined by the user

        if Nout>1; warning('Currently, the same poly indices are used for all response dimensions'); end
        if size(Xred, 2) ~= size(current_model.ExpDesign.X, 2); error('Constants are not supported for PC-Kriging with customized polynomials'); end
        
        % create a custom PCE to retrieve the auxiliary space
        popts.Type = 'Metamodel';
        popts.MetaType = 'PCE';
        popts.Method = 'Custom';
        popts.PCE.Basis.PolyTypes = current_model.Internal.PolyTypes;
        popts.PCE.Basis.Indices = current_model.Internal.PolyIndices;
        popts.PCE.Coefficients = ones(size(current_model.Internal.PolyIndices,1),1);
        popts.Input = current_model.Internal.Input;
        
        myPCE = uq_createModel(popts, '-private');
        for oo = 1:Nout
            idxranking{oo} = 1:size(current_model.Internal.PolyIndices,1);
            myPCE.PCE(oo) = myPCE.PCE(1);
        end
        
    case 'pce' %when the trend is defined by a PCE
        % compute a PCE model based on the provided options
        if isfield(current_model.Internal, 'PCE')
            popts = current_model.Internal.PCE;
        end
        popts.Type = 'Metamodel';
        popts.MetaType = 'PCE';
        popts.Input = RedInput;
        popts.ExpDesign.X = Xred;
        popts.ExpDesign.Y = current_model.ExpDesign.Y;
        if current_model.Internal.Display < 2; popts.Display = 0; end
        
        myPCE = uq_createModel(popts, '-private');
        %% now we have to find the ranking index
        for oo = 1:Nout
            PCEMethod = upper(myPCE.Internal.Method);
            FName = sprintf('%s_idx',lower(PCEMethod));
            idxranking{oo} = myPCE.Internal.PCE(oo).(PCEMethod).(FName);
        end
    otherwise
        error('Strategy to define the polynomial trend is missing!')
end

% overwrite the PCE results in Internal
current_model.Internal.PCE = myPCE;

% create the auxiliary domain as an input module of UQLab
ED_Input = uq_createInput(myPCE.Internal.ED_Input, '-private');

%% Compose the trend and the Kriging model
if isfield(current_model.Internal, 'Kriging')
    kopts = current_model.Internal.Kriging;
end
kopts.Type = 'Metamodel';
kopts.MetaType = 'Kriging';
kopts.Input = RedInput;
kopts.ExpDesign.Sampling = 'user';
kopts.ExpDesign.X = Xred;
if isfield(kopts, 'Scaling'); warning('Custom scaling options of Kriging are ignored in PC-Kriging'); end
kopts.Scaling = ED_Input;
if current_model.Internal.Display < 2; kopts.Display = 0; end


%% Compose the trend as a PCE
% General settings for a PCE model
popts1.Type = 'Metamodel';
popts1.MetaType = 'PCE';
popts1.Method = 'Custom';
popts1.Input = ED_Input;

%% Compute the Kriging model
switch lower(current_model.Internal.Mode)
    case 'sequential'
        % take all polynomials and put them as a trend for the Kriging 
        % model by creating a vector-output PCE
        for oo = 1:Nout
            popts2 = popts1;
            for ii = 1:length(idxranking{oo})
                popts2.PCE(ii) = myPCE.PCE(oo);
                popts2.PCE(ii).Coefficients(1:end,1) = 0;
                popts2.PCE(ii).Coefficients(idxranking{oo}(ii)) = 1;
            end
            myPIP = uq_createModel(popts2, '-private');
            
            % assign the PCE as a trend of the Kriging model
            kopts.Trend.Handle = @(X,dummy) uq_evalModel(myPIP, X);
            
            % assign the current component of the experimental design 
            % values
            kopts.ExpDesign.Y = current_model.ExpDesign.Y(:,oo);
            
            % Calibrate the Kriging model
            myPCKrigingoo = uq_createModel(kopts, '-private');
            NumberOfPoly(oo) = length(idxranking{oo});
            
            % Store the Krigign model
            if oo==1
                myPCKriging.Internal.Kriging = myPCKrigingoo;
                myPCKriging.Internal.Error = myPCKrigingoo.Error;
                myPCKriging.Kriging = myPCKrigingoo.Kriging;
            else
                myPCKriging.Internal.Kriging(oo) = myPCKrigingoo;
                myPCKriging.Internal.Error(oo) = myPCKrigingoo.Error;
                myPCKriging.Kriging(oo) = myPCKrigingoo.Kriging;
            end
        end
        
    case 'optimal'
        %comparison function
        CRITMODE = current_model.Internal.CombCrit;
        if strcmp(CRITMODE, 'fh'); ComparisonCriterion = str2func(current_model.Internal.CompCrit); end
        
        %compute a series of Kriging models with increasing size of the
        %trend
        for oo = 1:Nout
            popts2 = popts1;
            
            % assign the current component of the experimental design
            % values
            kopts.ExpDesign.Y = current_model.ExpDesign.Y(:,oo);
            
            for ii = 1:1:length(idxranking{oo})
                % take one-by-one polynomials and assign them in a
                % vector-valued PCE model
                popts2.PCE(ii) = myPCE.PCE(oo);
                popts2.PCE(ii).Coefficients(1:end,1) = 0;
                popts2.PCE(ii).Coefficients(idxranking{oo}(ii)) = 1;
                
                myPIP = uq_createModel(popts2, '-private');
                
                % assign the PCE as a trend of the Kriging model
                kopts.Trend.Handle = @(X,dummy) uq_evalModel(myPIP, X);
                
                % calibrate the Kriging model
                myKriging(ii) = uq_createModel(kopts, '-private');
                
                %compute comparison criterion
                switch CRITMODE
                    case 'rel_loo'
                        CompCrit(ii) = myKriging(ii).Error.LOO;
                    case 'fh'
                        CompCrit(ii) = ComparisonCriterion(myKriging(ii));
                    otherwise
                        error('Comparison criterion is not known!')
                end
            end
            
            % determine the minimum comparison value
            [~, iidx] = min(CompCrit(1:length(idxranking{oo})));
            
            % the final PC-Kriging model is model with minimum comparison
            % criterion value
            myPCKrigingoo = myKriging(iidx);
            NumberOfPoly(oo) = iidx;
            
            % assign the optimal PC-Kriging model
            if oo==1
                myPCKriging.Internal.Kriging = myPCKrigingoo;
                myPCKriging.Internal.Error = myPCKrigingoo.Error;
                myPCKriging.Kriging = myPCKrigingoo.Kriging;
            else
                myPCKriging.Internal.Kriging(oo) = myPCKrigingoo;
                myPCKriging.Internal.Error(oo) = myPCKrigingoo.Error;
                myPCKriging.Kriging(oo) = myPCKrigingoo.Kriging;
            end
        end
    otherwise
        error('Strategy to combine polynomials and Kriging is not known!')
end


%% store the results in a nice structure
uq_addprop(current_model, 'PCK', myPCKriging.Kriging);
current_model.Error = myPCKriging.Internal.Error;
current_model.Internal.Kriging = myPCKriging.Internal.Kriging;
current_model.Internal.Error = myPCKriging.Internal.Error;
current_model.Internal.AuxSpace = myPCKrigingoo.Internal.Scaling;
current_model.Internal.KeepCache = myPCKrigingoo.Internal.KeepCache;
current_model.Internal.eventLog = myPCKrigingoo.Internal.eventLog;
current_model.Internal.NumberOfPoly = NumberOfPoly;
current_model.ExpDesign.U = myPCKrigingoo.ExpDesign.U;
current_model.ExpDesign.ED_Input = current_model.Internal.AuxSpace;

%% Raise the flag that the metamodel has been calculated
current_model.Internal.Runtime.isCalculated = 1;

if DisplayLevel
    fprintf('---   Calculation finished!                                             ---\n')
end

success = 1;
