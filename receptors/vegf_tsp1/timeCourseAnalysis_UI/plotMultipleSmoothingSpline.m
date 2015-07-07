function [dataFit] = plotMultipleSmoothingSpline(outputDir, data, times, names, colors, plotTitle, yLabelName, smoothingPara)
%Scatter plots given data sets in one plot and fits smoothing spline through the scatterplots
%
%SYNOPSIS [dataFit] = plotMultipleSmoothingSpline(outputDir, data, times, names, colors, plotTitle, yLabelName, smoothingPara)
%
%INPUT
%   outputDir       : directory where the figure will be saved
%   data            : cell array of data sets (each set must be a column)
%   times           : cell array of times corresponding to the dataset (each set must be a column)
%   names           : cell array of names corresponding to each set (used in the legend)
%   colors          : cell array of colors to be used for each set
%   plotTitle       : name of the plot
%   unit            : y axis name
%   smoothingPara   : smoothing parameter for smoothing spline fit
%   
%OUTPUT
%   dataFit         : cell array of fitObjects from the smoothing spline fit
%
%Tae H Kim, July 2015

%% Input
%assign default value
if isempty(smoothingPara)
    smoothingPara = .95;
end
try
%% Fitting
    dataFit = cellfun(@(x, y) fit(x, y, 'smoothingspline', 'smoothingParam', smoothingPara), times, data, 'UniformOutput', false);
    %% Plotting
    %creates figure and stores the figure handle
    figureHandle = figure('Name', plotTitle);
    hold on;
    %plots all data and stores all line handles
    lineHandle = cellfun(@plot, dataFit, times, data, 'UniformOutput', false);
    %change the color so that color of data and fit match
    cellfun(@(x, y) set(x, 'Color', y), lineHandle, colors);
    %create legends only contain the fit
    fitHandle = [lineHandle{:}];
    legend(fitHandle(2,:), names);
    %label axis
    xlabel('Time (min)');
    ylabel(yLabelName);
    %% Saving
    %save and close
    savefig(figureHandle, [outputDir filesep plotTitle '.fig']);
    close(figureHandle);
catch
    warning(['Could not plot ' plotTitle]);
    dataFit = [];
end
end