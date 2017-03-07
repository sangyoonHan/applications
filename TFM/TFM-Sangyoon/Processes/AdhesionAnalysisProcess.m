classdef AdhesionAnalysisProcess < DataProcessingProcess %& DataProcessingProcess
    
    methods (Access = public)
    
        function obj = AdhesionAnalysisProcess(owner, varargin)
    
            if nargin == 0
                super_args = {};
            else
                % Input check
                ip = inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieData'));
                ip.addOptional('outputDir', owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;
                
                % Define arguments for superclass constructor
                super_args{1} = owner;
                super_args{2} = AdhesionAnalysisProcess.getName;
                super_args{3} = @analyzeAdhesionMaturation;
                
                if isempty(funParams)
                    funParams = AdhesionAnalysisProcess.getDefaultParams(owner,outputDir);
                end
                
                super_args{4} = funParams;
            end
            
            obj = obj@DataProcessingProcess(super_args{:});
                        
        end

        function sanityCheck(obj)
            
            sanityCheck@DataProcessingProcess(obj);
            
            % Cell Segmentation Check
            if obj.funParams_.ApplyCellSegMask                
                iProc = obj.funParams_.SegCellMaskProc;
                % Check Mask is available
                if ~isempty(iProc)
                    assert(iProc < length(obj.owner_.processes_), 'Invalid Process # for Cell Mask Process');
                    assert(isa(obj.owner_.getProcess(iProc), 'MaskRefinementProcess'), ['Process: ' num2str(iProc) ' not a MaskRefinementProcess!']);
                    maskProc = obj.owner_.getProcess(iProc);
                    assert(maskProc.checkChannelOutput(obj.funParams_.ChannelIndex), 'Cell Segmentation Mask Output Not found');
                    % iProc = obj.owner_.getProcessIndex('MaskProcess', 'askUser', false, 'nDesired', Inf);
                else
                    iProc = obj.owner_.getProcessIndex('MaskRefinementProcess');   
                    assert(~isempty(iProc), 'MaskRefinementProcess Process not found cannot Apply Cell Mask!');
                    disp('Setting Cell Segmentation Mask Process index');
                    obj.funParams_.SegCellMaskProc = iProc;
                end
            else
                warning('You do not have segmentation process run for a mask. Using entire image field ...')
            end
            
            %% Sanity check for Detecting FAs 
            iProc = obj.funParams_.detectedNAProc;
            if ~isempty(iProc)
                assert(iProc < length(obj.owner_.processes_), ['Invalid Process #' num2str(iProc) 'for FA Detection Process']);
                assert(isa(obj.owner_.getProcess(iProc), 'DetectionProcess'));
            else
                iProc = obj.owner_.getProcessIndex('DetectionProcess');
                assert(~isempty(iProc), 'FA DetectionProcess Process not found!');
                disp('Setting FA DetectionProcess index');
                obj.funParams_.detectedNAProc = iProc;
            end
            
            %% Sanity check for Tracking FAs 
            iProc = obj.funParams_.trackFAProc;
            if ~isempty(iProc)
                assert(iProc < length(obj.owner_.processes_), ['Invalid Process #' num2str(iProc) 'for FA Tracking Process']);
                assert(isa(obj.owner_.getProcess(iProc), 'TrackingProcess'));
            else
                iProc = obj.owner_.getProcessIndex('TrackingProcess');
                assert(~isempty(iProc), 'FA TrackingProcess Process not found!');
                disp('Setting FA TrackingProcess index');
                obj.funParams_.trackFAProc = iProc;
            end
            
            %% Add Sanity check for FAsegmentationProcess Mask
            iProc = obj.funParams_.FAsegProc;
            if ~isempty(iProc)
                assert(iProc < length(obj.owner_.processes_), ['Invalid Process #' num2str(iProc) 'for FA Seg Process']);
                assert(isa(obj.owner_.getProcess(iProc), 'FocalAdhesionSegmentationProcess'));
            else
                iProc = obj.owner_.getProcessIndex('FocalAdhesionSegmentationProcess');
                assert(~isempty(iProc), 'FocalAdhesionSegmentationProcess Process not found!');
                disp('Setting FocalAdhesionSegmentationProcess index');
                obj.funParams_.FAsegProc = iProc;
            end
        end
        
        function varargout = loadChannelOutput(obj, iChan, varargin)
            % Input check
            outputList = {'detBA','detectedFA','detFA','detFC','detNA',...
                          'adhboundary','trackFC','trackNA','trackFA','staticTracks'};

            ip =inputParser;
            ip.addRequired('obj');
            ip.addRequired('iChan', @(x) obj.checkChanNum(x));
            ip.addOptional('iFrame', [] ,@(x) obj.checkFrameNum(x));
            ip.addParameter('useCache',true,@islogical);
            ip.addParameter('output', outputList{3}, @(x) all(ismember(x,outputList)));
            ip.parse(obj,iChan,varargin{:})
            output = ip.Results.output;
            varargout = cell(numel(output), 1);
            iFrame = ip.Results.iFrame;
            if ischar(output),output={output}; end
            
            % Data loading
            s = cached.load(obj.outFilePaths_{1,iChan}, '-useCache', ip.Results.useCache, 'tableTracksNA');
%             st = cached.load(obj.outFilePaths_{1,iChan}, '-useCache', ip.Results.useCache, 'tracksNA');
            
            if isstruct(s)
                s = s.tableTracksNA;
            else
                disp('loaded as table');
            end
            %% Check struct vs table loading
            xCoord = s.xCoord(:,iFrame);
            yCoord = s.yCoord(:,iFrame);
            pres = s.presence(:,iFrame);
            nTracks = length(xCoord);
            number = [1:length(xCoord)]';
            state = categorical(s.state(:,iFrame));
            t = table(xCoord, yCoord, state, pres, number);
            

            for iout = 1:numel(output)
                switch output{iout}
                    case 'detectedFA'  
                        varargout{1} = t;
                    case 'detBA' 
                        rows = t.state == 'BA';
                    case {'detNA','trackNA'}
                        rows = t.state == 'NA';
                    case {'detFC','trackFC'}
                        rows = t.state == 'FC';
                    case {'detFA', 'trackFA'}
                        rows = t.state == 'FA';
                    case 'adhboundary'
                    case 'staticTracks'
                    otherwise
                        error('Incorrect Output Var type');
                end   
                if ~isempty(strfind(output{iout}, 'det'))
                    vars = {'xCoord','yCoord'};
                    varargout{iout} = t{rows,vars};                                 
                elseif ~isempty(strfind(output{iout},'track'))
                    vars = {'xCoord','yCoord','number'};
                    s = horzcat(s(:,{'xCoord','yCoord'}), table(number));
                    varargout{iout}(nTracks, 1) = struct('xCoord', [], 'yCoord', [], 'number', []);
                    varargout{iout}(rows, :) = table2struct(s(rows, vars));
                else
                    varargout{iout} = [];
                end
            end
        end      
    end


    methods (Static)
        function name = getName()
            name = 'Focal Adhesion Analysis';
        end

        function h = GUI()
            h = @focalAdhesionAnalysisProcessGUI;
        end
        
        function output = getDrawableOutput()
            % output(1).name = 'Adhesion Detections';
            % keySet = {'BA','NA','FC','FA'};
            % valueSet = {'g','r', 'y', 'b'};
            % ColorsDict = containers.Map(keySet,valueSet);
            % % Detection Points
            % % Colors = 'grob'; % optional
            % output(1).var = 'detectedFA';
            % output(1).formatData = [];%obj.formatSpotOutput;
            % output(1).type = 'overlay';
            % output(1).defaultDisplayMethod=@(x)FASpotDisplay('ColorDict', ColorsDict);
            % colors = 'g';
            i = 1;          
            output(i).name='Before Adhesion Detection'; 
            output(i).var='detBA';
            output(1).formatData=[];
            output(1).type='overlay';
            output(1).defaultDisplayMethod=@(x) LineDisplay('Marker','d',...
                'LineStyle','none', 'Color', 'g');            
            i = 2; % NA Detection Nascent Adhesion
            output(i).name='Nascent Adhesion Detection'; 
            output(i).var='detNA';
            output(i).formatData=[];
            output(i).type='overlay';
            output(i).defaultDisplayMethod=@(x) LineDisplay('Marker','o',...
                'LineStyle','none', 'LineWidth', .7, 'Color', 'r'); 
            i = 3; % FC Detection Focal Contact
            output(i).name='Focal Contact Detection'; 
            output(i).var='detFC';
            output(i).formatData=[];
            output(i).type='overlay';
            output(i).defaultDisplayMethod=@(x) LineDisplay('Marker','o',...
                'LineStyle','none', 'LineWidth', .75, 'Color', [255/255 153/255 51/255]); 
            % FA Detection Focal Adhesion
            i = 4;
            output(i).name='Focal Adhesion Detection'; 
            output(i).var='detFA';
            output(i).formatData=[];
            output(i).type='overlay';
            output(i).defaultDisplayMethod=@(x) LineDisplay('Marker','o',...
                'LineStyle','none', 'LineWidth', .75, 'Color', 'b'); 
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Tracks Display
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            i=5; output(i).name='Nascent Adhesion Tracks'; 
            output(i).var='trackNA';
            output(i).formatData=[];
            output(i).type='overlay';
            output(i).defaultDisplayMethod=@(x) FATracksDisplay('Linewidth', 2, 'Color', 'r'); 
            i=6; output(i).name='Focal Contact Tracks'; 
            output(i).var='trackFC';
            output(i).formatData=[];
            output(i).type='overlay';
            output(i).defaultDisplayMethod=@(x) FATracksDisplay('Linewidth', 2, 'Color', [255/255 153/255 51/255]); 
            i=7; output(i).name='Focal Adhesion Tracks'; 
            output(i).var='trackFA';
            output(i).formatData=[];
            output(i).type='overlay';
            output(i).defaultDisplayMethod=@(x) FATracksDisplay('Linewidth', 2, 'Color', 'b'); 

            % NA Track
            % FC Track
            % FA Track


            % % Adhesion Boundaries
            % colorsAdhBound = hsv(numel(obj.owner_.channels_));
            % output(2).name='Adh. Boundaries';
            % output(2).var='adhboundary';
            % output(2).formatData=@DetectionProcess.formatOutput;
            % output(2).type='overlay';
            % output(2).defaultDisplayMethod=@(x) LineDisplay('Marker','o',...
            %     'LineStyle','none','Color', colorsAdhBound(x,:));
            
            % % Tracks
            % colors = hsv(numel(obj.owner_.channels_));
            % output(3).name='FA Tracks';
            % output(3).var='tracks';
            % output(3).formatData=@TrackingProcess.formatTracks;
            % output(3).type='overlay';
            % output(3).defaultDisplayMethod = @(x)FATracksDisplay(...
            %     'Color',colors(x,:));
            
            % output(4).name='Static FA tracks';
            % output(4).var='staticTracks';
            % output(4).formatData=@TrackingProcess.formatTracks;
            % output(4).type='overlay';
            % output(4).defaultDisplayMethod = @(x)FATracksDisplay(...
            %     'Color',colors(x,:), 'useDragtail', false);



        end       

        function funParams = getDefaultParams(owner, varargin)

            % MD.getPackage(MD.getPackageIndex('FocalAdhesionPackage')).outputDirectory_
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            ip.addOptional('iChan', 1:numel(owner.channels_),...
               @(x) all(owner.checkChanNum(x)));
            ip.parse(owner, varargin{:});
            
            % Set default parameters
            funParams.OutputDirectory = [ip.Results.outputDir filesep 'AdhesionAnalysis'];
            funParams.ChannelIndex = ip.Results.iChan;

            funParams.ApplyCellSegMask = true;
            funParams.SegCellMaskProc = []; % Specify Process with cell mask output
            funParams.detectedNAProc = []; % Specify FA detection Process index
            funParams.trackFAProc = []; % Specify FA tracking Process index
            funParams.FAsegProc = []; % Specify FA segmentation Process index           

            funParams.onlyEdge = false; 
            funParams.matchWithFA = true; 
            funParams.minLifetime = 5;  % For tracks
            funParams.reTrack = true;
            funParams.getEdgeRelatedFeatures = true;
            funParams.bandwidthNA = 7;
            
            %% TODO - likely will remove this.
            funParams.backupOldResults = true;           
        end

    end
end
