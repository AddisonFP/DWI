% Assign new directory for this Analysis script and outputs
date='20230623';
date2='20230627';
addpath(genpath('/v/raid10/users/apowell/DWI/functions/'));
addpath(genpath('/v/raid10/users/apowell/DWI/2023_06_27_DWI_Twice_Refocused/DicomMats/'))
addpath(genpath('/v/raid10/users/apowell/DWI/2023_06_27_DWI_Twice_Refocused/Exp_EPIValidation/'))
workdir1 = ['/v/raid10/users/apowell/DWI/2023_06_27_DWI_Twice_Refocused/Exp_EPIValidation/'];
matdir = '/v/raid10/users/apowell/DWI/2023_06_27_DWI_Twice_Refocused/DicomMats/';

%% default B values for SOS
b_vals = [10, 50, 100, 840];
b_vals = [70, 2339];

% IMPORTANT: This is the class object that contains the plotting/analysis
% functions. My attempt to make MATLAB python-y.. 
pltfun = functionsPlotting;  % Make changes to plotting/analysis functions here!

%% 1. Get DWI Signal data from the vial ROIs for every DICOM

% List of DICOM .mat files to include in analysis. Input as cell sets of MR Exams/Dates.
% Each set has a respective vial_file with the vial ROIs. 
dicom_lists = {dir([matdir 'REP1_EPI_*.mat']); dir([matdir 'REP2_EPI_*.mat']);
    dir([matdir 'REP1_SOS_*.mat']); dir([matdir 'REP2_SOS_*.mat'])};

vials_files = {'REP1_EPI_vials_rot0'; 'REP2_EPI_vials_rot0'; 
    'REP1_EPI_vials_rot0'; 'REP2_EPI_vials_rot0';};

if ~exist([workdir1 'dwiData_EPIvials_all.mat'],'file')
    [dwiData, dwiData_table] = getDWIfromDICOMs(vials_files,dicom_lists, false, false, matdir);
    save([workdir1 'dwiData_EPIvials_all.mat'], 'dwiData', 'dwiData_table'); 
end
%% 2. Set Global Parameters for Analysis

TE_keep = 1; 
b_keep = [1,2];
additional = 'Two_bvalues_TE2/';  % file extension
workdir = [workdir1 additional];

slice = 13; 
dwiData_file = [workdir1 'dwiData_EPIvials_all.mat']; % file that contains all the DWI Signal data (generated in section 1)


%% EXP 2: SOS Comp Delay Time - 10ms TR

sequences = {};
% for i=[0 10 20 50 100 150 200]
%     parameters = {
%              {'PhantomRotation', 0}; 
%              {'TR', [5000, 10]};
%              {'TR_readout', i};
%              };
%     title_str = ['SOS_comp_delayTime_TR10_delay=', num2str(i)]; 
%     [adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_keep, TE_keep, slice);
% 
%     % Box and Whiskers plot 
%     pltfun.box_and_whiskers(adcTable, title_str, 'Date', workdir, false);
% end

%% EXP 3: Both days, all TR delays - 10ms TR

parameters = {
             {'PhantomRotation', 0}; 
             {'TR', [5000, 10]};
             };
    title_str = 'Every experiment, both days'; 

[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_vals(b_keep), TE_keep, slice);
pltfun.box_and_whiskers(adcTable, title_str, 'Filename', workdir, false);

%% EXP 4: EPI v SOS - 10ms TR

parameters = {
             {'PhantomRotation', 0}; 
             {'TR', [5000, 10]};
             };
    title_str = 'EPI benchmark vs SOS, both days combined'; 

[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_vals(b_keep), TE_keep, slice);
pltfun.box_and_whiskers(adcTable, title_str, 'SequenceType', workdir, false);

%% EXP 5: First Day, all TR delays - 10ms TR

parameters = {
             {'PhantomRotation', 0}; 
             {'TR', [5000, 10]};
             {'Date', date}
             };
    title_str = 'Every experiment, first day'; 

[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_vals(b_keep), TE_keep, slice);
pltfun.box_and_whiskers(adcTable, title_str, 'Filename', workdir, false);


%% EXP 6: Second Day, all TR delays - 10ms TR

parameters = {
             {'PhantomRotation', 0}; 
             {'TR', [5000, 10]};
             {'Date', date2}
             };
    title_str = 'Every experiment, second day'; 

[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_vals(b_keep), TE_keep, slice);
pltfun.box_and_whiskers(adcTable, title_str, 'Filename', workdir, false);

