function loglinADCcompare(EPI_imge, SOS_imge, vials_file, title_str, slice, TE_keep, b_keep)

    dicom_list = {EPI_imge, SOS_imge};
    % gets DWI signal at all b-values for each .mat DICOM file, in specific
    % slice
    [dwiData, ~] = getDWIfromDICOMs(vials_file, dicom_list, slice); 
    
    load(vials_file);
    figure; 
    % make a seperate plot for each % of polymer
    sets = {1:3,4:5,6:7,8:9,10:11,12:13};
    per = {'0%';'10%';'20%';'30%';'40%';'50%'}; 
    tiledlayout(3,2, 'Padding', 'compact', 'TileSpacing', 'compact');
    for plts =1:length(sets)
        nexttile;
    
        keep_v = sets{plts};
        title_str = ['Compare ' per{plts} ' Vials']; 
        leg_text={};
        clear Sv
    
        for d = 1:length(dwiData)
        
            lab = dwiData(d).SequenceType;
            trial = strrep(dwiData(d).Description,'_',' '); 
            Sv = dwiData(d).Signal;
    
            if strcmp(lab, 'SOS')
                b = [10, 50, 100, 840];
                line = '--';
                marker = '^';
            else 
                b = [0, 50, 100, 800];
                line = '-';
                marker = 'o';
            end 
    
            % plot multiple vials on each subplot
            for v = keep_v
                
                S = Sv{v};
                if size(S,3) > 1
                    S = squeeze(S(:,:,TE_keep));  
                end 
    
                Y = log(S./S(:,1)); 
                X = b(b_keep);
                
                for p = 1:length(Y)
                    P(p,:) = polyfit(X,Y(p,:),1); 
                end 
        
                Y_mean = mean(Y,1); 
                Y_std = std(Y,[],1); 
        
                % calculate the average ADC fit
                m_mean = mean(P(:,1)); 
                m_std = std(P(:,1),[],1);
                i_mean = mean(P(:,2)); 
                i_std = std(P(:,2),[],1);
                
                % plot Signal and ADC fit 
                Y_fit(v,:) = polyval([m_mean, i_mean], [0,850]); 
                plot([0,850], Y_fit(v,:), line, 'Color',vials(v).color, 'LineWidth', 1.5); hold on; 
                errorbar(X, Y_mean, Y_std, marker, 'Color',vials(v).color, 'LineWidth', 1.5); hold on;
                leg_text = cat(1,leg_text, ...
                    {[num2str(v) '-' trial ' (' num2str(-1*m_mean*1E3, 3) ' +/- ' num2str(abs(m_std*1E3),2) ')']},{''});
                % leg_text = cat(1,leg_text,{[num2str(v) '-' lab{c} ' ADC= ' num2str(-1*m_mean*1E3) ' +/- ' num2str(-1*m_std*1E3)]},{''});
        
                clear S Y P Y_fit
            end 
    
        end 
        
        plot(X,zeros(4,1),'--k'); 
        title(title_str); 
        xlabel('b-value');
        ylabel('log(S)'); 
        ylim([-2, 0.2]); 
        xlim([0, 850]); 
        set(gca, 'FontSize', 14, 'LineWidth', 1.5);
        legend(cat(1,leg_text,{''}), 'Location','SouthWest');
        set(gcf, 'Position', [680  1   861   976])
        
    end 
    
    saveas(gcf, ['LogLinADC_' title_str], 'tiff');
end 