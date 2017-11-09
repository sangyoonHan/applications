
allCellsFileName = '28-Mar-2017_LBP_dLBP_1.mat';
InFilePath =  '/project/bioinformatics/Danuser_lab/liveCellHistology/analysis/CellExplorerData';
loadMatPath = fullfile(InFilePath, allCellsFileName)

% My output path
omeTiffDir = '/work/bioinformatics/shared/dope/data/OMETIFF/clickFuryTest';

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('% Crop Assaf''s MDs');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');

load(loadMatPath);%, 'allCellsMovieData'); 

randset = 25;

if isempty(randset)
    allCellsSet = allCellsMovieData;
else
%     cellDataSet = cell2mat(allCellsMovieData(1,randsample(length(allCellsMovieData),randset,false)));
    allCellsSet = allCellsMovieData(1,randsample(length(allCellsMovieData),randset,false));
end

masterMovieDir = [omeTiffDir filesep 'sdcTest'];
if ~exist(masterMovieDir, 'dir')
    mkdir(masterMovieDir);
end

javaaddpath('/home2/s170480/matlab/extern/bioformats/bioformats_package.jar','-end')
MList = cell(1, length(allCellsSet));

% pixelSize = ome.units.quantity.Length(java.lang.Double(.325), ome.units.UNITS.MICROMETER);
PIXS = @(y) ome.units.quantity.Length(java.lang.Double(y), ome.units.UNITS.MICROMETER);
pixelSizepf = arrayfun(@(x) PIXS(x), repmat(.325,[1 length(allCellsSet)]), 'UniformOutput', false);


% How many frame to include in the movie chops...
% timeChop = 10?

% for i = 1:2
parfor i = 1:length(allCellsSet)

    iCell = allCellsSet{i};
    disp(['Creating movieData for cell ID key: ' iCell.key]);
    movieFileOut = [masterMovieDir filesep iCell.key filesep iCell.key '_CellX.ome.tiff'];
    disp(['Making OME-TIFF : ' movieFileOut]);

    disp(iCell.key);

    
    xs = iCell.xs;
    ys = iCell.ys;
    ts = iCell.ts;
    
    startTime = ts;
    ntime = length(ts);
    endTime = ts(1) + ntime;

    iCell.key = [iCell.key '_t' num2str(endTime)]
    
    MD = load(iCell.MD, 'MD');
    MD = MD.MD;
    
    %% HARD CODED!
    pixelSize_ = 0.325;
    FOVRadius = round(35/pixelSize_);
    movieM = zeros(2*FOVRadius+1, 2*FOVRadius+1, ntime);
    
    %% Configure OME-TIFF metadata
    javaaddpath('/home2/s170480/matlab/extern/bioformats/bioformats_package.jar','-end')
    metadata = createMinimalOMEXMLMetadata(movieM, 'XYTZC');
    metadata.setPixelsPhysicalSizeX(pixelSizepf{i}, 0);
    metadata.setPixelsPhysicalSizeY(pixelSizepf{i}, 0);
    metadata.setImageDescription(iCell.key, 0);
    metadata.setExperimenterGroupDescription(iCell.expStr,0);
    metadata.setExperimenterGroupID(iCell.date,0);
    metadata.setDatasetName(iCell.expStr,0);
    metadata.setDatasetID(iCell.MD,0);
    metadata.setDatasetDescription([...
        'notes=''for clickFuryTest-ARJ''', 'key=''' iCell.key ''',date=''' iCell.date ''',Celltype=''' iCell.cellType ''',metEff=' num2str(iCell.metEff) ',locationStr=' num2str(iCell.locationStr)],0);
    
    for itime = 1:ntime
        curTime = ts(itime);
        curI = MD.getChannel(1).loadImage(curTime);
        movieM(:,:,itime) = curI(round((ys(itime)-FOVRadius)):(round(ys(itime)+FOVRadius)),round((xs(itime)-FOVRadius)):round((xs(itime)+FOVRadius)));
    end
    
    % Save as OME-TIFF 
    mkdir(fileparts(movieFileOut));
    bfsave(movieM, movieFileOut, 'metadata', metadata);
    
    
    % MovieData Validation
    disp('Loading with MovieData BF reader')
    MD = MovieData(movieFileOut, true, fileparts(movieFileOut));
    MD.sanityCheck();
    MD.save();
    
    extProc = ExternalProcess(MD, 'LBPfeatures');
    MD.addProcess(extProc);
    MD.processes_{1}.setParameters(iCell);

    MD.addProcess(EfficientSubpixelRegistrationProcess(MD));
    SDCindx = MD.getProcessIndex('EfficientSubpixelRegistrationProcess');
    MD.processes_{SDCindx}.run()

    % MDpath = MD.getFullPath();
    % Save individual cell movieData
    allCellsSet{i}.cellMD = MD.getFullPath();
    allCellsSet{i}.key = iCell.key;
    MList{i} = MD; 
end

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('% Save cell array with cell MD info');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');

save([omeTiffDir filesep 'clickFuryCellData.mat'], 'allCellsSet');

annotationSet = containers.Map('KeyType','char','ValueType', 'any'); % tags to cells (by local master index)
annotationSet('bleb')=[NaN]
annotationSet('protrusion')=[NaN]
annotationSet('small')=[NaN]
annotationSet('big')=[NaN]
annotationSet('active')=[NaN]
annotationSet('inactive')=[NaN]
annotationSet('weird')=[NaN]
annotationSet('neat')=[NaN]
annotationSet.keys
cellDataSet = allCellsSet;

save([omeTiffDir filesep 'clickFuryCellData_R' num2str(randset) '.mat'], 'cellDataSet', 'annotationSet');

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('% [optional & slow..] Create MovieList');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');

% ML = MovieList([MList{:}], masterMovieDir, 'movieListFileName_', 'movieListCells.mat');
% ML.sanityCheck();
% ML.save();


% disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
% disp('% Examples to acccess metadata via MovieData/MovieList');
% disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
% Access metadata info in the following fashion...
% ML.movies_{3}.reader.formatReader.getMetadataStore().getDatasetID(0)
% ML.movies_{3}.reader.formatReader.getMetadataStore().getDatasetName(0) 
% ML.movies_{3}.reader.formatReader.getMetadataStore().getImageDescription(0) 
% ML.movies_{3}.reader.formatReader.getMetadataStore().getExperimenterGroupDescription(0)
% ML.movies_{3}.reader.formatReader.getMetadataStore().getsetDatasetDescription(0)


% annotationSet = containers.Map('KeyType','char','ValueType', 'any'); % tags to cells (by local master index)
% annotationSet('bleb')=[NaN]
% annotationSet('protrusion')=[NaN]
% annotationSet('small')=[NaN]
% annotationSet('big')=[NaN]
% annotationSet('active')=[NaN]
% annotationSet('inactive')=[NaN]
% annotationSet('weird')=[NaN]
% annotationSet('neat')=[NaN]
% annotationSet.keys
% cellDataSet = allCellsSet;

