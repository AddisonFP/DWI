classdef functionsPlotting
   methods

      function box_and_whiskers(obj, adcTable, title_str, groupby, savedir, plt_T1)
    
            % pivot datatable:
            vial_1 = find(strcmp(adcTable.Properties.VariableNames, 'Vial 1'));
            adc2 = stack(adcTable,{adcTable.Properties.VariableNames{vial_1:end}},...
                  'NewDataVariableName','ADC',...
                  'IndexVariableName','Vial'); 
            
            % Creates numerical category for Vial #, not necessary to use. 
            VialNum = rowfun(@convertvial, table(adc2.Vial)); 
            adc2 = [adc2, VialNum]; 
            
            figure;
            boxchart(adc2.Vial,adc2.ADC,'GroupByColor',adc2.(groupby), 'MarkerStyle', 'none', 'BoxWidth', .85);
            legend
            ax = gca; 
            ax.Legend.AutoUpdate = "off"; 
            ax.Legend.Interpreter = 'none';
            ax.Legend.FontSize = 9;
            pause(.2); 
            yl = ylim(); 
            %xvec = [1.5:1:12.5];   % for gridlines
            xvec = [0.5:2:12.5];  %for patches 
            for x = xvec
                hold on; fill([x,x,x+1,x+1],[0,yl(2),yl(2),0],'k','FaceAlpha',.1,'EdgeColor','none'); 
                %hold on; plot([x,x],[0,2.5],'-','Color',[.3, .3, .3], 'LineWidth', .5);
            end
            ylabel('ADC'); 
            ylim([0, yl(2)]); 
            set(gca, 'FontSize', 15);
            set(gcf, 'Position',  [680, 380, 1142, 597]); 
            title(strrep(title_str, '_', ' ')); 
            pause(.2); 
            
            if plt_T1 
                for v=1:length(vials); T1(v) = vials(v).T1_mean; end
                yyaxis right
                plot([2, 4.5, 6.5, 8.5, 10.5, 12.5], T1([2,4,6,8,10,12]), 'o-', 'MarkerFaceColor', 'auto', 'LineWidth', 1); 
                ylim([0, 3300]); 
                %plot([1:13]-.5, T1, '-'); % 'Color',[0.30,0.75,0.93],'LineWidth',2); %'ok','MarkerFaceColor','k'); 
                ylabel('Mean T1'); 
            end 
        
            saveas(gcf, [savedir 'Box_' title_str], 'tiff');

            function vnum = convertvial(vstr)
                vstr = char(vstr);
                ind = strfind(vstr, 'l ');
                vnum = str2num(vstr(ind+2:end));
            end 

        end 
     

      function [PearsonsRho, rmse_total, rmse_vial] = get_errorStats(obj, adcTable, title_str, groupby, workdir, ref_trial)
       

            rep_trials = unique(adcTable.(groupby), 'stable');
   
                
            if exist('ref_trial','var')
                ground_truth = ref_trial;
            else
                try
                    ground_truth = rep_trials{1}; 
                catch
                    ground_truth = rep_trials(1); 
                end 
            end 

            if isnumeric(rep_trials) && ~iscell(rep_trials)
                labels = rep_trials(rep_trials ~= ground_truth);
                labels_str = cellstr(num2str(labels));
                labels = num2cell(labels); 

            elseif iscell(rep_trials) 
                bool_trials = strfind(rep_trials, ground_truth); 
                labels = {rep_trials{find(cellfun(@isempty,bool_trials))}}; 
                for t=1:length(labels)
                    if isnumeric(labels{t})
                        labels_str{t} = num2str(labels{t});
                     else
                        labels_str{t} = labels{t}; 
                    end
                end 
            end 
        
            %ground_truth = rep_trials{1};
            bool_cell = strfind(adcTable.Properties.VariableNames,'Vial'); 
            vial_inds = find(~cellfun(@isempty, bool_cell));
            
            if isnumeric(ground_truth)
                truth_data = adcTable(adcTable.(groupby) == ground_truth, vial_inds);
                seq_truth = unique(adcTable(adcTable.(groupby) == ground_truth,:).Filename);
            else
                truth_data = adcTable(strcmp(adcTable.(groupby), ground_truth), vial_inds);
                seq_truth = unique(adcTable(strcmp(adcTable.(groupby), ground_truth),:).Filename);
            end
            truth_data = table2array(truth_data);

            % check that data will be one-to-one
            seq_all = unique(adcTable.Filename);
            seq_label = setdiff(seq_all, seq_truth); 
            if (length(seq_truth) > 1) && (length(seq_truth) ~= length(seq_label))
                error(['Multiple sequences are being compared in one correlation plot, and' ...
                    'the number of sequences included in x-data and y-data are not equal.']); 
            end 
        
            for col = 1:size(truth_data,2)
                numvox_truth(col) = sum(~isnan(truth_data(:,col))); 
            end
           
            color_order = [      0    0.4470    0.7410
                            0.8500    0.3250    0.0980
                            0.9290    0.6940    0.1250
                            0.4940    0.1840    0.5560
                            0.4660    0.6740    0.1880
                            0.3010    0.7450    0.9330
                            0.6350    0.0780    0.1840
                            0.7290    0         0.7410];
            rmse_total = []; 
            rmse_vial = []; 
            PearsonsRho = []; 
            
            figure; set(gcf, 'Position', [1000, 810, 1235, 530])
            ncol = max([4, length(labels)]);
            tiledlayout(2,5, 'TileSpacing', 'loose');
            for t = 1:length(labels)
                measured = labels{t}; 
                if isnumeric(measured)
                    measured_data = adcTable(adcTable.(groupby) == measured, vial_inds);
                else
                    measured_data = adcTable(strcmp(adcTable.(groupby), measured), vial_inds);
                end
                measured_data = table2array(measured_data);

                % Since the ROIs are different sizes on Day1 and Day2, only use as many
                % voxels from each ROI in the smallest ROI between the two compared
                % datasets
                measured_datar = []; 
                truth_datar = []; 
                for v = 1:size(truth_data, 2)
                    numvox = sum(~isnan(measured_data(:,v)));
                    measured_vial = measured_data(1:min(numvox, numvox_truth(v)), v); 
                    truth_vial = truth_data(1:min(numvox, numvox_truth(v)), v); 
                    measured_datar = cat(1, measured_datar, measured_vial); 
                    truth_datar = cat(1, truth_datar, truth_vial); 
                end 

                rmse_vial(t,:) = sqrt(sum((measured_data - truth_data).^2, 1, "omitnan")./sum(~isnan(truth_data),1)); 
                rmse_total(t) = sqrt(sum((measured_data - truth_data).^2, 'all', "omitnan")./sum(~isnan(truth_data),'all')); 
           
                Rho = corrcoef(measured_datar, truth_datar);
                PearsonsRho(t) = Rho(1,2); 

                nexttile; 
                plot([0, max([truth_datar, measured_datar],[],'all')],[0, max([truth_datar, measured_datar],[],'all')],'-k'); 
                hold on; scatter(truth_datar, measured_datar,3,color_order(t+1,:)); 
                axis square;
                xlabel(strrep(ground_truth, '_',' ')); 
                ylabel(strrep(labels_str{t}, '_',' '));
                ylim([0, max([truth_datar, measured_datar],[],'all')]);
                xlim([0, max([truth_datar, measured_datar],[],'all')]);
                %title(strrep(labels{t}, '_', ' ')); 
                set(gca,'FontSize', 12); 
        
            end 
            
            nexttile(6,[1,2]);
            bar([PearsonsRho; rmse_total]); ylim([0, 1]);
            set(gca,'XTickLabels',{"Pearson's Rho", "RMSE"},'FontSize', 12, 'ColorOrder', color_order(2:end,:));  
            nexttile(8,[1,2]);
            bar(1:length(rmse_vial), rmse_vial); %legend(labels_str, 'Location','northwestoutside'); 
            title('Vial ROIs RMSE'); 
            xlabel('Vial #'); ylim([0 .3])
            set(gca,'FontSize', 12,'ColorOrder', color_order(2:end,:)); 
        
                
            sgtitle(strrep(title_str, '_', ' '), 'FontSize', 14); 
            saveas(gcf, [workdir 'Stats_' title_str '.tif'], 'tiff'); 
        
      end 

      function dwiSignalPlots(obj, dwiTable, vialfile, b_keep, dwi_lim, savedir)

