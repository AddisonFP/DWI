% Addison Powell July 10th 2023
% Add packages/functions needed for analysis
clear all
addpath(genpath('/v/raid10/users/sjohnson/Matlab Code/Packages/'));
addpath(genpath('/v/raid10/users/sjohnson/Matlab Code/MedImageReslicer/'));
addpath(genpath('/v/raid10/users/apowell/DWI/functions/')); % DWI and ADC processing functions

% Define directories
datadir = '/v/raid10/users/apowell/2023/2023-06-23_Diffusion/DicomData/'; % the location of the .dcm files that start with 's0000## fl3d...'
workdir = '/v/raid10/users/apowell/DWI/2023_06_27_DWI_Twice_Refocused/'; % where the proccessed plots are saved (should be the same folder as the one this script is in)
matdir = '/v/raid10/users/apowell/DWI/2023_06_27_DWI_Twice_Refocused/DicomMats/'; % where the .mat dicom data is saved
cd(workdir);

%% Load the DICOMs as .mat files

trial = 'REP1';  % TRIAL: Used to preface saved files/figures and compare scans acquired during different MR Exams. 
                 % I was using "REP1", "REP2" etc to indicate different acquisition dates of the same sequences (repeatability test). 
                 % Since we're testing a new prep pulse, I restarted at
                 % REP1 on 5/9/2023. So this is REP2.

% List of DICOM folders at datadir to be loaded into MATLAB. 
% Format is a cell, with each cell entry being a different sequence. 
% For the 2D EPI data, the cell entry is a string (the name of the folder). 
% For the 3D SOS data, each b-value is stored in a separate folder, so the cell
% entry is another cell, with an entry for each folder in the data set. 
 
% Phantom Position 1 
dicom_list = {{'s000023 fl3d_Twice_Refocus_dur=11'; 's000024 fl3d_Twice_Refocus_dur=11'};
              {'s000025 fl3d_Twice_Refocus_dur=11_delay=10'; 's000026 fl3d_Twice_Refocus_dur=11_delay=10'}; 
              {'s000027 fl3d_Twice_Refocus_dur=11_delay=20'; 's000028 fl3d_Twice_Refocus_dur=11_delay=20'};
              {'s000029 fl3d_Twice_Refocus_dur=11_delay=50'; 's000030 fl3d_Twice_Refocus_dur=11_delay=50'};
              {'s000031 fl3d_Twice_Refocus_dur=11_delay=100'; 's000032 fl3d_Twice_Refocus_dur=11_delay=100'};
              {'s000033 fl3d_Twice_Refocus_dur=11_delay=150'; 's000034 fl3d_Twice_Refocus_dur=11_delay=150'};
              {'s000035 fl3d_Twice_Refocus_dur=11_delay=200'; 's000036 fl3d_Twice_Refocus_dur=11_delay=200'};
              's000037 DWI2D_iPat3_RabbitProtocolCopy_TRACEW'};

% DICOM mats are saved with more descriptive names for analysis. The naming convention is
% also used to record information in the acqInfo struct during "loadDWIdicoms" 

% Current Convention = [EPI or SOS]_[prep pulse type for SOS]_[delay b/w diffusion
% gradients as "d00" in milliseconds]_[TR b/w diffusion preps as "TR000" in
% milliseconds]_[phantom in-plane rotation as "rot0","rot90","rot180" or
% "rot270"]
%% this list determines how the created .mat files will be named, REP[1/2]_"name from list"
dicom_dsc = {'SOS_TwiRef_d00_TR000_rot0'; 
    'SOS_TwiRef_d00_TR010_rot0';
    'SOS_TwiRef_d00_TR020_rot0';
    'SOS_TwiRef_d00_TR050_rot0';
    'SOS_TwiRef_d00_TR100_rot0';
    'SOS_TwiRef_d00_TR150_rot0';
    'SOS_TwiRef_d00_TR200_rot0';
    'EPI_rot0'};


