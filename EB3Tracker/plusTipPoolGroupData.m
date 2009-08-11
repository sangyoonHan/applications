function [groupData] = plusTipPoolGroupData


% ask user to pick groups
[projGroupDir,projGroupName]=plusTipPickGroups;

% get output directory
histDir = uigetdir(pwd,'Please select output directory.');

% count unique groups and find out which movies go in which group
[grpNames,m,movGroupIdx] = unique(projGroupName);


mCount=1; % all-movie counter
movCount=1; % in-group movie counter 
allGrwthSpdCell=cell(1,length(projGroupName)); % cell array for holding growth speeds from groups
% iterate thru groups
for iGroup = 1:length(grpNames)
    % empty these values each time
    growthSpeeds=[];
    meanStdGrowth=[];
    growthLifes=[];
    pauseSpeeds=[];
    pauseLifes=[];
    shrinkSpeeds=[];
    shrinkLifes=[];
    growthSpeeds=[];
    meanStdGrowth=[];
    data=[];
    
    % these movies are in iGroup - get big info matrix into cell array
    tempIdx=find(movGroupIdx==iGroup);
    for iMov = 1:length(tempIdx)
        temp = load([projGroupDir{tempIdx(iMov)} filesep 'meta' filesep 'projData']);
        temp2 = temp.projData.nTrack_sF_eF_vMicPerMin_trackType_lifetime_totalDispPix;
        temp2(:,6)=temp2(:,6).*temp.projData.secPerFrame; % convert lifetimes to seconds
        data{iMov,1} = temp2;
        movNum{movCount,1}=iMov;
        movNum{movCount,2}=temp.projData.anDir;
        movCount=movCount+1;
    end

    % extract all growth speeds from each movie in group
    growthSpeeds = cellfun(@(x) x(x(:,5)==1,4),data,'uniformoutput',0);
        [outlierIdx,inlierIdx] = cellfun(@(x) detectOutliers(x),growthSpeeds,'uniformoutput',0);
        growthSpeeds = cellfun(@(x,y) x(y),growthSpeeds,inlierIdx,'uniformoutput',0);
        outlierIdx=[]; inlierIdx=[];

    % get movie-specific mean/std for growth speeds
    meanStdGrowth = cell2mat(cellfun(@(x) [mean(x) std(x)],growthSpeeds,'uniformoutput',0));
    % collect growth speeds for all movies (not just this group)
    allGrwthSpdCell(1,mCount:mCount+length(tempIdx)-1) = growthSpeeds';
    
    % turn cell array into matrix
    growthSpeeds = cell2mat(growthSpeeds);
    
    % extract all growth phase lifetimes from each movie in group
    growthLifes = cellfun(@(x) x(x(:,5)==1,6),data,'uniformoutput',0);
        [outlierIdx,inlierIdx] = cellfun(@(x) detectOutliers(x),growthLifes,'uniformoutput',0);
        growthLifes = cellfun(@(x,y) x(y),growthLifes,inlierIdx,'uniformoutput',0);
        outlierIdx=[]; inlierIdx=[];
        % turn cell array into matrix
        growthLifes = cell2mat(growthLifes);
    
    % extract all pause speeds from each movie in group
    pauseSpeeds = cellfun(@(x) x(x(:,5)==2,4),data,'uniformoutput',0);
            [outlierIdx,inlierIdx] = cellfun(@(x) detectOutliers(x),pauseSpeeds,'uniformoutput',0);
            pauseSpeeds = cellfun(@(x,y) x(y),pauseSpeeds,inlierIdx,'uniformoutput',0);
            outlierIdx=[]; inlierIdx=[];
            % turn cell array into matrix
            pauseSpeeds = cell2mat(pauseSpeeds);
    
    % extract all pause phase lifetimes from each movie in group
    pauseLifes = cellfun(@(x) x(x(:,5)==2,6),data,'uniformoutput',0);
            [outlierIdx,inlierIdx] = cellfun(@(x) detectOutliers(x),pauseLifes,'uniformoutput',0);
            pauseLifes = cellfun(@(x,y) x(y),pauseLifes,inlierIdx,'uniformoutput',0);
            outlierIdx=[]; inlierIdx=[];    
            % turn cell array into matrix
            pauseLifes = cell2mat(pauseLifes);            
    
    % extract all shrinkage speeds from each movie in group
    shrinkSpeeds = cellfun(@(x) abs(x(x(:,5)==3,4)),data,'uniformoutput',0);
            [outlierIdx,inlierIdx] = cellfun(@(x) detectOutliers(x),shrinkSpeeds,'uniformoutput',0);
            shrinkSpeeds = cellfun(@(x,y) x(y),shrinkSpeeds,inlierIdx,'uniformoutput',0);
            outlierIdx=[]; inlierIdx=[];   
            % turn cell array into matrix
            shrinkSpeeds = cell2mat(shrinkSpeeds);            
    
    % extract all shrinkage phase lifetimes from each movie in group
    shrinkLifes = cellfun(@(x) x(x(:,5)==3,6),data,'uniformoutput',0);
            [outlierIdx,inlierIdx] = cellfun(@(x) detectOutliers(x),shrinkLifes,'uniformoutput',0);
            shrinkLifes = cellfun(@(x,y) x(y),shrinkLifes,inlierIdx,'uniformoutput',0);
            outlierIdx=[]; inlierIdx=[];    
            % turn cell array into matrix
            shrinkLifes = cell2mat(shrinkLifes);


    % assign group data to output structure
    groupData.(grpNames{iGroup,1}).growthSpeeds = growthSpeeds;
    groupData.(grpNames{iGroup,1}).meanStdGrowth = meanStdGrowth;
    
    groupData.(grpNames{iGroup,1}).growthLifetimes = growthLifes; 
    
    groupData.(grpNames{iGroup,1}).pauseSpeeds = pauseSpeeds;
    
    groupData.(grpNames{iGroup,1}).pauseLifetimes = pauseLifes;

    groupData.(grpNames{iGroup,1}).shrinkSpeeds = shrinkSpeeds;
    
    groupData.(grpNames{iGroup,1}).shrinkLifetimes = shrinkLifes;

    % create x-axis bins spanning all speeds in sample
    n=linspace(min([growthSpeeds; pauseSpeeds; shrinkSpeeds]),max([growthSpeeds; pauseSpeeds ;shrinkSpeeds]),25);

    % bin the samples
    [x1,nbins1] = histc(growthSpeeds,n);
    [x2,nbins2] = histc(pauseSpeeds,n);
    [x3,nbins3] = histc(shrinkSpeeds,n);

    % M contains growth, pause, and shrinkage values in matrix backfilled
    % with nans
    M=nan(max([length(x1) length(x2) length(x3)]),3);
    M(1:length(x1),1)=x1;
    M(1:length(x2),2)=x2;
    M(1:length(x3),3)=x3;

    % make a stacked histogram of growth, pause, and shrinkage
    figure
    bar(n,M,'stack')
    colormap([1 0 0; 0 0 1; 0 1 0])
    legend('growth','pause','shrinkage','Location','best')
    title(['Sub-Track Speed Distribution: ' grpNames{iGroup,1}])
    xlabel('speed (um/min)');
    ylabel('frequency of tracks');
    saveas(gcf,[histDir filesep 'stackedHist_' grpNames{iGroup,1} '.fig'])
    saveas(gcf,[histDir filesep 'stackedHist_' grpNames{iGroup,1} '.tif'])

    % make a growth speed histogram
    [x1 x2]=hist(growthSpeeds,25);
    bar(x2,x1,'r')
    title('growth speed distribution')
    xlabel('speed (um/min)');
    ylabel('frequency of tracks');

    saveas(gcf,[histDir filesep 'growthHist_' grpNames{iGroup,1} '.fig'])
    saveas(gcf,[histDir filesep 'growthHist_' grpNames{iGroup,1} '.tif'])
    
    % update the counter
    mCount = mCount+length(tempIdx);

