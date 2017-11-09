function spindleEnrichment(MD,varargin)
ip = inputParser;
ip.CaseSensitive = false;
ip.KeepUnmatched = true;
ip.addParameter('package',[]);
ip.addParameter('trackKTPackage',MD.searchPackageName('trackKT','selectIdx','last'));
ip.addParameter('startTime',0);
ip.addParameter('dynROIProject',[]);
ip.addParameter('useKT',true);
ip.addParameter('name',[]);
ip.addParameter('packPID',400);
ip.parse(varargin{:});
p=ip.Results;

% Process type placeholdes
packPID=p.packPID;
% We save the temp processes at packID+1, that way if process get killed
% halfway through, or other issues, the previous logs are not overidden but
% the last computation location are still available.

packPIDTMP=packPID+1;

MD.setPackage(packPIDTMP,GenericPackage({ ...
    PointSourceDetectionProcess3D(MD,[MD.outputDirectory_ filesep 'EB3']),...
    ExternalProcess(MD,'detectPoles'),...
    ExternalProcess(MD,'buildRefsAndROI'), ...
    ExternalProcess(MD,'project1D'),...
    ExternalProcess(MD,'project1D'),...
    ExternalProcess(MD,'spindleEnrichment'),...
    ExternalProcess(MD,'DetectionAstral'),...
    ExternalProcess(MD,'DetectionPolar')...
    ExternalProcess(MD,'DetectionAstral'),...
    ExternalProcess(MD,'DetectionPolar')...
    ExternalProcess(MD,'KTDetection')...
    }));

lpid=1;

if(~isempty(p.package)&&(~isempty(p.package.getProcess(lpid))))
   processDetectEB3=p.package.getProcess(lpid);
else
    disp('Computing  detections')
    tic
    processDetectEB3=PointSourceDetectionProcess3D(MD, [MD.outputDirectory_ filesep 'EB3'],UTrackPackage3D.getDefaultDetectionParams(MD,[MD.outputDirectory_ filesep 'EB3']));
    MD.addProcess(processDetectEB3);
    funParams = processDetectEB3.funParams_;
    funParams.showAll=true;
    %funParams.frameRange=[1 2];    
    funParams.alpha=0.05;
    funParams.filterSigma=[1.4396 1.4396;1.2913 1.2913  ];
    funParams.WindowSize={[],[]};
    funParams.algorithmType= {'pointSourceLM'  'pointSourceLM'};
    funParams.ConfRadius={[],[]};       
    processDetectEB3.setPara(funParams);
    paramsIn.ChannelIndex=1;
    paramsIn.isoCoord=true;
    processDetectEB3.run(paramsIn);
    toc;
end
MD.getPackage(packPIDTMP).setProcess(lpid,processDetectEB3);

lpid=2;
if(~isempty(p.package)&&(~isempty(p.package.getProcess(lpid))))
    processDetectPoles=p.package.getProcess(lpid);
else
    disp('Computing spindle ref');tic;
    processDetectPoles=ExternalProcess(MD,'detectPoles',@(p) detectPoles(p.getOwner(),'process',p,'isoOutput',true));
    processDetectPoles.run();
    toc;
end
MD.getPackage(packPIDTMP).setProcess(lpid,processDetectPoles);

lpid=3;
if(~isempty(p.package)&&(~isempty(p.package.getProcess(lpid))))
    processBuildRef=p.package.getProcess(lpid);
else
    processBuildRef=ExternalProcess(MD,'buildRefsAndROI',@(p) buildRefsFromTracks(processDetectPoles,processDetectPoles,'buildROI',true,'process',p));
    processBuildRef.run();
end
MD.getPackage(packPIDTMP).setProcess(lpid,processBuildRef);

disp('Loading spindle ref');tic;

tmp=load(processDetectPoles.outFilePaths_{1});
P1=tmp.tracks(1);
P2=tmp.tracks(2);