%             % check that there is only 1 file in the data Table 
%             if length(unique(dwiTable.Filename)) > 1
%                 error('dwiSignalPlot takes data from only 1 sequence at a time.')
%             end 
            
            filename = dwiTable.Filename(1,:); 
            if b_keep > 5
                b_values = b_keep; 
            else 
                if any(matches(split(filename,'_'), 'SOS'))
                    b = [10, 50, 100, 840]
                    if any(matches(split(filename,'_'), 'MELV4'))
                        b = [10, 1100] 
                        b_keep = [1,2];
                    end 
                    if strcmp(dwiTable.Filename(1,:),'REP2_SOS_MELV2_d10_b400_rot270')
                        b = [10, 50, 400, 840] 
                    end
                else 
                    b = [0, 50, 100, 800]
                end 
    
                b_values = b(b_keep); 
            end 
        
            load(vialfile,'vials'); 
          
            bool_cell = strfind(dwiTable.Properties.VariableNames,'Vial'); 
            vial_inds = find(~cellfun(@isempty, bool_cell));
            
            titlestr = strrep(dwiTable.Filename(1,:),'_',' ');
            
            dwiData = dwiTable(:,vial_inds); 
            nbval = numel(dwiData{1,1});
            dwiDataMat = table2array(dwiData);
            dwiDataMat = reshape(dwiDataMat,size(dwiDataMat,1), nbval, []); 
        
            dwiData_mean = squeeze(mean(dwiDataMat,1,'omitnan')); 
            dwiData_std = squeeze(std(dwiDataMat,[],1,'omitnan')); 
        
            figure; subplot(1,2,1); 
            for v = 1:size(dwiData_mean,2)
                errorbar(b_values, dwiData_mean(:,v), dwiData_std(:,v), 'o-', 'LineWidth', 1.5, 'Color', vials(v).color);
                hold on; 
            end 

            set(gca,'FontSize',14); 
            ylabel('DWI Signal Intensity'); 
            xlabel('b-value');
            xlim([0 150]);
            xlim([-100 1150]); 
            ylim(dwi_lim);
        
            subplot(1,2,2); 
            for v = 1:size(dwiData_mean,2)
                Y = log(dwiData_mean(:,v)./dwiData_mean(1,v));
                plot(b_values, Y, 'o-', 'LineWidth', 1.5, 'Color', vials(v).color); 
                hold on; 
            end 
            set(gca,'FontSize',14);
            xlabel('b-value');
            ylabel('log(S)'); 
            ylim([-3, 0.2]); 
            %ylim([-0.25, 0.05]); 
            %xlim([0 150]);
            xlim([-100 1150]); 
            sgtitle(titlestr);

            set(gcf,'Position', [697   718   967   444])
    
            saveas(gcf, [savedir 'SignalPlot_' titlestr '.png'], 'png'); 
          
      end 

      function dwiSignal2DImages(obj, files, vialfile, matdir, savedir, savestr, slice, ylabelvar, shrinkROIs)
      
          load(vialfile,'vials');
          
          s = slice; 
          cax = [-.25,1];  
          
           load([matdir files{1} '.mat'], 'imge'); 

          figure; 
            tiledlayout(length(files),size(imge,4),'TileSpacing', 'none', 'Padding','tight'); 
            for f = 1:length(files)
                load([matdir files{f} '.mat'], 'imge','acqInfo'); 
