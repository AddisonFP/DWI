function [vials, bg_imge, bg_geomInfo] = createVialROIs(bg_imge_file, view_slice, radius, slnum)
% Plots background coronal slice for selecting 5-voxel radius ROIs for each
% vial in the phantom. 
% INPUTS --
% bg_imge_file     Char. Path and filename of the background image
% view_slice       Integer. Coronal slice number to use for 2D background
% 
% OUTPUTS --
% vials            Struct. Information and ROI for each vial 
% bg_imge          4D Double. The background image used  
% bg_geomInfo      Struct. Background image geometric info

% Sara L. Johnson 
% 03.01.2023

    if ~exist('radius', 'var')
        radius = 10; 
    end 
    
    load(bg_imge_file,'imge', 'geomInfo');

    % DEFINE VIALS
    vial_list = 1:13;
    vial_percent = {0,0,0,10,10,20,20,30,30,40,40,50,50};
    vial_color = {[0 0.4470 0.7410],[0 0.4470 0.7410],[0 0.4470 0.7410],...
                    [0.8500 0.3250 0.0980],[0.8500 0.3250 0.0980],...
                    [0.9290 0.6940 0.1250],[0.9290 0.6940 0.1250],...
                    [0.4940 0.1840 0.5560],[0.4940 0.1840 0.5560],...
                    [0.4660 0.6740 0.1880],[0.4660 0.6740 0.1880],...
                    [0.6350 0.0780 0.1840],[0.6350 0.0780 0.1840]};
    vials = struct('percent', cell(1,13));
    [vials(vial_list).percent] = deal(vial_percent{:});
    [vials(vial_list).color] = deal(vial_color{:});
    
    % SELECT ROI FOR EACH VIAL
   
    sl = view_slice; 
    %temp = imagesc(squeeze(imge(:,:,sl,2)));
    if isa(slnum,'char') && strcmp(slnum, 'end')
        I = imagesc(squeeze(imge(:,:,sl,end))); colormap('gray'); axis image;
    else
        I = imagesc(squeeze(imge(:,:,sl,slnum))); colormap('gray'); axis image;
    end
    % Select ROIs in each multiple vials
    for v = 1:13
        h = drawpoint('Color','r'); 
        ind(:,v) = [round(h.Position(2)), round(h.Position(1)), sl];
        roi = images.roi.Circle('Color','r','Radius',radius,'Center', h.Position); 
        mask = createMask(roi, I); 
        inds_mask = find(mask == 1); 
        [r, c] = ind2sub(size(squeeze(imge(:,:,sl,2))),inds_mask); 
        hold on; visboundaries(mask,'Color',vials(v).color,'EnhanceVisibility',0)
        vials(v).circleROI_inds = [r,c]; 
        vials(v).circleROI_mask = mask; 
        vials(v).pointROI = h.Position;
    end 
    bg_imge = imge;
    try
        bg_geomInfo = geomInfo; 
    catch 
        bg_geomInfo = nan; 
    end 
end 