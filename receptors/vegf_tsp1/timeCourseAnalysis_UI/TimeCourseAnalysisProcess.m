classdef TimeCourseAnalysisProcess < Process
    %MovieList Process that stores the result of timeCourseAnalysis 
    %
    %PROPERTIES
    %       summary_: Structure array storing various results for each
    %                 movie, ordered based on their time (corresponding
    %                 to caseTimeList). Contains the fields: 
    %           .diffSummary         : Diffusion analysis summary, as output
    %                                  by summarizeDiffAnRes.
    %           .diffCoefMeanPerClass: Mean diffusion coefficient per motion
    %                                  class. Order: Immobile, confined, free,
    %                                  directed, undetermined.
    %           .confRadMeanPerClass : Mean confinement radius per motion
    %                                  class. Same order as above.
    %           .ampMeanPerClass     : Mean particle amplitude per motion
    %                                  class. Rows in same order as above.
    %                                  Columns: first for "absolute" amplitude,
    %                                  second for amplitude normalized by
    %                                  monomer amplitude, as derived from modal
    %                                  analysis of particles in last 20 frames
    %                                  of each movie.
    %           .ampStatsF20         : Amplitude statistics in first 20
    %                                  frame of each movie. 
    %                                  Order: mean amplitude, first mode
    %                                  mean, first mode std, first mode
    %                                  fraction, number of modes, mean
    %                                  normalized by monomer amplitude (see
    %                                  ampMeanPerClass for details).
    %           .ampStatsL20         : Same as ampStatsF20, but for last 20
    %                                  frames of movie.
    %      time_      (CML and ML only)
    %      extra_     (CML and ML only)
    %      timeCourseStartTime_ (CML and ML only)

    
    properties
        summary_
        time_
        extra_
        timeCourseStartTime_
    end
    %% Constructor
    methods(Access = public)
        function obj = TimeCourseAnalysisProcess(owner)
            %obj.owner_ = owner;
            %obj.name_ = getName();
            obj = obj@Process(owner, TimeCourseAnalysisProcess.getName());
            obj.summary_ = [];
            obj.outFilePaths_ = [owner.outputDirectory_ filesep 'timeCourseAnalysis'];
            obj.setParameters(obj.getDefaultParams);
            obj.funName_ = obj.getFunction(owner);
        end
        function sanityCheck(obj)
            try
                % check if this works, otherwise clear it
                test = nargin(obj.funName_);
            catch
                obj.funName_ = [];
            end
            if(isempty(obj.funName_))
                obj.funName_ = obj.getFunction(obj.owner_);
            else
                funInfo = functions(obj.funName_);
                if(~strcmp(funInfo.type,'anonymous'))
                    obj.funName_ = obj.getFunction;
                end
            end
            if(isempty(obj.outFilePaths_))
                obj.outFilePaths_ = [obj.owner_.outputDirectory_ filesep 'timeCourseAnalysis'];
            end
            sanityCheck@Process(obj);
        end
    end
    %% Get Set
    methods
        function setSummary(obj, summary)
            obj.summary_ = summary;
        end
    end
    %% Adapter Methods for MovieObjects
    methods
        function fun = getFunction(proc,owner)
            if(nargin < 2)
                owner = proc.getOwner;
            end
            switch(class(owner))
                case 'CombinedMovieList'
                    fun = @proc.CML_fxn;
                case 'MovieList'
                    fun = @proc.ML_fxn;
                case 'MovieData'
                    fun = @proc.MD_fxn;
                otherwise
                    if(isa(owner,'MovieData'))
                        % Allow for subclasses
                        fun = @proc.MD_fxn;
                    else
                        error('TimeCourseAnalysisProcess:incompatibleOwner', ...
                            'Owner must be a CombinedMovieList, MovieList, or MovieData');
                    end
            end
        end
        function CML_fxn(proc,CML,params,varargin)
        % CML_fxn Adapter for timeCourseAnalysis.CMLAnalyze
        % CML: CombinedMovieList
        % params: (optional) struct, see timeCourseAnalysis.CMLAnalyze
        %         default: Process.getParameters()
        %
        % Output stored in Process
            if(nargin < 3)
                params = proc.getParameters();
            end
            if(isempty(params.outputDir))
                params.outputDir = proc.outFilePaths_;
            end
            [proc.summary_, proc.time_, proc.extra_, proc.timeCourseStartTime_] = ...
                timeCourseAnalysis.CMLAnalyze(CML,params,varargin{:});
        end
        function ML_fxn(proc,ML,alignEvent,params,varargin)
        % CML_fxn Adapter for timeCourseAnalysis.MLAnalyze
        % CML: CombinedMovieList
        % alignEvent: (optional) default: params.alignEvent
        % params: (optional) struct, see timeCourseAnalysis.MLAnalyze
        %         default: Process.getParameters()
        %
        % Output stored in Process
            if(nargin < 4)
                if(nargin > 2 && isstruct(alignEvent))
                    params = alignEvent;
                    alignEvent = params.alignEvent;
                else
                    params = proc.getParameters();
                end
            end
            if(nargin < 3)
                alignEvent = params.alignEvent;
            end
            if(isempty(params.outputDir))
                params.outputDir = proc.outFilePaths_;
            end
            [proc.summary_, proc.time_, proc.extra_, proc.timeCourseStartTime_] = ...
                timeCourseAnalysis.MLAnalyze(ML,alignEvent,params);
        end
        function MD_fxn(proc,MD,params,varargin)
        % MD_fxn Adapter for resultsIndTimeCoursePerMovie
        % MD: MovieData
        % params: (optional) struct, see timeCourseAnalysis.MLAnalyze
        %         default: Process.getParameters()
        %
        % Output stored in Process and saved to resSummary_movie.mat (summary only)
            if(nargin < 3)
                params = proc.getParameters();
            end
            if(isempty(params.outputDir))
                params.outputDir = proc.outFilePaths_;
            end
            if(~exist(params.outputDir,'dir'))
                mkdir(params.outputDir);
            end
            saveFile = fullfile(params.outputDir,'resSummary_movie.mat');
            [ proc.summary_ ] = resultsIndTimeCoursePerMovie(MD,saveFile,params.channels);
        end
    end
    %% Superclass abstracts
    methods(Static)
        function funParams = getDefaultParams(owner)
            ip = inputParser;
            % If empty, will be converted to Process outFilePaths_
            ip.addParameter('outputDir','',@ischar);
            ip.addParameter('channels', [], @isnumeric);
            ip.addParameter('doPartition', false, @(x) isnumeric(x) || islogical(x));
            ip.addParameter('doNewAnalysis', true, @(x) isnumeric(x) || islogical(x));
            ip.addParameter('start2zero', false, @(x) islogical(x)||isnumeric(x));
            ip.addParameter('channelNames', false, @(x) iscellstr(x));
            % normally stored in each CML
            ip.addParameter('alignEvent', 'start', @ischar);
            ip.parse();
            funParams = ip.Results;
        end
        function name = getName()
            name = 'TimeCourseAnalysisProcess';
        end
    end
end