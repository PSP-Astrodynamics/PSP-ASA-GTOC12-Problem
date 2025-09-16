function pass = uq_SVC_test_LossTypes( level )
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
fprintf(['\nRunning: |' level '| uq_SVC_test_LossTypes...\n']);

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
    metaopts.Kernel.Family = 'Gaussian' ;
    metaopts.Kernel.Isotropic = true ;
    metaopts.Kernel.Type = 'separable' ;
    metaopts.Kernel.Nugget = 0 ;

    metaopts.Hyperparameters.C = 10 ;
    metaopts.Hyperparameters.theta = 0.25 ;
    metaopts.Optim.Method = 'none';
    s = rng(100,'twister');
    metaopts.Scaling = scaling(ii);
    modelID = modelID + 1;
    
    %% Norm-1 loss
    rng(s);
    metaopts.Name = ['Lin_SVC_',num2str(modelID)];
    metaopts.Penalization = 'linear' ;
    [~,Lin_SVC] = evalc('uq_createModel(metaopts)');
    %% Norm 2 loss
    rng(s);
    metaopts.Name = ['Quad_SVC_',num2str(modelID)];
    metaopts.Penalization = 'quadratic' ;
    [~,Quad_SVC] = evalc('uq_createModel(metaopts)');
    
    %% Calculate Predictions
    Kpred = uq_eval_Kernel( Xtrain, X_pred, metaopts.Hyperparameters.theta, metaopts.Kernel);
    if modelID == 1
        beta1 = [   3.220100036236435
            0.491440654729056
            -0.000000000651947
            0.077276870921556
            -0.000000000005936
            3.856926447707549
            5.110189677357930
            0.559151294714221
            -2.329694700676039
            -2.797900270246543
            -2.877666858831692
            0.000000000000688
            0.000000000000661
            0.000000000000507
            -0.889468583166691
            0.703084310476140
            -0.518362986688688
            1.571728083370047
            1.178845521608468
            1.816148446992825
            1.413110744324656
            0.243458058162644
            -0.746253807642611
            0.000000000026123
            0.378525993355597
            0.000000045868431
            -0.323044007570961
            0.000000000001842
            -0.000000000005798
            -0.000000000000735
            -0.000000000001998
            0.431880533733646
            -0.000000000000280
            -0.802748313584252
            -0.199739282673499
            0.000000000003030
            0.000000000001129
            0.000000000011862
            -0.000000000006202
            0.000000000003047
            0.000000000001720
            0.553114707122782
            -0.000000000002737
            0.000000004706532
            -0.552610888014094
            -4.481472648644495
            -5.086019083093700
            0.000000000062854
            0.000000000006083
            0.000000000000836 ];
        % bias
        b1 = 0.109430360378572;
        % Evaluate model
        Y_pred1 = transpose(beta1) * Kpred + b1 ;
        
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
        Y_pred2 = transpose(beta2) * Kpred + b2 ;
    else %modelID = 2
        beta1 = [
            1.688891963960171
            0.410241458523198
            -0.495012963634393
            0.466021794699989
            -0.540110887524876
            1.607075034172515
            1.853719302580215
            0.743940542335825
            -1.594121208235027
            -1.510577596824854
            -1.498761648594336
            0.166470739236051
            0.234156035161576
            0.000000015716043
            -1.002396341364285
            0.665428860284825
            -0.710263027789224
            1.072345530504028
            1.015291193471321
            0.944694474934065
            0.918331416827121
            0.609117398715646
            -0.971461352148202
            0.072183227703997
            0.583452941701681
            0.248247539586412
            -0.493736731321992
            0.602310464795598
            -0.827836783673959
            -0.702718589494929
            -1.047883929865179
            0.749994205471918
            -0.246772394513636
            -1.066684188233135
            -0.856086301095953
            0.612219702024600
            0.362824223349171
            0.571422744594668
            -0.530754607469106
            0.000000008782859
            0.000000015243018
            0.641332815869637
            -0.368289173095533
            0.392399062832287
            -0.744107009952293
            -1.841059965984933
            -2.161992090572137
            0.715950265882037
            0.676153756945018
            0.586410055482493 ];
        
        b1 = 0.150825034880329 ;
        
        Y_pred1 = transpose(beta1) * Kpred + b1 ;
        
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
        Y_pred2 = transpose(beta2) * Kpred + b2 ;
    end
    if modelID == 1
        Y_lin_svc = uq_evalModel(uq_getModel(['Lin_SVC_',num2str(modelID)]),X_pred);
        Y_quad_svc = uq_evalModel(uq_getModel(['Quad_SVC_',num2str(modelID)]),X_pred);
        
        %% make sure that predictions coincide with SVR model as implemented in 07/16
        pass = pass & ( length(find(Y_lin_svc .* Y_pred1' < 0)) / length(Y_pred1') < eps );
        pass = pass & length(find(Y_quad_svc .* Y_pred2' < 0)) / length(Y_pred2') < eps;
    else
        pass = pass & max(beta1 - Lin_SVC.SVC.Coefficients.beta) < eps ;
        pass = pass & max(beta2 - Quad_SVC.SVC.Coefficients.beta) < eps ;
    end
end
