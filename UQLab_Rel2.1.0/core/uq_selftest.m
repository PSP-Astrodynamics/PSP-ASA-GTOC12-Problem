function success = uq_selftest(level)
% UQ_SELFTEST(level) executes all the selftests found at the specified
% level
fid = fopen('Log_uq_selftest.txt','a+');
% Retrieve the uqlab main path and move to it
mainpath = fullfile(uq_rootPath, 'modules');



% Modules to be checked
modules = {'uq_dispatcher','uq_analysis', 'uq_input', 'uq_model'};

% Subfolders of the modules to be checked
subfolders = {'builtin','contrib'};

% Save the name of the performed tests:
AllTests = {};

% Execute the uqlib selftests
fprintf('\nTesting component: %s...','uq_lib');
selftest = 'uq_selftest_uq_uqlib';
try
    [Output, success] = evalc(selftest);
    fprintf(fid,['\n\n\n --- ' selftest ' output ---\n\n\n']);
    fprintf(fid,'%s', Output);
    ErrMsg = 0;
catch ME
    success = 0;
    ErrMsg = sprintf(['\n  *** ' ME.message ' ***\n']);
end
if success
    fprintf('\t\t\t[OK]');
    ResMsg = sprintf('\t\t\t [OK]');
else
    fprintf('\t\t[FAILED]');
    ResMsg = sprintf('\t\t\t [FAILED]');
end
AllTests = [AllTests ;[selftest,ResMsg,ErrMsg]]; % Store its name

for i = 1:length(modules)
    for j = 1:length(subfolders)
        
        % Retrieve the contents of the folder
        components = dir(fullfile(mainpath, modules{i}, subfolders{j}));
        
        % First two are always "." and ".."
        components(1:2) = []; 
        
        % Check that the ones that are folders (correspond to modules) have
        % a file inside named uq_selftest_<module name> and run it.
        for k = 1:length(components)
            if ~components(k).isdir
                continue
            end
            
            % Name of the selftest
            selftest = ['uq_selftest_' components(k).name];
            
            if exist(selftest, 'file') % Then we run it
                fprintf('\nTesting component: %s...',components(k).name);
                try
                    [Output, success] = evalc(selftest);
                    fprintf(fid,['\n\n\n --- ' selftest ' output ---\n\n\n']);
                    fprintf(fid,'%s', Output);
                    ErrMsg = 0;
                catch ME
                    success = 0;
                    ErrMsg = sprintf(['\n  *** ' ME.message ' ***\n']);
                end
                if success
                    fprintf('\t\t[OK]');
                    ResMsg = sprintf('\t\t\t [OK]');
                else
                    fprintf('\t\t[FAILED]');
                    ResMsg = sprintf('\t\t\t [FAILED]');
                end
                AllTests = [AllTests ;[selftest,ResMsg,ErrMsg]]; % Store its name
            end
        end
    end
    
end



% Display on the command window:
fprintf('\n\n --- UQLab selftest results ---\n\n');
fprintf('+ %s \t \n', AllTests{:});

% Write on the log file:
fprintf(fid, '\n\n --- UQLab selftest results ---\n\n');
fprintf(fid, '+ %s \t \n', AllTests{:});
fclose(fid);