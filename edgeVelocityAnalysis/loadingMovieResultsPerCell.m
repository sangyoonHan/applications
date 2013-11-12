function  out = loadingMovieResultsPerCell(ML,analysisDir,fileName)
%Loading edge velocity analysis for each cell in the MovieList
%
%Usage:
%       out = loadingMovieResultsPerCell(ML,analysisDir,fileName)
%       
%Input:
%       ML - movie list
%       analysisDir - path for the specific analysis 
%       fileName
%
%Output:
%       structure array where each element comes from a cell. Fields are the analysis parameters. 
%       Empty if no analysis exist.
%
% Marco Vilela, 2013

nCell        = numel(ML.movies_);
out{1,nCell} = [];

for iCell = 1:nCell

    currMD   = ML.movies_{iCell};
    %Saving results for each cell
    edgePath = [currMD.outputDirectory_ filesep analysisDir];
    filePath = [edgePath filesep fileName '.mat'];
    
    if exist(filePath,'file')
        
        aux         = load(filePath);
        if isfield(aux.analysisResults.data,{'processedLastRun'})
            out{iCell}     = aux.analysisResults;
        end
        
    end
        
end