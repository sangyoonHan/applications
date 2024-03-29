function movieData = getMovieSegmentTracking(movieData,batchMode)

%Indicate that tracking was started
movieData.segmentTracking.status = 0;

%Check that detection has been performed
assert(checkMovieSegmentDetection(movieData));

movieData.segmentTracking.directory = [movieData.analysisDirectory filesep 'segmentTracking'];
movieData.segmentTracking.filename = 'tracks.mat';

if ~exist(movieData.segmentTracking.directory, 'dir')
    mkdir(movieData.segmentTracking.directory);
end

% Load detection
filename = [movieData.segmentDetection.directory filesep movieData.segmentDetection.filename];
load(filename);
nFrames = numel(segmentParams); %#ok<USENS>

%
% TODO: this should go in the runBatchProcess*.m
%

% Create movieInfo structure

movieInfo(1:nFrames) = struct(...
    'xCoord',[], ...
    'yCoord',[],...
    'amp',[],...
    'length',[],...
    'angle',[]);

for iFrame = 1:nFrames
    clusters = segmentParams{iFrame};
    segments = vertcat(clusters(:).segments);
    
    xC = segments(:,1);
    yC = segments(:,2);
    A = segments(:,3);
    l = segments(:,5);
    t = segments(:,6);

    Z = zeros(size(xC));
    movieInfo(iFrame).xCoord = [xC Z];
    movieInfo(iFrame).yCoord = [yC Z];
    movieInfo(iFrame).amp = [A Z];
    movieInfo(iFrame).length= [l Z];
    movieInfo(iFrame).angle = [t Z];
end

% Create gapCloseParam structure

% maximum allowed time gap (in frames) between a track segment end and a
% track segment start that allows linking them.
% (TMP) disable the gap closing by setting timeWindow = 1 (default = 7)
gapCloseParam.timeWindow = 1;
% 1 if merging and splitting are to be considered, 2 if only merging is to
% be considered, 3 if only splitting is to be considered, 0 if no merging
% or splitting are to be considered.
% (TMP) disable split and merge
gapCloseParam.mergeSplit = 0;
% minimum length of track segments from linking to be used in gap closing.
gapCloseParam.minTrackLen = 1;
% 1 to plot a histogram of gap lengths in the end; 0 or empty otherwise.
gapCloseParam.diagnostics = 1; 

% Create costMatrices structure

% cost matrix function name
costMatrices(1).funcName = 'costMatLinearMotionLink2_XYLT';
% use linear motion Kalman filter.
costMatrices(1).parameters.linearMotion = 1;
% minimum allowed search radius. The search radius is calculated on the spot
% in the code given a feature's motion parameters. If it happens to be
% smaller than this minimum, it will be increased to the minimum.
costMatrices(1).parameters.minSearchRadius = 2;
% maximum allowed search radius. Again, if a feature's calculated search
% radius is larger than this maximum, it will be reduced to this maximum.
costMatrices(1).parameters.maxSearchRadius = 5;
% multiplication factor to calculate search radius from standard deviation.
costMatrices(1).parameters.brownStdMult = 3;
% Maximum ratio between the length of two features in two consecutive time
% points that  allows linking them.
costMatrices(1).parameters.maxLengthRatio = 4;
% Maximum ratio between the angle of two features in two consecutive time
% points that  allows linking them.
costMatrices(1).parameters.maxAnglePenalty = 2; % i.e. tan(pi/4) + 1
% 1 if you want to expand the search radius of isolated features in the
% linking (initial tracking) step.
costMatrices(1).parameters.useLocalDensity = 1;
% number of frames before the current one where you want to look to see a
% feature's nearest neighbor in order to decide how isolated it is (in the
% initial linking step).
costMatrices(1).parameters.nnWindow = gapCloseParam.timeWindow;
%Kalman filter initialization parameters.
costMatrices(1).parameters.kalmanInitParam = [];
% if you want to plot the histogram of linking distances up to certain
% frames, indicate their numbers; 0 or empty otherwise. Does not work for
% the first or last frame of a movie.
costMatrices(1).parameters.diagnostics = [];

