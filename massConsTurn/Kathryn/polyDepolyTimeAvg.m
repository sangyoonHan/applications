function [runInfo]=polyDepolyTimeAvg(runInfo,nFrms2Avg,timeStepSize,startFrm,endFrm)
%POLYDEPOLYTIMEAVG: time average kinetic maps and calculate mean total poly/depoly over frame range
%
% SYNOPSIS: [polyDepolySumAvg]=polyDepolyTimeAvg(runInfo,nFrms2Avg,timeStepSize,startFrm,endFrm)
%
% INPUT: runInfo        : structure containing a field with the turnover
%                         analysis directory path (from polyDepolyMap)
%        nFrms2Avg      : frame interval to average
%        timeStepSize   : number of frames between averages
%        startFrm       : first frame to use in calculation
%        endFrm         : last frame to use in calculation
%        
%
%        e.g.) if you want frames 1-5 averaged, 3-8, 5-11, etc. then
%                         nFrms2Avg=5 and timeStepSize=3
%
% OUTPUT: /analysis/turn/turnTmAvgDir/mapMats : directory with .mat files
%              containing the averaged poly-depoly maps
%         /turnTmAvgDir/activityHist : directory containing histograms of
%              poly-depoly values for each averaged frame
%
% USERNAME: kathomps
% DATE: 11-Jan-2008


% --------------------
% CHECK USER INPUT

if nargin<1
    error('turnoverMap: Not enough input parameters')
end
if ~isstruct(runInfo)
    runInfo=struct;
end

if ~isfield(runInfo,'imDir') || ~isfield(runInfo,'anDir') || ~isfield(runInfo,'turnDir')
    error('turnoverMap: runInfo should contain fields imDir and anDir');
else
    [runInfo.anDir] = formatPath(runInfo.anDir);
    [runInfo.imDir] = formatPath(runInfo.imDir);
    [runInfo.turnDir] = formatPath(runInfo.turnDir);
end

cmDir=2; % user might want to change this
if cmDir==1
    % use the cell masks of the images to average
    cmDir=[runInfo.anDir filesep 'edge' filesep 'cell_mask'];
elseif cmDir==2
    % use vectorCoverageMasks instead of cell masks
    cmDir=[runInfo.anDir filesep 'corr' filesep 'filt' filesep 'vectorCoverageMask'];
end




if nargin<2 || isempty(nFrms2Avg)
    nFrms2Avg=5; % default
    disp(['polyDepolyTimeAvg: nFrms2Avg = ' num2str(nFrms2Avg)])
end

if nargin<3 || isempty(timeStepSize)
    timeStep=1; % default
    disp(['polyDepolyTimeAvg: timeStep = ' num2str(timeStepSize)])
end

if nargin<4 || isempty(startFrm)
    startFrm=1; % default
end

if nargin<5 || isempty(endFrm)
    endFrm=[]; % will assign to nTotalFrames
end


% --------------------
% MAKE DIRECTORIES

% create subdirectory for time averaging the spatially averaged maps
% (first remove old directory if it exists)
turnTmAvgDir=[runInfo.turnDir filesep 'timeAvg_' num2str(nFrms2Avg) '_' num2str(timeStepSize)];
runInfo.turnTmAvgDir=turnTmAvgDir;

if isdir(turnTmAvgDir)
    rmdir(turnTmAvgDir,'s');
end
tmMatsDir=[turnTmAvgDir filesep 'mapMats'];
mkdir(tmMatsDir);

% make subdirectory for storing average cell masks over the time interval
tmCellMasksDir=[tmMatsDir filesep 'avgCellMask'];
mkdir(tmCellMasksDir);

% create subdirectory for histograms showing the kinetic activity from the
% time-averaged data
% (first remove old directory if it exists)
histDir=[turnTmAvgDir filesep 'activityHist'];
mkdir(histDir);

% --------------------

% count frames for proper naming
turnMapDir=[runInfo.turnDir filesep 'interp'];
[listOfFiles] = searchFiles('polyDepoly',[],turnMapDir,0);
nFrames=size(listOfFiles,1);
s=length(num2str(nFrames));
strg=sprintf('%%.%dd',s);

% if 0, than average over the whole movie
if nFrms2Avg==0
    nFrms2Avg=nFrames;
    endFrm=nFrames;
end

% figure out which frames to average in a given iteration
if isempty(endFrm)
    endFrm=nFrames;
end
firstFrm=[startFrm:timeStepSize:endFrm]; lastFrm=firstFrm+nFrms2Avg-1;
firstFrm(lastFrm>endFrm)=[];             lastFrm(lastFrm>endFrm)=[];

nIterations=length(firstFrm); % how many iterations needed to go thru all frame ranges
avgPolyDepolyPerFrame=zeros(nIterations,2); % store [sum(avgPoly) sum(avgDepoly)] for each frame range


% roiMask is the user-selected region where poly/depoly should be
% calculated
roiFile=[runInfo.anDir filesep 'polyDepolyROI.tif'];
if exist(roiFile,'file')
    roiMask=imread(roiFile);
else
    roiMask=ones(runInfo.imL,runInfo.imW);
end

h=get(0,'CurrentFigure');
if h==1
    close(h)
end
figure(1);


[listOfCellMasks] = searchFiles('.tif',[],cmDir,0);
for i=1:nIterations

    counter=1;

    polyDepolySum=zeros(runInfo.imL,runInfo.imW,nFrms2Avg);
    cellMaskSum=zeros(runInfo.imL,runInfo.imW,nFrms2Avg);

    for j=firstFrm(i):lastFrm(i)
        % accumulate polyDepoly maps for the interval
        iMap=load([char(listOfFiles(j,2)) filesep char(listOfFiles(j,1))]);
        polyDepolySum(:,:,j) = iMap.polyDepoly;

        % accumulate the cell masks, bound by roiMask
        cMask=double(imread([char(listOfCellMasks(j,2)) filesep char(listOfCellMasks(j,1))]));
        cellMaskSum(:,:,j) = cMask.*roiMask;

        counter=counter+1;
    end

    indxStr1=sprintf(strg,firstFrm(i));
    indxStr2=sprintf(strg,lastFrm(i));

    polyDepolySum=nansum(polyDepolySum,3);
    cellMaskSum=nansum(cellMaskSum,3);

    % get average mask, write image
    cellMaskAvg=(cellMaskSum./nFrms2Avg);
    save([tmCellMasksDir filesep 'timeAvgCellMask' indxStr1 '_' indxStr2 '.mat'],'cellMaskAvg');
    
    cellMaskSum=swapMaskValues(cellMaskSum,0,NaN); % 1's inside avg cell; nan's outside

    % get average poly/depoly map and bound by roiMask, save
    polyDepolyAvg=(polyDepolySum./cellMaskSum).*roiMask;
    save([tmMatsDir filesep 'polyDepolyAvg' indxStr1 '_' indxStr2 '.mat'],'polyDepolyAvg');

    m=max(abs([runInfo.polyDepolyMovieMin runInfo.polyDepolyMovieMax]));    
    
    % create histogram of poly/depoly values from the set of nFrms2Avg
    temp=polyDepolyAvg(:);
    temp(isnan(temp))=[];
    hist(temp,100);
    axis([-m m 0 3000]);
    drawnow
    h=get(0,'CurrentFigure');
    saveas(h,[histDir filesep 'actHist' indxStr1 '_' indxStr2 '.png']);
   
end
close
save([tmMatsDir filesep 'tmAvgParams'],'nFrms2Avg','timeStepSize','startFrm','endFrm');



