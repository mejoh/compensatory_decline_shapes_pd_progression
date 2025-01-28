% Summarise 1st-level beta values in significant clusters
% Depends on the ExtractClusters.sh script
% 1st-level images are those that were used as inputs for 3dLME/3dttest++
% These images are concatenated and used to extract stats with idx masks
% Cluster index masks are loaded using spm_atlas
% spm_summarise extracts the average beta within each cluster
% Averages are appended to the datatable that was used as input in group
% comparisons
% @Martin E. Johansson, 28/01/2025

function ExtractBetas(dir,con)

dStats =  fullfile(dir, 'stats');

% Find cluster index masks
% Exit if none are found
Masks = spm_select('FPList',dStats, [con '.*_idxmask.nii']);
if size(Masks,1) > 0
    msg = ['Masks found for search pattern ' [con '.*_idxmask.nii'] '\n'];
    fprintf(msg)
    Masks = cellstr(spm_select('FPList',dStats, [con '.*_idxmask.nii']));  % Find cluster index masks
else
    msg = ['No masks found for search pattern ' [con '.*_idxmask.nii'] ', moving on...\n'];
    fprintf(msg)
    return
end

% Load data table and concatenate betas
tname = 'con_combined_disease_dataTable2.txt';
fname_dataTable = spm_select('FPList', dir, tname);
if(size(fname_dataTable,1)>1)
    msg = strcat('Error: More than one dataTable found in ', dir);
    error(msg)
end
dataTable = readtable(fname_dataTable);     % input table
spm_file_merge(dataTable.InputFile, fullfile(dStats, '4d_Cons'))    % Concatenate 1st-level contrasts
ConcatImg = spm_select('FPList', dStats, '4d_Cons.nii');

for m = 1:numel(Masks)
    % For each value in each cluster index mask, extract the average beta
    % estimate and append it to the 3dLME input table
    IdxMask = spm_atlas('load', Masks{m}); %https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=SPM;d4de8f88.1704
    for i = 2:numel(IdxMask.labels) % Note that labels include 0, which is the background. Therefore, skip first label
        clear d
        d = spm_summarise(ConcatImg, spm_atlas('mask',IdxMask,IdxMask.labels(i).index), @mean);
        d = round(d,5);
        colname = erase(IdxMask.info.name, {'_idxmask' '_x_' 'Group2' 'TimepointNr2' 'Type3', 'Severity2'});
        colname = {[colname '_cid' num2str(IdxMask.labels(i).index)]};
        d = table(d,'VariableNames',colname);
        dataTable = [dataTable,d];
    end
end
outputname = fullfile(dStats, [con '_dataTable_' date '.txt']);
writetable(dataTable, outputname)

% Binary mask of all contrast images
% ci = ConcatImg;
% co = fullfile('/project/3024006.02/Analyses/DurAvg_ReAROMA_PMOD_TimeDer_Trem/Group/Longitudinal/Masks', '3dLME_4dConsMask.nii');
% spm_imcalc(ci, co, '(i1.^2) > 0');

if exist(ConcatImg,'file')
    delete(ConcatImg)
end

end