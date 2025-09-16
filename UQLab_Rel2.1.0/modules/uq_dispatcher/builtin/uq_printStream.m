function uq_printStream(OutputStreams,fieldName)

%%
if nargin < 2
    fprintf('Select the output stream to print:\n')
    fprintf('    - ''SubmitStdOut''  : submission command standard output\n')
    fprintf('    - ''JobStdOut''     : job execution standard output\n')
    fprintf('    - ''JobStdErr''     : job execution standard error\n')
    fprintf('    - ''ProcessStdErr'' : (MATLAB) process error\n')
    fprintf('    - ''TaskStdOut''    : (Bash) task execution standard output\n')
    fprintf('    - ''TaskStdErr''    : (Bash) task execution standard error\n')
    fprintf('    - ''TaskExitStatus'': (Bash) task execution exit status\n')
    fprintf('\n')
    fprintf('Example: uq_printStream(myOutputStreams,''JobStdOut'')\n')
    return
end

%%
outputStream = OutputStreams.(fieldName);

if any(strcmpi(fieldName,{'submitstdout','jobstdout','jobstderr'}))
    fprintf('%s\n',outputStream{:})
end


if any(strcmpi(fieldName,{'processstderr'}))
    for i = 1:numel(outputStream)
        fprintf('\n')
        s = sprintf('%s\n', outputStream{i}{:});
        fprintf('%%--- Process %d ---%%\n\n',i)
        fprintf('%s',s)
    end
    fprintf('\n')
end

%% Task streams
if any(strcmpi(fieldName,{'taskstdout','taskstderr','taskexitstatus'}))
    for i = 1:numel(outputStream)
        fprintf('\n')
        s = sprintf('%s\n', outputStream{i}{:});
        fprintf('%%--- Task %d ---%%\n',i)
        fprintf('%s',s)
    end
    fprintf('\n')
end

end