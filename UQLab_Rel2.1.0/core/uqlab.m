% UQLAB   Initialize the UQLab uncertainty quantification software
%    UQLab is the uncertainty quantification software developed in the Matlab 
%    environment at ETH Zurich. It allows you to set up ingredients for a UQ 
%    analysis, namely to define a probabilistic INPUT model (input random 
%    variables), a computational MODEL, and to select the ANALYSIS you want 
%    to carry out, e.g. create a surrogate model, compute sensitivity indices, 
%    compute a probability of failure, etc.
%
%    Usage:
%    UQLAB - Initialize the UQLab framework and clear the current UQLab
%    session
%
%    UQLAB('SESSIONFILE.mat') - load the UQLab session file SESSIONFILE.mat
%    previously created with the uq_saveSession('SESSIONFILE.mat') command.
%    All the objects created can be accessed by using the <a href="matlab:help uq_getModel">uq_getModel</a>,
%    <a href="matlab:help uq_getInput">uq_getInput</a> and <a href="matlab:help uq_getAnslysis">uq_getAnalysis</a> commands.
%
%    See also: uq_saveSession, uq_createInput, uq_getInput, uq_createModel,
%              uq_getModel, uq_createAnalysis, uq_getAnalysis 
%
%    To access the list of available user manuals, please use the following 
%    command: <a href="matlab:uqlab -doc">uqlab -doc</a>
%


% Copyright (c) 2013-2024, Stefano Marelli and Bruno Sudret (ETH Zurich)
% 
% Redistribution and use of UQLab in source and binary forms, with 
% or without modification, are permitted provided that the following 
% conditions are met:  
% 
% 1. Redistributions of source code must retain the above copyright
% notice, this list of conditions and the following disclaimer.  
% 
% 2. Redistributions in binary form must reproduce the above copyright
% notice, this list of conditions and the following disclaimer in the
% documentation and/or other materials provided with the distribution. 
% 
% 3. Neither the name of Stefano Marelli, Bruno Sudret or ETH Zurich nor
% the names of its contributors may be used to endorse or promote
% products derived from this software without specific prior written
% permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
% A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
% HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
% LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
% DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
% THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 


function uqlab(varargin)
% UQLAB: access point to the UQLab facilities
VERSION_ID = '2.0';
% first of all, set the relevant paths for core initialization
root_folder = uq_rootPath;
addpath(fullfile(root_folder));
addpath(fullfile(root_folder,'core'));



%% Setting the default options/flags
% by default we are not importing a session, but starting a new one
import = false; 
% show the splashscreen on default
showsplash = true;


%% parsing the command line
parse_keys = {'-nosplash', '-selftest', '-version', '-license', '-rngshuffle','-help','-doc'};
parse_types = {'f', 'f', 'f', 'f', 'f','f','f'};
[uq_startup_options, varargin] = uq_simple_parser(varargin, parse_keys, parse_types);

% the index of the startup options is the same as in parse_keys and
% parse_types

% set the splash flag to disabled if specified
if strcmp(uq_startup_options{1}, 'true') 
    showsplash = false;
end

% execute the selftest routines and exit
if strcmp(uq_startup_options{2}, 'true') 
    uq_selftest;
    return;
end

% execute the get version routine and exit
if strcmp(uq_startup_options{3}, 'true') 
    uq_get_version(VERSION_ID);
    return;
end

% execute the get version routine and exit
if strcmp(uq_startup_options{4}, 'true') 
    disp(fileread(fullfile(uq_rootPath(),'LICENSE')));
    return;
end



% shuffle the random seed if required
if strcmp(uq_startup_options{5}, 'true') 
    rng('shuffle');
end

% show some useful help
if strcmp(uq_startup_options{6}, 'true') 
    help uqlab;
    return;
end

% show the available documentation
if strcmp(uq_startup_options{7}, 'true') 
    uq_doc;
    return;
end


% at this stage, clear the page and throw out the copyright notice if not
% disabled
if showsplash
    uq_disp_disclaimer;
end


%% ok, now it's time to instance the gateway/uqlab session
%  this is local to the current MATLAB instance, therefore we MUST run it
%  even when running through the dispatcher

gwoptions.new = true;
uq_gw = uq_gateway.instance(gwoptions);
    


% now the retrieval of a previous session comes into play
if numel(varargin) % let's assume the first non-empty option in the command line is a file from which to load configuration
    try
        uq_gw.import_session_from_file(varargin{1});
        import = true;
    catch me
        warning('Could not import session from file ''%s'', starting a new session instead', varargin{1});
    end
end


%% dispatcher & workflow initialization

if ~import
    %% workflow initialization here
    % % add a default workflow if not importing a session
    wf = uq_gw.workflow.add_module('default');
        
    % add a default dispatcher as well
    uq_gw.dispatcher.add_module('empty', 'empty');
    % set it to consistent values
    wf.set_workflow({'dispatcher'}, {'empty'});
end

% UQLab is now initialized



%% Extra functions
function uq_get_version(VERSION_ID)

fprintf('UQLab version : %s.\n',VERSION_ID) ; 
