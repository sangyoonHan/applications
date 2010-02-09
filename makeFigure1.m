function makeFigure1(paths, batchMode)

if batchMode
    hFig = figure('Visible', 'off');
else
    hFig = figure('Visible', 'on');
end

for iCol = 1:3
    fileName = [paths{iCol} filesep 'windowAnalysis' filesep 'movieData.mat'];
    if ~exist(fileName, 'file')
        error(['Unable to locate ' fileName]);
    end
    load(fileName);

    %Verify that the labeling has been performed
    if ~checkMovieLabels(movieData)
        error('Must label movie before computing figure 1.');
    end

    names = cellfun(@fliplr, strtok(cellfun(@fliplr,movieData.fsmDirectory, ...
        'UniformOutput', false), filesep), 'UniformOutput', false);

    nFrames = movieData.labels.nFrames;
    pixelSize = movieData.pixelSize_nm;

    labelPath = movieData.labels.directory;
    labelFiles = dir([labelPath filesep '*.tif']);

    s1Path = [movieData.fsmDirectory{1} filesep 'tack' filesep 'cands'];
    s1Files = dir([s1Path filesep '*.mat']);

    s2Path = [movieData.fsmDirectory{2} filesep 'tack' filesep 'cands'];
    s2Files = dir([s2Path filesep '*.mat']);

    maskPath = movieData.masks.directory;
    maskFiles = dir([maskPath filesep '*.tif']);

    nPanelA = 100;
    dataPanelA = zeros(2, nFrames-1);
    dataPanelB = cell(1, nFrames-1);
    dataPanelCprot = cell(1, nFrames-1);
    dataPanelCret = cell(1, nFrames-1);
    
    if ~batchMode
        h = waitbar(0, ['Making column ' num2str(iCol) ' in figure 1...']);
    end
    
    % load protrusion sample
    fileName = [movieData.protrusion.directory filesep ...
        movieData.protrusion.samples.fileName];
    if ~exist(fileName, 'file')
        error(['Unable to locate ' fileName]);
    end
    load(fileName);
    % We do not consider the first 1% of the protrusion values (too small
    % to be significant)
    protMagnitude = protrusionSamples.averageMagnitude;
    protSign = sign(protrusionSamples.averageNormalComponent);
    protMagnitudeS = sort(protMagnitude(:));
    protMagCutOff = protMagnitudeS(ceil(.01 * numel(protMagnitudeS)));
    
    for iFrame = 1:nFrames-1
        % Load speckles channel 1
        load([s1Path filesep s1Files(iFrame).name]);
        status = vertcat(cands(:).status); %#ok<NODEF>
        S1 = vertcat(cands(status == 1).Lmax);
        clear cands;
        
        if isempty(S1)
            fprintf('%s channel doesn''t contain any speckle in frame %d/%d !!!\n',...
                names{1}, iFrame, nFrames);
            continue;
        end
        
        % Load speckles channel 2
        load([s2Path filesep s2Files(iFrame).name]);
        status = vertcat(cands(:).status);
        S2 = vertcat(cands(status == 1).Lmax);
        clear cands;
        
        if isempty(S2)
            fprintf('%s channel doesn''t contain any speckle in frame %d/%n !!!\n',...
                names{2}, iFrame, nFrames);
            continue;
        end
        
        % Compute distance to the edge
        BW = imread([maskPath filesep maskFiles(iFrame).name]);
        distToEdge = bwdist(max(BW(:)) - BW) * pixelSize;
        
        % Compute linear indices of speckles
        idxS1 = sub2ind(size(distToEdge), S1(:, 1), S1(:, 2));
        idxS2 = sub2ind(size(distToEdge), S2(:, 1), S2(:, 2));

        % Data for panel A
        
        minD1 = sort(distToEdge(idxS1));
        minD2 = sort(distToEdge(idxS2));

        n1 = min(nPanelA, numel(minD1));
        n2 = min(nPanelA, numel(minD2));
        
        dataPanelA(1,iFrame) = mean(minD1(1:n1));
        dataPanelA(2,iFrame) = mean(minD2(1:n2));
    
        % Data for panel B
        
        L = imread([labelPath filesep labelFiles(iFrame).name]);
        dataPanelB{iFrame} = arrayfun(@(l) ...
            mean(distToEdge(idxS2(L(idxS2) == l))) - ...
            mean(distToEdge(idxS1(L(idxS1) == l))), 1:max(L(:)));
        
        % Data for panel C
        idxLprot = find(protMagnitude(:, iFrame) > protMagCutOff & ...
            protSign(:, iFrame) > 0);
        idxLret = find(protMagnitude(:, iFrame) > protMagCutOff & ...
            protSign(:, iFrame) < 0);
               
        dataPanelCprot{iFrame} = arrayfun(@(l) ...
            distToEdge(idxS2(L(idxS2) == l)) - ...
            mean(distToEdge(idxS1(L(idxS1) == l))), idxLprot,...
            'UniformOutput', false);
        
        dataPanelCret{iFrame} = arrayfun(@(l) ...
            distToEdge(idxS2(L(idxS2) == l)) - ...
            mean(distToEdge(idxS1(L(idxS1) == l))), idxLret,...
            'UniformOutput', false);
        
        if ~batchMode && ishandle(h)
            waitbar(iFrame / (nFrames-1), h);
        end
    end

    if ~batchMode && ishandle(h)
        close(h);
    end
    
    %
    % Panel A
    %
    
    subplot(hFig, 3, 3, iCol);
    plot(dataPanelA');
    xlabel('frame');
    ylabel('nm');
    
    %
    % Panel B
    %

    dataPanelB = cell2mat(dataPanelB);
    subplot(hFig, 3, 3, 3 + iCol);
    imagesc(dataPanelB);
    colormap('jet');
    xlabel('frame');
    ylabel('sector');
  
    %
    % Panel C
    %
    
    dataPanelCprot = vertcat(dataPanelCprot{:});
    dataPanelCret = vertcat(dataPanelCret{:});
    subplot(hFig, 3, 3, 7:9);
    [n1, xout1] = hist(dataPanelCprot, 50);
    [n2, xout2] = hist(dataPanelCret, 50);
    c = rand(3, 1);
    bar(xout1, n1, 'FaceColor', c); hold on;
    bar(xout2, -n2, 'FaceColor', c * .5); hold on;
    xlabel('nm');
end

