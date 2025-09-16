function [testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig)
% A helper function to create a test profile file.

currentDir = fileparts(mfilename('fullpath'));
testDir = fullfile(currentDir,uq_createUniqueID());
mkdir(testDir)
testProfile = fullfile(testDir,'test_profile_file.m');
uq_Dispatcher_scripts_createProfile(testProfile,RemoteConfig)

end
