%nested function for above: checking MD has necessary processes
function [] = MLCheck(ML, parameter)
    nMD = numel(ML.movies_);
    for iMD = 1:nMD
        if isempty(ML.movies_{iMD}.getProcessIndex('MotionAnalysisProcess'))
            error('timeCourseAnalysis:MotionAnalysisProcessMissing', ...
                ['MovieData ' ML.movies_{iMD}.movieDataFileName_ ...
                '\n at ' ML.movies_{iMD}.movieDataPath_ ...
                '\n does not contain MotionAnalysisProcess']);
        end
        if parameter.doPartition ...
                && isempty(ML.movies_{iMD}.getProcessIndex('PartitionAnalysisProcess'))
            error('timeCourseAnalysis:PartitionAnalysisProcessMissing', ... 
                ['MovieData ' ML.movies_{iMD}.movieDataFileName_ ...
                '\n at ' ML.movies_{iMD}.movieDataPath_ ...
                '\n does not contain PartitionAnalysisProcess']);
        end
    end
end

