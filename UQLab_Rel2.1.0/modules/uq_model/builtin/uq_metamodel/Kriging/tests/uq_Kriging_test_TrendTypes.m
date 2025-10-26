function pass = uq_Kriging_test_TrendTypes( level )
% UQ_KRIGING_TEST_TRENDTYPES(LEVEL) Non-regression and validation test 
% of the supported trend types of the Kriging module
%
% Summary:
% In the first part all the diffrerent options of Kriging.Trend.Type
% are tested and in the second part it is made sure that regression
% result is correct

%% Initialize test
pass = 1;
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| uq_Kriging_test_TrendTypes...\n']);

%% parameters
eps = 1e-5;
nvalidation = 1000 ;

%% Create inputs
Input.Marginals.Type = 'Uniform' ;
Input.Marginals.Parameters = [-2, 2] ;
Input.Name = 'Input1';
uq_createInput(Input);

Input.Marginals(2).Type = 'Uniform' ;
Input.Marginals(2).Parameters = [-1, 1] ;
Input.Name = 'Input2';
uq_createInput(Input);

%% Create the full models
% 1)  y = 0
model.Name = 'y_const';
model.mString = 'zeros(size(X))' ;
model.isVectorized = true;
evalc('uq_createModel(model)');
% 2) y = x
model.Name = 'y_lin';
model.mString = '5*X' ;
model.isVectorized = true;
evalc('uq_createModel(model)');
% 3) y = x^2
model.Name = 'y_sq';
model.mString = '3*X.^2' ;
model.isVectorized = true;
evalc('uq_createModel(model)');

% 4) y = cos(x) 
model.Name = 'y_trig';
model.mString = 'cos(X)' ;
model.isVectorized = true;
evalc('uq_createModel(model)');

% 5) y = 2*x1 * x2
model.Name = 'y_ind';
model.mString = '2*X(:,1)+ X(:,2).^2' ;
model.isVectorized = true;
evalc('uq_createModel(model)');


% Run the tests for both scaled and unscaled versions:
scaling = [0, 1];
modelID = 0;
for ii = 1 : length(scaling)
    clear metaopts;
    %% general options
    metaopts.Type = 'Metamodel';
    metaopts.MetaType = 'Kriging';
    metaopts.Input = 'Input1';
    metaopts.ExpDesign.NSamples = 100;
    metaopts.ExpDesign.Sampling = 'LHS' ;
    metaopts.Optim.InitialValue = 0.5;
    metaopts.Optim.Method = 'none';
    s = rng(10);
    metaopts.Scaling = scaling(ii);
    modelID = modelID + 1;
    %% Simple Kriging
    metaopts.Name = ['Simple_Kriging',num2str(modelID)];
    metaopts.Trend.Type = 'simple' ;
    metaopts.FullModel = 'y_const';
    metaopts.Trend.CustomF = 0;
    [~,Simple_Krig] = evalc('uq_createModel(metaopts)');
    
    %% Ordinary Kriging
    rng(s);
    metaopts.Name = ['Ordinary_Kriging',num2str(modelID)];
    metaopts.Trend.Type = 'ordinary' ;
    metaopts.FullModel = 'y_const';
    [~,Ordin_Krig] = evalc('uq_createModel(metaopts)');
    
    %% Linear Trend
    rng(s);
    metaopts.Name = ['Linear_Trend',num2str(modelID)];
    metaopts.Trend.Type = 'linear' ;
    metaopts.FullModel = 'y_lin';
    [~, Lin_Krig] = evalc('uq_createModel(metaopts)');
    
    %% Quadratic Trend
    rng(s);
    metaopts.Name = ['Quad_Trend',num2str(modelID)];
    metaopts.Trend.Type = 'quadratic' ;
    metaopts.FullModel = 'y_sq';
    [~,Quad_Krig] = evalc('uq_createModel(metaopts)');
    
    %% Custom Trend (char)
    rng(s);
    metaopts.Name = ['Custom_Trend_char',num2str(modelID)];
    metaopts.Trend.Type = 'custom' ;
    metaopts.FullModel = 'y_trig';
    metaopts.Trend.CustomF = 'cos';
    [~,Custom_Krig_char] = evalc('uq_createModel(metaopts)');
    
    %% Custom Trend (cell, char)
    rng(s);
    metaopts.Name = ['Custom_Trend_cell_char',num2str(modelID)];
    metaopts.Trend.Type = 'custom' ;
    metaopts.FullModel = 'y_trig';
    metaopts.Trend.CustomF = {'cos'};
    [~,Custom_Krig_cell_char] = evalc('uq_createModel(metaopts)');
    
    %% Custom Trend (cell, function handle)
    rng(s);
    metaopts.Name = ['Custom_Trend_cell_funchandle',num2str(modelID)];
    metaopts.Trend.Type = 'custom' ;
    metaopts.FullModel = 'y_trig';
    metaopts.Trend.CustomF = {@cos};
    [~,Custom_Krig_cell_func] = evalc('uq_createModel(metaopts)');
    
    %% Custom Trend (function handle)
    rng(s);
    metaopts.Name = ['Custom_Trend_funchandle',num2str(modelID)];
    metaopts.Trend.Type = 'custom';
    metaopts.FullModel = 'y_trig';
    metaopts.Trend.CustomF = @cos;
    [~,Custom_Krig_char] = evalc('uq_createModel(metaopts)');
    
    %% Polynomial Trend
    rng(s);
    metaopts.Name = ['Poly_Trend',num2str(modelID)];
    metaopts.Trend.Type = 'polynomial' ; 
    metaopts.FullModel = 'y_sq';
    metaopts.Trend.Degree = 3 ;
    metaopts.Trend.PolyTypes = 'simple_poly' ;
    [~,Poly_Krig] = evalc('uq_createModel(metaopts)');
    
    %% Trend : 2*x1+ x2^2
    rng(s);
    metaopts.Input = 'Input2';
    metaopts.Name = ['Custom_Coeff',num2str(modelID)];
    metaopts.FullModel = 'y_ind';
    metaopts.Trend.Type = 'polynomial' ;
