# Generate the final .txt input files to AFNI.
# This script contains two potential extensions that are currently not used:
#  1. Subtype comparisons, as defined by Johansson et al. 2023+2024.
#  2. Matching of patients and control samples.
# @Martin E. Johansson, 28/01/2025

source("/home/sysneu/marjoh/scripts/Personalized-Parkinson-Project-Motor/AFNI/dataTable_3dLMEr_single.R")

library(tidyverse)

# Write tables for summary contrasts
dataTable_3dLMEr_single(con = 'con_0007.nii')
dataTable_3dLMEr_single(con = 'con_0010.nii')
dataTable_3dLMEr_single(con = 'con_0011.nii')
dataTable_3dLMEr_single(con = 'con_0012.nii')

# Write tables for choice contrasts
dataTable_3dLMEr_single(con = 'con_0001.nii')
dataTable_3dLMEr_single(con = 'con_0002.nii')
dataTable_3dLMEr_single(con = 'con_0003.nii')
dataTable_3dLMEr_single(con = 'con_0005.nii')

# Assemble combined tables for group comparisons
c1 <- read_tsv('/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_0001_disease_dataTable.txt') %>%
  mutate(trial_type = '1c')
c2 <- read_tsv('/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_0002_disease_dataTable.txt') %>%
  mutate(trial_type = '2c')
c3 <- read_tsv('/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_0003_disease_dataTable.txt') %>%
  mutate(trial_type = '3c')
c2n3 <- read_tsv('/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_0005_disease_dataTable.txt') %>%
  mutate(trial_type = '23c')

# Patients vs Controls
match_groups <- function(df){
  
  library(MatchIt)
  set.seed(312)
  
  # Find subjects with complete data
  subj_t0 <- df %>% filter(TimepointNr=='T0') %>% select(Subj) %>% unique()
  subj_t1 <- df %>% filter(TimepointNr=='T1') %>% select(Subj) %>% unique()
  subj_complete <- intersect(subj_t0$Subj,subj_t1$Subj)
  df1 <- df %>% filter(Subj %in% subj_complete)
  
  # Find matching pairs of controls and patients
  matching1 <- df1 %>%
    filter(TimepointNr == 'T0',
           trial_type == '1c') %>%
    mutate(Group = factor(Group),
           Sex = factor(Sex),
           RespHandIsDominant = factor(RespHandIsDominant)) %>%
    matchit(Group ~ Age + Sex + NpsEducYears + RespHandIsDominant,
            data = .,
            method = 'optimal',
            distance = 'glm',
            link = 'probit',
            estimand = 'ATT',
            tol = 1e-4)
  matched_ids1 <- match.data(matching1) %>%
    select(Subj)
  
  # Subset data
  df1 <- df1 %>% filter(Subj %in% matched_ids1$Subj)
  
  df1
  
}
c12 <- full_join(c1,c2)
c123 <- full_join(c12,c3) %>%
  arrange(Subj, TimepointNr, trial_type) %>% relocate(Subj, Group, trial_type)
OutputName <- '/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_combined_disease_dataTable.txt'
write_tsv(c123, OutputName)

c123 %>% match_groups() %>% write_tsv(., '/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_combined_disease_dataTable_matched.txt')

c123.c <- full_join(c1,c2n3) %>%
    arrange(Subj, TimepointNr, trial_type) %>% relocate(Subj, Group, trial_type)
OutputName <- '/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_combined_disease_dataTable2.txt'
write_tsv(c123.c, OutputName)

c123.c %>% match_groups() %>% write_tsv(., '/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_combined_disease_dataTable2_matched.txt')

# Controls vs Subtypes
tmp <- c123.c %>%
    filter(Subtype == '0_Healthy' | Subtype == '1_Mild-Motor') %>%
    mutate(Subtype = if_else(Subtype=='0_Healthy','G1','G2'))
OutputName <- '/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_combined_disease_HCvsMMP_dataTable.txt'
write_tsv(tmp, OutputName)
tmp <- c123.c %>%
    filter(Subtype == '0_Healthy' | Subtype == '2_Intermediate') %>%
    mutate(Subtype = if_else(Subtype=='0_Healthy','G1','G2'))
OutputName <- '/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_combined_disease_HCvsIM_dataTable.txt'
write_tsv(tmp, OutputName)
tmp <- c123.c %>%
    filter(Subtype == '0_Healthy' | Subtype == '3_Diffuse-Malignant') %>%
    mutate(Subtype = if_else(Subtype=='0_Healthy','G1','G2'))
OutputName <- '/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_combined_disease_HCvsDM_dataTable.txt'
write_tsv(tmp, OutputName)

# Subtypes vs Subtypes
  #MMPvsIM
c1 <- read_tsv('/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_0001_disease_MMPvsIM_dataTable.txt') %>%
  mutate(trial_type = '1c')
c2n3 <- read_tsv('/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_0005_disease_MMPvsIM_dataTable.txt') %>%
  mutate(trial_type = '23c')
c123.c <- full_join(c1,c2n3) %>%
  arrange(Subj, TimepointNr, trial_type) %>% relocate(Subj, Subtype, TimepointNr, trial_type)
tmp <- c123.c
OutputName <- '/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_combined_disease_MMPvsIM_dataTable.txt'
write_tsv(tmp, OutputName)
  #MMPvsDM
c1 <- read_tsv('/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_0001_disease_MMPvsDM_dataTable.txt') %>%
  mutate(trial_type = '1c')
c2n3 <- read_tsv('/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_0002_disease_MMPvsDM_dataTable.txt') %>%
  mutate(trial_type = '23c')
c123.c <- full_join(c1,c2n3) %>%
  arrange(Subj, TimepointNr, trial_type) %>% relocate(Subj, Subtype, TimepointNr, trial_type)
tmp <- c123.c
OutputName <- '/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_combined_disease_MMPvsDM_dataTable.txt'
write_tsv(tmp, OutputName)
  #IMvsDM
c1 <- read_tsv('/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_0001_disease_IMvsDM_dataTable.txt') %>%
  mutate(trial_type = '1c')
c2n3 <- read_tsv('/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_0002_disease_IMvsDM_dataTable.txt') %>%
  mutate(trial_type = '23c')
c123.c <- full_join(c1,c2n3) %>%
  arrange(Subj, TimepointNr, trial_type) %>% relocate(Subj, Subtype, TimepointNr, trial_type)
tmp <- c123.c
OutputName <- '/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_combined_disease_IMvsDM_dataTable.txt'
write_tsv(tmp, OutputName)

# Assemble combined tables for associations with clinical score
c1 <- read_tsv('/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_0001_severity_dataTable.txt') %>%
  mutate(trial_type = '1c')
c2 <- read_tsv('/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_0002_severity_dataTable.txt') %>%
  mutate(trial_type = '2c')
c3 <- read_tsv('/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_0003_severity_dataTable.txt') %>%
  mutate(trial_type = '3c')
c2n3 <- read_tsv('/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_0005_severity_dataTable.txt') %>%
  mutate(trial_type = '23c')

c12 <- full_join(c1,c2)
c123 <- full_join(c12,c3) %>%
  arrange(Subj, TimepointNr, trial_type) %>% relocate(Subj, TimepointNr, trial_type)
OutputName <- '/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_combined_severity_dataTable.txt'
write_tsv(c123, OutputName)

c123 <- full_join(c1,c2n3) %>%
  arrange(Subj, TimepointNr, trial_type) %>% relocate(Subj, TimepointNr, trial_type)
OutputName <- '/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/con_combined_severity_dataTable2.txt'
write_tsv(c123, OutputName)
