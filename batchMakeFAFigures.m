function batchMakeFAFigures(rootDirectory, forceRun, batchMode)

nSteps = 8;

if nargin < 1 || isempty(rootDirectory)
    dataDirectory = uigetdir('', 'Select a data directory:');

    if ~ischar(dataDirectory)
        return;
    end
end

if nargin < 2 || isempty(forceRun)        
    forceRun = zeros(nSteps, 1);
end

if length(forceRun) ~= nSteps
    error('Invalid number of steps in forceRun (2nd argument).');
end

if nargin < 3 || isempty(batchMode)
        batchMode = 1;
end

% Get every path from rootDirectory containing ch488 & ch560 subfolders.
paths = getDirectories(rootDirectory, 2, {'ch488', 'ch560'});

disp('List of directories:');

for iMovie = 1:numel(paths)
    disp([num2str(iMovie) ': ' paths{iMovie}]);
end

disp('Process all directories (Grab a coffee)...');

nMovies = numel(paths);

movieData = cell(nMovies, 1);

for iMovie = 1:nMovies
    movieName = ['Movie ' num2str(iMovie) '/' num2str(numel(paths))];
    
    path = paths{iMovie};
   
    currMovie = movieData{iMovie};
    
    % STEP 1: SETUP MOVIE DATA

    try
        fieldNames = {...
            'bgDirectory',...
            'roiDirectory',...
            'tifDirectory',...
            'stkDirectory',...
            'analysisDirectory'};
        
        subDirNames = {'bg', 'roi', 'tif', 'stk', 'analysis'};
        
        channels = cell(numel(fieldNames), 1, 2);
        channels(:, 1, 1) = cellfun(@(x) [path filesep 'ch488' filesep x],...
            subDirNames, 'UniformOutput', false);
        channels(:, 1, 2) = cellfun(@(x) [path filesep 'ch560' filesep x],...
            subDirNames, 'UniformOutput', false);
        currMovie.channels = cell2struct(channels, fieldNames, 1);
        
        % We put every subsequent analysis in the ch488 analysis directory.
        currMovie.analysisDirectory = currMovie.channels(1).analysisDirectory;
        
        % Add these 2 fields to be compliant with Hunter's check routines:
        currMovie.imageDirectory = currMovie.channels(1).roiDirectory;
        currMovie.channelDirectory = {''};
        
        % STEP 1.1: Get the number of images
        
        n1 = numel(dir([currMovie.channels(1).roiDirectory filesep '*.tif']));
        n2 = numel(dir([currMovie.channels(2).roiDirectory filesep '*.tif']));
        
        % In case one of the channel hasn't been set, we still might want
        % to compute some process.
        currMovie.nImages = max(n1,n2);
        
        assert(currMovie.nImages ~= 0);

        % STEP 1.2: Load physical parameter from
        filename = [currMovie.channels(2).analysisDirectory filesep 'fsmPhysiParam.mat'];
        if exist(filename, 'file')
            load(filename);
            currMovie.pixelSize_nm = fsmPhysiParam.pixelSize;
            currMovie.timeInterval_s = fsmPhysiParam.frameInterval;
            clear fsmPhysiParam;
        else
            % It can happens when qFSM hasn't been run yet.
            currMovie.pixelSize_nm = 67;
            currMovie.timeInteral_s = 10;
        end
        
        % STEP 1.3: Get the mask directory
        currMovie.masks.channelDirectory = {''};
        currMovie.masks.directory = [currMovie.channels(2).analysisDirectory...
            filesep 'edge' filesep 'cell_mask'];
        if exist(currMovie.masks.directory, 'dir')
            currMovie.masks.n = numel(dir([currMovie.masks.directory filesep '*.tif']));
            currMovie.masks.status = 1;
        else
            currMovie.masks.status = 0;
        end
        
        % STEP 1.4: Update from already saved movieData
        filename = [currMovie.analysisDirectory filesep 'movieData.mat'];
        if exist(filename, 'file') && ~forceRun(1)
            currMovie = load(filename);
            currMovie = currMovie.movieData;
        end
         
    catch errMess
        disp([movieName ': ' errMess.stack(1).name ':' num2str(errMess.stack(1).line) ' : ' errMess.message]);
        disp(['Error in movie ' num2str(iMovie) ': ' errMess.message '(SKIPPING)']);
        continue;
    end
    
