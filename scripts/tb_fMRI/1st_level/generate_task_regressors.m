%% [taskregs] = generate_task_regressors(EventsTsvFile)
% Convolves task design with a canonical hrf.
% Relies on extract_onsets_and_duration_pm() for generating design.
% Convolution has been adapted from the spm_fMRI_design function.
% @Martin E. Johansson, 28/01/2025

function [taskregs] = generate_task_regressors(bidsdir, subject, session)

%% Define inputs

% Scans
funcdat = cellstr(spm_select('FPList', fullfile(bidsdir, 'derivatives/fmriprep_v23.0.2/motor', subject, session, 'func'), [subject '_' session '_task-motor_acq-MB6_run-.*_space-MNI152NLin6Asym.*_desc-preproc_bold.nii.gz']));
funcdat = funcdat{size(funcdat,1)};
volinfo = ft_read_mri(funcdat);
SPM.nscan = size(volinfo.anatomy,4);

% Events
EventsTsvFile = cellstr(spm_select('FPList', fullfile(bidsdir, subject, session, 'beh'), [subject '_' session '_task-motor_acq-MB6_run-.*_events.tsv']));
if numel(EventsTsvFile) > 1
    fprintf('WARNING: %s %s has %i tsv files. Selecting the last run! \n', subject, session, numel(EventsTsvFile))
end
EventsTsvFile = EventsTsvFile{numel(EventsTsvFile)};
filetext = fileread(strrep(funcdat,'.nii.gz','.json'));
expr = '[^\n]*RepetitionTime[^\n]*';
matches = regexp(filetext,expr,'match');
TR = cell2num_my(extractBetween(matches, ': ', ','));
expr = '[^\n]*StartTime[^\n]*';
matches = regexp(filetext,expr,'match');
stime = cell2num_my(extractBetween(matches, ': ', ','));
fprintf('%s %s start time: %f\n', subject, session, stime)
StimulusEvents = extract_onsets_and_duration_pm(EventsTsvFile, TR, stime, false);

%% Define basis functions
SPM.xY.RT = TR;                                      %repetition time (TR)
SPM.xBF.UNITS = 'secs'; 
fMRI_T = 72;
fMRI_T0 = 36;
SPM.xBF.T  = fMRI_T;                                %microtime resolution (number of time bins per scan) - number of slices
SPM.xBF.T0 = fMRI_T0;                               %microtime onset (reference time bin, see slice timing) - reference slice for slice time correction
SPM.xBF.name = 'hrf';                               %description of basis functions specified
SPM.xBF.Volterra = 1;
SPM.xBF.dt = SPM.xY.RT/SPM.xBF.T;                   %time bin length {seconds}
SPM.xBF = spm_get_bf(SPM.xBF);

% Stimulus input structure
SPM.Sess.U = [];
P.name = 'none';
P.h = 0;
P.i = 1;
for i=1:numel(StimulusEvents.names)
    SPM.Sess.U(i).name = StimulusEvents.names(i);
    SPM.Sess.U(i).ons = StimulusEvents.onsets{i};
    SPM.Sess.U(i).dur = StimulusEvents.durations{i};
    SPM.Sess.U(i).orth = true;
    SPM.Sess.U(i).P = P;
    SPM.Sess.U(i).dt = SPM.xBF.dt;
end
U = spm_get_ons(SPM,1);

%% Convolve
[X,~,Fc] = spm_Volterra(U, SPM.xBF.bf, SPM.xBF.Volterra);

% Resample regressors at acquisition times (32 bin offset)
if ~isempty(X)
    X = X((0:(SPM.nscan - 1))*fMRI_T + fMRI_T0 + 32,:);
end
% Orthogonalise (within trial type)    
for i = 1:length(Fc)
    if i<= numel(U) && ... % for Volterra kernels
            (~isfield(U(i),'orth') || U(i).orth)
        p = ones(size(Fc(i).i));
    else
        p = Fc(i).p;
    end
    for j = 1:max(p)
        X(:,Fc(i).i(p==j)) = spm_orth(X(:,Fc(i).i(p==j)));
    end
end

%% Output
taskregs.X = X;
taskregs.names = StimulusEvents.names;
