%deals with individual CML
function [CMLSummary, CMLTime, CMLExtra, startTime] = CMLAnalyze(CML,analysisPara)
    alignEvent = CML.analysisPara_.alignEvent;
    %[CMLSummary, CMLTime, CMLExtra] = arrayfun(@(x) MLAnalyze(x, alignEvent), CML.movieLists_, 'UniformOutput', false);
%     nML = numel(CML.movieLists_);
%     CMLSummary = cell(1,nML);
%     CMLTime = cell(1,nML);
%     CMLExtra = cell(1,nML);
%     startTime = zeros(1,nML);
    movieLists = CML.movieLists_;
%     parfor iML = 1:nML
%         [CMLSummary{iML}, CMLTime{iML}, CMLExtra{iML}, startTime(iML)] = timeCourseAnalysis.MLAnalyze(movieLists(iML), alignEvent,analysisPara);
%     end
%     [CMLSummary,CMLTime,CMLExtra,startTime] = ...
%         pararrayfun_progress(...
%         @(x) timeCourseAnalysis.MLAnalyze(x,alignEvent,analysisPara) ...
%         , movieLists ...
%         , 'UniformOutput',false ...
%         , 'DisplayFunc', 'progressTextMultiple' ...
%         );
    [CMLSummary,CMLTime,CMLExtra,startTime] = ...
        arrayfun(...
        @(x) timeCourseAnalysis.MLAnalyze(x,alignEvent,analysisPara) ...
        , movieLists ...
        , 'UniformOutput',false ...
        );
    CMLSummary = vertcat(CMLSummary{:});
    CMLTime = vertcat(CMLTime{:});
    CMLExtra = vertcat(CMLExtra{:});
%     startTime = mean(startTime);
    startTime = mean([startTime{:}]);
end