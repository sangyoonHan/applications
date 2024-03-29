function runBatchProcessTropoMovies

dataDirectory = '/home/sb234/Projects/Tropo/Data_for_paper';
%dataDirectory = '/Volumes/Time Machine Backups/HMS/Projects/Tropo/Data_for_paper';

analysisDirectory = '/home/sb234/Projects/Tropo/Analysis_for_paper';
%analysisDirectory = '/Volumes/Time Machine Backups/HMS/Projects/Tropo/Analysis_for_paper';

params.pixelSize = 67;
params.timeInterval = 10;
params.runSteps = [-1 -1 -1 -1 -1 -1 -1];
params.batchMode = 1;

% PROC 1: contours
dContour = 1000 / params.pixelSize; % 1 um
params.contours.distVals = 0:dContour:500;
params.contours.forceClose = 0;
params.contours.maskChannels = 1;
params.contours.contourName = ['contours_'  num2str(dContour) 'pix.mat'];

% PROC 2: protrusion
params.protrusion.maskChannel = 1;
params.protrusion.downSample = 20;
params.protrusion.nSeg = 30;

% PROC 3: windows
params.windows.methodStr = 'p';
params.windows.winSize = 1000 / params.pixelSize; % ~1um;
params.windows.nBands = [];
params.windows.iOuter = 2;
params.windows.iInner = 4;
params.windows.nReinit = [];
params.windows.meshQuality = [];
params.windows.windowName = ['windows_' params.windows.methodStr '_' ...
    num2str(dContour) 'by' num2str(params.windows.winSize) 'pix_' ...
    num2str(params.windows.iOuter) '_' num2str(params.windows.iInner) '.mat'];

% PROC 4: protrusion sampling
params.protrusion.samples.protName = ['protSamples_' params.windows.methodStr '_' params.windows.windowName  '.mat'];

% PROC 5: labels
params.labels.method = 'sector';

% PROC 6: distance transform
params.bwdist = struct([]); % no parameter

% PROC 7: density map
params.density = struct([]); % no parameter

batchProcessTropoMovies(dataDirectory,analysisDirectory,params);