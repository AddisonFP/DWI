function ADC = getADCmap(dicom_file, vial_file, slice, TE_keep, b_keep, save_flag)
    load([vial_file]); 
    imgeVials = imgeEPI; 
    geomInfoVials = geomInfo; 
    
    load([dicom_file '.mat'], 'imge', 'imge_reg', 'geomInfo'); 
    if exist('imge_reg', 'var')
        imge = imge_reg; 
    end 
    
    % Pad slice dimension if image is 2D for reslicing
    if size(imge, 3) == 1
        if ndims(imge) == 4
            imge = repmat(imge,[1,1,2,1]); 
        elseif ndims(imge) == 5
            imge = imge(:,:,:,:,TE_keep);
            imge = repmat(imge,[1,1,2,1]);
        end
    end 

    % Resample to Vial Reference 
    imge_interp = coregister_images('linear', imgeVials, geomInfoVials, imge, geomInfo); 
     

    % Fit to ADC 
    %if ndims
    if strcmp(dicom_file(1:3), 'SOS')
        b = [10, 50, 100, 840];
    else 
        b = [0, 50, 100, 800];
    end 

    % S is a 2D Slice of DWI data, all b-values
    S = squeeze(imge_interp(:,:,slice,b_keep)); 
    S2 = reshape(S, [size(S,1)*size(S,2), size(S,3)]);

    Y = log(S2./S2(:,1)); 
    X = b(b_keep);
    
    for p = 1:length(Y)
        P(p,:) = polyfit(X,Y(p,:),1); 
    end 
    ADC = -1*reshape(P(:,1), size(S,1:2))*1E3;

    if save_flag
        save([dicom_file '.mat'], 'ADC'); 
    end 
end 

    