%function name
costMatrices(2).funcName = 'costMatLinearMotionCloseGaps2';
% use linear motion Kalman filter.
costMatrices(2).parameters.linearMotion = 0;
% minimum allowed search radius. The search radius is calculated on the spot
% in the code given a feature's motion parameters. If it happens to be
% smaller than this minimum, it will be increased to the minimum.
costMatrices(2).parameters.minSearchRadius = 2;
% maximum allowed search radius. Again, if a feature's calculated search
% radius is larger than this maximum, it will be reduced to this maximum.
costMatrices(2).parameters.maxSearchRadius = 5;
% multiplication factor to calculate search radius from standard deviation.
costMatrices(2).parameters.brownStdMult = 3 * ones(gapCloseParam.timeWindow, 1);
% in the code, the search radius expands with the time gap (since a
% particle is expected to move further away in a longer gap than in a
% shorter one). This parameter controls how fast the search radius grows
% with time. timeReachConfB stands for time to reach confinement for the
% Brownian part of the motion. So before timeReachConfB, the search radius
% grows with the square root of time, after that it grows very, very slowly
% (it's almost fixed). %in the code, the search radius expands with the
% time gap (since a particle is expected to move further away in a longer
% gap than in a shorter one). This parameter controls how fast the search
% radius grows with time. timeReachConfB stands for time to reach
% confinement for the Brownian part of the motion. So before
% timeReachConfB, the search radius grows with the square root of time,
% after that it grows very, very slowly (it's almost fixed).
costMatrices(2).parameters.timeReachConfB = gapCloseParam.timeWindow;
% for merging and splitting. Minimum and maximum ratios between the
% intensity of a feature after merging/before splitting and the sum of the
% intensities of the 2 features that merge/split.
costMatrices(2).parameters.ampRatioLimit = [0 Inf]; 
% minimum track segment length to classify it as linear or random.
costMatrices(2).parameters.lenForClassify = 5;
% 1 if you want to expand the search radius of isolated features in the gap
% closing and merging/splitting step.
costMatrices(2).parameters.useLocalDensity = 1;
% number of frames before/after the current one where you want to look for
% a track's nearest neighbor at its end/start (in the gap closing step).
costMatrices(2).parameters.nnWindow = gapCloseParam.timeWindow;
% multiplication factor to calculate linear search radius from standard
% deviation.
costMatrices(2).parameters.linStdMult = 3*ones(gapCloseParam.timeWindow,1);
% same as timeReachConfB, but for the linear part of the motion.
costMatrices(2).parameters.timeReachConfL = gapCloseParam.timeWindow;
% maximum angle between the directions of motion of two tracks that allows
% linking them (and thus closing a gap). Think of it as the equivalent of a
%searchRadius but for angles.
costMatrices(2).parameters.maxAngleVV = 45;
% optional; if not input, 1 will be used (i.e. no penalty)
% penalty for increasing temporary disappearance time (disappearing for n
%f rames gets a penalty of gapPenalty^n).
costMatrices(2).parameters.gapPenalty = 1.1;
%optional; to calculate MS search radius
%if not input, MS search radius will be the same as gap closing search
%radius. Resolution limit, which is generally equal to 3 * point spread
%function sigma.
costMatrices(2).parameters.resLimit = 1.5;

% Create kalmanFunctions structure

kalmanFunctions.reserveMem  = 'kalmanResMemLM';
kalmanFunctions.initialize  = 'kalmanInitLinearMotion';
kalmanFunctions.calcGain    = 'kalmanGainLinearMotion';
kalmanFunctions.timeReverse = 'kalmanReverseLinearMotion';

% Create saveResutls structure

saveResults.dir = movieData.segmentTracking.directory;
saveResults.filename = movieData.segmentTracking.filename;

% We set probDim to 3 since each feature are defined by 3  
probDim = 2;
verbose = ~batchMode;

% Run the tracking
[tracks,kalmanInfoLink,errFlag] = trackCloseGapsKalmanSparse(movieInfo,...
    costMatrices,gapCloseParam,kalmanFunctions,probDim,saveResults,verbose);

movieData.segmentTracking.dateTime = datestr(now);
movieData.segmentTracking.status = 1;

updateMovieData(movieData);
