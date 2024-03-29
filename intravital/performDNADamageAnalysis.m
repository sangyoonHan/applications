function [flagSuccess] = performDNADamageAnalysis(imageDataFilePath, channelId53BP1, resultsDir, varargin)

    flagSuccess = false;
    
    p = inputParser;

    % channels for colocalization measures
    p.addParamValue('channelIdDrug', [], @(x) (isempty(x) || (isnumeric(x) && isscalar(x))) );
    p.addParamValue('channelIdMacrophage', [], @(x) (isempty(x) || (isnumeric(x) && isscalar(x))));
    
    % data selection
    p.addParamValue('seriesId', 1, @(x) (isnumeric(x) && isscalar(x)));
    p.addParamValue('timepointId', 1, @(x) (isnumeric(x) && isscalar(x)));
    
    % nuclei segmentation
    p.addParamValue('cellDiameterRange', [8, 20], @(x) (isnumeric(x) && numel(x) == 2) );
    p.addParamValue('minCellVolume', 400, @(x) (isnumeric(x) && isscalar(x)) );
    p.addParamValue('regionMergingModelFile', [], @(x) (isempty(x) || (ischar(x) && exist(x, 'file'))) );
    p.addParamValue('flagIgnoreCellsOnXYBorder', true, @(x) (isscalar(x) && islogical(x)) );
    
    % foci detection
    p.addParamValue('fociDiameterRange',  0.621 * [3, 7], @(x) (isnumeric(x) && numel(x) == 2) );
    p.addParamValue('minDistanceToROIBoundary', 1.25, @(x) (isnumeric(x) && isscalar(x)) );
    p.addParamValue('fociDetectionModelFile', [], @(x) (isempty(x) || (ischar(x) && exist(x, 'file'))) );
    p.addParamValue('maxFociCount', 6, @(x) (isnumeric(x) && isscalar(x)));
    
    % drug segmentation
    p.addParamValue('maxDrugObjectRadius', 20, @(x) (isnumeric(x) && isscalar(x)));
    p.addParamValue('minDrugSignalToBackgroundRatio', 2.5, @(x) (isnumeric(x) && isscalar(x)));
    
    % macrophages segmentation
    p.addParamValue('maxMacrophageObjectRadius', 20, @(x) (isnumeric(x) && isscalar(x)));
    p.addParamValue('minMacrophageObjectRadius', 1.0, @(x) (isnumeric(x) && isscalar(x)));
    p.addParamValue('minMacrophageSignalToBackgroundRatio', 2.5, @(x) (isnumeric(x) && isscalar(x)));

    % colocalization
    p.addParamValue('maxNeighDist', 30, @(x) (isscalar(x) && isnumeric(x)));
    p.addParamValue('numNeighDistLevels', 6, @(x) (isscalar(x) && isnumeric(x)));
    
    % miscelleneous
    p.addParamValue('metaInfoStruct', [], @(x) (isstruct(x) && all(isfield(x, {'header', 'data'}))) );
    p.addParamValue('flagParallelize', false, @(x) (isscalar(x) && islogical(x)) );
    p.addParamValue('flagSaveImages', false, @(x) (isscalar(x) && islogical(x)) );    
    p.addParamValue('finishStatusReportFile', [], @(x) (ischar(x)) );
    p.parse( varargin{:} );
    
    PARAMETERS = p.Results;      

    if ~isdir( resultsDir ) 
        mkdir(resultsDir);
    end
                                              
    % setup diary for logging analysis progress
    diary off;
    diary_file = fullfile( resultsDir , sprintf( '%s.log' , mfilename ) );
    if exist( diary_file, 'file' )
        delete( diary_file );
    end
    diary_file
    diary( diary_file );
    diary on;

    % check if all file provided exist
    if ~exist( imageDataFilePath, 'file' )
        error( 'unable to find the image data file - %s', imageDataFilePath );
    end

    PARAMETERS
    imageDataFilePath
    metaInfoStruct = PARAMETERS.metaInfoStruct
    
    if PARAMETERS.flagSaveImages
        if isdir( fullfile(resultsDir, 'images') )            
            rmdir( fullfile(resultsDir, 'images'), 's' );
        end
        mkdir( fullfile(resultsDir, 'images') );
    end
    
    AddWekaClassesToPath();
    
    %matlabpath
    %javaclasspath('-dynamic')
    %version -java
    
    if ~isempty(PARAMETERS.finishStatusReportFile)
        fidStatus = fopen( PARAMETERS.finishStatusReportFile, 'w' );       
    end
    
    % load input data
    PrettyPrintStepDescription( 'Loading Image Data' );
    dataLoadTimer = tic;
    
        % initialize bio image reader
        try 
            br = BioImageReader(imageDataFilePath);    
        catch err
            error( 'could not load image data data from file %s\n', imageDataFilePath);
            err
        end
    
        % get imagedata and metadata
        metadata = br.getMetadata(PARAMETERS.seriesId);
        imageData = br.getImageData(PARAMETERS.seriesId, 'timepointId', PARAMETERS.timepointId);
        
        % check whether the Drug and Macrophage channels are present
        metadata.channelId53BP1 = channelId53BP1;
        if isempty(channelId53BP1) || channelId53BP1 < 1 || channelId53BP1 > metadata.numChannels
            error( 'Invalid 53bp1 channel id.');
        end
        metadata.channelNames{metadata.channelId53BP1} = '53BP1';
        
        if ~isempty(PARAMETERS.channelIdMacrophage) && ~isnan(PARAMETERS.channelIdMacrophage)
            
            if PARAMETERS.channelIdMacrophage < 1 || PARAMETERS.channelIdMacrophage > metadata.numChannels
                error( 'Invalid macrophage channel id.');
            end
            
            metadata.channelIdMacrophage = PARAMETERS.channelIdMacrophage;
            metadata.channelNames{metadata.channelIdMacrophage} = 'Macrophage';
            
        else
            metadata.channelIdMacrophage = [];
        end
        
        if ~isempty(PARAMETERS.channelIdDrug) && ~isnan(PARAMETERS.channelIdDrug)
            
            if PARAMETERS.channelIdDrug < 1 || PARAMETERS.channelIdDrug > metadata.numChannels
                error( 'Invalid drug channel id.');
            end
            
            metadata.channelIdDrug = PARAMETERS.channelIdDrug;
            metadata.channelNames{metadata.channelIdDrug} = 'Drug';
        
        else
            metadata.channelIdDrug = [];
        end
                
        stackInfoStruct.metadata = rmfield(metadata, {'dataFilePath', 'channelNames'});
        
        compInfo.dataLoadTime = toc(dataLoadTimer);    

        metadata

        if PARAMETERS.flagSaveImages

            imwrite( generateMultichannelMIPImage(imageData, [], metadata.pixelSize), ...
                     fullfile(resultsDir, 'images', 'stackMIP.png'), 'png');

        end   

    % analyze data
    analysisTimer = tic;
    
        % segment nuclei
        PrettyPrintStepDescription( 'Running the nuclei segmentation algorithm' );
        
        segTimer = tic;
        
        [imLabelCellSeg, imCellSeedPoints, ...
         segAlgoParameters ] = segmentCellsInIntravitalData( imageData{metadata.channelId53BP1}, ...
                                                             metadata.pixelSize, ...      
                                                             'thresholdingAlgorithm', 'BackgroudRemovalUsingMorphologicalOpening', ...
                                                             'minSignalToBackgroundRatio', 2.5, ...
                                                             'seedPointDetectionAlgorithm', 'AdaptiveMultiscaleLoG', ...
                                                             'cellDiameterRange', PARAMETERS.cellDiameterRange, ...
                                                             'minCellVolume', PARAMETERS.minCellVolume, ...
                                                             'flagIgnoreCellsOnXYBorder', PARAMETERS.flagIgnoreCellsOnXYBorder, ...
                                                             'regionMergingModelFile', PARAMETERS.regionMergingModelFile, ...
                                                             'flagParallelize', PARAMETERS.flagParallelize, ...
                                                             'flagDebugMode', false);
        
        segAlgoParameters

        numCells = max(imLabelCellSeg(:));       
        cellStats = regionprops( imLabelCellSeg, 'Centroid', 'BoundingBox', 'Area', 'PixelIdxList' );
        
        fprintf( '\nThe segmentation algorithm found %d cells\n', numCells );
        
        compInfo.segmentationTime = toc(segTimer);      
		compInfo.totalAlgorithmTime = compInfo.segmentationTime;
        
        stackInfoStruct.cellCount = numCells;
        stackInfoStruct.cellDensity = sum([cellStats.Area]) / numel(imLabelCellSeg);
        
        % detect foci
        PrettyPrintStepDescription( 'Running the foci detection algorithm' );
        
        fociDetectionTimer = tic;
        
        [fociStats, imFociSeedPoints, imLabelFociSeg, ...
         fociDetectionParameters ] = segmentFociInsideNuclei( imageData{metadata.channelId53BP1}, ...
                                                              PARAMETERS.fociDiameterRange, ...                      
                                                              'spacing', metadata.pixelSize, ...
                                                              'roiMask', imLabelCellSeg, ...
                                                              'minDistanceToROIBoundary', PARAMETERS.minDistanceToROIBoundary, ...
                                                              'fociDetectionModelFile', PARAMETERS.fociDetectionModelFile);

        for cid = 1:numel(cellStats)

            curCellPixInd = find(imLabelCellSeg == cid);
            curCellFoci = unique(imFociSeedPoints(curCellPixInd));
            curCellFoci = curCellFoci(curCellFoci > 0);
            cellStats(cid).foci = curCellFoci;
            cellStats(cid).fociCount = numel(curCellFoci);

        end        

        compInfo.fociDetectionTime = toc(fociDetectionTimer);        
		compInfo.totalAlgorithmTime = compInfo.totalAlgorithmTime + compInfo.fociDetectionTime;
		
        fprintf( '\nThe foci detection algorithm found %d foci\n', numel(fociStats));
        tabulate( [cellStats.fociCount] )
        
        if PARAMETERS.flagSaveImages

            imFociDetectionSummary = generateMIPMaskOverlay(imageData{metadata.channelId53BP1}, imLabelFociSeg > 0, [1, 0, 0], 0.5, ...
                                                            'spacing', metadata.pixelSize);            
                
            imwrite(imFociDetectionSummary, fullfile(resultsDir, 'images', 'fociDetectionSummary.png'), 'png');

        end
        
        % perform colocalization analysis with the macrophage channel
        cellColocStats = [];
        
        if ~isempty(metadata.channelIdMacrophage) 
            
            % segment macrophage channel
            PrettyPrintStepDescription( 'Segmenting Macrophage Channel' );

            macSegTimer = tic;

            imMacrophageSeg = segmentMacrophages(imageData{metadata.channelIdMacrophage}, ...
                                                 'maxObjectRadius', PARAMETERS.maxMacrophageObjectRadius, ...
                                                 'minSignalToBackgroundRatio', PARAMETERS.minMacrophageSignalToBackgroundRatio, ...
                                                 'spacing', metadata.pixelSize, ...
                                                 'minObjectRadius', PARAMETERS.minMacrophageObjectRadius);
            
            compInfo.macrophageSegTime = toc(macSegTimer);

            fprintf('\ntook %f seconds\n', compInfo.macrophageSegTime);
            
            % compute colocalization measures with drug channel
            fprintf('\n>> Computing colocalization measures for the drug channel ... \n');

            macColocMeasureTime = tic;

            [macrophageColocStats] = ComputeDNADamageColocalizationMeasures(imageData{metadata.channelId53BP1}, ...   
                       														imageData{metadata.channelIdMacrophage}, ... 
                            												metadata.pixelSize, ...
                                   											imLabelCellSeg, cellStats, ...
                                          									imMacrophageSeg, ...
																			'maxObjectRadius', PARAMETERS.maxMacrophageObjectRadius, ...
																			'maxNeighDist', PARAMETERS.maxNeighDist, ...
																			'numNeighDistLevels', PARAMETERS.numNeighDistLevels);

            cellColocStats.macrophage = macrophageColocStats;

            compInfo.macrophageColocMeasureTime = toc(macColocMeasureTime);
            compInfo.macrophageColocAnalysisTime = compInfo.macrophageSegTime + compInfo.macrophageColocMeasureTime;
			compInfo.totalAlgorithmTime = compInfo.totalAlgorithmTime + compInfo.macrophageColocAnalysisTime;

            fprintf('\ntook %f seconds\n', compInfo.macrophageColocMeasureTime);

			if PARAMETERS.flagSaveImages

				imMacrophageSegSummary = generateMIPMaskOverlay(imageData{metadata.channelIdMacrophage}, ...
																imMacrophageSeg, [1, 0, 0], 0.5, ...
																'spacing', metadata.pixelSize);            
                
				imwrite(imMacrophageSegSummary, fullfile(resultsDir, 'images', 'macrophageSegSummary.png'), 'png');

			end
            
        else
            
            compInfo.macrophageSegTime = 0;
            compInfo.macrophageColocMeasureTime = 0;
            compInfo.macrophageColocAnalysisTime = 0;
            
        end
        
        % perform colocalization analysis with the drug channel
        if ~isempty(metadata.channelIdDrug)
            
            % segment drug channel
            PrettyPrintStepDescription( 'Segmenting Drug Channel' );

            drugSegTimer = tic;

            imDrugSeg = segmentDrugCisplatin(imageData{metadata.channelIdDrug}, ...
                                             'maxObjectRadius', PARAMETERS.maxDrugObjectRadius, ...
                                             'minSignalToBackgroundRatio', PARAMETERS.minDrugSignalToBackgroundRatio, ...
                                             'spacing', metadata.pixelSize);
                                         
            compInfo.drugSegTime = toc(drugSegTimer);
            
            fprintf('\ntook %f seconds\n', compInfo.drugSegTime);
            
            % compute colocalization measures with drug channel
            fprintf('\n>> Computing colocalization measures for the drug channel ... \n');

            drugColocMeasureTime = tic;

            [drugColocStats] = ComputeDNADamageColocalizationMeasures(imageData{metadata.channelId53BP1}, ...   
                                                                      imageData{metadata.channelIdDrug}, ... 
                                                                      metadata.pixelSize, ...
                                                                      imLabelCellSeg, cellStats, ...
                                                                      imDrugSeg, ...
																	  'maxObjectRadius', PARAMETERS.maxDrugObjectRadius, ...
																	  'maxNeighDist', PARAMETERS.maxNeighDist, ...
																	  'numNeighDistLevels', PARAMETERS.numNeighDistLevels);

            cellColocStats.drug = drugColocStats;

            compInfo.drugColocMeasureTime = toc(drugColocMeasureTime);
            compInfo.drugColocAnalysisTime = compInfo.drugSegTime + compInfo.drugColocMeasureTime;
			compInfo.totalAlgorithmTime = compInfo.totalAlgorithmTime + compInfo.drugColocAnalysisTime;

            fprintf('\ntook %f seconds\n', compInfo.drugColocMeasureTime);
            
			if PARAMETERS.flagSaveImages

				imDrugSegSummary = generateMIPMaskOverlay(imageData{metadata.channelIdDrug}, ...
						 								  imDrugSeg, [1, 0, 0], 0.5, ...
														  'spacing', metadata.pixelSize);            
                
				imwrite(imDrugSegSummary, fullfile(resultsDir, 'images', 'drugSegSummary.png'), 'png');

			end

        else
            
            compInfo.drugSegTime = 0;
            compInfo.drugColocMeasureTime = 0;
            compInfo.drugColocAnalysisTime = 0;
            
        end
        
        % compute and store stack level info
        stackInfoStruct.totalFociCount = numel(fociStats);
        cellFociCounts = [cellStats.fociCount];
        
        for i = 0:PARAMETERS.maxFociCount
            curField = (sprintf('cellFociCountDistribution_%.2d', i));
            stackInfoStruct.(curField) = 0;
        end
        
        for i = 1:numel(cellStats)
            
            if cellStats(i).fociCount >= PARAMETERS.maxFociCount
                curField = (sprintf('cellFociCountDistribution_%.2d', PARAMETERS.maxFociCount));
            else
                curField = (sprintf('cellFociCountDistribution_%.2d', cellStats(i).fociCount));
            end
            
            stackInfoStruct.(curField) = stackInfoStruct.(curField) + (1.0 / (eps + numCells));
            
        end

        % compute and store cell level info
        fprintf('\n>> Computing some information about each cell ...\n');       
        
        cellInfoStruct = [];
        cellInfoFeatureMatrix = {};
        
        cellDrugColocInfoStruct = [];
        cellDrugColocInfoFeatureMatrix = [];

        cellMacrophageColocInfoStruct = [];
        cellMacrophageColocInfoFeatureMatrix = [];
        
        fprintf( '\nProgress: \n' );
        last_percent_done = 0;
        numPrint = 0;
        
        for cellId = 1:numel(cellStats)
            
            curCellStruct = [];
            curCellStruct.cellId = cellId;
            
            % compute region properties
            curCellProps = ComputeRegionProperties( imLabelCellSeg, cellId );
            
            % note down whether or not the cell touches the border
            ptCellPixelCoord = ind2submat(size(imLabelCellSeg), curCellProps.PixelIdxList);

            curCellStruct.flagIsCellOnBorder = zeros(1,3);
            for dim = 1:3
                if any( ismember(ptCellPixelCoord(:,dim), [1, size(imLabelCellSeg, dim)]) )
                    curCellStruct.flagIsCellOnBorder(dim) = 1;
                end
            end

            curCellStruct.flagIsCellOnXYBorder = any(curCellStruct.flagIsCellOnBorder(1:2));
            curCellStruct.flagIsCellOnZBorder = any(curCellStruct.flagIsCellOnBorder(3));
            
            % some basic properties
            basicProps.centroidImsp = cellStats(cellId).Centroid;
            basicProps.centroidPhysp = cellStats(cellId).Centroid .* metadata.pixelSize;

            basicProps.bboxSizeImsp = cellStats(cellId).BoundingBox(4:end);
            basicProps.bboxSizePhysp = cellStats(cellId).BoundingBox(4:end) .* metadata.pixelSize; 

            volVoxel = prod(metadata.pixelSize);
            basicProps.volume = curCellProps.Area * volVoxel;       
            basicProps.volumeOfConvexHull = curCellProps.ConvexArea * volVoxel;
            basicProps.convexity = curCellProps.Area / curCellProps.ConvexArea;

            ptCell = ind2submat( size(imLabelCellSeg), curCellProps.PixelIdxList ); 
            ptCell = bsxfun(@times, ptCell, metadata.pixelSize);
            ptCell = ptCell - repmat( mean(ptCell), [size(ptCell,1), 1] );
            [U, S, V] = svd( (ptCell' * ptCell) / size(ptCell,1) );
            curCellEllipsoidRadiusPhysp = zeros(1,3); 
            for j = 1:3
                curCellEllipsoidRadiusPhysp(j) = 2 * sqrt(S(j,j)); % eigen-values are a measure of variance
            end
            basicProps.ellipsoidRadiusPhysp = curCellEllipsoidRadiusPhysp;        
            basicProps.fittedEllipsoidVolume = (4/3) * pi * prod(curCellEllipsoidRadiusPhysp);
            basicProps.ellipticVariance = ComputeEllipticVariance(ptCell, metadata.pixelSize);

            curCellStruct.cellprops = basicProps;      
            
            % foci inside cell
            curCellStruct.fociprops.cellFociCount = cellStats(cellId).fociCount;
            
            curCellStruct.fociprops.fociVolumeFraction = 0;
            
            curCellStruct.fociprops.meanCellFociRadius = 0;
            curCellStruct.fociprops.stdCellFociRadius = 0;
            curCellStruct.fociprops.minCellFociRadius = 0;            
            curCellStruct.fociprops.maxCellFociRadius = 0;           
            
            if cellStats(cellId).fociCount > 0
                curCellFociStats = fociStats(cellStats(cellId).foci);
                curCellStruct.fociprops.fociVolumeFraction = sum((4/3) * pi * [curCellFociStats.Radius].^3) / basicProps.volume;
                
                curCellStruct.fociprops.meanCellFociRadius = min([curCellFociStats.Radius]);
                curCellStruct.fociprops.stdCellFociRadius = max([curCellFociStats.Radius]);
                curCellStruct.fociprops.minCellFociRadius = mean([curCellFociStats.Radius]);
                curCellStruct.fociprops.maxCellFociRadius = std([curCellFociStats.Radius]);
            end
            
            % append to cellInfoStruct
            cellInfoStruct = [cellInfoStruct ; curCellStruct];                    
            [featureVec, cellInfoFeatureNameList] = ConvertFeatureStructToFeatureVec(curCellStruct);
            cellInfoFeatureMatrix = cat(1, cellInfoFeatureMatrix, featureVec);

            % add colocalization stats with the drug channel if present
            if ~isempty(metadata.channelIdDrug)
                
                curCellDrugColocStruct = curCellStruct;
                curCellDrugColocStruct.colocprops = cellColocStats.drug(cellId);
                cellDrugColocInfoStruct = [cellDrugColocInfoStruct; curCellDrugColocStruct];
                [featureVec, cellDrugColocInfoFeatureNameList] = ConvertFeatureStructToFeatureVec(curCellDrugColocStruct);
                cellDrugColocInfoFeatureMatrix = cat(1, cellDrugColocInfoFeatureMatrix, featureVec);
                
            end

            % add colocalization stats with the macrophage channel if present
            if ~isempty(metadata.channelIdMacrophage)
                
                curCellMacrophageColocStruct = curCellStruct;
                curCellMacrophageColocStruct.colocprops = cellColocStats.macrophage(cellId);
                cellMacrophageColocInfoStruct = [cellMacrophageColocInfoStruct; curCellMacrophageColocStruct];
                [featureVec, cellMacrophageColocInfoFeatureNameList] = ConvertFeatureStructToFeatureVec(curCellMacrophageColocStruct);
                cellMacrophageColocInfoFeatureMatrix = cat(1, cellMacrophageColocInfoFeatureMatrix, featureVec);
                
            end
            
            % update progress
            percent_done = round(100*cellId/numCells);       

            if percent_done > last_percent_done
                fprintf( '%.2d%%  ', percent_done );
                last_percent_done = percent_done;
                numPrint = numPrint + 1;
                if mod( numPrint, 10 ) == 0
                   fprintf( '\n' ); 
                end
            end        
            
        end
        
        % compute and store foci level info
        fociInfoStruct = [];
        fociInfoFeatureMatrix = {};
        
        for fid = 1:numel(fociStats)                    
            fociInfoStruct(fid).cellId = imLabelCellSeg( fociStats(fid).PixelLocationIndex );
            fociInfoStruct(fid).cellFociCount = cellStats(fociInfoStruct(fid).cellId).fociCount;
            fociInfoStruct(fid).fociprops = fociStats(fid);
            [featureVec, fociInfoFeatureNameList] = ConvertFeatureStructToFeatureVec(fociInfoStruct(fid));
             fociInfoFeatureMatrix = cat(1, fociInfoFeatureMatrix, featureVec);
        end

        % save foci distribution plot
        numCells = numel(cellStats); 
        punctaCounts = [cellStats.fociCount];

        hFociDist = figure();
        centers = 0:max(punctaCounts);
        [counts, inds] = histc(punctaCounts, centers);
        bar(centers, counts/sum(counts), ...
            'linewidth', 2.0, ...
            'barwidth', 0.9, ...
            'EdgeColor', 'k', ...
            'FaceColor', 0.7 * ones(1,3));

        [~, fname, ~] = fileparts(imageDataFilePath);
        fname = strrep(fname,'_','\_');
        text(0.5, 0.95, {fname, sprintf('#cells = %d, #puncta= %d', numCells, sum(punctaCounts))}, ...
             'units', 'normalized', 'horizontalalignment', 'center');

        title({'Distribution of Number of Puncta In a Cell'}, ...
              'FontSize', 12.0, 'FontWeight', 'bold');
        xlabel('Number of puncta per cell');
        ylabel('Proportion of cells');
        ylim([0, 1]);
        grid on;
        SaveFigure(hFociDist , fullfile(resultsDir, 'fociCountDistributionPlot.jpg') , 'jpg');
        SaveFigure(hFociDist , fullfile(resultsDir, 'fociCountDistributionPlot.fig') , 'fig');
        close(hFociDist);
            
        % save images
        if PARAMETERS.flagSaveImages 

            fprintf('\n>> Saving snapshot images of cells ...\n');       
            
            imageSaveTimer = tic;

            % save cell images
            if PARAMETERS.flagParallelize

                parfor cellId = 1:numCells

                    if(cellStats(cellId).fociCount == 0)
                        continue;
                    end
                    
                    imageOutputDir = fullfile(resultsDir, 'images', num2str(cellStats(cellId).fociCount));

                    if ~isdir( imageOutputDir )
                        mkdir( imageOutputDir );
                    end

                    WriteCellSnapshotImages(imageData{metadata.channelId53BP1}, imLabelCellSeg == cellId, ...
                                            cellStats(cellId), cellId, fociStats(cellStats(cellId).foci), ...
                                            metadata.pixelSize, imageOutputDir)

                end

            else

                fprintf( '\nProgress: \n' );

                last_percent_done = 0;
                numPrint = 0;

                for cellId = 1:numCells

                    if(cellStats(cellId).fociCount == 0)
                        continue;
                    end
                    
                    imageOutputDir = fullfile(resultsDir, 'images', num2str(cellStats(cellId).fociCount));

                    if ~isdir( imageOutputDir )
                        mkdir( imageOutputDir );
                    end

                    WriteCellSnapshotImages(imageData{metadata.channelId53BP1}, imLabelCellSeg == cellId, ...
                                            cellStats(cellId), cellId, fociStats(cellStats(cellId).foci), ...
                                            metadata.pixelSize, imageOutputDir)
                    
                    percent_done = round(100*cellId/numCells);       

                    if percent_done > last_percent_done
                        fprintf( '%.2d%%  ', percent_done );
                        last_percent_done = percent_done;
                        numPrint = numPrint + 1;
                        if mod( numPrint, 10 ) == 0
                           fprintf( '\n' ); 
                        end
                    end     

                    diaryFlush();

                end

            end
            
            compInfo.imageSaveTime = toc(imageSaveTimer);

        end        
        
    compInfo.totalAlgorithmTime = compInfo.segmentationTime + compInfo.fociDetectionTime;
    compInfo.totalAnalysisTime = toc(analysisTimer);

    stackInfoStruct.computation = compInfo;
    stackInfoStruct.resultsDir = resultsDir;
    
    metaInfoStruct
    stackInfoStruct
    compInfo
        
    % write stack info
    fprintf( '\n>>Writing stack analysis csv file ... \n' );

    [ stackFeatureVec , stackFeatureNameList ] = ConvertFeatureStructToFeatureVec( stackInfoStruct );

    if ~isempty( PARAMETERS.metaInfoStruct )
        stackFeatureNameList = cat(2, metaInfoStruct.header, stackFeatureNameList);            
        stackFeatureVec = cat(2, metaInfoStruct.data , stackFeatureVec);            
    end

    WriteFeatureMatrixToCSVFile( fullfile(resultsDir, 'stackAnalysisInfo.csv' ), ...
                                 stackFeatureVec, stackFeatureNameList );
                             
    % write cell info
    fprintf( '\n>>Writing cell analysis csv file ... \n' );

    featureNameList = cat(2, stackFeatureNameList, cellInfoFeatureNameList );
    featureMatrix = cat(2, repmat(stackFeatureVec, numCells, 1), cellInfoFeatureMatrix );

    WriteFeatureMatrixToCSVFile( fullfile(resultsDir, 'cellAnalysisInfo.csv' ), ...
                                 featureMatrix, featureNameList );

    % write foci info
    fprintf( '\n>>Writing foci analysis csv file ... \n' );

    featureNameList = cat(2, stackFeatureNameList, fociInfoFeatureNameList );
    featureMatrix = cat(2, repmat(stackFeatureVec, numel(fociInfoStruct), 1), fociInfoFeatureMatrix);

    WriteFeatureMatrixToCSVFile( fullfile(resultsDir, 'fociAnalysisInfo.csv' ), ...
                                 featureMatrix, featureNameList );

    % write cell macrophage coloc info
    if ~isempty(metadata.channelIdDrug)
        
        fprintf( '\n>>Writing cell-macrophage colocalization analysis csv file ... \n' );

        featureNameList = cat(2, stackFeatureNameList, cellMacrophageColocInfoFeatureNameList );
        featureMatrix = cat(2, repmat(stackFeatureVec, numCells, 1), cellMacrophageColocInfoFeatureMatrix );

        WriteFeatureMatrixToCSVFile( fullfile(resultsDir, 'cellMacrophageColocalizationAnalysisInfo.csv' ), ...
                                     featureMatrix, featureNameList );

    end
                             
    % write cell drug coloc info
    if ~isempty(metadata.channelIdDrug)
        
        fprintf( '\n>>Writing cell-drug colocalization analysis csv file ... \n' );

        featureNameList = cat(2, stackFeatureNameList, cellDrugColocInfoFeatureNameList );
        featureMatrix = cat(2, repmat(stackFeatureVec, numCells, 1), cellDrugColocInfoFeatureMatrix );

        WriteFeatureMatrixToCSVFile( fullfile(resultsDir, 'cellDrugColocalizationAnalysisInfo.csv' ), ...
                                     featureMatrix, featureNameList );

    end
    
    % save analysis info in a mat file for inspection later
    save( fullfile(resultsDir, 'DNADamageAnalysisInfo.mat'), ...
          'stackInfoStruct', 'cellInfoStruct', 'cellMacrophageColocInfoStruct', 'cellDrugColocInfoStruct', 'fociInfoStruct', ...
          'PARAMETERS', 'segAlgoParameters', 'fociDetectionParameters');
    
    % save mat file that can be loaded into the DNADamageAnalyzer tool
    analysisData.dataFilePath = imageDataFilePath;    
    for i = 1:numel(imageData)
        imageData{i} = uint16(imageData{i});
    end
    analysisData.imageData = imageData;
    analysisData.metadata = metadata;
    
    analysisData.imLabelCellSeg = uint16( imLabelCellSeg );
    analysisData.imCellSeedPoints = uint16( imCellSeedPoints );
    [imCellSegMaskRGB, analysisData.CellSegColorMap] = label2rgbND(imLabelCellSeg);
    analysisData.segAlgoParameters = segAlgoParameters;
    analysisData.cellStats = cellStats;
    
    analysisData.fociStats = fociStats;
    analysisData.imFociSeedPoints = uint16( imFociSeedPoints );
    analysisData.imLabelFociSeg = uint16( imLabelFociSeg );
    [imFociSegMaskRGB, analysisData.FociSegColorMap] = label2rgbND(imLabelFociSeg);
    analysisData.fociDetectionParameters = fociDetectionParameters;

    if ~isempty(metadata.channelIdMacrophage)
        analysisData.imMacrophageSeg = imMacrophageSeg;
    end

    if ~isempty(metadata.channelIdDrug)
        analysisData.imDrugSeg = imDrugSeg;
    end
    
    analysisData.cellColocStats = cellColocStats;

    save( fullfile(resultsDir, 'DNADamageAnalysis.mat'), '-struct', 'analysisData' );
                             
    % report success
    flagSuccess = true;
    fprintf( '\n\n---- Analysis Succeeded ---- \n\n' );
    
    if ~isempty(PARAMETERS.finishStatusReportFile)
        fprintf( fidStatus, 'Analysis Succeeded' );
        fclose(fidStatus);
    end
    
    diary off;
    
end

function WriteCellSnapshotImages(imageData, imCellMask, cellStats, cellId, fociStats, spacing, imageOutputDir)

    curCellCentroid = cellStats.Centroid;
    curCellBoundingBox = cellStats.BoundingBox;
    curCellDisplaySize = max( [curCellBoundingBox(4:5), 70] );
    szOutputImage = [100, 100];

    % crop images
    subinds = cell(1,3);
    imsize = size(imageData);
    for i = 1:2

        xi = round(curCellCentroid(3-i) - 0.5 * curCellDisplaySize);

        xi_low = xi;
        if xi_low < 1 
            xi_low = 1;
        end

        xi_high = xi + curCellDisplaySize - 1;
        if xi_high > imsize(i)
            xi_high = imsize(i);
        end

        subinds{i} = xi_low:xi_high;

    end     
    subinds{3} = round(curCellBoundingBox(3):(curCellBoundingBox(3)+curCellBoundingBox(6)-1));

    imCurCellMIP = mat2gray( max(double(imageData(subinds{:})) .* double(imCellMask(subinds{:})), [], 3) );

    imLabelFociMask = zeros(size(imCurCellMIP));    
    fociSeedPointLoc = ind2submat(size(imCellMask), [fociStats.PixelLocationIndex]);
    fociSeedPointLoc(:,3) = [];
    for i = 1:2
        fociSeedPointLoc(:,i) = fociSeedPointLoc(:,i) - min(subinds{i}) + 1;
    end        
    seedPos = fociSeedPointLoc * diag(spacing(1:2));
    kd = KDTreeSearcher(seedPos);
    pixelPos = ind2submat(size(imCurCellMIP), (1:numel(imCurCellMIP))') * diag(spacing(1:2));
    [closestSeedInd, distanceToSeed] = kd.knnsearch(pixelPos);

    blobRadii = ([fociStats.Radius])';
    flagIsPixelInSeedVicinity = abs(distanceToSeed - blobRadii(closestSeedInd)) <= min(spacing(1:2));
    imLabelFociMask( flagIsPixelInSeedVicinity ) = closestSeedInd( flagIsPixelInSeedVicinity );
    imFociRGBMask = label2rgbND(imLabelFociMask);
    
    imwrite( imresize(genImageRGBMaskOverlay(imCurCellMIP, imFociRGBMask, 0.5 ), szOutputImage), ...
             fullfile(imageOutputDir, sprintf('Cell53BP1MIPFociOverlay_%.3d.png', cellId)), 'png' );   

end
