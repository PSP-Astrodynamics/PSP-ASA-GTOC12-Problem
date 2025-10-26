function uq_textProgressBar(P)
%UQ_TEXTPROGRESSBAR prints out a progress bar to the command window 
%
%   UQ_TEXTPROGRESSBAR(P) will print out the progress in percent P to the
%   command window. If called with P = 0, the bar is initialized. Repeated
%   calls with 0 < P <= 1 will refresh the plotted progress bar.
%
%   It is important, that UQ_TEXTPROGRESSBAR is properly initialized by
%   calling it with P = 0 and not printing any output to the command window
%   between repeated calls to UQ_TEXTPROGRESSBAR.

if P < 0 || P > 1
    error('The argument is outside the definition range [0,1].')
end

% Setup
barLength = 30;
barDelimiter = '|';
barFilled = '#';
barEmpty = ' ';

% Percentage template
barPercentage_temp = '%7.2f%%%%';

% assemble bar
progress = [repmat(barFilled,1,round(P*barLength)),repmat(barEmpty,1,barLength - round(P*barLength))];
barPercentage = sprintf(barPercentage_temp,P*100);
BAR = [barDelimiter,progress,barDelimiter,barPercentage];

if P == 0
    % newline
    tt = '\n';
else
    % Update bar
    % Delete previous line plus newline
    tt = repmat('\b',1,length(BAR)-1);
end

% Print out actual bar
fprintf([tt BAR])

if P == 1
    % newline
    fprintf('\n');
end

