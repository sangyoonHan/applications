function [dataStats,errFlag] = analyzeHingeModel(model,modelParam,...
    initialState,runInfo,saveTraj,saveStats,numTrials,hingeParam,hingeInit)
%ANALYZEHINGEMODEL statistically analyzes trajectories of microtubules
%
%SYNOPSIS [dataStats,errFlag] = analyzeHingeModel(model,modelParam,...
%    initialState,runInfo,saveTraj,saveStats,numTrials,hingeParam,hingeInit)
%
%INPUT  model        : model of interest. 1 - mtDynInstability,
%                      2 - mtGTPCapLDepK.
%       modelParam   : Parameters needed for the model of interest.
%       initialState : Variables defining the initial state of the
%                      microtubule, according to the model of interest.
%       runInfo      : Structure containing information for run(s):
%           .maxNumSim    : Number of simulations to be done using given
%                           model and parameters.
%           .totalTime    : Total time of each simulation, in seconds.
%           .simTimeStep  : Time intervale used in simulations, in seconds.
%           .timeEps      : Value of the product of simulation time step and 
%                           maximum rate constant.
%           .expTimeStep  : Time interval, in seconds, at which experimental 
%                           measurements are taken.
%           .aveInterval  : Time interval, in seconds, over which
%                           simulation data is averaged to "reproduce" experimental data.
%       saveTraj     : Array of structures defining whether and where trajectories
%                      generated by mtGTPCapLDepK will be saved. It
%                      contains two elements, saveOrNot and fileName, which
%                      are both described below for saveStats.
%       saveStats    : Structure defining whether and where results will be
%                      saved.
%           .saveOrNot    : 1 if user wants to save, 0 if not.
%           .fileName     : name (including location) of file where results 
%                           will be saved. If empty and saveOrNot is 1, the name
%                           is chosen automatically to be
%                           "dataStats-day-month-year-hour-minute-second",
%                           and the data is saved in directory where
%                           function is called from.
%       numTrials    : Number of runs with different offset conditions,
%                      added to the same MT trajectory.
%       hingeParam   : Structure (of length numTrials) with parameters needed for 
%                      the hinge model of GFP tag next to kinetochore.
%       hingeInit    : numTrials by 3 vector of initial positions of tags.
%
%OUTPUT dataStats  : Statistical descriptors of trajectory. 1st entry is for trajectory
%                    without offset, 2nd through (numTrials+1)st entries are
%                    for trajectories with the numTrials different offsets.
%       errFlag    : 0 if function executes normally, 1 otherwise.
%       
%Khuloud Jaqaman, 9/03

errFlag = 0;

%check if correct number of arguments were used when function was called
if nargin ~= nargin('analyzeHingeModel')
    disp('--analyzeHingeModel: Incorrect number of input arguments!');
    errFlag  = 1;
    return;
end

maxNumSim   = runInfo.maxNumSim;
totalTime   = runInfo.totalTime;
simTimeStep = runInfo.simTimeStep;
timeEps     = runInfo.timeEps;
expTimeStep = runInfo.expTimeStep;
aveInterval = runInfo.aveInterval;

%check input data
if length(saveTraj) ~= maxNumSim
    disp('--analyzeHingeModel: The size of array saveTraj should be equal to maxNumSim!')
    errFlag = 1;
    dataStats = [];
    return;
end

if model ~= 1 && model ~= 2
    disp('--analyzeHingeModel: The variable "model" should be either 1 or 2!');
    errFlag = 1;
end
if maxNumSim < 1
    disp('--analyzeHingeModel: At least 1 simulation should be done!');
    errFlag = 1;
end
if totalTime <= 0
    disp('--analyzeHingeModel: Total time should be positive!');
    errFlag = 1;
end
if simTimeStep <= 0
    disp('--analyzeHingeModel: Simulation time step should be positive!');
    errFlag = 1;
end
if timeEps > 1
    disp('--analyzeHingeModel: The product of the time step and maximum rate ');
    disp('  constant should be smaller than 1!');
    errFlag = 1;
end
if expTimeStep <= 0
    disp('--analyzeHingeModel: Experimental time step should be positive!');
    errFlag = 1;
end
if aveInterval <= 0
    disp('--analyzeHingeModel: Averaging interval should be positive and smaller than exp. time step!');
    errFlag = 1;
end
for bigIter = 1:maxNumSim
    if saveTraj(bigIter).saveOrNot ~= 0 && saveTraj(bigIter).saveOrNot ~= 1
        disp('--analyzeHingeModel: "saveTraj.saveOrNot" should be 0 or 1!');
        errFlag = 1;
    end
end
if saveStats.saveOrNot ~= 0 && saveStats.saveOrNot ~= 1
    disp('--analyzeHingeModel: "saveStats.saveOrNot" should be 0 or 1!');
    errFlag = 1;
end
if numTrials <= 0
    disp('--analyzeHingeModel: "numTrials" must be greater than or equal to 1!');
    errFlag = 1;
end
if length(hingeParam) ~= numTrials
    disp('--analyzeHingeModel: "hingeParam" should be of length "numTrials"!');
    errFlag = 1;
end
if size(hingeInit,1) ~= numTrials
    disp('--analyzeHingeModel: "hingeInit" should have "numTrials" rows!');
    errFlag = 1;
end
if errFlag
    disp('--analyzeHingeModel: Please fix input data!');
    dataStats = [];
    return;
end

