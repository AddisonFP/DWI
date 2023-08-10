function [imge_reg, tform_out, tform_init, tform_best] = registerDWIimage(target_img, moving_img, init_rot, view_slice, tform_type, MIbins, optimizer, metric)
% Registers 3D DWI images of phantoms acquired with the phantom rotated in
% the coronal plane.
% -- User selects which b-value had best registration result, and applies
%    that transform to all b-values (4th DIM)
% INPUTS -- 
% target_img       4D double, image to register to
% moving_img       4D double, image to register
% init_rot         Scalar, initial guess of coronal rotation angle
% view_slice       Integer, coronal slice used for plotting phantom
% tform_type       Char, registration type ie: 'rigid' or 'affine'
% optimizer        Optimizer object and config 
%                   [DEFAULT = registration.optimizer.RegularStepGradientDescent]
% metric           Scoring metric object and config
%                   [DEFAULT = registration.metric.MattesMutualInformation]
% OUTPUTS --
% imge_reg         4D double, the registered image
% tform            Transformation object 
%
% Sara. L Johnson
% 03.01.2023


    if ~exist('optimizer','var')
        optimizer = registration.optimizer.RegularStepGradientDescent; 
    end 

    if ~exist('metric','var')
        metric = registration.metric.MattesMutualInformation; 
        metric.NumberOfHistogramBins = 20;
    end

    if exist('MIbins','var')
        metric.NumberOfHistogramBins = MIbins;
    end 
    
    if ~exist('tform_type','var')
        tform_type = 'rigid';
    end 

%     if length(view_slice) > 1
%         sT = view_slice(1);  %target image view
%         sS = view_slice(2);  %source image view
%     
    s = view_slice;
    h = figure; 
    
    moving_imgr = zeros(size(target_img)); 
    for b = 1:size(target_img,4)
        display([init_rot, b]);
    
        target_imgb = squeeze(target_img(:,:,:,b));  
        moving_imgb = squeeze(moving_img(:,:,:,b));  
        
        % perform initial rotation before intensity-based registration
        moving_imgr(:,:,:,b) = imrotate3(moving_imgb, init_rot, [0,0,1], 'linear', 'crop', 'FillValues', 72);
        tform_init = rigidtform3d([0, 0, -init_rot],[0,0,0]); 
        moving_imgr2 = imwarp(moving_imgb, tform_init); 
        
        % plot initial images 
        subplot(3,4,1); imagesc(target_img(:,:,s,1)); axis image; title('Target');
        subplot(3,4,2); imagesc(moving_img(:,:,s,1)); axis image; title('Source');
        subplot(3,4,3); imagesc(moving_imgr(:,:,s,1)); axis image; title('Source-Initial Rot'); 
        subplot(3,4,4); imagesc(moving_imgr2(:,:,s,1)); axis image; title('Source-Initial Rot-imWarp'); 
        
       % if b == 1 || b == 4
            % perform intensity-based registration
            tform(b) = imregtform(moving_imgr(:,:,:,b), imref3d(size(moving_imgr(:,:,:,b))), ...
                         target_imgb, imref3d(size(target_imgb)),...
                        tform_type,...
                        optimizer, ...
                        metric); 
            moving_reg = imwarp(moving_imgr(:,:,:,b), tform(b), ...
                         "OutputView", imref3d(size(target_imgb)));
            
            % plot blended image for b-value
            subplot(3,4,4+b);
            imshowpair(target_imgb(:,:,s),moving_reg(:,:,s),"Scaling","joint");
            title(['Blended B=' num2str(b)]); 
        %end 
    
    end 
    
    % User select best tform from all b-values 
    b_best = inputdlg('Best transformation was for b-value (1,2,3, or 4):');
    clear moving_reg
    
    % apply best tform to all b-values in image
    tform_best = tform(str2num(b_best{1}));
    moving_reg = zeros(size(target_img));
    for b = 1:size(target_img,4)
        moving_reg(:,:,:,b) = imwarp(moving_imgr(:,:,:,b), tform_best, ...
            "OutputView", imref3d(size(target_img(:,:,:,b))));
    end 
    
    tform_compose = rigidtform3d(tform_best.A*tform_init.A); 

    % plot registered image for all b-values 
    subplot(3,4,9); imagesc(moving_reg(:,:,s,1)); axis image; title(['Registered B=1'])
    subplot(3,4,10); imagesc(moving_reg(:,:,s,2)); axis image; title(['Registered B=2'])
    subplot(3,4,11); imagesc(moving_reg(:,:,s,3)); axis image; title(['Registered B=3'])
    subplot(3,4,12); imagesc(moving_reg(:,:,s,4)); axis image; title(['Registered B=4'])
    waitfor(h)
    imge_reg = moving_reg; 
    %tform_out = tform(str2num(b_best{1})); 
    tform_out = tform_compose; 
    end 
