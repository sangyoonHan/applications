function [dataStats,errFlag] = analyzeMtTrajectory(model,modelParam,...
    initialState,runInfo,saveTraj,saveStats)
%ANALYZEMTTRAJECTORY statistically analyzes trajectories of microtubules
%
%SYNOPSIS [dataStats,errFlag] = analyzeMtTrajectory(model,modelParam,...
%   initialState,runInfo,saveTraj,saveToFile)
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
%                           function is called from
%
%OUTPUT errFlag   : 0 if function executes normally, 1 otherwise.
%       dataStats : Statistical descriptors of trajectory. 
%
%Khuloud Jaqaman, 9/03

errFlag = 0;

%check if correct number of arguments were used when function was called
if nargin ~= nargin('analyzeMtTrajectory')
    disp('--analyzeMtTrajectory: Incorrect number of input arguments!');
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
    disp('--analyzeMtTrajectory: The size of array saveTraj should be equal to maxNumSim!')
    errFlag = 1;
    dataStats = [];
    return;
end

if model ~= 1 && model ~= 2
    disp('--analyzeMtTrajectory: The variable "model" should be either 1 or 2!');
    errFlag = 1;
end
if maxNumSim < 1
    disp('--analyzeMtTrajectory: At least 1 simulation should be done!');
    errFlag = 1;
end
if totalTime <= 0
    disp('--analyzeMtTrajectory: Total time should be positive!');
    errFlag = 1;
end
if simTimeStep <= 0
    disp('--analyzeMtTrajectory: Simulation time step should be positive!');
    errFlag = 1;
end
if timeEps > 1
    disp('--analyzeMtTrajectory: The product of the time step and maximum rate ');
    disp('  constant should be smaller than 1!');
    errFlag = 1;
end
if expTimeStep <= 0
    disp('--analyzeMtTrajectory: Experimental time step should be positive!');
    errFlag = 1;
end
if aveInterval <= 0
    disp('--analyzeMtTrajectory: Averaging interval should be positive and smaller than exp. time step!');
    errFlag = 1;
end
for bigIter = 1:maxNumSim
    if saveTraj(bigIter).saveOrNot ~= 0 && saveTraj(bigIter).saveOrNot ~= 1
        disp('--analyzeMtTrajectory: "saveTraj.saveOrNot" should be 0 or 1!');
        errFlag = 1;
    end
end
if saveStats.saveOrNot ~= 0 && saveStats.saveOrNot ~= 1
    disp('--analyzeMtTrajectory: "saveStats.saveOrNot" should be 0 or 1!');
    errFlag = 1;
end
if errFlag
    disp('--analyzeMtTrajectory: Please fix input data!');
    dataStats = [];
    return;
end

%in case a non-integer value is assigned to maxNumSim,
maxNumSim = round(maxNumSim); %round it to nearest integer

%make sure simTimeStep is at least 2 times smaller than aveInterval
if simTimeStep > aveInterval/2
    simTimeStep = aveInterval/2;
end

%get maxNumSim trajectories of totalTime seconds each 
for bigIter = 1:maxNumSim
    
    %get MT trajectory (stored in mtLength) under current conditions.
    %forcedRescue: stores time points at which rescue is forced in model #1.
    %capSize: stores number of GTP-"units" making up cap at every time step
    %in model #2.
    switch model
        case 1
            [mtLength1,forcedRescue,errFlag] = mtDynInstability(...
                modelParam,initialState,totalTime+expTimeStep,...
                simTimeStep,timeEps,saveTraj(bigIter));
            if errFlag
                return;
            end
            mtLength(:,bigIter) = mtLength1;
        case 2
            [mtLength1,capSize1,errFlag] = mtGTPCapLDepK(modelParam,...
                initialState,totalTime+expTimeStep,simTimeStep,...
                timeEps,saveTraj(bigIter));
            if errFlag
                return;
            end
            mtLength(:,bigIter) = mtLength1;
            capSize(:,bigIter) = capSize1;
        otherwise
            disp('--analyzeMtTrajectory: The variable "model" should be either 1 or 2!');
            errFlag = 1;
            return;
    end
    
    %shift the whole trajectory to make it positive in case there are unphysical
    %negative lengths of MT that are not understood by "calcMTDynamics".
    minminLength(bigIter) = min(mtLength(:,bigIter));
    if minminLength(bigIter) < 0
        mtLength(:,bigIter) = mtLength(:,bigIter) - 1.1*minminLength(bigIter);
    else
        minminLength(bigIter) = 0;
    end
    
end

for bigIter = 1:maxNumSim
    
    %sample trajectory at instances of experimental measurement (expTimeStep). 
    %Use the average value of the position and its standard deviation in 
    %an appropriate interval (aveInterval) around the instance as the 
    %position and error at that instance.
    [mtLengthAve(:,bigIter),mtLengthSD(:,bigIter),errFlag] = averageMtTraj(...
        mtLength(:,bigIter),simTimeStep,expTimeStep,aveInterval);
    if errFlag
        return;
    end
    
    %get rid of unreasonably small standard deviations which mess up the statistical 
    %analysis in "trajectoryAnalysis".
    %compute the chi2 cumulative distribution
    p = chi2cdf(mtLengthSD(:,bigIter),1);
    %find indices of very small STDs
    badIdx = find(p<0.001);
    %assign a large value to those entries
    mtLengthSD(badIdx,bigIter) = 999;
    %assign to them 0.8 the new minimum value 
    mtLengthSD(badIdx,bigIter) = 0.8*min(mtLengthSD(:,bigIter));
    
end

%write data in correct format for statistical analysis
trajLength = length(mtLengthAve(:,1));
for bigIter = 1:maxNumSim
    data(bigIter).distance = [mtLengthAve(:,bigIter) mtLengthSD(:,bigIter)]; %distance + std
    data(bigIter).time = [[0:trajLength-1]'*expTimeStep zeros(trajLength,1)]; %time + std
    data(bigIter).timePoints = [1:trajLength]'; %time point number
    data(bigIter).info.tags = {'spb1','cen1'}; %tag labels
end

%additional input variables for statistical analysis function
ioOpt.verbose = 0;
ioOpt.convergence = 0; %check descriptor convergence as a function of sample size
ioOpt.saveTxt = 0;
%ioOpt.saveTxtPath = '/home/kjaqaman/matlab/chromdyn/simulations/hingeModel/stat0.txt'; %save results in file
ioOpt.expOrSim = 's'; %specify that it is simulation data

%perform Jonas' statistical analysis and get restults in dataStats
dataStats = trajectoryAnalysis(data,ioOpt);

%save data if user wants to
if saveStats.saveOrNot
    if isempty(saveStats.fileName)
        save(['dataStats-',nowString],'dataStats'); %save in file
    else
        save(saveStats.fileName,'dataStats'); %save in file (directory specified through name)
    end
end

save('simTraj','mtLengthAve');
