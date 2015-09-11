function [] = timeCourseAnalysis(CMLs, outputDir, varargin)
%TimeCourseAnalysis of CombinedMovieList objects.
%In TimeCourseAnalysis, MLs in each CML are considered to be in similar
%condition and grouped together for plotting.
%
%SYNOPSIS function [] = timeCourseAnalysis(CMLs, outputDir, varargin)
%
%INPUT
%   CMLs        : (array of CombinedMovieList) objects or (cell of string)
%                 containingfull paths to CMLs
%   ouputDir    : (string) Directory where figures and analysis result will
%                 be stored
%   varargin    : name_value pairs for analysis parameter
%       'smoothingPara'         : parameter used for smoothing spline fit
%       'channel'               : Channel of MD to be analyzed. Default = 1
%       'doNewAnalysis'           : (logical) true: always do new analysis even if
%                                 the analysis has already been done.
%                                 false: avoid doing the analysis again if
%                                 analysis has already been done and the
%                                 analysis parameters are identical.
%                                 true by default
%       'doPartitionAnalysis'   : (logical) to analyzes trackPartitioning
%                                 process or not. false by default
%       'shiftPlotPositive'     : (logical) determines whether or not whole
%                                 plots are shifted so that no negative
%                                 time values are present. In other words,
%                                 minimum time point is taken to be the
%                                 zero. Default is false.
%
%Tae H Kim, July 2015

%% Input
%convert CMLs if it's cell of strings
nCML = numel(CMLs);
if iscellstr(CMLs)
    directory_CML = CMLs;
    clear CMLs
    for iCML = 1:nCML
        fprintf('Loading CombinedMovieList %g/%g\n', iCML, nCML);
        CMLs(iCML) = CombinedMovieList.load(directory_CML{iCML});
    end
elseif isa(CMLs, 'CombinedMovieList')
    directory_CML = arrayfun(@(x) x.getFullPath(), CMLs, 'UniformOutput', false); %#ok<NASGU>
else
    error('CMLs must be class object CombinedMovieList');
end
%input parser
ip = inputParser;
ip.CaseSensitive = false;
ip.KeepUnmatched = true;
ip.addRequired('outputDir', @ischar);
ip.addParameter('smoothingPara', .01, @(x) isnumeric(x) && x>=0 && x<=1);
ip.addParameter('channel', 1, @isnumeric);
ip.addParameter('doPartitionAnalysis', false, @(x) isnumeric(x) || islogical(x));
ip.addParameter('doNewAnalysis', true, @(x) isnumeric(x) || islogical(x));
ip.addParameter('shiftPlotPositive', false, @(x) islogical(x)||isnumeric(x));
ip.parse(outputDir, varargin{:});
%for easier access to ip.Result variables
smoothingPara = ip.Results.smoothingPara;
analysisPara.smoothingPara = smoothingPara;
analysisPara.shiftPlotPositive = ip.Results.shiftPlotPositive;
channel = round(ip.Results.channel);
doNewAnalysis = ip.Results.doNewAnalysis;
%used for Extra Analysis
analysisPara.doPartition = ip.Results.doPartitionAnalysis;
%checks if CMLs are loaded or not
%AND determines how many ML there are total
nMLTot = 0;
for iCML = 1:nCML
    progressDisp = fprintf('Loading Combined Movie List %g/%g\n', iCML, nCML); %loading progress display
    % if not loads it
    if numel(CMLs(iCML).movieLists_) ~= numel(CMLs(iCML).movieListDirectory_)
        CMLs(iCML).sanityCheck();
    end
    %checks if all MD has necessary processes
    arrayfun(@(x) MLCheck(x, analysisPara), CMLs(iCML).movieLists_);
    fprintf(repmat('\b', 1, progressDisp)); %loading progress display
    nMLTot = nMLTot + numel(CMLs(iCML).movieLists_);
