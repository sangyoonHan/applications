
% simple script to pre-process the cells for Deep learning.
% Andrew R. Jamieson Oct 2017


clear;
clc;


%% load data state 
[filename, pathname] = uigetfile('/work/bioinformatics/shared/dope/torch/test/217x217/segmented/','Which data to load?');
load(fullfile(pathname,filename));

load('/work/bioinformatics/shared/dope/torch/test/cellData/cellMovieData_wAnno08May2017_0558.mat', 'cellDataSet')
c = [cellDataSet{:}];
labelSet = unique({c.cellType});


% imdsTrainFiles = {};
% for i = 1:length(imdsTrain.Files)
%     [a b] = fileparts(imdsTrain.Files{i});
%     imdsTrainFiles{i} = b;
% end


for i = 1:length(labelSet)
    label = labelSet{i};
    cellLabel = cell2mat(cellfun(@(x) contains(x,['28-Mar-2017_' label]) ,imdsTrain.Files, 'Uniform', false));
    imdsTrain.Labels(cellLabel) = label;
end


for i = 1:length(labelSet)
    label = labelSet{i};
    cellLabel = cell2mat(cellfun(@(x) contains(x,['28-Mar-2017_' label]) ,imdsValid.Files, 'Uniform', false));
    imdsValid.Labels(cellLabel) = label;
end

% tumorLabel = imdsTrain_Tumor_v_Mel.Labels == 'highMet' | ...
%     imdsTrain_Tumor_v_Mel.Labels == 'lowMet';
% imdsTrain_Tumor_v_Mel.Labels(tumorLabel) = 'tumor';


[imdsTrain] = splitEachLabel(imdsTrain,.9999999,...
                            'Exclude',{'highMet','lowMet','unMet'});
[imdsValid] = splitEachLabel(imdsValid,.9999999,...
                            'Exclude',{'highMet','lowMet','unMet'});
uisave();

%% Define Checkpoint
[checkPointDir] = uigetdir('/work/bioinformatics/shared/dope/torch/test/217x217/segmented/netTEMP',...
                            'Where to store net Checkpoints?');
                                                                      
                        
if ~verLessThan('matlab', '9.3')
    % define network
    disp('Note: using 2017b MATLAB layer definitions');
    layers = [ ...netTempDir
        imageInputLayer([217 217 1])
        convolution2dLayer(7, 24, 'Stride', 2,'Name','conv1')
        batchNormalizationLayer
        reluLayer
        maxPooling2dLayer(3,'Stride',2,'Name','maxPool1')
        convolution2dLayer(5, 48,'Stride',2,'Name','conv2')
        batchNormalizationLayer
        reluLayer
        maxPooling2dLayer(3,'Stride',2,'Name','maxPool11')
        convolution2dLayer(3,48,'Name','conv3')
        batchNormalizationLayer
        reluLayer
        maxPooling2dLayer(3,'Stride',2,'Name','maxPool3')
        convolution2dLayer(3,96,'Name','conv4','Padding','same')
        reluLayer
        convolution2dLayer(3,96,'Name','conv5','Padding','same')
        reluLayer
        maxPooling2dLayer(3,'Stride', 2,'Name','maxPool4')
        fullyConnectedLayer(1024,'Name','fc1')
        reluLayer
        dropoutLayer
        fullyConnectedLayer(1024,'Name','fc2')
        reluLayer
        dropoutLayer
        fullyConnectedLayer(length(labelSet),'Name','fc3')
        softmaxLayer
        classificationLayer]
end

%% Training options
if ~verLessThan('matlab', '9.3')
                        % 2017b
    options = trainingOptions('sgdm',...
        'MaxEpochs',100000, ...
        'ValidationFrequency',3000,...
        'MiniBatchSize',50,...
        'Verbose',true,...
        'Plots','training-progress',...
        'ValidationData',imdsValid,...
        'ValidationPatience', Inf,...
        'ExecutionEnvironment' , 'multi-gpu',...
        'CheckpointPath', checkPointDir);  
end

%% Start Training
trainedNet = trainNetwork(imdsTrain,layers,options);