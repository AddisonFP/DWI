function [adcTable, mean_adcTable, std_adcTable, mean_SvTable, dwiTable] = getDWIsubset(dwiData_file, parameters, b_vals, TE_keep, slice)

    if ~exist('TE_keep', 'var')
        TE_keep = 1; 
    end 
    
    % Load full dwiData table 
    if ischar(dwiData_file)
        load(dwiData_file, 'dwiData');
    elseif isstruct(dwiData_file)
        dwiData = dwiData_file; 
    end 
    
    % get subset of dwiData Table based on parameters
    for p = 1:length(parameters)
        field_name = parameters{p}{1};
        if isstring(dwiData(1).(field_name)) || ischar(dwiData(1).(field_name))
            idx = matches({dwiData.(field_name)}, parameters{p}{2});  
        else
            idx = ismember([dwiData.(field_name)], parameters{p}{2}); 
        end 
        data_sub = dwiData(idx); 
        dwiData = data_sub; 
    end 

    if size(dwiData,2) == 0
        error('No sequences match the input parameters.')
    end 
    
    % Reformat dwiData from struct to Table
    dwiTable = struct2table(dwiData); 
    for row = 1:height(dwiTable)
        dwiTable.Description(row) = strrep(dwiTable.Description(row), '_', ' '); 
    end 
    dwiTable.Date = str2double(dwiTable.Date); 
    days = unique(dwiTable.Date); 
    for d = 1:length(days)
        dwiTable.DateTag(dwiTable.Date == days(d)) = {['Day' num2str(d)]};
    end 
    display(dwiTable);

    % Set-up empty tables 
    mean_adcTable = removevars(dwiTable, 'Signal'); 
    std_adcTable = removevars(dwiTable, 'Signal');
    mean_SvTable = removevars(dwiTable, 'Signal');
    numcols = width(mean_adcTable); 
    vial_cols = string(compose('Vial %d', 1:13));
    adcTable = table();
    dwiTable = table(); 
    
    % Calculate maximum length of output table 
    S = dwiData(1).Signal;
    for v = 1:13
        l(v) = length(S{v});
    end 

    % Store ADC value for each voxel in all vial ROIs
    for d = 1:length(dwiData) % for each image in the dwiData subset
    
        % Set-up empty tables 
        param_table = repmat(mean_adcTable(d,1:numcols),[max(l),1]); % length is == largest ROI
        adc_table_d = table();
        dwi_table_d = table(); 
    
        % Select b-values for ADC fit
        if ~exist('b_vals', 'var')
            b_vals = [0, 50, 100, 800];
        end
        b_keep = 1:length(b_vals);
      
        b_vec = b_vals;
        S = dwiData(d).Signal;
        
        for v = 1:13 % for each vial ROI 
   
            % Get dwi Signal from all vial voxels and slices. Keep selected TE 
            Sv = S{v}; 
            if size(Sv,4) > 1
                Sv = squeeze(Sv(:,:,:,TE_keep));  
            end 
            
            if exist('slice', 'var')
                Svb = Sv(:,slice,b_keep); % Svb: [nvox, 1, nbval]
                % For output tables, set matrix length to maximum ROI size:
                P = nan(max(l), 1); % P:[nvoxMAX]
                Svb_out = nan(max(l), length(b_keep)); % Sbv_out:[nvoxMAX, nbval];
                Svb_out(1:size(Svb,1),:) = squeeze(Svb); 
            else 
                Svb = Sv(:,:,b_keep);  % Svb:[nvox, nslices, nbval]
                % For output tables, set matrix length to maximum ROI size:
                P = nan(max(l), size(Sv,2)); % P:[nvoxMAX, nslices]
                Svb_out = nan(max(l), size(Sv,2), length(b_keep)); % Svb_out:[nvoxMAX, nslices, nbval];
                Svb_out(1:size(Svb,1),:,:) = Svb; 
            end

            % Reshape: Combine DIMS 1 (nvox) and 2 (nslices) 
            Svb_reshape = reshape(Svb, [size(Svb,1)*size(Svb,2), size(Svb,3)]); % Svb_reshape:[nvox*nslices, nbval]
                      
            % Perform ADC fit 
            Y = log(Svb_reshape./Svb_reshape(:,1)); 
            X = b_vec;
            
            for p = 1:length(Y)
                P_reshape(p,:) = polyfit(X,Y(p,:),1); 
            end 
            P(1:size(Svb,1),:,:) = reshape(P_reshape(:,1),[size(Svb,1), size(Svb,2)]);
    
            % Save mean, std of ADC into Tables
            adc_mean(v) = -1*mean(P,1,'omitnan')*1E3; 
            adc_std = abs(std(P,[],1, 'omitnan'))*1E3;
            Sv_mean = mean(Svb_reshape,1); 
            Sv_mean = mean(Svb_reshape(:,2)./Svb_reshape(:,1)); 
    
%             adc_mean = -1*mean(P(~isnan(P(:,1)),1))*1E3; 
%             adc_std = abs(std(P(~isnan(P(:,1)),1),[],1))*1E3;
    
            mean_adcTable.(vial_cols(v))(d) = {adc_mean(v)}; 
            std_adcTable.(vial_cols(v))(d) = {adc_std}; 
            mean_SvTable.(vial_cols(v))(d) = {Sv_mean}; 
    
            % Save all vial voxel ADCs into Table
            adc_table_d.(vial_cols(v)) = -1*P*1E3;
            dwi_table_d.(vial_cols(v)) = Svb_out; 

            clear P_reshape P
        end
        
        adc_table_d = fillmissing(adc_table_d,'constant', adc_mean);
        %dwi_table_d = fillmissing(dwi_table_d,'constant', Sv_mean);

        adc_table_d = [param_table, adc_table_d]; % HORZ cat of sequence parameters and ADC values
        adcTable = [adcTable; adc_table_d];  % VERT cat of data from each sequence

        dwi_table_d = [param_table, dwi_table_d]; 
        dwiTable = [dwiTable; dwi_table_d]; 

        clear adc_table_d adc_mean
    end 
end 