function success = uq_PCE_test_set_marginals()
% PASS = UQ_PCE_TEST_SET_MARGINALS(LEVEL): non-regression test to assert
%     the proper handling of input distributions when using manually specified
%     specified PolyTypes.
%
% Description:
%
%   This is a test checking that it is possible to set different 
%   "Marginals" with different parameters along various directions and
%   their respective polynomials and parameters are set correctly.
%
% testing procedure:
%  * set the marginals to an Input instance
%
%  * run uq_auto_retrieve_poly_types
%
%  * check that the output of the uq_auto_retrieve_poly_types 
%    is correct.


success = true;

test_input.Marginals(1).Type = 'uniform' ;
test_input.Marginals(1).Parameters = [-pi , pi] ;

test_input.Marginals(2).Type = 'gamma' ;
test_input.Marginals(2).Parameters = [15 , 3] ;

test_input.Marginals(3).Type = 'beta' ;
test_input.Marginals(3).Parameters = [5 , 15, -0.3 , 0.5] ;

test_input.Marginals(4).Type = 'gaussian' ;
test_input.Marginals(4).Parameters = [0 , 0.1] ;

my_test_input = uq_createInput(test_input);

ptypes_res = uq_auto_retrieve_poly_types(test_input);
success = success & sum(strcmp(ptypes_res,{'Legendre';'Laguerre';'Jacobi';'Hermite'})) == length(ptypes_res);
if(~success)
    disp('*** The polynomials are not deduced correctly by the uq_auto_retrieve_poly_types function!')
end

modelopts.mFile = 'uq_ishigami' ;
myModel = uq_createModel(modelopts);
metaopts.FullModel = myModel;
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'PCE';
metaopts.Method = 'Quadrature' ;
metaopts.Degree = 15;
mymetamodel = uq_createModel(metaopts);

% Check that the metamodel creation does not violate the expected behavior


