function pass = uq_default_input_test_extractInputs(level)
% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_extractInputs...\n']);
pass = true;

% initialize
nDim = 5; extractDims = [2 4];

iOpts.Marginals = uq_StdUniformMarginals(nDim);
for ii = 1:nDim
    iOpts.Marginals(ii).Bounds = [1 2]*rand;
end
myInput = uq_createInput(iOpts);

% extract from myInput
newInput = uq_extractInputs(myInput, extractDims);

% some tests
for ii = 1:length(extractDims)
    dd = extractDims(ii);
    if ~(all(newInput.Marginals(ii).Bounds == myInput.Marginals(dd).Bounds))
        pass = false;
        break
    end
end
end
