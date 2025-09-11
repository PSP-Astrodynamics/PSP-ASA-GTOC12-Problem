function pass = uq_test_morris_trajectory(level)
% PASS = UQ_TEST_MORRIS_TRAJECTORY(LEVEL): non-regression test for Morris
%     trajectories
%
% See also: UQ_MORRIS_INDICES, UQ_SENSITIVITY

uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_morris_trajectory...\n']);

switch level
    case 'slow'
        MM = [6, 12, 100];
        R = [3, 10];
        GL = [6, 13];
        PS = [1, 4];
    otherwise
        MM = 6;
        R = 3;
        % Grid levels:
        GL = 6;
        % Perturbation steps:
        PS = 1;
end

%% Loop over the specified options
for gl = GL
    for ps = PS
        for M = MM
            for r = R
                % Grid levels
                Options.Morris.GridLevels = gl;
                % Perturbation steps
                Options.Morris.PerturbationSteps = ps;
                % Create the trajectories
                [AllTraj, AllSigns, DerIdx] = uq_create_morris_trajectory(M, r, Options);
                
                % Test that the outputs are in the correct format:
                if isequal(size(AllTraj), [r*(M+1), M])
                    fprintf('\nAllTraj dim. is OK');
                else
                    error('AllTraj Bad dimension');
                end
                if isequal(size(AllSigns), [r, M])
                    fprintf('\nAllSigns dim. is OK');
                else
                    error('AllSigns Bad dimension');
                end
                if isequal(size(DerIdx), [r, M])
                    fprintf('\nDerIdx dim. is OK');
                else
                    error('DerIdx Bad dimension');
                end
                
                % Check that the difference between the points is always PerturbationSteps units:
                for ii = 1:r
                    ThisTraj = AllTraj(1 + (M + 1)*(ii - 1):(M + 1)*ii, :);
                    DiffTraj = ThisTraj(2: M + 1, :) - ThisTraj(1:M, :);
                    
                    % Check that the difference has the correct number of zeros and ones:
                    C = (DiffTraj == zeros(M));
                    if sum(sum(C)) == M^2 - M
                        fprintf('\nTraj: %d has correct no. of zeros.', ii);
                    else
                        error('Incorrect no. of zeros');
                    end
                    % Check that the other values are ps:
                    C = (abs(DiffTraj) == ps*ones(M));
                    if sum(sum(C)) == M
                        fprintf('\nTraj: %d has correct no. of perturbation values.', ii);
                    else
                        error('Incorrect no. of perturbation values');
                    end
                    
                    % Check that its rows and columns sum what they should:
                    if isequal(sum(abs(DiffTraj), 1), ps*ones(1, M)) ...
                            && isequal(sum(abs(DiffTraj), 2), ps*ones(M, 1))
                        fprintf('\nTraj: %d is correct in terms of displacements.', ii);
                    else
                        error('Trajs. are not correct');
                    end
                    
                    % Test that AllSigns and DerIdx are correct:
                    ThisSigns = AllSigns(ii, :);
                    ThisIdx = DerIdx(ii, :)';
                    for jj = 1:M
                        if abs(DiffTraj(ThisIdx(jj), jj)) ~= ps
                            fprintf('\nError in traj: %d, derivative %d.', ii, jj);
                            fprintf('\nGot %.3f, while expecting %.3f\n', DiffTraj(ThisIdx(jj), jj), ThisSigns(jj)*ps);
                            error('DerIdx is not correct');
                        elseif DiffTraj(ThisIdx(jj), jj) ~= ThisSigns(ThisIdx(jj))*ps
                            fprintf('\nError in traj: %d, derivative %d.', ii, jj);
                            fprintf('\nGot %.3f, while expecting %.3f\n', DiffTraj(ThisIdx(jj), jj), ThisSigns(jj)*ps);
                            error('AllSigns is not correct');
                        end
                    end
                    fprintf('\nDerIdx and AllSigns are correct for traj: %d.', ii);
                end
                fprintf('\n');
            end
        end
    end
end
%% FINAL RESULT
pass = 1;
