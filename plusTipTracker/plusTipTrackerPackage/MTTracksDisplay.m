classdef MTTracksDisplay < MovieDataDisplay
    %Conrete class for displaying flow
    properties
        Events={'Growth','Pause','Shrinkage','Unclassified',...
            'Growth reclass','Pause reclass'};
        Linestyle='-:::-:';
        Color='rcymgb';  
        dragtailLength=Inf;
    end
    methods
        function obj=TracksDisplay(varargin)
            nVarargin = numel(varargin);
            if nVarargin > 1 && mod(nVarargin,2)==0
                for i=1 : 2 : nVarargin-1
                    obj.(varargin{i}) = varargin{i+1};
                end
            end
        end
        function h=initDraw(obj,data,tag,varargin)
            
            if isempty(data.x), h=[]; return; end
            h= -ones(size(data.x),1);
            uniqueTypes=unique(data.trackType);
            for i=1:numel(uniqueTypes), 
                index=data.trackType==uniqueTypes(i);
                h(index) = plot(data.x(index,max(1,end-obj.dragtailLength):end)',...
                    data.y(index,max(1,end-obj.dragtailLength):end)',...
                    'Color',obj.Color(uniqueTypes(i)),'Linestyle',obj.Linestyle(uniqueTypes(i)),'LineWidth',1.5);
            end
%             for i=1:size(data.x,1), set(h(data.trackType==i),...
%                     
%                 set(h(data.trackType==i),...
% %                     'Color',obj.Color(i),'Linestyle',obj.Linestyle(i));
%
%             h = plot(data.x(:,max(1,end-obj.dragtailLength):end)',...
%                     data.y(:,max(1,end-obj.dragtailLength):end)','LineWidth',1.5);
%             for i=1:numel(obj.Events), set(h(data.trackType==i),...
%                     'Color',obj.Color(i),'Linestyle',obj.Linestyle(i));
%             for iColor=1:8
%                 switch iColor
%                     case 1 % growth
%                         c1='r';
%                         c2='r';
%                     case 2 % forward gaps - pause
%                         c1='c:';
%                         c2='c';
%                     case 3 % backward gaps - shrinkage
%                         c1='y:';
%                         c2='y';
%                     case 4 % unclassified gaps
%                         c1='m:';
%                         c2='m';
%                     case 5 % forward gaps - reclassified as growth
%                         c1='g';
%                         c2='g';
%                     case 6 % backward gaps - slow
%                         c1='b:';
%                         c2='b';
%                     case 7 % backward gaps - very fast
%                         c1 = 'g.-';
%                         c2 = 'g';
%                     case 8
%                         c1 = 'b.-';
%                         c2 = 'b';
%                         
%                 end
%                 
%                 h{iColor} = plot(data.x(data.trackType==iColor,max(1,end-obj.dragtailLength):end)',...
%                     data.y(data.trackType==iColor,max(1,end-obj.dragtailLength):end)',c1,'LineWidth',1.5);
%                 
                %movieROI/movieData.mat plot big circle around transition events (red circle when start of
                % growth, yellow circle when start of shrinkage, etc.)
%                 if plotCurrentOnly~=0
%                     cTTIdx=find(trackType==iColor); % current track type indices
%                     currenStartingSubtrackIdx=cTTIdx(sF(cTTIdx)==plotCurrentOnly);
%                     if ~isempty(currenStartingSubtrackIdx)
%                         coordIdx=sub2ind(size(xMat),currenStartingSubtrackIdx,plotCurrentOnly*ones(length(currenStartingSubtrackIdx),1));
%                         scatter(xMat(coordIdx),yMat(coordIdx),'MarkerEdgeColor',c2,'SizeData',(72/3)^2)
%                     end
%                 end
                
                
%             end
            set(h,'Tag',tag);
        end

        function updateDraw(obj,h,data)
            tag=get(h(1),'Tag');
            nTracks = size(data.x,1);
            
            % Delete tracks
            delete(h(nTracks+1:end));
            h(nTracks+1:end)=[];
            if nTracks==0, return; end
            
            %
            existingTracks=false(nTracks,1);
            existingTracks(1:min(numel(h),nTracks))=true;
            uniqueTypes=unique(data.trackType);
            for i=1:numel(uniqueTypes), 
                index=data.trackType==uniqueTypes(i);
                index1=index & existingTracks;
                for j=find(index1)'
                    
                    set(h(j),'XData',data.x(j,max(1,end-obj.dragtailLength):end),...
                        'YData',data.y(j,max(1,end-obj.dragtailLength):end)',...
                        'Color',obj.Color(uniqueTypes(i)),'Linestyle',obj.Linestyle(uniqueTypes(i)));
                end
                
                index2= index & ~existingTracks;
                h(index2) = plot(data.x(index2,max(1,end-obj.dragtailLength):end)',...
                    data.y(index2,max(1,end-obj.dragtailLength):end)',...
                    'Color',obj.Color(uniqueTypes(i)),'Linestyle',obj.Linestyle(uniqueTypes(i)),'LineWidth',1.5);
            end
            
            % Set tag
            set(h,'Tag',tag);          
        end
    end    
    
    methods (Static)
        function params=getParamValidators()
            params(1).name='Color';
            params(1).validator=@ischar;
            params(2).name='Linestyle';
            params(2).validator=@ischar;
            params(3).name='Events';
            params(3).validator=@iscell;
            params(4).name='dragtailLength';
            params(4).validator=@isscalar;
        end

        function f=getDataValidator() 
            f=@isstruct;
        end
    end    
end