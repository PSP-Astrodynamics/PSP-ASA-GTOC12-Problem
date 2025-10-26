function uq_disp_disclaimer
% Interactive display
DMODE = usejava('Desktop');
if DMODE
    MAILSTR = '<a href="mailto:marelli@ibk.baug.ethz.ch">marelli@ibk.baug.ethz.ch</a>';
    LICFILE = '<a href="https://uqlab.com/license">https://uqlab.com/license</a>';
else
    MAILSTR =  'marelli@ibk.baug.ethz.ch';
    LICFILE = 'https://uqlab.com/license';
end
fprintf('Copyright 2013-2024, Stefano Marelli and Bruno Sudret.\n' )
fprintf('This is UQLab, version 2.1\n')
fprintf('UQLab is distributed under the BSD 3-clause open source license available at: \n%s.\n\n',LICFILE)
fprintf('To request special permissions, please contact:\n')
fprintf('  - Stefano Marelli (%s).\n\n',MAILSTR)

if DMODE
    fprintf(['Useful commands to get started with UQLab:\n'...
        '<a href="matlab:uqlab -doc">uqlab -doc</a>           - Access the available documentation\n'...
        '<a href="matlab:uqlab -help">uqlab -help</a>          - Additional help on how to get started with UQLab\n'...
        '<a href="matlab:uq_citation help">uq_citation help</a>   - Information on how to cite UQLab in publications\n' ...
        '<a href="matlab:uqlab -license">uqlab -license</a>       - Display UQLab license information\n\n'
    ])
end