%                 if size(imge, 4) < 4
%                     imge = padarray(imge,[0,0,0,4-size(imge, 4)],0,'post');
%                 end 
                for b = 1:size(imge,4)
                    nexttile; 
                    imgeb = squeeze(imge(:,:,s,b)); 
                    imgeb_norm = imgeb./max(imgeb,[],'all'); 
                    imagesc(imgeb_norm); axis image; clim(cax);
                    set(gca,'XTick',[], 'YTick', [])
    
                  %  if dispROIs
                        for v = 1:13                  
                            if shrinkROIs   %any(matches(split(files{f},'_'), 'SOS')) && ~(any(matches(split(files{f},'_'), 'REP3')))
                          %  hold on; visboundaries(vials(v).circleROI_mask,'Color',vials(v).color,'EnhanceVisibility',0)
                                hold on; plot(vials(v).pointROI(1)/2, ...
                                vials(v).pointROI(2)/2, '.', 'MarkerSize', 10, 'Color', vials(v).color);
                            else
                                hold on; plot(vials(v).pointROI(1), ...
                                vials(v).pointROI(2), '.', 'MarkerSize', 10, 'Color', vials(v).color);
                            end 
                        end 
                    % end 
    
                   % axis off;
                   
                    if b == 1
                        %ylabel(strrep(files{f},'_',' '), 'FontSize', 13);
                        ylabel(acqInfo.(ylabelvar), 'FontSize', 13,'FontWeight','bold')
                    end 
                    if b == size(imge,4) 
                        colorbar; 
                    end

                    if f == 1
                        title(['b' num2str(b)], 'FontSize', 13); 
                    end 
                end 
            end
            set(gcf, 'Position', [1000  300  689/(4/size(imge,4))  1045/(6/length(files))]); 
            colormap('gray')
            saveas(gcf,[savedir savestr '_norm.png'], 'png');

      end 

   end
end