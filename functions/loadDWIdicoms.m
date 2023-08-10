function loadDWIdicoms(datadir, savedir, prefix, dicomlist, dicom_names)
% Reads in .dcm files for each DWI image series as saves image as .mat.
% -- Saves DicomHeader1 and 2, geomInfo
% -- Saves acqInfo with information about DWI acquisition
% -- INPUTS --
% savedir     string. Directory to save .mat files in 
% prefix      string. Appended to beginning of dicom save name (date, or
%               trial reference)
% dicomlist   Cell of strings. List of DICOM folders to read in. To read
%               in multiple folders per DWI acquisition, create a cell of 
%               strings within the dicomlist. 
% dicom_names Cell of strings. List of descriptive names for the .mat
%               files. 'prefix' string will be appended to front. 
%
% Sara L. Johnson
% 3.1.2023

for f = 1:length(dicomlist)
    clear imge

    % if files are in multiple folders (MLEV data)
    if size(dicomlist{f}, 1) > 1  
        for i = 1:length(dicomlist{f})
            [img_temp, ~, ~, geomInfo] = load_image_DICOM(datadir, dicomlist{f}{i}, savedir);
            if i == 1
                img_temp2 = img_temp; 
            else 
                img_temp2 = cat(5,img_temp2, img_temp);
                delete([dicomlist{f}{i} '.mat'])
            end 
        end
        filename = dicomlist{f}{1};
        imge = permute(img_temp2, [1,2,3,5,4]);  % permute b-val and TE dimensions

    % if files are in single folder (EPI, regular SoS)
    else
        [imge, ~, ~, geomInfo] = load_image_DICOM(datadir, dicomlist{f}, savedir);
        filename = dicomlist{f};
    end

    % if SoS, re-order the b-values
    if strcmp(dicom_names{f}(1:3), 'SOS') 
        imge = cat(4,imge(:,:,:,4,:),imge(:,:,:,2,:),imge(:,:,:,3,:),imge(:,:,:,1,:));
    end 

    % Reload the Dicom Header, to save specific attributes in acqInfo
    load([savedir filename '.mat'], 'DicomHeader1'); 

    % if not acquired 'HFS', flip to HFS
    if strcmp(DicomHeader1.PatientPosition, 'HFP')
        % Flip image to be same as REP1 (HFS) 
        imge = flip(flip(imge,2),3);
    elseif ~strcmp(DicomHeader1.PatientPosition, 'HFS')
        error('Check PatientPosition. Cases only exist for HFP and HFS.');
    end 

    % save other acquisition info in acqInfo
    acqInfo.TE = DicomHeader1.EchoTime; 
    acqInfo.TR = DicomHeader1.RepetitionTime; 
    acqInfo.BandWidth = DicomHeader1.PixelBandwidth; 
    acqInfo.FA = DicomHeader1.FlipAngle; 
    acqInfo.Slices = size(imge,3);
    acqInfo.SequenceType = dicom_names{f}(1:3);
    acqInfo.Description = dicom_names{f}; 
    acqInfo.PhantomRotation = str2double(dicom_names{f}(strfind(dicom_names{f},'rot')+3:end));
    acqInfo.DicomFile = filename;
    acqInfo.Date = DicomHeader1.InstanceCreationDate;
    try
        acqInfo.CompositeDelay = str2double(dicom_names{f}(strfind(dicom_names{f},'_d')+2:strfind(dicom_dsc{f},'_d')+4));
    catch 
        acqInfo.CompositeDelay = nan;
    end
 
    movefile([savedir filename '.mat'],[savedir 'DicomMats/' prefix '_' dicom_names{f} '.mat'])
    save([savedir prefix '_' dicom_names{f} '.mat'], 'acqInfo', 'imge','-append');

end 