refs=load(processBuildRef.outFilePaths_{1}); refs=refs.refs;
ROIs=load(processBuildRef.outFilePaths_{2}); ROIs=ROIs.ROI;
toc;

disp('Loading, mapping and setting detection reference');tic;
tmp=load(processDetectEB3.outFilePaths_{1}); detection=tmp.movieInfo;

%EB3Inliers=mapDetectionsTo1DManifold(ROIs{1,2},detection,0,'distType','vertexDistOtsu');
EB3Inliers=mapDetectionsTo1DManifold(ROIs{1,2},detection,80,'distType','euclideanDist');


amiraWriteMovieInfo([fileparts(processBuildRef.outFilePaths_{2}) filesep 'AmiraDetect' filesep 'detectionLabRef.am'],EB3Inliers);

allDetections=Detections(detection);
oDetections=EB3Inliers.copy();
oDetectionsP1P2=refs(1,2).applyBase(oDetections,'');
oDetectionsP2P1=refs(2,1).applyBase(oDetections,'');
oDetectionsP1P2.addSphericalCoord();
oDetectionsP2P1.addSphericalCoord();
elevations=arrayfun(@(d,D) min(d.elevation,D.elevation),oDetectionsP1P2,oDetectionsP2P1,'unif',0);
azimuths=arrayfun(@(d,D) (d.azimuths,oDetectionsP1P2,'unif',0);
toc;

lpid=4;
if(~isempty(p.package)&&(length(p.package.processes_)>=lpid)&&(~isempty(p.package.getProcess(lpid))))
    processProj=p.package.getProcess(lpid);
else
processProj=ExternalProcess(MD,'project1D');
project1D(  MD, ...
            'name','fullMIPLabFrame','channelRender','grayRed','saveSingleProj',true, 'insetFringeWidth',20,'fringeWidth',60, ...
            'processSingleProj',processProj, 'intMinPrctil',[20 70],'intMaxPrctil',[99.99 99.99]);              
end    
MD.getPackage(packPIDTMP).setProcess(lpid,processProj);


lpid=lpid+1;
if(~isempty(p.package)&&(length(p.package.processes_)>=lpid)&&(~isempty(p.package.getProcess(lpid))))
    processProjSpindleRef=p.package.getProcess(lpid);
else
    processProjSpindleRef=ExternalProcess(MD,'project1D');
    project1D(  MD,[P1,P2],'FoF',refs(1,2),'dynPoligonREF',refs(1,2).applyBase([P1,P2],''), ...
        'name','CroppedSpindleRef','channelRender','grayRed','saveSingleProj',true, 'insetFringeWidth',100, ...
        'processSingleProj',processProjSpindleRef, 'intMinPrctil',[20 70],'intMaxPrctil',[99.99 99.99]);
end
MD.getPackage(packPIDTMP).setProcess(lpid,processProjSpindleRef);

%% Elevation and densities

%% Debug inlier selection
% process=ExternalProcess(MD,'Detection');
% overlayProjDetectionMovie(processProj,'detections',allDetections, ...
%         'process',process,'cumulative',true,'processFrames',1, ...
%         'name','cumulDetectionDensity');
% img1=imread(sprintfPath(process.outFilePaths_{2},1));
% process=ExternalProcess(MD,'Detection');
% overlayProjDetectionMovie(processProj,'detections',EB3Inliers, ...
%         'process',process,'cumulative',true,'processFrames',1, ...
%         'name','cumulDetectionDensity');
% img2=imread(sprintfPath(process.outFilePaths_{2},1));
% figure(); imshow([img1 img2]);

%% Compute tracks if necessary
trackKTPack=p.trackKTPackage;
if(isempty(trackKTPack))
    trackKT(MD);
    trackKTPack=MD.searchPackageName('trackKT','selectIdx','last');
end

%% load and map tracks to the spindle
KTTracks=TracksHandle(trackKTPack.getProcess(3).loadChannelOutput(2));
KTTracksInliers=mapTracksTo1DManifold(ROIs{1,2},KTTracks,0,'position','start','distType','vertexDistOtsu');
KTDetection=Detections(KTTracksInliers.getMovieInfo());
KTDetectionsP1P2=refs(1,2).applyBase(KTDetection,'');
KTDetectionsP2P1=refs(2,1).applyBase(KTDetection,'');
KTDetectionsP1P2.addSphericalCoord();
KTDetectionsP2P1.addSphericalCoord();
KTelevations=arrayfun(@(d,D) min(d.elevation,D.elevation),KTDetectionsP1P2,KTDetectionsP2P1,'unif',0);
KTpoleDistances=arrayfun(@(d,D) min(d.rho,D.rho),KTDetectionsP1P2,KTDetectionsP2P1,'unif',0);
KTazimuths=arrayfun(@(d,D) d.azimuths,KTDetectionsP1P2,'unif',0);

%% Select KT detections.
KTEndsIdx=arrayfun(@(t) t.tracksFeatIndxCG(end),KTTracksInliers);
KTEndsFrame=arrayfun(@(t) t.f(end),KTTracksInliers);
KTDetectionsEndIdx=arrayfun(@(f) KTEndsIdx(KTEndsFrame==f),1:length(KTDetectionsP1P2),'unif',0);
KTEndsP1P2=KTDetectionsP1P2.getSelectIdx(KTDetectionsEndIdx);

%% Create PKT manifolds and map detection to them
%[PKTROI]=build1DManifold([P1 P2],KTTracksInliers,[-40 1]);
[PKTROI]=build1DManifold([P1 P2],KTTracksInliers([KTTracksInliers.lifetime]>10));
disp('Mapping +Tips on PTK manifolds');tic;
PKTMapDist=15;
allKTMappedTips=cell(1,numel(PKTROI));
parfor mIdx=1:numel(PKTROI);
    [~,indices]=mapDetectionsTo1DManifold(PKTROI{mIdx},oDetections,PKTMapDist, ... 
                                                        'distType','normalDistPseudOptimized');
    allKTMappedTips{mIdx}=indices;
end
KTMappedTips=allKTMappedTips{1};
for mIdx=2:numel(PKTROI);
    KTMappedTips=cellfun(@(m,i) (m|i),KTMappedTips,allKTMappedTips{mIdx},'unif',0);
end
polarIndices=KTMappedTips;
astralIndices=cellfun(@(m) ~m,KTMappedTips,'unif',0);
toc;
process=ExternalProcess(MD,'Detection polar');

% detection debug visualization
% overlayProjDetectionMovie(processProjSpindleRef,'detections',oDetectionsP1P2.getSelectIdx(KTMappedTips),'process',process, ... 
%             'name','KTMappedTips');
% img=imread(sprintfPath(process.outFilePaths_{4},1));
% figure();imshow([img]);

disp('Compute densities in the spindle')
densities=estimateDensity(oDetections,20);
poleDistances=arrayfun(@(d,D) min(d.rho,D.rho),oDetectionsP1P2,oDetectionsP2P1,'unif',0);

%% Define astral and polar region in a naive way
astralThresh=-pi/6;
polarThresh=pi/6;

%% Count and density function of distance to poles
% astralDistBinning=linspace(30,60,30);
% polarDistBinning=linspace(30,50,30);
% astralDistBinning=linspace(5,50,40);
% polarDistBinning=linspace(5,50,40);
astralDistBinning=5:1:50;
polarDistBinning=5:1:50;

lpid=lpid+1;
if(GenericPackage.processExist(p.package,lpid))
    processEnrich=p.package.getProcess(lpid);
    load(processEnrich.outFilePaths_{2});
else

disp('Order and display stats in the spindle');tic;
if(~p.useKT)
  polarIndices=cellfun(@(p,e)  ((p<max(polarDistBinning))& ... 
                        (p>min(polarDistBinning))&(e>polarThresh)) ,poleDistances,elevations,'unif',0);
  astralIndices=cellfun(@(p,e)  ((p<max(astralDistBinning))& ... 
                        (p>min(astralDistBinning))&(e<astralThresh)) ,poleDistances,elevations,'unif',0);
end

allElevs=vertcat(elevations{:});
allDens=vertcat(densities{:});
scoresBin=-pi/2:0.05:pi/2;

%% Density vs Elevation stats
[counts,edges,binIdx]=histcounts(allElevs,scoresBin);
[means,meds,stds,orderedIndex,counts] = statPerIndx(allDens,binIdx+1);
% [H,~,F]=setupFigure(1,2,2);
% scatter(H(1),vertcat(elevations{:}),vertcat(densities{:}));
% axes(H(2));
% shadedErrorBar(scoresBin,means,stds,'r',1);       

[Handle,~,F]=setupFigure(1,1,1);
shadedErrorBar(scoresBin,means,stds,'r',1);       
xlabel('Elevation (rad)');
xlim(minmax(scoresBin));
ylim([0,8]);
ylabel('Comet density (1/\mu m^3)')
outputDirPlot=[MD.outputDirectory_ filesep 'enrichment' filesep 'plot' filesep];
mkdirRobust(outputDirPlot);
print([outputDirPlot  'ElevationDens.png'],'-dpng');
print([outputDirPlot  'ElevationDens.eps'],'-depsc');

%% total count and pole distance/elevation
amps=arrayfun(@(d) d.amp,oDetections,'unif',0); % just for data structure coherence

allDist=vertcat(poleDistances{:});
allAmp=vertcat(amps{:});
allAmp=allAmp(:,1);
timesSteps=arrayfun(@(d,t) p.startTime+MD.timeInterval_*(t-1)*ones(size(d.xCoord(:,1))),oDetections,1:length(oDetections),'unif',0);

polarDetectionsMask=logical([polarIndices{:}]);
astralDetectionsMask=~polarDetectionsMask;

[polarCounts,polarEdges,polarBinIdx]=histcounts(allDist(polarDetectionsMask),polarDistBinning);
[meanPolarDensities,medPolarDensities,stdPolarDensities]=statPerIndx(allDens(polarDetectionsMask),polarBinIdx);
[meanPolarAmp,medPolarAmp,stdPolarAmp,~,polarCount,sumPolarAmp]=statPerIndx(allAmp(polarDetectionsMask),polarBinIdx);
coneVolumes=2*pi*(1-cos(pi/2-polarThresh))*polarDistBinning.^3/3;
polarVolumes=(coneVolumes(2:end)-coneVolumes(1:(end-1)));
normalizedPolarAmp=sumPolarAmp./polarVolumes;
normalizedPolarCount=polarCounts./polarVolumes;

[astralCounts,astralEdges,astralBinIdx]=histcounts(allDist(astralDetectionsMask),astralDistBinning);
[meanAstralDensities,medAstralDensities,stdAstralDensities]=statPerIndx(allDens(astralDetectionsMask),astralBinIdx);
[meanAstralAmp,medAstralAmp,stdAstralAmp,~,astralCount,sumAstralAmp]=statPerIndx(allAmp(astralDetectionsMask),astralBinIdx);
coneVolumes=2*pi*(1-cos(pi/2+astralThresh))*astralDistBinning.^3/3;
astralVolumes=(coneVolumes(2:end)-coneVolumes(1:(end-1)));
normalizedAstralAmp=sumAstralAmp./astralVolumes;
normalizedAstralCount=astralCounts./astralVolumes;

%% Count function of distance to poles
[Handle,~,F]=setupFigure(1,2,2);
plot(Handle(1),astralEdges(1:end-1)*0.1,astralCounts);
plot(Handle(2),polarEdges(1:end-1)*0.1,polarCounts);
arrayfun(@(h) ylim(h,[0 max([astralCounts(:); polarCounts(:)])*1.05]),Handle);
arrayfun(@(h) xlim(h,[1,6.5]),Handle);
xlabel(Handle(1),'Pole distance (\mum)');
xlabel(Handle(2),'Pole distance (\mum)');
ylabel(Handle(1),'Astral Comet count')
ylabel(Handle(2),'Polar Comet count')
mkdirRobust(outputDirPlot);
print([outputDirPlot  'poleDist.png'],'-dpng');
print([outputDirPlot  'poleDist.eps'],'-depsc');

%% Density function of distance to poles
densityLimit=[0 max([meanAstralDensities(:); meanPolarDensities(:)])*1.05];

[Handle,~,F]=setupFigure(1,2,2);
plot(Handle(1),astralEdges(1:end-1)*0.1,meanAstralDensities);
plot(Handle(2),polarEdges(1:end-1)*0.1,meanPolarDensities);
arrayfun(@(h) xlim(h,[0,6.5]),Handle);
xlabel(Handle(1),'Pole distance (\mum)');
xlabel(Handle(2),'Pole distance (\mum)');
ylabel(Handle(1),'Astral Comet density (per volume)')
ylabel(Handle(2),'Polar Comet density (per volume)')
arrayfun(@(h) ylim(h,densityLimit),Handle);
mkdirRobust(outputDirPlot);
printPNGEPSFIG(F,outputDirPlot,'densityVsDist');

%% Amplitude function of distance to poles
[Handle,~,F]=setupFigure(1,2,2);
plot(Handle(1),astralEdges(1:end-1)*0.1,meanAstralAmp);
plot(Handle(2),polarEdges(1:end-1)*0.1,meanPolarAmp);
arrayfun(@(h) xlim(h,[0,6.5]),Handle);
xlabel(Handle(1),'Pole distance (\mum)');
xlabel(Handle(2),'Pole distance (\mum)');
ylabel(Handle(1),'Astral Comet Mean Intensity')
ylabel(Handle(2),'Polar Comet Mean Intensity')
arrayfun(@(h) ylim(h,[min([meanAstralAmp(:); meanPolarAmp(:)])*0.95 max([meanAstralAmp(:); meanPolarAmp(:)])*1.05]),Handle);
printPNGEPSFIG(F,outputDirPlot,'ampVsDist');

%% Normalized amplitude function of distance to poles
[Handle,~,F]=setupFigure(1,2,2);
plot(Handle(1),astralEdges(1:end-1)*0.1,normalizedAstralAmp);
plot(Handle(2),polarEdges(1:end-1)*0.1,normalizedPolarAmp);
arrayfun(@(h) xlim(h,[1,6.5]),Handle);
xlabel(Handle(1),'Pole distance (\mum)');
xlabel(Handle(2),'Pole distance (\mum)');
ylabel(Handle(1),'Astral Comet Intensity (Solid Angle Norm)')
ylabel(Handle(2),'Polar Comet Intensity (Solid Angle Norm)')
arrayfun(@(h) ylim(h,[min([normalizedPolarAmp(:); normalizedAstralAmp(:)])*0.95 max([normalizedPolarAmp(:); normalizedAstralAmp(:)])*1.05]),Handle);
printPNGEPSFIG(F,outputDirPlot,'normAmpVsDist');

%% Normalized count function of distance to poles
[Handle,~,F]=setupFigure(1,2,2);
plot(Handle(1),astralEdges(1:end-1)*0.1,normalizedAstralCount);
plot(Handle(2),polarEdges(1:end-1)*0.1,normalizedPolarCount);
arrayfun(@(h) xlim(h,[1,6.5]),Handle);
xlabel(Handle(1),'Pole distance (\mum)');
xlabel(Handle(2),'Pole distance (\mum)');
ylabel(Handle(1),'Astral Comet density (normCount)')
ylabel(Handle(2),'Polar Comet density (normCount)')
arrayfun(@(h) ylim(h,[0 max([normalizedPolarCount(:); normalizedAstralCount(:)])*1.05]),Handle);
printPNGEPSFIG(F,outputDirPlot,'normCountVsDist');

%% volumes function of distance to poles
[Handle,~,F]=setupFigure(1,2,2);
plot(Handle(1),astralEdges(1:end-1)*0.1,astralVolumes);
plot(Handle(2),polarEdges(1:end-1)*0.1,polarVolumes);
arrayfun(@(h) xlim(h,[1,6.5]),Handle);
xlabel(Handle(1),'Pole distance (\mum)');
xlabel(Handle(2),'Pole distance (\mum)');
ylabel(Handle(1),'Astral area')
ylabel(Handle(2),'Polar area')
arrayfun(@(h) ylim(h,[0 max([astralVolumes(:); polarVolumes(:)])*1.05]),Handle);
printPNGEPSFIG(F,outputDirPlot,'polarVolumes');

disp('Save final process');tic;
processEnrich=ExternalProcess(MD,'spindleEnrichment');
outputFileName=[MD.outputDirectory_ filesep 'enrichment' filesep 'elevation-density-poleDistance.mat'];
save(outputFileName,'elevations','azimuths','densities','timesSteps','poleDistances','amps', ... 
    'astralThresh','polarThresh','polarDistBinning','astralDistBinning','densityLimit', ...
    'KTelevations','KTpoleDistances','KTazimuths');
processEnrich.setOutFilePaths({[outputDirPlot  'ElevationDens.png'], ...
    outputFileName, ...
    [outputDirPlot  'poleDist.png'], ...
    [outputDirPlot  'densityVsDist.png'], ...
    [outputDirPlot  'ampVsDist.png'], ...
    [outputDirPlot  'normAmpVsDist.png'], ...
    [outputDirPlot  'normCountVsDist.png'], ...
    });
end
MD.getPackage(packPIDTMP).setProcess(lpid,processEnrich);


%% Rendering cumulative distribution for debugging and illustrative purposes
disp('Render Astral and Polar still');tic;
myColormap=255*jet(256);
lpid=lpid+1;
if(~GenericPackage.processExist(p.package,lpid))
    process=ExternalProcess(MD,'Detection astral');
    astralDetections=oDetections.copy().selectIdx(astralIndices);
    astralDensitiesIndx=cellfun(@(e,i) floor(254*mat2gray(e(i),densityLimit))+1 , densities,astralIndices,'unif',0);
    overlayProjDetectionMovie(processProjSpindleRef,'detections',refs(1,2).applyBase(astralDetections,''), 'process',process, ... 
        'cumulative',true,'processFrames',1, ... 
        'colorIndx',astralDensitiesIndx,'colormap',myColormap,'name','astralCumulPoleDensity');
else
    process=p.package.getProcess(lpid);
end
MD.getPackage(packPIDTMP).setProcess(lpid,process);
imgAstral=imread(sprintfPath(process.outFilePaths_{4},1));

lpid=lpid+1;
if(~GenericPackage.processExist(p.package,lpid))
    process=ExternalProcess(MD,'Detection polar');
    polarDetections=oDetections.copy().selectIdx(polarIndices);
    polarDensitiesIndx=cellfun(@(e,i) floor(254*mat2gray(e(i),densityLimit))+1 , densities,polarIndices,'unif',0);
    overlayProjDetectionMovie(processProjSpindleRef,'detections',refs(1,2).applyBase(polarDetections,''), 'process',process, ... 
        'cumulative',true,'processFrames',1, ...
        'colorIndx',polarDensitiesIndx,'colormap',myColormap,'name','polarCumulPoleDensity');
    % overlayProjDetectionMovie(process,'detections',KTEndsP1P2, 'process',process, ... 
    %     'cumulative',true,'processFrames',1 ...
    %     ,'name','polarCumulPoleDensityKT');
else
    process=p.package.getProcess(lpid);
end
MD.getPackage(packPIDTMP).setProcess(lpid,process);
imgPolar=imread(sprintfPath(process.outFilePaths_{4},1));

figure();
imshow([imgAstral imgPolar]);

if(~isempty(p.dynROIProject))
    processProjSpindleRef=p.dynROIProject;
end

disp('Render Astral and Polar detections');tic;
lpid=lpid+1;
if(~GenericPackage.processExist(p.package,lpid))
    process=ExternalProcess(MD,'Detection astral');
    astralDetections=oDetections.copy().selectIdx(astralIndices);
    %polarDistancesIndx=cellfun(@(e,i)  floor(254*mat2gray(e(i)))+1, poleDistances,polarIndx,'unif',0);
    astralDensitiesIndx=cellfun(@(e,i) floor(254*mat2gray(e(i),densityLimit))+1 , densities,astralIndices,'unif',0);
    overlayProjDetectionMovie(processProjSpindleRef,'detections',refs(1,2).applyBase(astralDetections,''), 'process',process, ... 
        'cumulative',false, ... 
        'colorIndx',astralDensitiesIndx,'colormap',myColormap,'name',['astralPoleDensity-' p.name]);
else
    process=p.package.getProcess(lpid);
end
MD.getPackage(packPIDTMP).setProcess(lpid,process);
imgAstral=imread(sprintfPath(process.outFilePaths_{2},1));

%%
poleDistLimit=[19.999 20];
lpid=lpid+1;
if(~GenericPackage.processExist(p.package,lpid))
    process=ExternalProcess(MD,'Detection polar');
    polarDetections=oDetections.copy().selectIdx(polarIndices);
    polarDensitiesIndx=cellfun(@(e,i) floor(254*mat2gray(e(i),densityLimit))+1 , densities,polarIndices,'unif',0);
    polarDistanceIndx=cellfun(@(e,i) floor(254*mat2gray(e(i),poleDistLimit))+1 , poleDistances,polarIndices,'unif',0);
    overlayProjDetectionMovie(processProjSpindleRef,'detections',refs(1,2).applyBase(polarDetections,''), 'process',process, ... 
        'cumulative',false, ...
        'colorIndx',polarDistanceIndx,'colormap',myColormap,'name',['polarPoleDensity-' p.name]);
else
    process=p.package.getProcess(lpid);
end
MD.getPackage(packPIDTMP).setProcess(lpid,process);
toc;
%% debug display
imgPolar=imread(sprintfPath(process.outFilePaths_{2},1));
figure();
imshow([imgAstral imgPolar]);

disp('Render KT detections (TrackKT is broken ...)');tic;
lpid=lpid+1;
if(~GenericPackage.processExist(p.package,lpid))
    process=ExternalProcess(MD,'KTDetection');
    overlayProjDetectionMovie(processProjSpindleRef,'detections',KTDetectionsP1P2, 'process',process, ... 
        'cumulative',false,'name',['KTDetection-' p.name]);
else
    process=p.package.getProcess(lpid);
end
MD.getPackage(packPIDTMP).setProcess(lpid,process);



MD.setPackage(packPID,MD.getPackage(packPIDTMP));
%MD.setPackage(packPIDTMP,[]);

function [means,meds,stds,orderedIndex,counts,sums] = statPerIndx(values,index)
means=zeros(1,max(index));
meds=zeros(1,max(index));
stds=zeros(1,max(index));
counts=zeros(1,max(index));
sums=zeros(1,max(index));

orderedIndex=1:max(index);
for t=unique(index)'
    if(t>0)
    biasAtTime=(values(index==t));
    means(t)=mean(biasAtTime);
    meds(t)=median(biasAtTime);
    stds(t)=std(biasAtTime);
    counts(t)=sum(index==t);
    sums(t)=sum(biasAtTime);
    end
end