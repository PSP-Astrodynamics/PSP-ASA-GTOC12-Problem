function pass = uq_checkMATLAB(matlabMinimum)
%UQ_CHECKMATLAB checks if a minimum version of MATLAB requirement is met.
%
%   PASS = UQ_CHECKMATLAB(MATLABMINIMUM) checks if the minimum version of
%   MATLAB requirement MATLABMINIMUM is met. The function returns TRUE if
%   the requirement is met and FALSE otherwise. MATLABMINIMUM is given as a
%   char-array, for example: 'r2015b', 'r2017b', '2018a', '2014a'. If the
%   character suffix 'a' or 'b' is not specified, it is assumed to be 'a'.
%

%% Parse and verify input
matlabMinimum = lower(matlabMinimum);
matlabMinimum = strrep(matlabMinimum,'r','');

%% Parse the current MATLAB version
matlabRelease = version('-release');

% Version number
versionNumber = regexp(matlabRelease, '[0-9]+', 'match');
versionNumber = str2double(versionNumber{1});
% Version release
versionRelease = regexp(matlabRelease, '[ab]', 'match');
versionRelease = versionRelease{1};

%% Parse the minimum MATLAB requirement

% Version number
versionNumberMin = regexp(matlabMinimum, '[0-9]+', 'match');
versionNumberMin = str2double(versionNumberMin{1});
% Version release
versionReleaseMin = regexp(matlabMinimum, '[a-z]', 'match');
if isempty(versionReleaseMin)
    versionReleaseMin = 'a';
else
    versionReleaseMin = versionReleaseMin{1};
end

%% Compare the current MATLAB and the minimum requirement
pass = (versionNumber > versionNumberMin) || ...
    (versionNumber == versionNumberMin &&...
        versionRelease >= versionReleaseMin);

end