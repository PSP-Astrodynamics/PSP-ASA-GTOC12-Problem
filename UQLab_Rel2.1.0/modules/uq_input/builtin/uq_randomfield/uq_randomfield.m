function [ SampleRF, xi ] = uq_randomfield( inputObj, N, varargin )
% uq_randomfield generates N random field trajectories based on inputObj,
% together with realization of the underlying standard Gaussian random
% variables xi

[ SampleRF, xi ] = uq_getRFSample( inputObj, N, varargin{:} ) ;

