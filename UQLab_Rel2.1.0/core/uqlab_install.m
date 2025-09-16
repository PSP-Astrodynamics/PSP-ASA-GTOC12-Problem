function uqlab_install
UQLABROOTCORE = fileparts(which('uqlab_install'));
% strip the final "core"
UQLABROOT = UQLABROOTCORE(1:end-5);

% figure out whether we are in interactive mode
DESKTOPMODE=usejava('desktop') ;
% prompt the user for a license if not already existing

%% Version and toolbox checks
try
    % Make sure that the host Matlab version is at least 2011x
    vstr = version('-release');
    v = str2double(vstr(1:4));
    version_check = v > 2016;
catch
    version_check = false;
end
try
    % Make sure that the Statistics toolbox is installed
    xx = lhsdesign(1,1);
    statistics_check = true;
catch
    statistics_check = false;
end

try
    % Make sure that the optimization toolbox is avaialble
    evalc('x = fmincon(@(x)x.^2, 0.5, 1, 3);');
    optimization_check = true;
catch
    optimization_check = false;
end

try
    % Make sure that the global optimization toolbox is avaialble
    GAoptions = gaoptimset;
    goptimization_check = true;
catch
    goptimization_check = false;
end

%% fail and print an error report in case any of the previous checks fails
if ~(version_check && statistics_check)
    disp('Minimum system requirements not met, UQLab can not be installed on this system.')
    version_result = {'Ok', '*Fail*'};
    toolbox_result = {'Available', '*Not Available*'};
    fprintf('\t Matlab version (>=R2016a): %s \t[%s]\n', vstr, version_result{2-version_check})
    fprintf('\t Statistics toolbox: \t\t\t[%s]\n', toolbox_result{2-statistics_check})
    fprintf('\n')
    error('Installation failed: minimum system requirements not met');
end
% Issue a warning if neither optimization or global optimization toolbox
% licenses are available
if ~optimization_check && ~goptimization_check
   fprintf('No available license for the optimization toolbox and for the global optimization toolbox\n');
   warning('Some features of the software may not be available'); 
end
%% Check whether an old installation of UQLab exists and prompt the user for removal
Uninstall = false;
PrevUQPaths = which('uqlab', '-ALL');
if ischar(PrevUQPaths)
    PrevUQPaths = {PrevUQPaths};
end
% remove from the paths those which are identical to PWD
curPWD = pwd;
PWDIdx = false(length(PrevUQPaths),1);
for ii = 1:length(PrevUQPaths)
    pp = fileparts(PrevUQPaths{ii});
    if isequal(pp,curPWD)
       PWDIdx(ii) = true;
    end
end
PrevUQPaths(PWDIdx) = [];

% Prompt the user for the removal of previous versions
try
    if ~isempty(PrevUQPaths) 
        Response = questdlg({'Other versions of UQLab found','do you want to remove them from the MATLAB path?'},...
            'UQLab Installer', 'Yes', 'No', 'Cancel', 'Yes');
        switch Response
            case 'No'
                Uninstall = false;
            case 'Yes'
                Uninstall = true;
            case 'Cancel'
                disp('Installation cancelled by the user')
                return;
        end
    end
catch me
    
end
%% Remove older versions from the PATH if requested
if Uninstall
    % Add the path of UQLABROOT
    addpath(fullfile(UQLABROOT, 'core'), '-BEGIN');
    % loop over the various installations
    for ii = 1:length(PrevUQPaths)
        CurRootPath = fileparts(PrevUQPaths{ii});
        % remove the trailing 'core'
        CurRootPath = CurRootPath(1:end-5);
        % split the path in a cell of individual paths
        splitPath = uq_strsplit(path, pathsep);
        % prepare a logical mask to remove the unwanted paths
        pathMask = false(size(splitPath));
        % identify the path lines belonging to the old installation
        tt = strfind(splitPath,CurRootPath);
        % update the path mask
        for jj = 1:length(tt)
            pathMask(jj) =  isempty(tt{jj});
        end
        % join again the selected path elements into a path string
        newPath = uq_strjoin(splitPath(pathMask), pathsep);
        % set the final path
        path(newPath);
    end
end

%% add the UQLABROOT/core path to the top of the MATLAB path and save it
try
    % Add the path of UQLABROOT
    addpath(fullfile(UQLABROOT, 'core'), '-BEGIN');
    %clear java;
    %clear classes;
    status = savepath;
    if status
        fprintf(['Warning: the UQLab installer detected that the MATLAB path could not be saved.\n' ...
            'Please make sure that the MATLAB startup folder is set to a writable location in the MATLAB preferences:\n'...
            'Preferences->General->Initial Working Folder\n'
            ]);
    end
    uqlab;
    fprintf('\nUQLab installation complete! \n\n');
catch me
    fprintf('The installation was not successful!\nThe installer returned the following message: %s\n\n', me.message);
end
