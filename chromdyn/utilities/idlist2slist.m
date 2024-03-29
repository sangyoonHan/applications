function [slist, nSpots] = idlist2slist(idlist)
%IDLIST2SLIST generates an slist based on an idlist
%
% INPUT idlist - any idlist
%
% OUTPUT slist - the "spots" list that is used by spotID, and that can be
%                generated by slist2spots.
%                Fields: xyz, amp, detectQ, trackQ, noise
%
% c: jonas 4/05
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


totalNumOfFrames = length(idlist);

slist(1:totalNumOfFrames)=struct('amp',[],'xyz',[]);

nSpots=zeros(totalNumOfFrames,1);


for t=1:totalNumOfFrames
    if ~isempty(idlist(t).linklist)
        nSpots(t)=max(idlist(t).linklist(:,2));
        
        detQ = [];
        nse = [];
        traQ = [];
        totQ = [];
        for i=1:nSpots(t) %readout each spot separately
            rowIdx=find(idlist(t).linklist(:,2)==i);
            slist(t).xyz(i,:)=idlist(t).linklist(rowIdx(1),9:11);
            slist(t).amp(i)=sum(idlist(t).linklist(rowIdx,8));
            
            
            %restore QMatrix (sorted by spot)
            detQ = blkdiag(detQ,idlist(t).info.detectQ_Pix( (rowIdx(1)-1)*3+1:rowIdx(1)*3,(rowIdx(1)-1)*3+1:rowIdx(1)*3 ) );
            if isfield(idlist(t).info,'totalQ_Pix')
                totQ = blkdiag(traQ,idlist(t).info.totalQ_Pix( (rowIdx(1)-1)*3+1:rowIdx(1)*3,(rowIdx(1)-1)*3+1:rowIdx(1)*3 ) );
            else
                if ~isempty(idlist(t).info.trackQ_Pix)
                traQ = blkdiag(traQ,idlist(t).info.trackQ_Pix( (rowIdx(1)-1)*3+1:rowIdx(1)*3,(rowIdx(1)-1)*3+1:rowIdx(1)*3 ) );
                end
            end
            
            %get chi^2 back from linklist (we cannot trust the old "noise"-field)
            if size(idlist(t).linklist,2)>11
                nse = [nse,idlist(t).linklist(rowIdx(1),12)];
            end
        end
        
        slist(t).detectQ=detQ;
        slist(t).noise=nse;        
        slist(t).trackQ=traQ;
        slist(t).totalQ=totQ;
        if isfield(idlist(t).info,'trackerMessage')
            slist(t).trackerMessage = idlist(t).info.trackerMessage;
        end
        
    else
        %nSpots stays zero
        slist(t).amp=[];
    end
end