%in case a non-integer value is assigned to maxNumSim,
maxNumSim = round(maxNumSim); %round it to nearest integer

%make sure simTimeStep is at least 2 times smaller than aveInterval
if simTimeStep > aveInterval/2
    simTimeStep = aveInterval/2;
end

%get maxNumSim MT trajectories of totalTime+expTimeStep seconds each 
for bigIter = 1:maxNumSim
    
    %get MT trajectory (stored in mtLength) under current conditions.
    %forcedRescue: stores time points at which rescue is forced in model #1.
    %capSize: stores number of GTP-"units" making up cap at every time step
    %in model #2.
    switch model
        case 1
            [mtLength(:,bigIter),forcedRescue,errFlag] = mtDynInstability(...
                modelParam,initialState,totalTime+expTimeStep,...
                simTimeStep,timeEps);
            if errFlag
                return;
            end
        case 2
            [mtLength(:,bigIter),capSize,errFlag] = mtGTPCapLDepK(...
                modelParam,initialState,totalTime+expTimeStep,simTimeStep,...
                timeEps,saveTraj(bigIter));
            if errFlag
                return;
            end
    otherwise
            disp('--analyzeHingeModel: The variable "model" should be either 1 or 2!');
            errFlag = 1;
            return;
    end
    
    %shift the whole trajectory to make it positive in case there are unphysical
    %negative lengths of MT.
    minminLength(bigIter) = min(mtLength(:,bigIter));
    if minminLength(bigIter) < 0
        mtLength(:,bigIter) = mtLength(:,bigIter) - 1.1*minminLength(bigIter);
    else
        minminLength(bigIter) = 0;
    end
    
end

%get numTrials trajectories (of same length as MT trajectories) of tag relative to microtubule tip
for trialIter = 1:numTrials    
    [tagPos(:,:,trialIter),errFlag] = hingeModel(hingeParam(trialIter),...
        hingeInit(trialIter,:),totalTime+expTimeStep,simTimeStep);
    if errFlag
        return;
    end
end

%write MT trajectory data (without any offset) in correct format for Jonas' code
for bigIter = 1:maxNumSim    

    %sample trajectory at instances of experimental measurement (expTimeStep). 
    %Use the average value of the position and its standard deviation in 
    %an appropriate interval (aveInterval) around the instance as the 
    %position and error at that instance.
    [mtLengthAve,mtLengthSD,errFlag] = averageMtTraj(...
        mtLength(:,bigIter),simTimeStep,expTimeStep,aveInterval);
    if errFlag
        return;
    end

    %find length of averaged trajectory
    trajLength = length(mtLengthAve);
    
    %get rid of unreasonably small standard deviations which mess up the statistical
    %analysis in "trajectoryAnalysis".
    %compute the chi2 cumulative distribution of mtLengthSD
    p = chi2cdf(mtLengthSD,1);
    %find indices of very small STDs
    badIdx = find(p<0.001);
    %assign a large value to those entries
    mtLengthSD(badIdx) = 999;
    %assign to them 0.8 the new minimum value 
    mtLengthSD(badIdx) = 0.8*min(mtLengthSD);

    %write data in correct format for statistical analysis
    data(bigIter).distance = [mtLengthAve mtLengthSD]; %distance + std
    data(bigIter).time = [[0:trajLength-1]'*expTimeStep zeros(trajLength,1)]; %time + std
    data(bigIter).timePoints = [1:trajLength]'; %time point number
    data(bigIter).info.tags = {'spb1','cen1'}; %tag labels

    inputData(1).fileNameList{bigIter} = 'noOffset';
    
end

inputData(1).data = data;

%combine MT trajectory with tag position, sample at instances of experimental 
%measurement, and do the same statistical analysis 
for trialIter = 1:numTrials
    
    for bigIter = 1:maxNumSim    
    
        %get SPB to Tag vector
        SPBToTag(:,1) = mtLength(:,bigIter) + tagPos(:,1,trialIter);
        SPBToTag(:,2) = tagPos(:,2,trialIter);
        SPBToTag(:,3) = tagPos(:,3,trialIter);
        
        %sample trajectory at instances of experimental measurement
        for i=1:3
            [SPBToTagAve(:,i),SPBToTagSD(:,i),errFlag] = averageMtTraj(...
                SPBToTag(:,i),simTimeStep,expTimeStep,aveInterval);
        end
        if errFlag
            return;
        end
        
        %calculate distance between SPB and tag
        distance = sqrt((sum((SPBToTagAve.^2)'))'); 
        %find std of distance between SPG and tag (calculated through error propagation) 
        distErr = sqrt((sum(((SPBToTagAve.*SPBToTagSD).^2)'))'./distance.^2); 
        
        %get rid of unreasonably small SPBToTagSD
        p = chi2cdf(distErr,1);
        badIdx = find(p<0.001);
        distErr(badIdx) = 999;
        distErr(badIdx) = 0.8*min(distErr);
        
        %write data in correct format for Jonas' code       
        data(bigIter).distance = [distance distErr];
        inputData(trialIter+1).fileNameList{bigIter} = 'withOffset';

    end
    
    inputData(trialIter+1).data = data;
    
end

%additional input variables for statistical analysis function
ioOpt.verbose = 0;
ioOpt.saveTxt = 0;
ioOpt.expOrSim = 's'; %specify that it is simulation data

%perform Jonas' statistical analysis and get restults in dataStats
dataStats = trajectoryAnalysis(inputData,ioOpt);