%     % STEP 2: CONTOUR
%     
%     dContour = 1000 / currMovie.pixelSize_nm; % ~ 1um
%     
%     if ~checkMovieContours(currMovie) || forceRun(2)
%         try
%             disp(['Get contours of movie ' num2str(iMovie) ' of ' num2str(nMovies) '...']);
%             currMovie = getMovieContours(currMovie, 0:dContour:500, 0, 1, ...
%                 ['contours_'  num2str(dContour) 'pix.mat'], batchMode);
%             
%             if isfield(currMovie.contours, 'error')
%                 currMovie.contours = rmfield(currMovie.contours,'error');
%             end            
%         catch errMess
%             disp([movieName ': ' errMess.stack(1).name ':' num2str(errMess.stack(1).line) ' : ' errMess.message]);
%             currMovie.contours.error = errMess;
%             currMovie.contours.status = 0;
%         end
%     end
% 
%     % STEP 3: PROTRUSION
% 
%     if ~isfield(currMovie,'protrusion') || ~isfield(currMovie.protrusion,'status') || ...
%             currMovie.protrusion.status ~= 1 || forceRun(3)
%         try
%             currMovie.protrusion.status = 0;
% 
%             currMovie = setupMovieData(currMovie);
% 
%             handles.batch_processing = batchMode;
%             handles.directory_name = [currMovie.masks.directory];
%             handles.result_directory_name = [currMovie.masks.directory];
%             handles.FileType = '*.tif';
%             handles.timevalue = currMovie.timeInterval_s;
%             handles.resolutionvalue = currMovie.pixelSize_nm;
%             handles.segvalue = 30;
%             handles.dl_rate = 30;
% 
%             %run it
%             [OK,handles] = protrusionAnalysis(handles);
% 
%             if ~OK
%                 currMovie.protrusion.status = 0;
%             else
%                 if isfield(currMovie.protrusion,'error')
%                     currMovie.protrusion = rmfield(currMovie.protrusion,'error');
%                 end
%                 
%                 %currMovie.protrusion.directory = [currMovie.masks.directory];
%                 % Workaround:
%                 currMovie.protrusion.directory = [currMovie.masks.directory filesep ...
%                     'analysis_dl' num2str(handles.dl_rate)];
%                 
%                 currMovie.protrusion.fileName = 'protrusion.mat';
%                 currMovie.protrusion.nfileName = 'normal_matrix.mat';
%                 currMovie.protrusion.status = 1;
%             end
%             
%             updateMovieData(currMovie);
% 
%             if isfield(currMovie.protrusion, 'error')
%                 currMovie.protrusion = rmfield(currMovie.protrusion,'error');
%             end            
%             
%         catch errMess
%             disp([movieName ': ' errMess.stack(1).name ':' num2str(errMess.stack(1).line) ' : ' errMess.message]);
%             currMovie.protrusion.error = errMess;
%             currMovie.protrusion.status = 0;
%         end
%     end
% 
%     % STEP 4: WINDOWING
%     
%     dWin = 2000 / currMovie.pixelSize_nm; % ~ 2um
%     iStart = 2;
%     iEnd = 5;
%     winMethod = 'c';
% 
%     windowString = [num2str(dContour) 'by' num2str(dWin) 'pix_' num2str(iStart) '_' num2str(iEnd)];
% 
%     if ~checkMovieWindows(currMovie) || forceRun(4)
%         try
%             currMovie = setupMovieData(currMovie);
% 
%             disp(['Get windows of movie ' num2str(iMovie) ' of ' num2str(nMovies) '...']);
%             currMovie = getMovieWindows(currMovie,winMethod,dWin,[],iStart,iEnd,[],[],...
%                 ['windows_' winMethod '_' windowString '.mat'], batchMode);
%             
%             if isfield(currMovie.windows,'error')
%                 currMovie.windows = rmfield(currMovie.windows,'error');
%             end
% 
%         catch errMess
%             disp([movieName ': ' errMess.stack(1).name ':' num2str(errMess.stack(1).line) ' : ' errMess.message]);
%             currMovie.windows.error = errMess;
%             currMovie.windows.status = 0;
%         end
%     end
%     
%     % STEP 5: SAMPLE PROTRUSION
% 
%     if ~checkMovieProtrusionSamples(currMovie) || forceRun(5)
%         try
%             disp(['Get sampled protrusion of movie ' num2str(iMovie) ' of ' num2str(nMovies) '...']);
%             currMovie = getMovieProtrusionSamples(currMovie,['protSamples_' ...
%                 winMethod '_' windowString  '.mat'], batchMode);
%             
%             if isfield(currMovie.protrusion.samples,'error')
%                currMovie.protrusion.samples = rmfield(currMovie.protrusion.samples,'error');
%            end
%             
%         catch errMess
%             disp([movieName ': ' errMess.stack(1).name ':' num2str(errMess.stack(1).line) ' : ' errMess.message]);           
%             currMovie.protrusion.samples.error = errMess;
%             currMovie.protrusion.samples.status = 0;
%         end
%         
%     end 
%     
%     % STEP 6: WINDOW LABELING
% 
%     if ~checkMovieLabels(currMovie) || forceRun(6)
%         try
%             currMovie = setupMovieData(currMovie);
% 
%             disp(['Get labels of movie ' num2str(iMovie) ' of ' num2str(nMovies) '...']);
%             
%             currMovie = getMovieLabels(currMovie, [], batchMode);
% 
%             if isfield(currMovie.labels,'error')
%                 currMovie.labels = rmfield(currMovie.labels,'error');
%             end
% 
%         catch errMess
%            disp([movieName ': ' errMess.stack(1).name ':' num2str(errMess.stack(1).line) ' : ' errMess.message]);
%            currMovie.labels.error = errMess;
%            currMovie.labels.status = 0;
%         end
%     end
%
%     % STEP 7: FA DETECTION
%     
%     if ~checkMovieDetection(currMovie) || forceRun(7)
%         try
%             currMovie = setupMovieData(currMovie);
%             
%             disp(['Detect FA of movie ' num2str(iMovie) ' of ' num2str(nMovies) '...']);
%             
%             currMovie = getMovieDetection(currMovie, batchMode);
%             
%             if isfield(currMovie.detection, 'error')
%                 currMovie.detection = rmfield(currMovie.detection, 'error');
%             end
%             
%         catch errMess
%             disp([movieName ': ' errMess.stack(1).name ':' num2str(errMess.stack(1).line) ' : ' errMess.message]);
%             currMovie.detection.error = errMess;
%             currMovie.detection.status = 0;
%         end
%     end 
%  
%     % STEP 8: FA TRACKING
%     
%     if ~checkMovieTracking(currMovie) || forceRun(8)
%         try
%             currMovie = setupMovieData(currMovie);
%             
%             disp(['Track FA of movie ' num2str(iMovie) ' of ' num2str(nMovies) '...']);
%             
%             currMovie = getMovieTracking(currMovie, batchMode);
%             
%             if isfield(currMovie.tracking, 'error')
%                 currMovie.tracking = rmfield(currMovie.tracking, 'error');
%             end
%             
%         catch errMess
%             disp([movieName ': ' errMess.stack(1).name ':' num2str(errMess.stack(1).line) ' : ' errMess.message]);
%             currMovie.tracking.error = errMess;
%             currMovie.tracking.status = 0;
%         end
%     end
    
    % Save results
    try
        %Save the updated movie data
        updateMovieData(currMovie)
    catch errMess
        errordlg(['Problem saving movie data in movie ' num2str(iMov) ': ' errMess.message], mfileName());
    end
    
    movieData{iMovie} = currMovie;

    disp([movieName ': DONE']);
end

%
% Create output directory for figures
%

outputDirectory = fullfile(rootDirectory,'figures');
if ~exist(outputDirectory, 'dir')
    mkdir(rootDirectory, 'figures');
end

% prefix the rootDirectory
selectedPaths = paths(9:-1:8);

% suffix ch488/analysis
selectedPaths = cellfun(@(subDir) fullfile(subDir,'ch488','analysis'),...
    selectedPaths, 'UniformOutput', false);

%
% Make Figure 1
%
%disp('Make figure 1...');
%makeFAFigure1(selectedPaths, outputDirectory);

%
% Make Figure 2
%
%disp('Make figure 2...');
%makeFAFigure2(selectedPaths, outputDirectory);

%
% Make Figure 3
%
disp('Make figure 3...');
makeFAFigure3(selectedPaths, outputDirectory);


