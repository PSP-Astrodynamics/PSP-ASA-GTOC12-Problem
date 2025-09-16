function pass = uq_default_input_test_mergeInputs(level)
% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_mergeInputs...\n']);

pass = 1;

iOpts1.Marginals = uq_StdNormalMarginals(3);
myInput1 = uq_createInput(iOpts1);

iOpts2.Marginals = uq_StdUniformMarginals(5);
iOpts2.Marginals(1).Bounds = [0,0.2];
iOpts2.Marginals(3).Bounds = [0.9,1];
iOpts2.Copula(1) = uq_PairCopula('Gumbel', 2);
iOpts2.Copula(1).Variables = [3, 4];
iOpts2.Copula(2) = uq_IndepCopula(3);
iOpts2.Copula(2).Variables = [1,2,5];
myInput2 = uq_createInput(iOpts2);

myInput3 = uq_mergeInputs(myInput1, myInput2, '-private');

pass1 = all(myInput3.Copula(1).Variables == 1:3) && ...
        all([myInput3.Copula(2:end).Variables] == [myInput2.Copula.Variables]+3);
pass2 = strcmpi(myInput3.Copula(1).Type, myInput1.Copula.Type) && ...
        strcmpi(myInput3.Copula(2).Type, myInput2.Copula(1).Type) && ...
        strcmpi(myInput3.Copula(3).Type, myInput2.Copula(2).Type);

Vars1 = [1,3,4];
Vars2 = setdiff(1:8, Vars1);
myInput4 = uq_mergeInputs(myInput1, myInput2, Vars1, Vars2, '-private');
pass3 = all(myInput4.Copula(1).Variables == Vars1) && ...
        all([myInput4.Copula(2:end).Variables] == ...
            Vars2([[myInput2.Copula.Variables]]));

pass = pass && all([pass1 pass2 pass3]);
