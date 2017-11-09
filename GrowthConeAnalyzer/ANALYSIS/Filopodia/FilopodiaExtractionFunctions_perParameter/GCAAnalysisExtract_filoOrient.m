function [filoOrient] = GCAAnalysisExtract_filoOrient(analInfo,filoFilterSet)
%% GCAAnalysisFilopodiaOrientInTime
% Collects Filopodia Orientation Distributions for a
% Filtered Set of Filopodia (Note Maria: Add Filter Sets)

%INPUT:
%
%analInfo :  REQUIRED:  large rx1 structure (currently takes some time to load)
%                       where r is the number of frames
%                       that includes all the information one would want about the
%                       segmentation of the movie (including the filopodia information)
%                       (eventually the analInfo needs to be
%                       saved per frame I think to make faster...too big of file)
%
%outDir:     PARAM:
%
%makeMovie:  PARAM:
%
%saveEXCEL:  PARAM:

%%
frames = length(analInfo);
% toPlot = nan(1000,frames-1);% overinitialize.

filoOrient = cell(frames,1);

for iFrame = 1:length(analInfo)-1
    
    
    filoInfo = analInfo(iFrame).filoInfo;
    if ~isempty(filoInfo)
        
        
        
        filterFrameC= filoFilterSet{iFrame};
        filoInfoFilt = filoInfo(filterFrameC(:,1)) ;
        orient =  vertcat(filoInfoFilt.orientation);
        filoOrient{iFrame} = orient;
        
        %toPlot(1:length(orient),iFrame)= orient;
        
        % filter out any that might have passed the exitflag criteria but NOT
        % gave a number for the fit ==0  % maybe flag above later and any
        % internal filopodia that do not exist (these will likewise be
        % marked by an NaN in the datastructure)
    else
        filoOrient{iFrame} = [];
    end
    clear orient
    
end


% if makeMovie == 1 ;
%     nFrame =length(analInfo)-1;
% else
%     nFrame =1;
%     
% end
% for iFrame = 1:nFrame
%     setFigureMoviePlots(200,200,'off');
%     toPlot = reformatDataCell(orientsCell);
%     boxplot(toPlot,'outlierSize',1,'Color','k' );
%     axis([0 frames 0 90]);
%     hold on
%     if makeMovie == 1
%         crim= [176	23	31]./255;
%     end
%     set(gca,'XTick',[100/5+1,200/5+1,300/5+1,400/5+1,500/5+1,600/5+1]);
%     set(gca,'XTickLabel',{'100','200','300','400','500','600'})
%     %frameRate = 5;
%     set(gca,'FontSize',10,'FontName','Arial');
%     xlabel('Time (s)','FontSize',14,'FontName','Arial');
%     ylabel('Orientation (Degrees)','FontSize',14','FontName','Arial');
%     if iFrame == 1
%         saveas(gcf,[outDir filesep num2str(iFrame,'%03d') '.fig']);
%     end
%     if makeMovie ==1
%         scatter(iFrame,nanmedian(toPlot(:,iFrame)),50,crim,'filled');
%     end
%     %axis([0 100*length(frames+1) 0 12])
%     
%     saveas(gcf,[outDir filesep num2str(iFrame,'%03d') '.png']);
%     
%     close gcf
%     
% end

%% Save EXCEL
% if writeExcel == 1
%     if ~exist(toPlot,'var');
%         toPlot = reformatDataCell(orientsCell);
%     end
%     xlswrite([outDir filesep 'filoOrient'],toPlot);
% end
% 
% % label with param so can just search for these files later within the
% % larger file structure (this way can keep a hiearchy of files so it is easy
% % for the user to navigate but still quickly grab for a variable amount of
% % parmeters run)
% save([outDir filesep 'param_filoOrient.mat'],'filoOrient');

