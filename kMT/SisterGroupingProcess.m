classdef SisterGroupingProcess < DataProcessingProcess
    % A concrete class associated to the grouping of sister tracks
    %
    % Sebastien Besson, March 2012
    
    methods (Access = public)
        
        function obj = SisterGroupingProcess(owner, varargin)
            if nargin == 0
                super_args = {};
            else
                % Input check
                ip = inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieData'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;
                
                super_args{1} = owner;
                super_args{2} = SisterGroupingProcess.getName;
                super_args{3} = @groupMovieSisters;
                if isempty(funParams)  % Default funParams
                    funParams = SisterGroupingProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            
            obj = obj@DataProcessingProcess(super_args{:});
        end
        
        function varargout = loadChannelOutput(obj,iChan,varargin)
            
            % Input check
            outputList = {'sisterList','trackPairs'};
            ip =inputParser;
            ip.addRequired('iChan',@(x) isscalar(x) && obj.checkChanNum(x));
            ip.addOptional('iFrame',1:obj.owner_.nFrames_,@(x) all(obj.checkFrameNum(x)));
            ip.addParamValue('output',outputList,@(x) all(ismember(x,outputList)));
            ip.parse(iChan,varargin{:})
            iFrame = ip.Results.iFrame;
            output = ip.Results.output;
            if ischar(output),output={output}; end
            
            % Data loading
            s = load(obj.outFilePaths_{1,iChan},output{:});
            if ~isempty(iFrame) && isfield(s,'sisterList'),
                fields = fieldnames(s.sisterList(1));
                for i=1:numel(s.sisterList)
                    for j=1:numel(fields);
                        s.sisterList(i).(fields{j})= s.sisterList(i).(fields{j})(iFrame,:);
                    end
                end
            end
            
            for i=1:numel(output),varargout{i}=s.(output{i}); end
            
        end
        
        function output = getDrawableOutput(obj)
            colors = hsv(numel(obj.owner_.channels_));
            output(1).name='Sister pairs';
            output(1).var='sisterList';
            output(1).formatData=[];
            output(1).type='overlay';
            output(1).defaultDisplayMethod=@(x)PairsDisplay('Color',colors(x,:));
        end
        
    end
    
    methods (Static)
        
        function name = getName()
            name = 'Sister Grouping';
        end
        
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            funParams.ChannelIndex = 1 : numel(owner.channels_);
            funParams.OutputDirectory = [outputDir  filesep 'SisterGrouping'];
            funParams.maxAngle = 30 * pi / 180;
            funParams.maxDist = 40;
            funParams.minOverlap = 10;
            funParams.useAlignment = 1;
            funParams.robust=0;
        end
        
    end
    
end

