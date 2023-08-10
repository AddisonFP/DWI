
% EXAMPLE ANALYSIS SCRIPT from 2/2023 DWI Data 

% Assign new directory for this Analysis script and outputs
workdir1 = ['/v/raid10/users/sjohnson/Experiment Analysis/Phantoms/' ...
    '2023_02_09_DWI_NISTphantom/Exp_EPIValidation/'];
matdir = '/v/raid10/users/sjohnson/Experiment Analysis/Phantoms/2023_02_09_DWI_NISTphantom/DicomMats/';

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

if ~exist([workdir '../dwiData_EPIvials_all.mat'],'file')
    [dwiData, dwiData_table] = getDWIfromDICOMs(vials_files,dicom_lists, false, false);
    save([workdir '../dwiData_EPIvials_all.mat'], 'dwiData', 'dwiData_table'); 
end
%% 2. Set Global Parameters for Analysis

TE_keep = 1; 
b_keep = [1,2,3,4];
additional = 'Four_bvalues_TE1/';  % file extension
workdir = [workdir1 additional];

slice = 13; 
dwiData_file = [workdir '../dwiData_EPIvials_all.mat']; % file that contains all the DWI Signal data (generated in section 1)

%% EXP 1: SOS Comp Delay Time - 5ms TR
% The goal of this "experiment" is to compare ADC values of the SOS sequence 
% acquired with different gradient delay times ("d00"), and compare them to
% the EPI Benchmark. I only need a subset of the Dicoms for this. 

% dwiData is a struct. Here you select which DICOMs to compare by selecting
% based on dwiData field names. 

% In this case, I've selected all DICOMS acquired on 20230303 with 0-degree
% phantom rotation and TRs of 5000 (EPI) and 5 ms (SOS). 
% NOTE: You can also select specfic DICOM series using the "Description"
% field.
parameters = {
             {'Date', {'20230303'}};   % format is pairwise: { FIELDNAME, VALUES }
             {'PhantomRotation', 0}; 
             {'TR', [5000, 5]}
             };

title_str = 'SOS_comp_delayTime_TR5'; % this will be used to name .tif outputs

% Get the subset of Dicoms based on these parameters and calculate the ADC
% values within the vial ROIs. 
[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_keep, TE_keep, slice);

% Box and Whiskers plot 
% "Decription" is the "groupby" variable. This is the variable/field of
% dwiData that we are comparing along. I could have also used
% "CompositeDelay" for this experiment, but I wanted to also compare to the
% EPI benchmark, so I used the series description instead. 
pltfun.box_and_whiskers(adcTable, title_str, 'Description', workdir, false); 

% Pearson's correlation and RMSE plot
[PearsonsRho, rmse_total, rmse_vial] = pltfun.get_errorStats(adcTable, title_str,'Description', workdir);



%% EXP 2: SOS Comp Delay Time - 10ms TR

sequences = {}
parameters = {
             {'Date', {'20230303'}};
             {'PhantomRotation', 0}; 
             {'TR', [5000, 10]}
             }

title_str = 'SOS_comp_delayTime_TR10'; 
[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_keep, TE_keep, slice);

% Box and Whiskers plot 
pltfun.box_and_whiskers(adcTable, title_str, 'Description', workdir, false);
[PearsonsRho, rmse_total, rmse_vial] = pltfun.get_errorStats(adcTable, title_str,'Description', workdir);


%% EXP 3: SOS Comp Delay 10ms, 5ms TR, all rotations

sequences = {'EPI_iPAT3_rot0';
             'SOS_MELV2_d10_rot0';
             'SOS_MELV2_d10_rot90';
             'SOS_MELV2_d10_rot180';
             'SOS_MELV2_d10_rot270'}; 
parameters = {{'Description', sequences}; 
              {'Date', '20230303'}} ; 

title_str = 'SOS_comp_d10ms_TR5_allRotations'; 
[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_keep, TE_keep, slice);
adcTable = sortrows(adcTable, 'PhantomRotation');

% Box and Whiskers plot 
pltfun.box_and_whiskers(adcTable, title_str, 'Description', workdir, false); 
[PearsonsRho, rmse_total, rmse_vial] = pltfun.get_errorStats(adcTable, title_str,'Description', workdir);


%% EXP 4: SOS Comp Delay 10ms, 5ms TR, all rotations COMBINED

sequences = {'EPI_iPAT3_rot0';
             'EPI_iPAT3_rot90';
             'EPI_iPAT3_rot180';
             'EPI_iPAT3_rot270';
             'SOS_MELV2_d10_rot0';
             'SOS_MELV2_d10_rot90';
             'SOS_MELV2_d10_rot180';
             'SOS_MELV2_d10_rot270'}; 
parameters = {{'Description', sequences}; 
              {'Date', '20230303'}} ; 

title_str = 'SOS_comp_d10ms_TR5_allRotations_Combined'; 
[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_keep, TE_keep, slice);
adcTable = sortrows(adcTable, 'PhantomRotation');

