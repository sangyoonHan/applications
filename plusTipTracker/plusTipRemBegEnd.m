function [ dataMatCrpSecMic,projData] = plusTipRemBegEnd(dataBeforeCrop, projData)
%Decided it would be useful to separate this bit of code from the
%reclassification scheme so can call for subregional analysis where this 
% has already been performed- might decide to change later(MB)
%% Remove Growths Initiated in First Frame or Ending in Last Frame From Stats
% do this so one does not bias growth lifetime/displacement data (might not
% be what we want for 

dataMat = dataBeforeCrop; 

subIdx2rem=[];
% get index of growth and following fgap or bgap (if it exists) that
% begin in the first frame

sF = projData.detectionFrameRange(1,1);
eF = projData.detectionFrameRange(1,2);

%sF=min(dataMat(:,2));

% compound track IDs of all subtracks with nminimum starting frame number

fullIdx2rem=unique(dataMat(dataMat(:,2)==sF,1)); 
for iTr=1:length(fullIdx2rem)
    subIdx=find(dataMat(:,1)==fullIdx2rem(iTr));
    if (length(subIdx)>1) && (dataMat(subIdx(2),5) > 1) % if there is a forward backward gap linked to growth in first frame
        subIdx2rem=[subIdx2rem; subIdx(1:2)]; % Don't remove entire compound track only the fgap or bgap it's linked to
    else
        subIdx2rem=[subIdx2rem; subIdx(1)];
    end
end

% get index of growth and preceeding fgap or bgap
% (if it exists) that end in the last frame

%eF=max(dataMat(:,3));
fullIdx2rem=unique(dataMat(dataMat(:,3)==eF,1));
for iTr=1:length(fullIdx2rem)
    subIdx=find(dataMat(:,1)==fullIdx2rem(iTr));
    if (length(subIdx)>1) && (dataMat(subIdx(end-1),5) > 1)
        subIdx2rem=[subIdx2rem; subIdx(end-1:end)]; % take out the last two of list  
    else
        subIdx2rem=[subIdx2rem; subIdx(end)];
    end
end
% remove both classes for statistics
dataMat(subIdx2rem,:)=[];
dataMatCrpSecMic=dataMat; % NOTE: Kathyrn makes these all absolute values 
% I think for stats it is better to keep sign (MB) 

end

