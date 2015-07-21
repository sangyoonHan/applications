function [ selectedFiles ] = GCAValidationReconstructRandomSelection( projList,nSamples )
%GCAValidationReconstructRandomSelection
% this function randomly selects a project and frame number from a list of
% projects for validation. 

% make the list of IDs 
projectsAll = repmat(projList,120,1); 
frames = arrayfun(@(i) repmat(i,length(projList),1),1:120,'uniformoutput',0); 
frames = vertcat(frames{:}); 

projectSamp = projectsAll(randsample(1:length(frames),nSamples)); 
framesSamp = frames(randsample(1:length(frames),nSamples)); 

selectedFiles = [projectSamp  num2cell(framesSamp)];  

end