end
%nested function for above: checking MD has necessary processes
    function [] = MLCheck(ML, parameter)
        nMD = numel(ML.movies_);
        for iMD = 1:nMD
            if isempty(ML.movies_{iMD}.getProcessIndex('MotionAnalysisProcess'))
                error(['MovieData ' ML.movies_{iMD}.movieDataFileName_ '\n at ' ML.movies_{iMD}.movieDataPath_ '\n does not contain MotionAnalysisProcess']);
            end
            if parameter.doPartition && isempty(ML.movies_{iMD}.getProcessIndex('PartitionAnalysisProcess'))
                error(['MovieData ' ML.movies_{iMD}.movieDataFileName_ '\n at ' ML.movies_{iMD}.movieDataPath_ '\n does not contain PartitionAnalysisProcess']);
            end
        end
    end
%% Main Time Course Analysis (CML-level)
%Progress Display
progressTextMultiple('Time Course Analysis', nMLTot);
%Using resultsIndTimeCourseMod.m to do basic analysis
%and extract time data and align
[summary, time, extra] = arrayfun(@CMLAnalyze, CMLs, 1:nCML, 'UniformOutput', false);
%nested function for above cellfun
%deals with individual CML
    function [CMLSummary, CMLTime, CMLExtra] = CMLAnalyze(CML, iCML)
        alignEvent = CML.analysisPara_.alignEvent;
        %[CMLSummary, CMLTime, CMLExtra] = arrayfun(@(x) MLAnalyze(x, alignEvent), CML.movieLists_, 'UniformOutput', false);
        nML = numel(CML.movieLists_);
        for iML = nML:-1:1
            [CMLSummary{iML}, CMLTime{iML}, CMLExtra{iML}] = MLAnalyze(CML.movieLists_(iML), alignEvent);
        end
        CMLSummary = vertcat(CMLSummary{:});
        CMLTime = vertcat(CMLTime{:});
        CMLExtra = vertcat(CMLExtra{:});
    end
