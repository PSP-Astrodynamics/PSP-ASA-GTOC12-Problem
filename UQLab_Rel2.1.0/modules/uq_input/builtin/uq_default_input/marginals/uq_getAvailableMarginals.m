function marginals = uq_getAvailableMarginals( varargin )
% UQ_GETAVAILABLEMARGINALS retrieves the list of the names of the built-in
% distributions

%% get the parent folder where all the built-in marginals are stored
root_folder =  uq_rootPath ;
marginals_folder = fullfile(root_folder,'modules','uq_input','builtin',...
    'uq_default_input','marginals');

%% parse input arguments
switch length(varargin)
    case 0 
        PRINT_REPORT = false;
    case 1
        PRINT_REPORT = varargin{1};
    otherwise
        error('Too many input arguments!')
end


%% get the list of built-in marginals
% Each folder inside marginals_folder is expected to be a distribution
% definition
files = dir(marginals_folder);
dirFlags = [files.isdir];
marginals = files(dirFlags);
marginals = {marginals.name};

% remove the '.' and '..' folder names
marginals = marginals(~strcmp(marginals, '.'));
marginals = marginals(~strcmp(marginals, '..'));

M = length(marginals) ;

PDF_EXISTS = zeros(M, 1); 
CDF_EXISTS = zeros(M, 1); 
INVCDF_EXISTS = zeros(M, 1); 
PTOM_EXISTS = zeros(M, 1); 
MTOP_EXISTS = zeros(M, 1); 


for ii = 1 : length(marginals)
	PDF_EXISTS(ii) = exist(fullfile(marginals_folder,marginals{ii}, ...
                sprintf('uq_%s_pdf.m', marginals{ii})), 'file') | ...
                exist(fullfile(marginals_folder, marginals{ii},...
                sprintf('uq_%s_pdf.p', marginals{ii})), 'file') ;
    CDF_EXISTS(ii) = exist(fullfile(marginals_folder, marginals{ii},...
                sprintf('uq_%s_cdf.m', marginals{ii})), 'file') | ...
                exist(fullfile(marginals_folder, marginals{ii},...
                sprintf('uq_%s_cdf.p', marginals{ii})), 'file') ;
    INVCDF_EXISTS(ii) = exist(fullfile(marginals_folder, marginals{ii},...
                sprintf('uq_%s_invcdf.m', marginals{ii})), 'file') | ...
                exist(fullfile(marginals_folder, marginals{ii},...
                sprintf('uq_%s_invcdf.p', marginals{ii})), 'file') ;
    PTOM_EXISTS(ii) = exist(fullfile(marginals_folder, marginals{ii},...
                sprintf('uq_%s_PtoM.m', marginals{ii})), 'file') | ...
                exist(fullfile(marginals_folder, marginals{ii},...
                sprintf('uq_%s_PtoM.p', marginals{ii})), 'file') ;
    MTOP_EXISTS(ii) = exist(fullfile(marginals_folder, marginals{ii},...
                sprintf('uq_%s_MtoP.m', marginals{ii})), 'file') | ...
                exist(fullfile(marginals_folder, marginals{ii},...
                sprintf('uq_%s_MtoP.p', marginals{ii})), 'file') ;
end




%% Print report if requested to 
if PRINT_REPORT
    rep = table(marginals', PDF_EXISTS, CDF_EXISTS, INVCDF_EXISTS, ...
        PTOM_EXISTS, MTOP_EXISTS);
    disp('');
    disp('Built-in marginals:');
    disp('');
    fprintf('Name \t\t PDF \t CDF \t invCDF \t PtoM \t MtoP\n');
    fprintf('____ \t\t ___ \t ___ \t ______ \t ____ \t ____\n');
    for ii = 1 : length(marginals)
       if length(marginals{ii}) > 6
           fprintf('%s \t %i \t %d \t %d \t\t %d \t %d\n', ...
               marginals{ii}, PDF_EXISTS(ii), CDF_EXISTS(ii), INVCDF_EXISTS(ii), ...
               PTOM_EXISTS(ii), MTOP_EXISTS(ii));
       else
           fprintf('%s \t\t %d \t %d \t %d \t\t %d \t %d\n', ...
               marginals{ii}, PDF_EXISTS(ii), CDF_EXISTS(ii), INVCDF_EXISTS(ii), ...
               PTOM_EXISTS(ii), MTOP_EXISTS(ii));
       end
    end
end

% The available marginals are considered the ones that their 
% PDF, CDF and inverse CDF are given.
AVAILABLE = PDF_EXISTS & CDF_EXISTS & INVCDF_EXISTS ; 
INVALID = ~AVAILABLE;

if sum(INVALID) > 0
   fprintf('The following distributions are not fully defined:\n')
   for ii = 1 : length(INVALID)
      if INVALID(ii)
            fprintf('\t%s\n', marginals{ii}) 
      end
   end
   fprintf('Please make sure that their PDF, CDF and inverse CDF files exist and are properly named.\n')
end

% Return only the 'AVAILABLE' marginals
marginals = marginals(AVAILABLE);