%     metaopts.Trend.PolyTypes = 'auto' ;
    metaopts.Trend.PolyTypes = {'simple_poly','simple_poly'} ;
    metaopts.Trend.TruncOptions.Custom = [ 0     0     1     0     2     0     3     1     1     2
        0     1     0     2     0     3     0     1     2     1]' ;
    [~,CustomCoeff_Krig] = evalc('uq_createModel(metaopts)');
    
    %% Custom function handle
    rng(s);
    metaopts.Input = 'Input2';
    metaopts.Name = ['Custom_Handle',num2str(modelID)];
    metaopts.Trend = [];
    metaopts.Trend.Handle = @(x, dum) [ones(size(x,1),1), x(:,2), x(:,1), x(:,2).^2, x(:,1).^2, x(:,2).^3, x(:,1).^3, x(:,1).*x(:,2), x(:,1).^2.*x(:,1), x(:,1).*x(:,2).^2] ;
    metaopts.FullModel = 'y_ind';
    [~,Poly_Krig] = evalc('uq_createModel(metaopts)');
    
    %% Calculate Predictions
    Xpred = linspace(-1,1,nvalidation)' ;
    uq_selectInput('Input2');
    Xpred2 = uq_getSample(nvalidation) ;
        
    Y_simple = uq_evalModel(uq_getModel(['Simple_Kriging',num2str(modelID)]),Xpred);
    Y_ordin = uq_evalModel(uq_getModel(['Ordinary_Kriging',num2str(modelID)]),Xpred);
    Y_lin = uq_evalModel(uq_getModel(['Linear_Trend',num2str(modelID)]),Xpred);
    Y_quad = uq_evalModel(uq_getModel(['Quad_Trend',num2str(modelID)]),Xpred);
    Y_custom_char = uq_evalModel(uq_getModel(['Custom_Trend_char',num2str(modelID)]),Xpred);
    Y_custom_cell_char = uq_evalModel(uq_getModel(['Custom_Trend_cell_char',num2str(modelID)]),Xpred);
    Y_custom_cell_funchandle = uq_evalModel(uq_getModel(['Custom_Trend_cell_funchandle',num2str(modelID)]),Xpred);
    Y_custom_funchandle = uq_evalModel(uq_getModel(['Custom_Trend_funchandle',num2str(modelID)]),Xpred);

    Y_poly = uq_evalModel(uq_getModel(['Poly_Trend',num2str(modelID)]),Xpred);
    Y_ind = uq_evalModel(uq_getModel(['Custom_Coeff',num2str(modelID)]),Xpred2);
    Y_ch = uq_evalModel(uq_getModel(['Custom_Handle',num2str(modelID)]),Xpred2);
    %% Calculate full model responses on Xpred
    Y_full_const = uq_evalModel(uq_getModel('y_const'),Xpred);
    Y_full_lin = uq_evalModel(uq_getModel('y_lin'),Xpred);
    Y_full_sq = uq_evalModel(uq_getModel('y_sq'),Xpred);
    Y_full_trig = uq_evalModel(uq_getModel('y_trig'),Xpred);
    Y_full_ind = uq_evalModel(uq_getModel('y_ind'),Xpred2);
    %% make sure that predictions coincide with full models
    pass = pass & max(abs(Y_simple - Y_full_const)) < eps;
    pass = pass & max(abs(Y_ordin - Y_full_const)) < eps;
    pass = pass & max(abs(Y_lin - Y_full_lin)) < eps;
    pass = pass & max(abs(Y_quad - Y_full_sq)) < eps;
    pass = pass & max(abs(Y_custom_char - Y_full_trig)) < eps;
    pass = pass & max(abs(Y_custom_cell_char - Y_full_trig)) < eps;
    pass = pass & max(abs(Y_custom_cell_funchandle - Y_full_trig)) < eps;
    pass = pass & max(abs(Y_custom_funchandle - Y_full_trig)) < eps;
    pass = pass & max(abs(Y_poly - Y_full_sq)) < eps;
    pass = pass & max(abs(Y_ind - Y_full_ind)) < eps;
    pass = pass & max(abs(Y_ch - Y_full_ind)) < eps;
end
