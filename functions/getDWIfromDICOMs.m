function [dwiData, dwiData_tab] = getDWIfromDICOMs(vials_files, dicom_lists, dispOverlay, dispROIs, matdir)

if ~exist('dispOverlay', 'var')
    dispOverlay = false; 
end 
if ~exist('dispROIs', 'var')
    dispROIs = false; 
end 
% 
% if ~iscell(vials_files)
%     if ~iscell(dicom_lists)
%         dicom_lists = {dicom_lists};
%     end 
%     vials_files = {vials_files};
% end 
dwiData = [];

for rep = 1:length(vials_files)
    vials_file = vials_files{rep}; 
    dicom_list = dicom_lists{rep}; 

    if ischar(dicom_list)
        number_dicoms = 1;
    else 
        number_dicoms = length(dicom_list); 
    end 

    % GET VIAL DATA: Resample onto Vials Reference Image 
    load([vials_file '.mat'], 'bg_imge', 'bg_geomInfo', 'vials'); 
    imgeVials = bg_imge;
    geomInfoVials = bg_geomInfo; 
    
    
    for f =1:number_dicoms
        if iscell(dicom_list)
            trial = dicom_list{f};
        elseif isstruct(dicom_list)
            trial = dicom_list(f).name; 
        else 
            trial = dicom_list; 
        end 
        display(trial)
    
        if any(matches(split(trial,'_'),'EPI')) %strcmp(trial(1:3), 'EPI')
            cax = [0 4000]; 
        else 
            cax = [0 3000];
        end
    
        % Load image
        try
            warning('off', 'MATLAB:load:variableNotFound');
            load([matdir '/' trial], 'imge','acqInfo','geomInfo', 'imge_reg'); 
        catch warningException
            load([matdir '/' trial], 'imge','acqInfo','geomInfo');
        end
          
        if exist('imge_reg', 'var')
            imge=imge_reg; 
        end 
        
        % Pad slice dimension if image is 2D for reslicing
        if size(imge, 3) == 1
            if ndims(imge) == 4
                imge = repmat(imge,[1,1,2,1]); 
            elseif ndims(imge) == 5
                imge = repmat(imge,[1,1,2,1,1]);
            end
        end 
    
        % Resample to Vial Reference 
        if size(imgeVials,[1,2]) ~= size(imge, [1,2])
            for te = 1:size(imge,5)
                [imge_interp(:,:,:,:,te)] = coregister_images('linear', imgeVials, geomInfoVials, imge, geomInfo); 
            end   
        
            if dispOverlay
                overlayVolume(imgeVials(:,:,:,1), imge_interp(:,:,:,1,1), 'title',trial); 
            end
        else
            imge_interp = imge; 
        end 

        if dispROIs
            figure;
            imagesc(squeeze(imge_interp(:,:,13,1,1))); colormap('gray'); axis image; caxis(cax); 
            for v = 1:13
                hold on; visboundaries(vials(v).circleROI_mask,'Color',vials(v).color,'EnhanceVisibility',0)
            end 
            title(strrep(trial, '_', ' '));
            saveas(gcf,['Mag_' trial(1:end-4)], 'png'); 
        end 
    
        % Get the DWI signal for all vial ROIs and b-values
        %S = zeros(length(inds),size(imge_interp,4), size(imge,5), length(vials));
        for v = 1:length(vials)
            inds = vials(v).circleROI_inds;
            for i = 1:length(inds)
                Sv(i,:,:,:) = squeeze(imge_interp(inds(i,1),inds(i,2), :, :, :)); 
            end
            S{v} = Sv;
            clear Sv
        end
        
        % Fix the acqInfo CompositeDelay field. Add isComposite Field 
        clear bool_cell
        parsed_trial = split(trial, '_'); 
        bool_cell = strfind(parsed_trial, 'MELV'); 
        ind_check = find(~cellfun(@isempty, bool_cell));
        if isempty(ind_check)
            is_composite = 0; 
            delay = nan; 
        else
            is_composite = 1; 
            clear bool_cell
            bool_cell = strfind(parsed_trial,'d'); 
            ind_delay = find(~cellfun(@isempty, bool_cell));
            delay_str = parsed_trial{ind_delay}; 
            delay = str2double(delay_str(2:end)); 
        end 

        % Create struct for storing DWI signals and image acquisition info
        acqInfo.CompositeDelay = delay; 
        acqInfo.IsComposite = is_composite; 
        acqInfo.Filename = trial; 
        pltInfo = acqInfo; 
        pltInfo.Signal = S; 
        clear S
    
        % Concatenate info for all files into single struct
        if f == 1
            pltInfoAll = pltInfo;
        else
            pltInfoAll = [pltInfoAll, pltInfo];
        end 
    
        clear imge_reg imge_interp
    end 

    if number_dicoms ~= 0
        dwiData = [dwiData, pltInfoAll]; 
        
        dwiData_tab = struct2table(dwiData);
    end

end
end 