function displayBiasStat(kinTracksOrCell,nameOrCell,varargin)
%Plot and compare building 
ip = inputParser;
ip.CaseSensitive = false;
ip.KeepUnmatched = true;
ip.addParameter('plotHandleArray',[]);
ip.addParameter('placeHolder',[10 35]);
ip.parse(varargin{:});
p=ip.Results;
H=p.plotHandleArray;
if(isempty(H))
    H=setupFigure(1,2,2,'AspectRatio',1,'AxesWidth',4);
end
% bias should be counted at the moment the MT disappear
if(~iscell(kinTracksOrCell))
    kinTracksOrCell={kinTracksOrCell};
end
mtDisappBias=cell(1,length(kinTracksOrCell));
mtDisappTime=cell(1,length(kinTracksOrCell));
biasAvgCell=cell(1,length(kinTracksOrCell));
biasStdCell=cell(1,length(kinTracksOrCell));
kinCount=cell(1,length(kinTracksOrCell));
biasAvgPerKinCell=cell(1,length(kinTracksOrCell));

timeCell=cell(1,length(kinTracksOrCell));


for ktIdx=1:length(kinTracksOrCell)
    kinTracks=kinTracksOrCell{ktIdx};
    kinCount{ktIdx}=zeros(1,kinTracks.numTimePoints());
    biasAvgPerKinCell{ktIdx}=zeros(1,kinTracks.numTimePoints());

    for kinIdx=1:length(kinTracks)
        kinTrack=kinTracks(kinIdx);
        
        mtDisappEnd=arrayfun(@(mt) mt.f(end), kinTrack.appearingMTP1);
        mtDisappBias{ktIdx}=[mtDisappBias{ktIdx} kinTrack.MTP1Angle'];
        mtDisappTime{ktIdx}=[mtDisappTime{ktIdx} mtDisappEnd'];
        if(~isempty(kinTrack.MTP1Angle))
            kinCount{ktIdx}(kinTrack.f)=kinCount{ktIdx}(kinTrack.f)+1;
            biasAvgPerKinCell{ktIdx}(kinTrack.f)=biasAvgPerKinCell{ktIdx}(kinTrack.f)+mean(kinTrack.MTP1Angle);
        end
        
        mtDisappEnd=arrayfun(@(mt) mt.f(end), kinTrack.appearingMTP2);
        mtDisappBias{ktIdx}=[mtDisappBias{ktIdx} kinTrack.MTP2Angle'];
        mtDisappTime{ktIdx}=[mtDisappTime{ktIdx} mtDisappEnd'];
        if(~isempty(kinTrack.MTP2Angle))
            kinCount{ktIdx}(kinTrack.f)=kinCount{ktIdx}(kinTrack.f)+1;
            biasAvgPerKinCell{ktIdx}(kinTrack.f)=biasAvgPerKinCell{ktIdx}(kinTrack.f)+mean(kinTrack.MTP2Angle);
        end
        
    end
    biasAvg=zeros(1,kinTracks.numTimePoints());
    biasStd=zeros(1,kinTracks.numTimePoints());
    for t=1:kinTracks.numTimePoints()
        biasAtTime=(mtDisappBias{ktIdx}(mtDisappTime{ktIdx}==t));
        biasAvg(t)=mean(biasAtTime);
        biasStd(t)=std(biasAtTime);
    end
    biasAvgPerKinCell{ktIdx}=biasAvgPerKinCell{ktIdx}./kinCount{ktIdx};
    biasAvgCell{ktIdx}=biasAvg;
    biasStdCell{ktIdx}=biasStd;
    timeCell{ktIdx}=1:kinTracks.numTimePoints();
end
%%
% groupID=arrayfun(@(i) i*ones(size(mtDisappTime{i})),1:length(mtDisappTime),'unif',0);
% gscatter([mtDisappTime{:}], [mtDisappBias{:}],[groupID{:}]);
%%
plot(H(1),vertcat(timeCell{:})',vertcat(biasAvgCell{:})');
legend(H(1),nameOrCell);
%%
plot(H(2),vertcat(timeCell{:})',vertcat(biasAvgPerKinCell{:})');
legend(H(2),nameOrCell);

end

