% /project/bioinformatics/Danuser_lab/liveCellHistology/analysis/All

addpath(genpath('/home2/azaritsky/code/extern')); % Assaf

% Input Path
allCellsFileName = '14-May-2017_LBP_dLBP_1.mat';
InFilePath =  '/project/bioinformatics/Danuser_lab/liveCellHistology/analysis/CellExplorerData';
loadMatPath = fullfile(InFilePath, allCellsFileName);

% Output path
omeTiffDir = '/work/bioinformatics/shared/dope_assaf';%/work/bioinformatics/shared/dope/data/OMETIFF/test4Assaf';
if ~exist(omeTiffDir, 'dir')
    mkdir(omeTiffDir);
end

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('% Chop up Assaf''s MDs');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');

load(loadMatPath);%, 'allCellsMovieData'); 

randset = 25;

if isempty(randset)
    allCellsSet = allCellsMovieData;
else
%     cellDataSet = cell2mat(allCellsMovieData(1,randsample(length(allCellsMovieData),randset,false)));
    allCellsSet = allCellsMovieData(1,randsample(length(allCellsMovieData),randset,false));
end

javaaddpath('/home2/azaritsky/code/extern/bioformats/bioformats_package.jar','-end')
MList = cell(1, length(allCellsSet));

% pixelSize = ome.units.quantity.Length(java.lang.Double(.325), ome.units.UNITS.MICROMETER);
PIXS = @(y) ome.units.quantity.Length(java.lang.Double(y), ome.units.UNITS.MICROMETER);
% pixelSizepf = arrayfun(@(x) PIXS(x), repmat(.325,[1
% length(allCellsSet)]), 'UniformOutput', false); % Assaf


% How many frame to include in the movie chops...
% timeChop = 10?

% for i = 1:2
% parfor i = 1:length(allCellsSet) % Assaf
for i = 1:length(allCellsSet)

    iCell = allCellsSet{i};
    disp(['Creating movieData for cell ID key: ' iCell.key]);
    movieFileOut = [omeTiffDir filesep iCell.key filesep iCell.key '_CellX.ome.tiff'];
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
    javaaddpath('/home2/azaritsky/code/extern/bioformats/bioformats_package.jar','-end')
    metadata = createMinimalOMEXMLMetadata(movieM, 'XYTZC');
    %     metadata.setPixelsPhysicalSizeX(pixelSizepf{i}, 0); % Assaf
    %     metadata.setPixelsPhysicalSizeY(pixelSizepf{i}, 0); % Assaf
    metadata.setPixelsPhysicalSizeX(pixelSize_, 0);
    metadata.setPixelsPhysicalSizeY(pixelSize_, 0);
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
annotationSet('Blebbing')=[NaN]
annotationSet('Balled')=[NaN]
annotationSet('Spread')=[NaN]
annotationSet('Smooth')=[NaN]
annotationSet('Short extension')=[NaN]
annotationSet('Long extension')=[NaN]
annotationSet('Migration')=[NaN]
annotationSet('Elongated')=[NaN]
annotationSet.keys

% Cell classes / labels / annotations:
% Blebbing- membrane ruffling 
% Balled- prominent halo, circular
% Spread- increased cell area, increased cytoplasm?
% Smooth- no discernible membrane ruffles
% Short extension- protrusion close to cell body
% Long extension- protrusion extending far from cell body
% Migration - cell movement that results in a change in xy
% Elongated- high eccentricity, long, thin
% Exclusion classifier:
% Dead / crap 
% Out of focus
% Multiple cells
% undefined

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('% Save .mat file with expected data structures and names (cell array and dictionary)');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');

cellDataSet = allCellsSet;
matFileName = [omeTiffDir filesep 'clickFuryCellData_R' num2str(randset) '.mat'];
save(matFileName, 'cellDataSet', 'annotationSet');


disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('% Examples to acccess metadata via MovieData/MovieList');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
uiwait

MList{3}.getReader.formatReader.getMetadataStore.getDatasetID(0)
MList{3}.getReader.formatReader.getMetadataStore.getDatasetName(0) 
MList{3}.getReader.formatReader.getMetadataStore.getImageDescription(0) 
MList{3}.getReader.formatReader.getMetadataStore.getExperimenterGroupDescription(0)
MList{3}.getReader.formatReader.getMetadataStore.getDatasetDescription(0)

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('% How to run cellXplorerDR and dopeAnnotator');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');

disp('Opt 1: load aboved saved .mat file by providing the file when the program is called');
cellXplorerDR(matFileName);

uiwait
% ff = findall(0,'Tag','cellXplore'); delete(ff);
disp('Opt 2: call function immediately and be prompted (via UI) to manually select file to load');
cellXplorerDR

uiwait

disp('Same applies for dopeAnnotator')
dopeAnnotator(matFileName);
uiwait
dopeAnnotator

% disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
% disp('% [optional & slow..] Create MovieList');
% disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');

% % ML = MovieList([MList{:}], omeTiffDir, 'movieListFileName_', 'movieListCells.mat');
% % ML.sanityCheck();
% % ML.save();



