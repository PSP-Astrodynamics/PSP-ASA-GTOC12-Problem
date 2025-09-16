function mySequence = uq_Dispatcher_tests_support_mySeqGen(varargin)

rng(varargin{3},'twister')
mySequence = varargin{1} + varargin{2} * randn(1e5,1e2);

end
