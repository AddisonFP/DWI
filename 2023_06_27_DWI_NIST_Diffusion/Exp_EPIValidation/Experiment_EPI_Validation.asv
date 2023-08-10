
% Addison Powell July 13th 2023

% Assign new directory for this Analysis script and outputs
date='20230623';
addpath(genpath('/v/raid10/users/apowell/DWI/functions/'));
addpath(genpath('/v/raid10/users/apowell/DWI/2023_06_27_DWI_NIST_Diffusion/DicomMats/'))
addpath(genpath('/v/raid10/users/apowell/DWI/2023_06_27_DWI_NIST_Diffusion/Exp_EPIValidation/'))
workdir1 = ['/v/raid10/users/apowell/DWI/2023_06_27_DWI_NIST_Diffusion/Exp_EPIValidation/'];
matdir = '/v/raid10/users/apowell/DWI/2023_06_27_DWI_NIST_Diffusion/DicomMats/';

%% default B values for SOS
b_vals = [10, 50, 100, 840];
b_vals = [70, 2339];

% IMPORTANT: This is the class object that contains the plotting/analysis
% functions. My attempt to make MATLAB python-y.. 
pltfun = functionsPlotting;  % Make changes to plotting/analysis functions here!

%% 1. Get DWI Signal data from the vial ROIs for every DICOM

% List of DICOM .mat files to include in analysis. Input as cell sets of MR Exams/Dates.
% Each set has a respective vial_file with the vial ROIs. 
dicom_lists = {dir([matdir 'REP1_EPI_*.mat']); dir([matdir 'REP1_SOS_*.mat']);};

vials_files = {'REP1_EPI_vials_rot0'; 'REP1_EPI_vials_rot0';};

if ~exist([workdir1 'dwiData1_EPIvials_all.mat'],'file')
    [dwiData, dwiData_table] = getDWIfromDICOMs(vials_files,dicom_lists, false, false, matdir);
    save([workdir1 'dwiData1_EPIvials_all.mat'], 'dwiData', 'dwiData_table'); 
end

%% EXP 1: Create ADC Map
% createADCmap(dicom_lists, vials_files, 13, TE_keep, b_keep)

%% 2. Set Global Parameters for Analysis

TE_keep = 1; 
b_keep = [1,2];
additional = 'Two_bvalues_TE1/';  % file extension
workdir = [workdir1 additional];

slice = 13; 
dwiData_file = [workdir1 'dwiData1_EPIvials_all.mat']; % file that contains all the DWI Signal data (generated in section 1)



%% EXP 1: SOS Comp Delay Time - 10ms TR

sequences = {}
parameters = {
             {'Date', {date}};
             {'PhantomRotation', 0}; 
             {'TR', [5000, 10]}
             }

title_str = 'SOS_comp_delayTime_TR10'; 
[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_vals(b_keep), TE_keep, slice);

% Box and Whiskers plot 
pltfun.box_and_whiskers(adcTable, title_str, 'Description', workdir, false);
[PearsonsRho, rmse_total, rmse_vial] = pltfun.get_errorStats(adcTable, title_str,'Description', workdir);