%% Time Course Analysis (ML-level)
    function [MLSummary, MLTime, MLExtra] = MLAnalyze(ML, alignEvent)
        %Basic Analysis-------------------------------
        %new analysis if doNewAnalysis is true or analysis has not been
        %done yet
        TCAPIndx = ML.getProcessIndex('TimeCourseAnalysisProcess');
        %(I'm not exactly sure what resultsIndTimeCourseMod does)
        %It is used like blackbox that does the basic analysis
        if isempty(TCAPIndx) || isempty(ML.processes_{TCAPIndx}.summary_)
            MLSummary = resultsIndTimeCourseMod(ML, false);
            ML.addProcess(TimeCourseAnalysisProcess(ML));
            TCAPIndx = ML.getProcessIndex('TimeCourseAnalysisProcess');
            ML.processes_{TCAPIndx}.setSummary(MLSummary);
            ML.save;
        elseif doNewAnalysis
            MLSummary = resultsIndTimeCourseMod(ML, false);
            ML.processes_{TCAPIndx}.setSummary(MLSummary);
            ML.save;
        else
            MLSummary = ML.processes_{TCAPIndx}.summary_;
        end
        %Time Analysis---------------------------------
        timeProcIndx = ML.getProcessIndex('TimePoints');
        alignIndx = ML.processes_{timeProcIndx}.getIndex(alignEvent);
        offSet = datenum(ML.processes_{timeProcIndx}.times_{alignIndx});
        MLTime = cellfun(@(x) (datenum(x.acquisitionDate_) - offSet) .* 1440, ML.movies_, 'UniformOutput', false);
        MLTime = vertcat(MLTime{:});
        %Conditional (Extra) Analysis-------------------------
        MLExtra = cellfun(@MDAnalyze, ML.movies_, 'UniformOutput', false);
        MLExtra = vertcat(MLExtra{:});
        %progress text
        progressTextMultiple();
    end
%% Time Course Analysis (MD-level)
    function [MDExtra] = MDAnalyze(MD)
        %Need blank if not used
        MDExtra.blank = [];
        %loads 'partitionResult'
        if analysisPara.doPartition
            load(MD.processes_{channel, MD.getProcessIndex('PartitionAnalysisProcess')}.outFilePaths_{1});
        end
        %loads 'tracks' and 'diffAnalysisRes'
        if analysisPara.doPartition
            load(MD.processes_{channel, MD.getProcessIndex('MotionAnalysisProcess')}.outFilePaths_{1});
        end
        %--------------------TrackPartitioning analysis---------------
        if analysisPara.doPartition
            %Column 1 : immobile
            %Column 2 : confined
            %Column 3 : free
            %Column 4 : directional
            %Column 5 : undetermined
            %Column 6 : determined
            %Column 7 : total
            %Initialize
            partitionSum = [0 0 0 0 0];
            trackTotal = [0 0 0 0 0];
            arrayfun(@(x, y) partitionTrack(x.classification(:,2), y.partitionFrac), tracks, partitionResult);
            MDExtra.partitionFrac = partitionSum ./ trackTotal;
            MDExtra.partitionFrac(6) = sum(partitionSum(1:4)) ./ sum(trackTotal(1:4));
            MDExtra.partitionFrac(7) = sum(partitionSum) ./ sum(trackTotal);
        end
        %Nested function that looks at each track
        function partitionTrack(diffClass, partition)
            nSubTrack = numel(partition);
            for iSubTrack = 1:nSubTrack
                if diffClass(iSubTrack) == 0
                    trackTotal(1) = trackTotal(1) + 1;
                    partitionSum(1) = partitionSum(1) + partition(iSubTrack);
                elseif diffClass(iSubTrack) == 1
                    trackTotal(2) = trackTotal(2) + 1;
                    partitionSum(2) = partitionSum(2) + partition(iSubTrack);
                elseif diffClass(iSubTrack) == 2
                    trackTotal(3) = trackTotal(3) + 1;
                    partitionSum(3) = partitionSum(3) + partition(iSubTrack);
                elseif diffClass(iSubTrack) == 3
                    trackTotal(4) = trackTotal(4) + 1;
                    partitionSum(4) = partitionSum(4) + partition(iSubTrack);
                elseif isnan(diffClass(iSubTrack))
                    trackTotal(5) = trackTotal(5) + 1;
                    partitionSum(5) = partitionSum(5) + partition(iSubTrack);
                end
            end
        end
        %---------------------
    end
%% Format Change
%Using resultsCombTimeCourseMod.m to store data in correct format
summary = cellfun(@resultsCombTimeCourseMod, summary, 'UniformOutput', false);
%adds time and name (because that's not in resultsCombTimeCourseMod.m)
for iCML = 1:nCML
    summary{iCML}.time = time{iCML};
    summary{iCML}.name = CMLs(iCML).name_;
end
%adds extra analysis if applicable
if analysisPara.doPartition
    for iCML = 1:nCML
        summary{iCML}.partitionFrac = extra{iCML}.partitionFrac;
    end
end
%% Sort
%order data from earliest time point to latest
for iCML = 1:nCML
    [summary{iCML}.time, sortIndx] = sort(summary{iCML}.time);
    summary{iCML}.numAbsClass = summary{iCML}.numAbsClass(sortIndx, :);
    summary{iCML}.numNorm0Class = summary{iCML}.numNorm0Class(sortIndx, :);
    summary{iCML}.probClass = summary{iCML}.probClass(sortIndx, :);
    summary{iCML}.diffCoefClass = summary{iCML}.diffCoefClass(sortIndx, :);
    summary{iCML}.confRadClass = summary{iCML}.confRadClass(sortIndx, :);
    summary{iCML}.ampClass = summary{iCML}.ampClass(sortIndx, :);
    summary{iCML}.ampNormClass = summary{iCML}.ampNormClass(sortIndx, :);
    summary{iCML}.ampStatsF20 = summary{iCML}.ampStatsF20(sortIndx, :);
    summary{iCML}.ampStatsL20 = summary{iCML}.ampStatsL20(sortIndx, :);
    summary{iCML}.rateMS = summary{iCML}.rateMS(sortIndx, :);
    if analysisPara.doPartition
        summary{iCML}.partitionFrac = summary{iCML}.partitionFrac(sortIndx, :);
    end
end
%% Plot by Calling StandAlone Function
timeCourseAnalysis_StandAlone(summary, outputDir, 'smoothingPara', smoothingPara, 'showPartitionAnalysis', analysisPara.doPartition, 'shiftPlotPositive', analysisPara.shiftPlotPositive);
%% Save
save([outputDir filesep 'analysisData.mat'], 'directory_CML', 'analysisPara', 'summary');
end
