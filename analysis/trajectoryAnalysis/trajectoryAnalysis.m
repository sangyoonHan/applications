function [trajectoryDescription,trajectoryDescription2] = trajectoryAnalysis(data,ioOpt,testOpt)
%TRAJECTORYANALYSIS analyzes experimental and simulated microtubule trajectories and returns corresponding statistical descriptors
%
% SYNOPSIS  [trajectoryDescription,trajectoryDescription2] = trajectoryAnalysis(data,ioOpt,testOpt)
%
% INPUT  data(1:n) (opt): structure containing n different trajectories with fields
%           - distance   tx2 array [distance, sigmaDistance] in microns
%           - time       tx2 array [time, sigmaTime] in seconds
%           - timePoints tx1 array [timePoint#] 
%           - info       struct containing additional information about the data
%                  -tags    : cell containing the two strings designating
%                             the tags between which the distance is
%                             measured, e.g. {'spb1','cen1'}
%
%        ioOpt: optional structure with the following optional fields
%           - details       : return detailed analysis? [{0}/1]
%           - convergence   : add convergence data? [{0}/1]
%           - verbose       : whether to show any graphs/write to
%                             commandline or not. (vector)
%                             Verbose = 1 writes to commandline
%                             Verbose = 2 shows trajectories
%                             Verbose = 3 shows distributions
%                             Verboes = 4 shows clustering result
%                             Verbose = [1,2,3,4] shows all
%                             Verbose = [] or [0] does not show anything.
%                             Asking for savePaths is not affected by
%                             verbose settings
%           - saveTxt       : write statistics in text file? [0/{1}]
%           - saveTxtPath   : if saveTxt is 1, specify the path to save.
%                               if does not end with filesep, program
%                               assumes it to include the filename!
%                               otherwise the program asks for the save-path
%           - saveMat       : save output in mat file? [{0}/1]
%           - saveMatPath   : if saveMat is 1, specify the path to save.
%                               if does not end with filesep, program
%                               assumes it to include the filename!
%                               otherwise the program asks for the save-path
%           - fileNameList  : list of fileNames/descriptions of the input
%                               data
%           - expOrSim      : switch that tells whether data is from
%                               experiment or simulation ['e'/'s']. def: 'x'
%           - calc2d        : [{0}/1/2] depending on whether the
%                               normal 3D-data or the maxProjection
%                               or the in-focus-slice data should be
%                               used. Works only if data is being loaded by
%                               the program. Otherwise, you have to specify
%                               this option in
%                               calculateTrajectoryFromIdlist
%           - clusterData   : [{0}/1/2/3] uses EM clustering to find clusters
%                               of speeds. 1 clusters only at the end, 2
%                               will additionaly cluster for the convergence
%                               statistics, and 3 will cluster all
%                               
%        testOpt: optional structure with the following optional fields
%           - splitData     : [{0}/1] split data into two sets, returns two
%                               output arguments
%           - debug         : [{0}/1] turns on debug features
%           - randomize     : [{0}/1] randomize the input list
%           - clustermax    : max # of clusters the EM algorithm looks for
%
% OUTPUT trajectoryDescription
%           .individualStatistics(1:n)
%               .statistics
%               .details (opt)
%                    .dataListG
%                    .dataListS
%                    .distributions
%           .overallStatistics
%               OR
%           .convergenceStatistics
%           .overallDistribution
%           .info
%
%           to get all the fieldnames of the statistics struct, type "help trajectoryAnalysisMainCalcStats"
%
%c: 11/03 jonas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%===================================================================
%--------------DEFINE CONSTANTS ET AL-- (for test input, see below)
%===================================================================

%set defaults
showDetails = 1;
doConvergence = 0;
saveTxt = 1;
saveTxtPath = '';
saveTxtName = '';
saveMat = 0;
saveMatPath = '';
saveMatName = '';
verbose = [1,2]; 
fileNameList = {'data_1'};
calculateTrajectoryOpt.calc2d = 0; %1 or 2 if MP/in-focus slices only
expOrSim = 'x';
clusterData = 0;

% test opt
DEBUG = []; %[1,2] for groupUnits
splitData = 0; % whether or not to split the data into two sets (to check the homogenity of the sample)
randomize = 0; % whether or not to randomize the order of the input data
CLUSTERMAX = 5;

% other
fidTxt = [];

%defaults not in inputStructure (see also constants!)
writeShortFileList = 1; %writes everything on one line.
standardTag1 = 'spb1';
standardTag2 = 'cen1';


constants.TESTPROBABILITY = 0.95;
constants.PROB2SIDES = 1-(1-constants.TESTPROBABILITY)/2; % testprob for 2-sided test
constants.PROBOUTLIER = 0.8; % probability for ouliers. if lower, less fits get accepted
constants.PROBF = 0.7; % probability for whether linear fit is better than pause. if lower, there are less pauses
constants.STRATEGY = 1; % fitting strategy
constants.MINLENGTH = 2; % minimum length of a unit
constants.MAXDELETED = 0; % max number of deleted frames between two timepoints that is accepted
constants.DEBUG = DEBUG; 
constants.DOCLUSTER = clusterData; % this does not really belong here, but it's easiest to pass it with the constants
constants.CLUSTERMIN = 1; % min # of cluster the EM algorithm looks for
constants.CLUSTERMAX = CLUSTERMAX; % max # of cluster the EM algorithm looks for
constants.CLUSTERIND = 0; % try all individual k's?
constants.CLUSTERTRY = 10; % how many times the clustering algorithm is repeated
constants.CLUSTERMINWEIGHT = 0.05; % min weight to become a significant cluster

%build list of possible identifiers
%HOME/BIODATA/SIMDATA (also: NONE/NOFILE)
%every row is: identifier, path, lengthOfPath
identifierCell = cell(3,3);

identifierCell{3,1} = 'HOME';
h = (getenv('HOME'));
if ~isempty(h) & strcmp(h(end),filesep) %should actually never happen
    h = h(1:end-1);
end
identifierCell{3,2} = h;
identifierCell{3,3} = length(identifierCell{3,2});

identifierCell{2,1} = 'BIODATA';
b = (getenv('BIODATA'));
if ~isempty(b) & strcmp(b(end),filesep)
    b = b(1:end-1);
end
identifierCell{2,2} = b;
identifierCell{2,3} = length(identifierCell{2,2});

identifierCell{1,1} = 'SIMDATA';
s = (getenv('SIMDATA'));
if ~isempty(s) & strcmp(s(end),filesep)
    s = s(1:end-1);
end
identifierCell{1,2} = s;
identifierCell{1,3} = length(identifierCell{1,2});

clear h b s
%===================================================================
%----------END DEFINE CONSTANTS ET AL--
%===================================================================




%===================================================================
%--------------TEST INPUT--------
%===================================================================


%lookfor data
if nargin == 0 | isempty(data)
    loadData = 1;
else
    loadData = 0;
    
    %make sure input is complete
    if ~isfield(data,'distance') | ~isfield(data,'time') | ~isfield(data,'timePoints') 
        error('please check your input structure!')
    end
    
    %add the info.tags field if it's missing
    if ~isfield(data,'info') 
        data(1).info = [];
    end
    for nData = 1:length(data)
        if ~isfield(data(nData).info,'tags') | isempty(data(nData).info.tags)
            data(nData).info.tags = {standardTag1,standardTag2};
        end
    end
end

%go through options
%check every field for existence and change defaults - we do not need
%to consider all cases!! (whenever there is a "wrong" input, the default is taken)


if nargin < 2 | isempty(ioOpt)
    %do nothing
else
    if isfield(ioOpt,'details')
        if ioOpt.details == 1
            showDetails = 1;
        elseif ioOpt.details == 0 %assign anyway: defaults can change!
            showDetails = 0;
        end
    end
    if isfield(ioOpt,'convergence')
        if ioOpt.convergence == 1
            doConvergence = 1;
        elseif ioOpt.convergence == 0
            doConvergence = 0;
        end
    end
    if isfield(ioOpt,'saveTxt')
        if ioOpt.saveTxt == 0
            saveTxt = 0;
        elseif ioOpt.saveTxt == 1
            saveTxt = 1;
        end
    end
    
    %only now check for path
    if saveTxt & isfield(ioOpt,'saveTxtPath')
        %check whether we have been given a name or a path
        pathNameLength = length(ioOpt.saveTxtPath);
        fileSepList = strfind(ioOpt.saveTxtPath,filesep);
        if isempty(fileSepList)
            %assume we're just being given the name
            saveTxtPath = pwd;
            saveTxtName = ioOpt.saveTxtPath;
        elseif fileSepList(end)==pathNameLength
            %path ends with filesep, so no name
            saveTxtPath = ioOpt.saveTxtPath;
            saveTxtName = '';
        else
            %1:lastFileSep-1 = path, rest = filename
            saveTxtPath = ioOpt.saveTxtPath(1:fileSepList(end)-1);
            saveTxtName = ioOpt.saveTxtPath(fileSepList(end)+1:end);
        end
    end
    
    if isfield(ioOpt,'saveMat')
        if ioOpt.saveMat == 0
            saveMat = 0;
        elseif ioOpt.saveMat == 1
            saveMat = 1;
        end
    end
    
    %only now check for path
    if saveMat & isfield(ioOpt,'saveMatPath')
        %check whether we have been given a name or a path
        pathNameLength = length(ioOpt.saveMatPath);
        fileSepList = strfind(ioOpt.saveMatPath,filesep);
        if isempty(fileSepList)
            %assume we're just being given the name
            saveMatPath = pwd;
            saveMatName = ioOpt.saveMatPath;
        elseif fileSepList(end)==pathNameLength
            %path ends with filesep, so no name
            saveMatPath = ioOpt.saveMatPath;
            saveMatName = '';
        else
            %1:lastFileSep-1 = path, rest = filename
            saveMatPath = ioOpt.saveMatPath(1:fileSepList(end)-1);
            saveMatName = ioOpt.saveMatPath(fileSepList(end)+1:end);
        end
    end
    
    if isfield(ioOpt,'verbose')
        if any(ioOpt.verbose == 0) %works for [], too
            verbose = 0;
        else %if the user set something wrong, it won't have an effect
            verbose = ioOpt.verbose;
        end
    end
    if isfield(ioOpt,'fileNameList')
        if iscell(ioOpt.fileNameList)
            fileNameList = ioOpt.fileNameList;
        else
            error('ioOpt.fileNameList has to be a cell array of strings!')
        end
    end
    if isfield(ioOpt,'expOrSim')
        if length(ioOpt.expOrSim)>1 | ~isstr(ioOpt.expOrSim) | isempty(strfind('esx',ioOpt.expOrSim))
            error('expOrSim has to be one letter (e, s, or x)');
        else
            expOrSim=ioOpt.expOrSim;
        end
    end
    if isfield(ioOpt,'calc2d')
        calculateTrajectoryOpt.calc2d = ioOpt.calc2d;
    end
    if isfield(ioOpt,'clusterData')
        constants.DOCLUSTER = ioOpt.clusterData;
    end
end

%make sure that we have enough fileNames
if ~loadData %loading data we ourselves make sure it's ok
    lengthFNL = length(fileNameList);
    lengthData = length(data);
    if (lengthData > lengthFNL) 
        %if more data than fnl : fill fnl if length 1
        %if > 1 return error
        %if less data than fnl : return warning
        if lengthFNL == 1
            if isempty(fileNameList{1}) || strcmp(fileNameList{1},'data_1');
                dataStr = [repmat('data_',[lengthData,1]),num2str([1:lengthData]')]; %string data_  1 - data_999
                dataStr = regexprep(dataStr,' ','_'); %dataStr = data___1 - data_999
                fileNameList = cellstr(dataStr);
            else
                fileNameList = repmat(fileNameList,[lengthData,1]);
            end
        else
            error('not enough fileNames in ioOpt.fileNameList!')
        end
    elseif lengthData < lengthFNL
        warning('there are more fileNames than data - assignment of names could be inaccurate!')
    end
end
    

%check testOpt

if nargin < 3 | isempty(testOpt)
    %do nothing
else
    if isfield(testOpt,'splitData')
        splitData = testOpt.splitData;
    end
    if isfield(testOpt,'debug')
        DEBUG = testOpt.debug;
        constants.DEBUG = DEBUG;
    end
    if isfield(testOpt,'randomize')
        randomize = testOpt.randomize;
    end
    if isfield(testOpt,'clustermax')
        constants.CLUSTERMAX = testOpt.clustermax;
    end
end

%===================================================================
%----------END TEST INPUT--------
%===================================================================



%===================================================================
%----------assign output---
%===================================================================
trajectoryDescription = [];
trajectoryDescription2 = [];
%--------------------------


%===================================================================
%--------------LOAD DATA & ASK FOR PATHS---------
%===================================================================
if loadData
    
    %go to biodata. remember oldDir first
    oldDir = pwd;
    cdBiodata(2);
    
    %buld a list of data files
    fileList = loadFileList({'*.mte;*.mts;*.mtx','results files';...
            '*-data-??-???-????-??-??-??.mat','project data files'},[2;1]);
    
end

%---interrupt load data and ask for paths - calculating the trajectories
%takes too much time!

%first: textFile
if saveTxt
    if isempty(saveTxtName) %only ask if no name has been given before
        helpTxt = 'Please select filename,';
        if isempty(saveTxtPath)
            helpTxt = [helpTxt, ' pathname,'];
        else
            cd(saveTxtPath)
        end
        helpTxt = [helpTxt, ' and filetype to save the summary of the results as text file! If you press ''cancel'', the file will not be saved'];
        
        %tell the user what's going on
        ans = myQuestdlg(helpTxt,'','OK','cancel','OK');
        if strcmp(ans,'OK')
            cdBiodata(0);
            [saveTxtName,saveTxtPath,eos] = uiputfile({'*.mte','experimental MT data';...
                    '*.mts','simulation MT data';...
                    '*.mtx','any (mixed) MT data'},'save results as text file');
        else
            saveTxtName = 0;
        end
        
        %if user cancelled, nothing will be save                               
        if saveTxtName == 0
            saveTxt = 0;
        else
            
            %get expOrSim
            eosVect = ['esx'];
            expOrSim = eosVect(eos);
        end
    end
    
    %append the file extension
    if saveTxt & ~strcmp(saveTxtName(end-3),'.')
        saveTxtName = [saveTxtName,'.mt',expOrSim];
    else
        %the user has chose something him/herself
    end
end

%second: matFile
if saveMat
    if isempty(saveMatName) %only ask if no name has been given before
        helpTxt = 'Please select filename';
        if isempty(saveMatPath)
            helpTxt = [helpTxt, ' and pathname,'];
        else
            cd(saveMatPath)
        end
        helpTxt = [helpTxt, ' to save the results as mat-file! If you press ''cancel'', the file will not be saved'];
        
        %tell the user what's going on
        ans = myQuestdlg(helpTxt,'','OK','cancel','OK');
        if strcmp(ans,'OK')
        
        [saveMatName,saveMatPath] = uiputfile({'*.mat;*.mt*','MT-dynamics files'},'save results as mat file');
        else
            saveMatName = 0;
        end
        
        %if user cancelled, nothing will be save                               
        if saveMatName == 0
            saveMat = 0;
        end
        
    end
end
   
%resume loading data
if loadData
    
    %count number of files
    nFiles = length(fileList);
    
    if nFiles == 0 %& noOtherFiles
        disp('no files loaded - end evaluation')
        return
    end
        
    
%     %define vars
%     rawData(1:nFiles) = struct('distance',[],'time',[],'timePoints',[]);
    
    ct = 1; %change this counter if we allow passing data && loading
    
    problem = [];
    %load the data
    for i = 1:length(fileList)
        
        
        try
        %load all
        allDat = load(fileList(i).file);
        
        %load the idlist specified in lastResult
        eval(['idlist2use = allDat.',allDat.lastResult,';']);
        
        
        
        %---prepare calculate trajectory
        
        %choose tags
        %check whether there is a non-empty field opt, else just use spb1
        %and cen1
        flopt = fileList(i).opt; %increase readability
        if isempty(flopt) | length(flopt)<3  | isempty(flopt{2}) | isempty(flopt{3})%there could be more options in the future!
            tag1 = 'spb1';
            tag2 = 'cen1';
        else
            tag1 = fileList(i).opt{2};
            tag2 = fileList(i).opt{3};
        end
        
        %store identifier
        if isempty(fileList(i).opt) | isempty(fileList(i).opt{1})
            calculateTrajectoryOpt.identifier = 'NONE';
        else
            calculateTrajectoryOpt.identifier = fileList(i).opt{1};
        end
        
        %-----calculate trajectory
        data(ct) = calculateTrajectoryFromIdlist(idlist2use,allDat.dataProperties,tag1,tag2,calculateTrajectoryOpt);
        %-------------------------
        
        %remember fileName
        fileNameList{ct} = fileList(i).file;
        ct = ct + 1;
        
        
        catch
            if isempty(problem)
                problem = lasterr;
            end
            disp([fileList(i).file, ' could not be loaded:',char(10),problem])
        end
        
        clear lr id dp
    end %for i = 1:length(fileList)
    cd(oldDir);
end %if loadFiles

clear fileList helpTxt problem i nFiles allDat

%===================================================================
%----------END LOAD DATA  & ASK FOR PATHS---------
%===================================================================



%===================================================================
%--------------WRITE FILE-LIST--------
%===================================================================

%already write the fileList for the results-file (if selected): if
%something happens during the calculations, at least the list is not lost.
if saveTxt
    %create the file
    fidTxt = fopen([saveTxtPath,saveTxtName],'w');
    
    %if we selected to write the short version of the fileList, we do not
    %use a line break between identifier/options and the rest of the
    %filename
    if writeShortFileList
        separationString = '   ';
    else
        separationString = '\n';
    end
    
    %write introduction to file
    fprintf(fidTxt,'%s\n%s\n%s\n%s\n','%  MICROTUBULE DYNAMICS ANALYSIS - list of filenames',...
        '%    this file contains a list of filenames that can be used for MT dynamic analysis',...
        '%    the list is made up as: Identifier#{''tag1'',''tag2''}# \n  restOfPathIncludingFileName, where Identifier is the environment variable for the particular path',...
        '%    Please do not uncomment this header or delete the ''***'' that mark the end of the filenames. Fileseps can be windows or linux type.');
    
    
    %now loop through the fileNameList, find the identifier and write the
    %file
    for nFile = 1:length(fileNameList)
        
        %init variables
        identifier = '';
        restOfFileName = '';
        tagList = {''};
        
        %read tagList
        tagList = data(nFile).info.tags;
        
        %read fileName
        fileName = fileNameList{nFile};
        lengthFileName = length(fileName);
        
        %now sieve the fileName until we find the identifier, or know for
        %sure that there isn't any
        %use if/elseif, because we want biodata/simdata to override home
        if ~isempty(identifierCell{1,2}) & strcmpi(identifierCell{1,2},fileName(1:min(identifierCell{1,3},lengthFileName))) %check for SIMDATA
            
            %read identifier, restOfFileName. There is no filesep at the
            %end of the identifier path, so the restOfFileName should start
            %with one
            identifier = identifierCell{1,1};
            restOfFileName = fileName(identifierCell{1,3}+1:end);
            
        elseif ~isempty(identifierCell{2,2}) & strcmpi(identifierCell{2,2},fileName(1:min(identifierCell{2,3},lengthFileName))) %check for BIODATA
            
            %read identifier, restOfFileName. There is no filesep at the
            %end of the identifier path, so the restOfFileName should start
            %with one
            identifier = identifierCell{2,1};
            restOfFileName = fileName(identifierCell{2,3}+1:end);
            
        elseif ~isempty(identifierCell{3,2}) & strcmpi(identifierCell{3,2},fileName(1:min(identifierCell{3,3},lengthFileName))) %check for HOME
            
            %read identifier, restOfFileName. There is no filesep at the
            %end of the identifier path, so the restOfFileName should start
            %with one
            identifier = identifierCell{3,1};
            restOfFileName = fileName(identifierCell{3,3}+1:end);
            
        elseif exist(fileName) %check for NONE
            
            %assign none
            identifier = 'NONE';
            restOfFileName = fileName;
            
        else %we have no valid filename at all
            
            identifier = 'NOFILE';
            restOfFileName = fileName;
            
        end %check for identifier and restOfFilename
        
        %now write everything to file
        fprintf(fidTxt,['%s#%s#%s',separationString,'%s\n'], identifier, tagList{1}, tagList{2}, restOfFileName);
           
        
    end %for nFile = 1:length(fileNameList)
    
    %close off the file by writing '***'
    fprintf(fidTxt,'\n***\n\n');
    
    %do not close file yet - we will write more!
end
%===================================================================
%----------END WRITE FILE-LIST--------
%===================================================================

%===================================================================
%----------COMPARE TWO DATA SETS / RANDOMIZE
%===================================================================

if splitData
    nData = length(data);
    if mod(nData,2)~=0
        disp('warning: odd number of files, not taking into account last file')
        nData = nData - 1;
    end
    % create two sets (thanks to Aaron for the idea!)
    % get nData random numbers, sort, take the first nData/2 indices for
    % the first half etc.
    rankList = randperm(nData);
    dataSet1 = rankList(1:nData/2);
    dataSet2 = rankList(nData/2+1:end);
    
    data2 = data(dataSet2);
    data  = data(dataSet1); % use data for data1 - makes coding easier
    fileNameList2 = fileNameList(dataSet2);
    fileNameList  = fileNameList(dataSet1); % same as above
    
elseif randomize
    
    % put data into random order
    nData = length(data);
    data = data(randperm(nData));
    
    % if splitData, we have everything random already, so no need
    
end
    
%===================================================================
%------END COMPARE TWO DATA SETS-----
%===================================================================


%===================================================================
%--------------CALCULATE---------
%===================================================================

if ~isempty(DEBUG) | ~saveTxt % if no file, we do not care
    trajectoryDescription = trajectoryAnalysisMain(data,constants,showDetails,doConvergence,verbose,fileNameList);
    if splitData % do the second set
        trajectoryDescription2 = trajectoryAnalysisMain(data2,constants,showDetails,doConvergence,verbose,fileNameList2);
    end
else
    try
        trajectoryDescription = trajectoryAnalysisMain(data,constants,showDetails,doConvergence,verbose,fileNameList);
        if splitData %do the second set
            trajectoryDescription2 = trajectoryAnalysisMain(data2,constants,showDetails,doConvergence,verbose,fileNameList2);
        end
        
    catch
        if ~isempty(fidTxt) 
            fclose(fidTxt);
        end
        error(lasterr)
    end
end
%===================================================================
%----------END CALCULATE---------
%===================================================================


%-----add additional info for trajDes here
%
%----------------------------------------

%===================================================================
%-------------STORE DATA---------
%===================================================================

%splitData only works for saveMat

%save mat file first, because it's less lines
if saveMat
    save([saveMatPath,saveMatName],'trajectoryDescription');
    if splitData
        save([saveMatPath,[saveMatName,'_2']],'trajectoryDescription2');
    end
end

%save text file
if saveTxt
    
    %get fieldNames for saving
    statisticsTitles = fieldnames(trajectoryDescription.individualStatistics(1).summary);
    numStats = length(statisticsTitles);
    
    %---write overall statistics, date, probabilities
    fprintf(fidTxt,['\n\n---OVERALL STATISTICS---\n']);
    fprintf(fidTxt,[nowString,'\n']);
    fprintf(fidTxt,'Slope   Test: %1.3f\n',constants.TESTPROBABILITY);
    fprintf(fidTxt,'Pause   Test: %1.3f\n',constants.PROBF);
    fprintf(fidTxt,'Outlier Test: %1.3f\n\n\n',constants.PROBOUTLIER);
    %fprintf(fidTxt,'Clustering:')
    
    %read them first
    if doConvergence
        overallStats = trajectoryDescription.convergenceStatistics(end);
    else
        overallStats = trajectoryDescription.overallStatistics;
    end
    %make cell for writing down
    statisticsCell = [statisticsTitles,struct2cell(overallStats)];
    
    for nStat = 1:numStats
        %(I so love these formatted strings)
        txt2write  = statisticsCell{nStat,1};
        vars2write = [statisticsCell{nStat,2:end}];
        switch length(vars2write)
            case 1
                fprintf(fidTxt,'%25s\t%5.6f\n',txt2write,vars2write);
            case 2
                fprintf(fidTxt,'%25s\t%5.6f\t%5.6f\n',txt2write,vars2write);
        end
    end
    
    %---loop through the individual trajectories, print their overall statistics
    fprintf(fidTxt,'\n\n---individual data---');
    numFiles = length(fileNameList);
    for nFile = 1:numFiles
        %write a nice title
        fprintf(fidTxt,'\n\noverall statistics for %s\n',fileNameList{nFile});
        
        %read the list
        statisticsCell = [statisticsTitles,struct2cell(trajectoryDescription.individualStatistics(nFile).summary)];
        for nStat = 1:numStats
            txt2write  = statisticsCell{nStat,1};
            vars2write = [statisticsCell{nStat,2:end}];
            switch length(vars2write)
                case 1
                    fprintf(fidTxt,'%25s\t%5.6f\n',txt2write,vars2write);
                case 2
                    fprintf(fidTxt,'%25s\t%5.6f\t%5.6f\n',txt2write,vars2write);
            end
        end
    end
    %DO NOT UNCOMMENT - USE ONLY AS TEMPLATE           
    %         %loop through individual trajectories, print measurements
    %         fprintf(fidData,'\n\n---individual data II---');
    %         for i = 1:numData
    %             fprintf(fidData,'\n\ndetailed statistics for %s\n',mtdDat(i).info.name);
    %             
    %             
    %             %group
    % %             numEntries = size(mtdDat(i).stateList.group,1);
    % %             fprintf(fidData,'group data [counter, state(1/2/-1/-2/0), startIdx#, endIdx#, deltaT, deltaD, speed1, speedSigma1, speed2, speedSigma2, avg. time in undetermined state, sum of single counters, significance1, significance2]\n');
    % %             for j = 1:numEntries
    % %                 fprintf(fidData,'%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\n*',mtdDat(i).stateList.group(j,:));
    % %             end
    %         end
    %-----------------------
    
    fclose(fidTxt);
end %if saveTxt


%===================================================================
%---------END STORE DATA---------
%===================================================================
