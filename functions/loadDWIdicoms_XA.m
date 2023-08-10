function loadDWIdicoms_XA(datadir, savedir, prefix, dicomlist, dicom_names)
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
            [img_temp, ~, ~, geomInfo] = load_image_DICOM_XA(datadir, dicomlist{f}{i}, savedir);
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
        [imge, ~, ~, geomInfo] = load_image_DICOM_XA(datadir, dicomlist{f}, savedir);
        filename = dicomlist{f};
    end

    % if SoS, re-order the b-values
    if strcmp(dicom_names{f}(1:3), 'SOS') 
        %imge = cat(4,imge(:,:,:,2,:),imge(:,:,:,1,:));
        imge = flipdim(imge,4); 
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
    acqInfo.TE = DicomHeader1.PerFrameFunctionalGroupsSequence.Item_1.MREchoSequence.Item_1.EffectiveEchoTime; 
    acqInfo.TR = DicomHeader1.SharedFunctionalGroupsSequence.Item_1.MRTimingAndRelatedParametersSequence.Item_1.RepetitionTime; 
    acqInfo.BandWidth = DicomHeader1.SharedFunctionalGroupsSequence.Item_1.MRImagingModifierSequence.Item_1.PixelBandwidth; 
    acqInfo.FA = DicomHeader1.SharedFunctionalGroupsSequence.Item_1.MRTimingAndRelatedParametersSequence.Item_1.FlipAngle; 
    acqInfo.Slices = size(imge,3);
    acqInfo.SequenceType = dicom_names{f}(1:3);
    acqInfo.Description = dicom_names{f}; 
    acqInfo.PhantomRotation = str2double(dicom_names{f}(strfind(dicom_names{f},'rot')+3:end));
    acqInfo.DicomFile = filename;

    acqInfo.Date = DicomHeader1.InstanceCreationDate;
    try
        acqInfo.TR_readout = str2double(dicom_names{f}(strfind(dicom_names{f},'_TR')+3:strfind(dicom_names{f},'_TR')+5));
    catch
        acqInfo.TR_readout = nan; 
    end 
    try
        acqInfo.CompositeDelay = str2double(dicom_names{f}(strfind(dicom_names{f},'_d')+2:strfind(dicom_names{f},'_d')+4));
    catch 
        acqInfo.CompositeDelay = nan;
    end
 
    movefile([savedir filename '.mat'],[savedir prefix '_' dicom_names{f} '.mat'])
    save([savedir prefix '_' dicom_names{f} '.mat'], 'acqInfo', 'imge','-append');

end 