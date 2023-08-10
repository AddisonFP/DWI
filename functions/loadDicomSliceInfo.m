function [imge, DicomHeader1, DicomHeader2, metadata] = loadDicomSliceInfo(dicomdir,dicomname)
% ImgeCoregistration MATLAB Package 
%
% Loads Dicom series saved to an individual folder and outputs it as a .mat
% array with meta-data header information.
%
%%%% INPUTS  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% dicomdir  = String. Path where the dicom folders are stored
% dicomname = String. Name of folder that contains the image volume
% savedir   = Optional String. Path where .mat file will be saved.
%
%%%% OUTPUTS  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% imge         = Double array, the loaded image. Output dimensions are: 
%                [rows, cols, slices, acquisitions, volumes]. "volumes" are
%                additional FOVs assigned to a single acqusition (rare).
% DicomHeader1 = Struct. Meta-data associated with the first image (.dcm
%                file) in the Dicom series
% DicomHeader2 = Struct. Meta-data associated with the last image (.dcm
%                file) in the Dicom series
% metadata     = Used for Debugging. Table that lists InstanceNumber, AcquisitionNumber, and
%                SliceLocation for each file in the Dicom folder. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% By: Sara L. Johnson
% 02/14/2023
%
% This version replaces the previous deprecated version of
% "loadDicomAsMat.mat" created by Sara L. Johnson on 10/01/2018. 
% 
% IMPROVEMENTS
% Corrects errors and generalizes for multi-volume acquisitions. Within
% each labeled FOV acquisition (m.AcquisitionNumber), there may be multiple
% FOVs. These multiple FOVs per Acquisition are saved to the 5th DIM. 
% -- Checks for multiple FOVs within each acquisition, by counting number of
%   unique slices (m.SliceLocation).  
%
% -- DWI EXAMPLE: m.AcquisitionNumber changes for different b-values, but there 
% are 3 volumes within each acquisition with different TEs. 
%    The output 'imge' dimensions will correspond to: 
%        
%        [rows, cols, slices, b-values, TEs]
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd([dicomdir dicomname]); 
list = dir(); 
list = list(~startsWith({list.name}, '.')); % character can change depending on dicom source. S. Johnson

% Sort list of files by InstanceNumber
for ii = 1:length(list) 
    md = dicominfo(list(ii).name);
    CurrentInstance = md.InstanceNumber; 
    newlist(CurrentInstance) = list(ii); 
end
list = newlist; 

% Get AcquisitionNumber and SliceLocation for each instance 
mdat = zeros(length(list), 3);
for ii = 1:length(list)
    hdr = dicominfo(list(ii).name);
    mdat(ii,1) = hdr.InstanceNumber;
    mdat(ii,2) = hdr.AcquisitionNumber;
    mdat(ii,3) = hdr.SliceLocation; 
end 

% Convert to metadata Table for output 
metadata = array2table(mdat,'VariableNames',{'Instance','Acquisition','SliceLocation'});

% SOME DEFINITIONS
m1 = dicominfo(list(1).name);
mN = dicominfo(list(end).name);

singleAcq = true; 
singleSlice = true; 
singleVolume = true; 

% CHECK - Number if files == number of instances
n_inst = length(list);
if ~(n_inst == mN.InstanceNumber)
    warning("Number of instances does not equal number of files in folder. Slice order may be incorrect.")
end 

% CHECK - Single or Multi-Acquisition 
n_acq = length(unique(metadata.Acquisition));
if n_acq > 1
    singleAcq = false; 
end 

% CHECK - Single or Multi-slice image
metadata_acq1 = metadata((metadata.Acquisition == 1),:);
n_slices = length(unique(metadata_acq1.SliceLocation));
if n_slices > 1
    singleSlice = false; 
end 

% CHECK - Single or Multi-volume per Acquisition
n_volumes = height(metadata_acq1)/n_slices;
if n_volumes > 1
    singleVolume = false; 
end 

% ALLOCATING DICOM ARRAY
m1 = dicominfo(list(1).name);
n_col = m1.Width;
n_row = m1.Height;
if (n_acq > 1) && (n_volumes > 1)
    DICOM = zeros(n_row, n_col, n_slices, n_acq, n_volumes);
elseif (n_acq > 1) && (n_volumes == 1)
    DICOM = zeros(n_row, n_col, n_slices, n_acq);
elseif (n_acq == 1) && (n_volumes > 1) 
    DICOM = zeros(n_row, n_col, n_slices, n_volumes);
else
    DICOM = zeros(n_row, n_col, n_slices);
end 

% CASE - Single Acquisition 
if singleAcq
    if singleVolume  % single volume, 2D or 3D image
        for ii = 1:length(list)
            imge = dicomread(list(ii).name); 
            sl = ii;
            DICOM(:,:,sl) = imge; 
        end 
    else % multiple volumes per acquisition
        if singleSlice % 2D image
            for ii = 1:length(list)
                imge = dicomread(list(ii).name); 
                vol = ii;
                DICOM(:,:,1,vol) = imge; 
            end 
        else   % 3D image
            for ii = 1:length(list)
                imge = dicomread(list(ii).name); 
                vol = ceil(ii/n_slices);
                sl = rem(ii-1, n_slices)+1;
                DICOM(:,:,sl,vol) = imge; 
            end 
        end 
    end 

% CASE - Multiple Acquisitions
else  
    if singleVolume % single volume per acquisition, 2D or 3D image
        for ii = 1:length(list)
            imge = dicomread(list(ii).name); 
            m = dicominfo(list(ii).name); 
            acq = m.AcquisitionNumber; 
            acq_sl = rem(ii-1, n_slices)+1;
            DICOM(:,:,acq_sl,acq) = imge; 
        end 
    else  % multiple volumes per acquisitions, 2D or 3D image
        for ii = 1:length(list)
            imge = dicomread(list(ii).name); 
            m = dicominfo(list(ii).name); 
            acq = m.AcquisitionNumber; 
            inst_per_acq = n_inst/n_acq;
            % calculate volume and slice number per acquisition
            acq_inst = rem(ii-1,inst_per_acq)+1; 
            acq_vol = ceil(acq_inst/n_slices); 
            acq_sl = rem(acq_inst-1, n_slices)+1; 
            DICOM(:,:,acq_sl,acq,acq_vol) = imge; 
        end 
    end 
end 

clear imge;
imge = double(DICOM); 
DicomHeader1 = dicominfo(list(1).name);
DicomHeader2 = dicominfo(list(end).name);

if exist('savedir','var')
    save([savedir ScanName '.mat'],'imge','DicomHeader1','DicomHeader2');
end 


end 