loadDWIdicoms_XA(datadir, matdir, trial, dicom_list, dicom_dsc)


%% Create the vial ROIs on a rot0 image (EPI image FOV)
% This section generates a mag image of the phantom. Just click the center
% of the vials in the order I've used in my presentations to generate the ROI. 
% I'll try to remember to send you a screenshot.

% For most of the downstream analysis, the SOS data gets re-sliced to match
% the FOV/resolution of the reference EPI image acquired at the same time.
% Therefore, I just create the vial ROIs for the EPI_rot0 reference image. 

bg_imge_file = [matdir 'REP1_EPI_rot0.mat']; 
view_slice = 13; 
radius = 7;

[vials, bg_imge, bg_geomInfo] = createVialROIs(bg_imge_file, view_slice, radius, 1);

save([workdir 'REP1_EPI_vials_rot0.mat'],'vials','bg_imge','bg_geomInfo');



%% Create the vial ROIs on a rot0 image (SOS image FOV)

% bg_imge_file = [matdir 'REP2_SOS_Tri_d00_TR000_rot0.mat']; 
% view_slice = 13; 
% radius = 10;
% 
% [vials, bg_imge, bg_geomInfo] = createVialROIs(bg_imge_file, view_slice, radius);
% 
% save([workdir 'REP2_SOS_vials_rot0.mat'],'vials','bg_imge','bg_geomInfo');

%% Register In-plane phantom rotations to the rot0 position for EPI and SOS images.

% I haven't done this for the new data because we only have the rot0
% position. 

% The "registerDWIimage" will attempt to automatically register for each
% b-value and show you the blended image. You then have to select in the
% input dialog which b-value transformation to use for all b-values.
% Sometimes the signal inhomogeneity is worse for some b-values, so the registration fails.  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Example from ADC_PreProcessing_03_31_2023.m:
% view_slice = 13; 
% tform_type = 'rigid'; 
% 
% target_files = {'REP3_EPI_iPAT3_rot0.mat'; 'REP3_SOS_MELV4_d20_rot0.mat'};
% 
% moving_files_sets ={{'REP3_EPI_iPAT3_rot180.mat'; 
%                   'REP3_EPI_iPAT3_rot270.mat'};
%                 {'REP3_SOS_MELV4_d20_rot90.mat';
%                 'REP3_SOS_MELV4_d20_rot180.mat';
%                 'REP3_SOS_MELV4_d20_rot270.mat';
%                 'REP3_SOS_MELV4_d10_rot90.mat';
%                 'REP3_SOS_MELV4_d10_rot180.mat';
%                 'REP3_SOS_MELV4_d10_rot270.mat';
%                 'REP3_SOS_MELV4_d00_rot90.mat';
%                 'REP3_SOS_MELV4_d00_rot180.mat';
%                 'REP3_SOS_MELV4_d00_rot270.mat';}};
% 
% 
% for set = 2:length(target_files)
%     load([matdir target_files{set}], 'imge','acqInfo');
%     target_img = imge; 
% 
%     moving_files = moving_files_sets{set}; 
% 
%     for mf = 6:length(moving_files)
% 
%         % load the moving image file
%         load([matdir moving_files{mf}], 'imge','acqInfo');
%         moving_img = imge; 
%         moving_rot = acqInfo.PhantomRotation;  %NOTE: if the phantom is more like 300 degrees rotated, rather than 270, manually changing this helps the rotation. 
%         %if moving_rot == 270; moving_rot =300; end  
% 
%         % perform registration
%         mi_bins = 10;
%        [imge_reg, tform, tform_init, tform_best] = registerDWIimage(target_img, moving_img, moving_rot, view_slice, ...
%             tform_type, mi_bins); 
% 
%         % append to moving image file
%         save([matdir moving_files{mf}], 'imge_reg', 'tform', 'tform_best', '-append');
%     end
% end