end


% get nMovie-vector with number of growth trajectories 
maxSize=cellfun(@(x) length(x),allGrwthSpdCell);
% convert cell array of growth speeds into nTraj x nMovie matrix
allGrwthSpdMatrix=nan(max(maxSize'),length(allGrwthSpdCell));
for i=1:length(allGrwthSpdCell)
   allGrwthSpdMatrix(1:maxSize(i),i) = allGrwthSpdCell{1,i}; 
end

% for each value, put group name into matrix
condition=repmat(projGroupName',[max(maxSize'),1]);
% for each value, put movie number (within group) into matrix
movNumMat=repmat(cell2mat(movNum(:,1))',[max(maxSize'),1]);

% make jonas dist plot comparing all the movies
figure
distributionPlot_JD(allGrwthSpdMatrix)
saveas(gcf,[histDir filesep 'distributionPlotByMovie.fig'])
saveas(gcf,[histDir filesep 'distributionPlotByMovie.tif'])

% make box plot comparing all the movies
figure
boxplot(allGrwthSpdMatrix(:),{condition(:) movNumMat(:)},'notch','on','orientation','horizontal');
title('Growth Speeds by Movie')
set(gca,'YDir','reverse')
xlabel('microns/minute')
saveas(gcf,[histDir filesep 'boxplotByMovie.fig'])
saveas(gcf,[histDir filesep 'boxplotByMovie.tif'])

% pool data at the level of the group and make box plot
figure
boxplot(allGrwthSpdMatrix(:),{condition(:)},'notch','on','orientation','horizontal');
title('Growth Speeds by Group')
set(gca,'YDir','reverse')
xlabel('microns/minute')
saveas(gcf,[histDir filesep 'boxplotByGroup.fig'])
saveas(gcf,[histDir filesep 'boxplotByGroup.tif'])


movIdx=[];
movIdx=cell(length(projGroupName),3);
movIdx(:,1)=projGroupName;
movIdx(:,2)=movNum(:,1);
movIdx(:,3)=movNum(:,2);
groupData.movIdx=movIdx;
save([histDir filesep 'groupData'],'groupData');
