function B1Flatten(dicom_mat_list, dicom_mat_file, b1_dicom_file)
    [b1map, ~, ~] = loadDicomAsMat_XA('', b1_dicom_file);
    b1map = normalize(b1map); %% you need to know the scaling on these values in order to norm it.

    for i = length(dicom_mat_list)
        if iscell(dicom_mat_list)
            trial = dicom_mat_list{i};
        elseif isstruct(dicom_mat_list)
            trial = dicom_mat_list(f).name; 
        else 
            trial = dicom_mat_list; 
        end 

        try
            warning('off', 'MATLAB:load:variableNotFound');
            load([dicom_mat_file trial '.mat'], 'imge','acqInfo','geomInfo', 'imge_reg'); 
        catch warningException
            load([dicom_mat_file trial '.mat'], 'imge','acqInfo','geomInfo');
        end
    end
end