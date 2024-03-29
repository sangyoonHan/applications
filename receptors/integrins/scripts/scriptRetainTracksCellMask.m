clear all
close all

firstMaskFile = 'C:\kjData\Galbraiths\data\alphaVY773AandCellEdge\140226_Cs3C2_Y773A\analysisCellEdgeSmall\SegmentationPackage\refined_masks\refined_masks_for_channel_1\refined_mask_140226_Cs3C2_Y773A_6mES_0001.tif';

cd ../../../../analysisAlphaVY773A/tracks/
load tracks1AllFrames.mat
cd ../diffusion/
load diffAnalysis1AllFrames.mat
cd ../furtherAnalysis

criteria.lifeTime.min = 5;
indx5 = chooseTracks(tracksFinal,criteria);
tracksFinal = tracksFinal(indx5);
diffAnalysisRes = diffAnalysisRes(indx5);

seqOfEvents = vertcat(tracksFinal(end-10:end).seqOfEvents);
maxFrame = max(seqOfEvents(:,1));
indxMask = findTracksInCellMask(tracksFinal,firstMaskFile,1:400:maxFrame+1);
% indxMask = findTracksInCellMask(tracksFinal,firstMaskFile,1:maxFrame:maxFrame+1);
tracksFinal = tracksFinal(indxMask);
diffAnalysisRes = diffAnalysisRes(indxMask);

save('tracksDiffusionLength5InMask','tracksFinal','diffAnalysisRes','indx5','indxMask');

