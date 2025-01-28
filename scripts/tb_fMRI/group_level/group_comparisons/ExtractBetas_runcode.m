% @Martin E. Johansson, 28/01/2025

% ROI
dir = '/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/ROI/Masked_full/3dLME_disease';
con = {'con_combined_Group2_x_TimepointNr2_x_Type3_Z_Group';
    'con_combined_Group2_x_TimepointNr2_x_Type3_z_Group_by_Type';
    'con_combined_Group2_x_TimepointNr2_x_Type3_z_Group_by_Time';
    'con_combined_Group2_x_TimepointNr2_x_Type3_z_Group_by_Type_Time'};
for c = 1:numel(con)
    ExtractBetas(dir,con{c})
end

% Whole brain
dir = '/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/WholeBrain/3dLME_disease';
con = {'con_combined_Group2_x_TimepointNr2_x_Type3_Z_Group';
    'con_combined_Group2_x_TimepointNr2_x_Type3_z_Group_by_Type';
    'con_combined_Group2_x_TimepointNr2_x_Type3_z_Group_by_Time';
    'con_combined_Group2_x_TimepointNr2_x_Type3_z_Group_by_Type_Time'};
for c = 1:numel(con)
    ExtractBetas(dir,con{c})
end

% Unused: included for potential later use.
% COI='con_combined';
% AOI={'disease' 'severity'};
% for a = 1:numel(AOI)
%     motor_ROI_BetaExtraction(COI, a, false)
% end

