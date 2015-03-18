function plotResCombinedDataset(varPerCond,timePerCond,namePerCond,...
    colorPerCond,figNameList,dir2save,yaxisUnits,shiftNegTime)

%% Input

numCond = length(namePerCond);
numFig = length(figNameList);

%% Plot

%plot each variable separately
for iVar = 1 : numFig
    
    h = figure('Name',figNameList{iVar}); hold on
    
    time0Info = NaN(numCond,2);
    
    for iCond = 1 : numCond
        
        %get this condition's time points
        time4plot = timePerCond{iCond};
        
        %shift time to start at 0, store index of original 0
        if shiftNegTime
            indx0 = find(time4plot==0);
            if indx0 > 1
                time4plot = time4plot - time4plot(1);
                time0Info(iCond,:) = [time4plot(indx0) varPerCond{iCond}(indx0,iVar,1)];
            end            
        end
        
        %make plot
        plot(time4plot,varPerCond{iCond}(:,iVar,1),'Color',colorPerCond{iCond});
        myErrorbar(time4plot,varPerCond{iCond}(:,iVar,1),varPerCond{iCond}(:,iVar,2)./sqrt(varPerCond{iCond}(:,iVar,3)));
        
    end
    
    legend(namePerCond)
    
    %indicate original 0 if time was shifted
    if shiftNegTime
        plot(time0Info(:,1),time0Info(:,2),'ko','MarkerSize',10)
    end
    
    xlabel('Time (min)')
    ylabel([figNameList{iVar} ' ' yaxisUnits])
    
    savefig(h,fullfile(dir2save,figNameList{iVar}));
    
end