function [ dataTrans  ] = elastixTransformMasks(data, dataSpacing, elastixTransforms, varargin)
% ELASTIXTRANSFORMMASKS Perform a transform on a mask, using transforms parameters generated by Elastix.
% Author: Paul Balan�a
%
% [ dataTrans  ] = elastixTransformMasks(data, dataSpacing, elastixTransforms, param1, val1, param2, val2, ...)
%  
%     Input:
%        data                Mask to transform. Can be a struct or a single mask.
%        dataSpacing         Data spacing.
%        elastixTransforms   Transform parameters, generated by Elastix.
%
%     Parameters:
%        'logFile'           Filename where to save the log file.
%        'transformixExe'    Filename of the Transformix executable.
%        'outputDir'         Directory where to save Elastix outputs.
%                            The default value is a temporary directory which will be deleted at the end.
%
%     Output:   
%        dataTrans           Masks transformed.
%
% See Elastix documentation : http://elastix.isi.uu.nl
%

% Modify transforms
for i = 1:numel(elastixTransforms)
    % Use nearest interpolation for binary masks
    elastixTransforms{i}.FinalBSplineInterpolationOrder = 0;

    % Use 0 as default pixel value
    elastixTransforms{i}.DefaultPixelValue = 0;
end

% Convert structure
if isstruct(data)
    structNames = fieldnames(data);
    for i = 1:numel(structNames)
        fprintf('>>> Transform volume : %s\n', structNames{i});
        tmpMask = data.(structNames{i});
        dataTrans.(structNames{i}) = elastixTransform(tmpMask, dataSpacing, elastixTransforms, varargin{:});
    end
end

% Simple volume
if ~isstruct(data)
    dataTrans = elastixTransform(data, dataSpacing, elastixTransforms, varargin{:});
end

end
