function MTBundling(MD,varargin)
ip = inputParser;
ip.CaseSensitive = false;
ip.KeepUnmatched = true;
ip.addRequired('MD',@(MD) isa(MD,'MovieData'));
ip.addOptional('kinTracksWithSpindle',[]);
ip.addOptional('EB3TracksWithSpindle',[]);
ip.addOptional('randKinTracksWithSpindle',[]);
ip.addOptional('processSpindleRef',[]);
ip.addParameter('printAll',false, @islogical);
ip.addOptional('processRandKin',[]);
ip.addParameter('kinRange',[],@isnumeric);
%ip.addParameter('kinRange',[19 46 156],@isnumeric);
ip.addParameter('cutoffs',250, @isnumeric);
ip.addParameter('plotHandle',[]);
ip.addParameter('process',[]);
ip.addParameter('name',[]);
ip.parse(MD,varargin{:});
p=ip.Results;

cutoff=p.cutoffs;
kinRange=p.kinRange;
printAll=p.printAll;

%%
%% Loading kin and EB3
if(~isempty(p.processSpindleRef)&&isempty(p.kinTracksWithSpindle))
    disp('reading process');tic;
    poleRefProcess=p.processSpindleRef;% MD.getProcess(find(poleRefProcessIdx,1,'last'));
    EB3Tracks=load(poleRefProcess.outFilePaths_{1}); EB3Tracks=EB3Tracks.EB3Tracks;
    kinTracks=load(poleRefProcess.outFilePaths_{2}); kinTracks=kinTracks.kinTracks;
    EB3TracksInliers=load(poleRefProcess.outFilePaths_{3}); EB3TracksInliers=EB3TracksInliers.EB3TracksInliers;
    kinTracksInliers=load(poleRefProcess.outFilePaths_{4}); kinTracksInliers=kinTracksInliers.kinTracksInliers;
    toc
else
    EB3Tracks=p.EB3TracksWithSpindle;
    kinTracks=p.kinTracksWithSpindle;
    inliersEB3=(logical(arrayfun(@(eb) eb.inliers(1),EB3Tracks)));
    EB3TracksInliers=EB3Tracks(inliersEB3);
    inliersKin=logical(arrayfun(@(k) k.inliers(1),kinTracks));
    kinTracksInliers=kinTracks(inliersKin);
end

%% Loading rand kin
if(isempty(kinRange))
    kinRange=1:length(kinTracksInliers);
end


%% Functionalize and processize
if(~isempty(p.processRandKin)&&isempty(p.randKinTracksWithSpindle))
    tmp=load(p.processRandKin.outFilePaths_{1});
    randKinTracks=tmp.randKinTracks;
else
    randKinTracks=p.randKinTracksWithSpindle;
end
%%

%% Functionalize and processize
% randKinProcIdx=cellfun(@(p) strcmp(p.name_,'randKin'),MD.processes_);
% if(any(randKinProcIdx)&&isempty(p.randKinTracksWithSpindle))
%     randKinProc=MD.getProcess(find(randKinProcIdx,1,'last'));
%     tmp=load(randKinProc.outFilePaths_{1});
%     randKinTracks=tmp.randKinTracks;
%     inliersKin=logical(arrayfun(@(k) k.inliers(1),kinTracks));
%     randKinTracksInliers=randKinTracks(inliersKin);
% else
%     randKinTracks=p.randKinTracksWithSpindle;
%     inliersKin=logical(arrayfun(@(k) k.inliers(1),kinTracks));
%     randKinTracksInliers=randKinTracks(inliersKin);
% edn

%%  Plot randomize
if(p.printAll)
    amiraWriteTracks([MD.outputDirectory_ filesep 'Kin' filesep 'randomizedAugmented' filesep 'random.am'], randKinTracksInliers)
end

%%
outputDirBundle=[MD.outputDirectory_ filesep 'Kin' filesep 'bundles'];

%% Estimate bundle in KinPole axis
captureDetection(MD,'kinTracks',kinTracksInliers(kinRange),'EB3tracks',EB3TracksInliers,'name','inliers');
%Inlier=detectMTAlignment(MD,'kinCapture',kinTracksInliers(kinRange),'testKinIdx',[],'name','inliers','printAll',false);
%%
Inlier=detectMTAlignment(MD,'kinCapture',kinTracksInliers(kinRange),'testKinIdx',[],'bundlierPole',false,'name','inliers','printAll',false);

%% For each kinetochore, plot an Amira file with attached mt
if(p.printAll)
outputDirAmira=[outputDirBundle filesep 'Amira_normal' filesep];
parfor kIdx=1:length(Inlier)
    kinTrack=Inlier(kIdx);
    trackSet=[kinTrack; kinTrack.catchingMT];
    trackType=[1; zeros(length(kinTrack.catchingMT),1)];
    bundleInfo=[0 kinTrack.fiber];
    bundlingMTKinInfo=[2 (kinTrack.fiber>0)];
    amiraWriteTracks([outputDirAmira filesep 'kin_' num2str(kIdx) '.am'],trackSet,'cumulativeOnly',true,'edgeProp',{{'kinEB3',trackType},{'bundleSize',bundleInfo},{'bundlingMTKin',bundlingMTKinInfo}})
end
end

%%
if(~isempty(randKinTracks))
    
    inliersKin=logical(arrayfun(@(k) k.inliers(1),kinTracks));
    randKinTracksInliers=randKinTracks(inliersKin);
    
    captureDetection(MD,'kinTracks',randKinTracksInliers(kinRange),'EB3tracks',EB3TracksInliers,'name','inliersRandom');
    %RandomInlier=detectMTAlignment(MD,'kinCapture',randKinTracksInliers(kinRange),'testKinIdx',[],'name','inliersRandom','printAll',false);
    RandomInlier=detectMTAlignment(MD,'kinCapture',randKinTracksInliers(kinRange),'testKinIdx',[],'bundlierPole',false,'name','inliersRandom','printAll',false);

  %% For each kinetochore, plot an Amira file with attached mt
  if(p.printAll)
  outputDirAmira=[outputDirBundle filesep 'Amira_random' filesep];
  parfor kIdx=1:length(RandomInlier)
    kinTrack=RandomInlier(kIdx);
    trackSet=[kinTrack; kinTrack.catchingMT];
    trackType=[1; zeros(length(kinTrack.catchingMT),1)];
    bundleInfo=[0 kinTrack.fiber+1];
    amiraWriteTracks([outputDirAmira filesep 'ki/n_' num2str(kIdx) '.am'],trackSet,'cumulativeOnly',true,'edgeProp',{{'kinEB3',trackType},{'bundle',bundleInfo}})
  end
  end
  bundleStatistics(MD,'kinBundle',{Inlier,RandomInlier},'kinBundleName',{'Inlier','RandomInlier'},'plotName',p.name);
end
