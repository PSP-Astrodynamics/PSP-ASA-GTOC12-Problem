function merged_results = uq_metamodel_merge_exp_design(resultfiles)
% MERGED_RESULTS = UQ_METAMODEL_MERGE_EXP_DESIGN(RESULTFILES): merge
%     results from HPC-enabled evaluation a surrogate model ED evaluation.

uq_retrieveSession

% the current analysis name
model_name = UQ_model.Name;

merged_results{1} = [];

for i = 1:length(resultfiles)
    % load the output files and only retrieve the important information
    imported = load(resultfiles{i}, 'UQ');
    results{i} = imported.UQ.model.get_module(model_name).ExpDesign.Y;
end


merged_results = [results{:}];

UQ_model.ExpDesign.Y = merged_results;


uq_saveSession([resultfiles{1}(1:end-6) 'merged.mat']);
