function pass = uq_SVC_test_Kernel( level )
% UQ_SVC_TEST_LOSSTYPES Regression test for SVR loss functions
% The model is built using known hyperparameters. The SVR coefficients are
% with values as computed by the model as of 13.05.2017 version 0.
% Please reformulate this...

eps = 1e-3;
N = 50 ;
% Initialize test:
pass = 1;
evalc('uqlab');
uq_retrieveSession;
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_SVC_test_Kernel...\n']);

%% Create Input
Input.Marginals(1).Type = 'Uniform' ;
Input.Marginals(1).Parameters = [-1, 1] ;
Input.Marginals(2).Type = 'Uniform' ;
Input.Marginals(2).Parameters = [-1, 1] ;
Input.Name = 'Input1';
uq_createInput(Input);
%% Create the full model
model.Name = 'bisector';
model.mFile = 'uq_bisector' ;
evalc('uq_createModel(model)');
%% Create inputs
Xtrain = uq_getSample(N, 'Sobol');
Ytrain = uq_evalModel(uq_getModel('bisector'),Xtrain);
Nval = 100 ;
X_pred = uq_getSample(Nval, 'Sobol');

% Run the tests for both scaled and unscaled versions:
% scaling = [0, 1]; % For now disregard the scaled one until scaling scheme is decided
scaling = [0, 1];
modelID = 0;
for ii = 1 : length(scaling)
    clear metaopts;
    %% general options
    metaopts.Type = 'Metamodel';
    metaopts.MetaType = 'SVC';
    metaopts.ExpDesign.X = Xtrain ;
    metaopts.ExpDesign.Y = Ytrain ;
    %Given parameters
    metaopts.Kernel.Family = 'Linear_NS' ;
    metaopts.Kernel.Isotropic = true ;
    metaopts.Kernel.Type = 'separable' ;
    metaopts.Kernel.Nugget = 0 ;

    metaopts.Hyperparameters.C = 10 ;
    metaopts.Optim.Method = 'none';
    s = rng(100,'twister');
    metaopts.Scaling = scaling(ii);
    modelID = modelID + 1;
    
    %% Norm-1 loss
    rng(s);
    metaopts.Name = ['SVC_lin',num2str(modelID)];
    metaopts.Penalization = 'quadratic' ;
    [~,SVC_lin] = evalc('uq_createModel(metaopts)');
    Kpred1 = uq_eval_Kernel( Xtrain, X_pred, [], metaopts.Kernel);

    %% Norm 2 loss
    rng(s);
    metaopts.Kernel.Family = 'Gaussian' ;
    metaopts.Hyperparameters.theta = 0.25 ;
    metaopts.Name = ['SVC_Gauss',num2str(modelID)];
    [~,SVC_Gauss] = evalc('uq_createModel(metaopts)');
     Kpred2 = uq_eval_Kernel( Xtrain, X_pred, metaopts.Hyperparameters.theta, metaopts.Kernel);
   
    %% Calculate Predictions
    if modelID == 1
        beta1 = [      4.755081115887136
   0.000000000000001
  -0.000000000000002
   0.000000000000001
  -0.000000000000002
   4.416780969976374
   5.769981553619442
   0.000000000000001
  -5.966035306401422
  -6.642635598222970
  -5.289435014579893
   0.000000000000006
   0.000000000000009
   0.000000000000007
  -0.000000000000001
   0.000000000000001
  -0.000000000000002
   4.163055860543291
   5.516256444186367
   3.824755714632515
   5.177956298275596
   0.000000000000001
  -0.000000000000002
   0.000000000000001
   0.000000000000002
   0.000000000000001
  -0.000000000000001
   0.000000000000001
  -0.000000000000003
  -0.000000000000003
  -0.000000000000003
   0.000000000000001
  -0.000000000000049
  -0.000000001034752
  -0.000000000000024
   0.000000000000002
   0.000000000000002
   0.000000000000002
  -0.000000000000001
   0.000000000000004
   0.000000000000005
   0.000000000000001
  -0.000000000000003
   0.000000000000001
  -0.000000000000001
  -8.539481310262355
  -7.186280726619293
   0.000000000000003
   0.000000000000003
   0.000000000000003 ];
        % bias
        b1 = 0.524491888411287;
        % Evaluate model
        Y_pred1 = transpose(beta1) * Kpred1 + b1 ;
        
        beta2 = [         2.480801499292028
            0.334632844442606
            -0.110298429396207
            0.121890031990538
            -0.000000000000000
            2.408450060358165
            3.069330897511525
            0.524540985681651
            -1.975851136827290
            -2.272120956333784
            -2.399781789498244
            0.000000000000000
            0.000000000000000
            0.000000000000000
            -0.797943281377868
            0.604885333499757
            -0.557372183822408
            1.494554135117372
            1.362427527020191
            1.473561971216238
            1.217707263127070
            0.227880822589517
            -0.656242624775445
            0.000000000000000
            0.420415590800471
            0.140440868319015
            -0.248853984764738
            0.002917731767698
            -0.000000000000000
            -0.000000000000000
            -0.039282053401151
            0.413726725589570
            -0.000000000000000
            -0.805828416376855
            -0.351020382477483
            0.000000000000000
            0.000000000000000
            0.000000000000000
            -0.067129039918178
            0.000000000000000
            0.000000000000000
            0.511929099182526
            -0.000000000000000
            0.073140177856679
            -0.496899383813555
            -2.918119862739388
            -3.249961075186318
            0.063471035346292
            0.000000000000000
            0.000000000000000 ] ;
        b2 = 0.115551273109348 ;
        Y_pred2 = transpose(beta2) * Kpred2 + b2 ;
    else %modelID = 2
        beta1 = [
               2.589643139461036
   0.000000000345772
  -0.000000000444254
   0.000000000332118
  -0.000000000448777
   2.321582748179182
   3.393824313451887
   0.000000000430249
  -2.302341095839834
  -2.838461877675911
  -1.766220312593012
   0.000000001414696
   0.000000002490736
   0.000000002256791
  -0.000000000368372
   0.000000000322281
  -0.000000000452114
   2.120537454770440
   3.192779019927472
   1.852477063647430
   2.924718628597355
   0.000000000363580
  -0.000000000438513
   0.000000000336306
   0.000000000361171
   0.000000000348546
  -0.000000000461699
   0.000000000339427
  -0.000000001045835
  -0.000000001207167
  -0.000000000891697
   0.000000000367813
  -0.000000003966804
  -0.000000000933961
  -0.000000004264813
   0.000000000598724
   0.000000000846143
   0.000000000711202
  -0.000000000417568
   0.000000002730332
   0.000000002605916
   0.000000000337834
  -0.000000001772495
   0.000000000354624
  -0.000000000506417
  -6.280390326782153
  -5.208148760868027
   0.000000001681626
   0.000000002001687
   0.000000001859230 ];
        
        b1 = 1.021740249701997 ;
        
        Y_pred1 = transpose(beta1) * Kpred1 + b1 ;
        
        beta2 = [   1.396614743902226
            0.384461752201666
            -0.488188253850507
            0.442729504280599
            -0.527776354096513
            1.324354769355287
            1.525950190635369
            0.684466274168845
            -1.366895371752653
            -1.326505568563598
            -1.322949110538288
            0.233145477205620
            0.265647732672492
            0.059135559193628
            -0.914223709641651
            0.578429801520651
            -0.664636575687205
            0.931368784107178
            0.898815106166116
            0.842944360633196
            0.816542689551940
            0.569518154788270
            -0.878638746777044
            0.169943114040019
            0.535064019723384
            0.281295719429700
            -0.466855149222289
            0.561256606143461
            -0.763250327975086
            -0.664360815667445
            -0.959398894043681
            0.689418955848186
            -0.372052654455579
            -0.978828207858409
            -0.777130149897621
            0.499662612407415
            0.357271180232816
            0.497379274764024
            -0.518949066886674
            0.007593969360507
            0.035780876942820
            0.596067255821673
            -0.400259441776096
            0.376873866305708
            -0.685507546272852
            -1.486632901972281
            -1.803305443679655
            0.650533683353633
            0.597668464722198
            0.556409791136502 ] ;
        b2 = 0.150056310344331 ;
        Y_pred2 = transpose(beta2) * Kpred2 + b2 ;
    end
    if modelID == 1
        Y_lin_svc = uq_evalModel(uq_getModel(['SVC_lin',num2str(modelID)]),X_pred);
        Y_quad_svc = uq_evalModel(uq_getModel(['SVC_Gauss',num2str(modelID)]),X_pred);
        
        %% make sure that predictions coincide with SVR model as implemented in 07/16
        pass = pass & ( length(find(Y_lin_svc .* Y_pred1' < 0)) / length(Y_pred1') < eps );
        pass = pass & length(find(Y_quad_svc .* Y_pred2' < 0)) / length(Y_pred2') < eps;
    else
        pass = pass & max(beta1 - SVC_lin.SVC.Coefficients.beta) < eps ;
        pass = pass & max(beta2 - SVC_Gauss.SVC.Coefficients.beta) < eps ;
    end
end