% Box and Whiskers plot 
pltfun.box_and_whiskers(adcTable, title_str, 'SequenceType', workdir, false); 
[PearsonsRho, rmse_total, rmse_vial] = pltfun.get_errorStats(adcTable, title_str,'SequenceType', workdir, 'EPI');


%% EXP 5: SOS Comp Delay 10ms, 10ms TR, all rotations

sequences = {'EPI_iPAT3_rot0';
             'SOS_MELV2_d10_TR10_rot0';
             'SOS_MELV2_d10_TR10_rot270'}; 
parameters = {{'Description', sequences}; 
              {'Date', '20230303'}} ; 

title_str = 'SOS_comp_d10ms_TR10_allRotations'; 
[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_keep, TE_keep, slice);
adcTable = sortrows(adcTable, 'PhantomRotation');

% Box and Whiskers plot 
pltfun.box_and_whiskers(adcTable, title_str, 'Description', workdir, false); 
[PearsonsRho, rmse_total, rmse_vial] = pltfun.get_errorStats(adcTable, title_str,'Description', workdir);


%% EXP 6: SOS Comp Delay 10ms, 10ms TR, all rotations COMBINED

sequences = {'EPI_iPAT3_rot0';
             'EPI_iPAT3_rot270';
             'SOS_MELV2_d10_TR10_rot0';
             'SOS_MELV2_d10_TR10_rot270'}; 
parameters = {{'Description', sequences}; 
              {'Date', '20230303'}} ; 

title_str = 'SOS_comp_d10ms_TR10_allRotations_Combined'; 
[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_keep, TE_keep, slice);
adcTable = sortrows(adcTable, 'PhantomRotation');

% Box and Whiskers plot 
pltfun.box_and_whiskers(adcTable, title_str, 'SequenceType', workdir, false); 
[PearsonsRho, rmse_total, rmse_vial] = pltfun.get_errorStats(adcTable, title_str,'SequenceType', workdir, 'EPI');


%% EXP 7: SOS 5ms TR, all rotations 

sequences = {'EPI_iPAT3_rot0';
             'SOS_24sl_rot0';
             'SOS_24sl_rot90';
             'SOS_24sl_rot180';
             'SOS_24sl_rot270';}; 
parameters = {{'Description', sequences}; 
              {'Date', '20230209'}} ; 

title_str = 'SOS_24sl_allRotations'; 
[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_keep, TE_keep, slice);
adcTable = sortrows(adcTable, 'PhantomRotation');

% Box and Whiskers plot 
pltfun.box_and_whiskers(adcTable, title_str, 'Description', workdir, false); 
[PearsonsRho, rmse_total, rmse_vial] = pltfun.get_errorStats(adcTable, title_str,'Description', workdir);


%% EXP 6: SOS 5ms TR, all rotations COMBINED

sequences = {'EPI_iPAT3_rot0';
             'EPI_iPAT3_rot90';
             'EPI_iPAT3_rot180';
             'EPI_iPAT3_rot270';
             'SOS_24sl_rot0';
             'SOS_24sl_rot90';
             'SOS_24sl_rot180';
             'SOS_24sl_rot270';}; 
parameters = {{'Description', sequences}; 
              {'Date', '20230209'}} ; 

title_str = 'SOS_24sl_allRotations_Combined'; 
[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_keep, TE_keep, slice);
adcTable = sortrows(adcTable, 'PhantomRotation');

% Box and Whiskers plot 
pltfun.box_and_whiskers(adcTable, title_str, 'SequenceType', workdir, false); 
[PearsonsRho, rmse_total, rmse_vial] = pltfun.get_errorStats(adcTable, title_str,'SequenceType', workdir, 'EPI');

%% EXP 7: SOS Number of Slices - no Comp

sequences = {'EPI_iPAT3_rot0';
             'SOS_8sl_rot0';
             'SOS_16sl_rot0';
             'SOS_24sl_rot0';
             'SOS_32sl_rot0' }; 
parameters = {{'Description', sequences}; 
              {'Date', '20230209'}} ; 

title_str = 'SOS_numSlices_noComp'; 
[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_keep, TE_keep, slice);
adcTable = sortrows(adcTable, {'SequenceType', 'Slices'}); 

% Box and Whiskers plot 
pltfun.box_and_whiskers(adcTable, title_str, 'Description', workdir, false); 
[PearsonsRho, rmse_total, rmse_vial] = pltfun.get_errorStats(adcTable, title_str,'Description', workdir);

%% EXP 8: SOS 5ms TR, all rotations 


sequences = {'EPI_iPAT3_rot0';
             'SOS_MELV2_d10_rot270';
             'SOS_MELV2_d10_b400_rot270'}; 
parameters = {{'Description', sequences}; 
              {'Date', '20230303'}} ; 

title_str = 'SOS_comp_10ms_b400'; 
[adcTable, mean_adcTable, std_adcTable, ~] = getDWIsubset(dwiData_file, parameters, b_keep, TE_keep, slice);

% Box and Whiskers plot 
pltfun.box_and_whiskers(adcTable, title_str, 'Description', workdir, false); 
[PearsonsRho, rmse_total, rmse_vial] = pltfun.get_errorStats(adcTable, title_str,'Description', workdir);

