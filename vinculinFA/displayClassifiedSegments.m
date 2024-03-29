function displayClassifiedSegments(hAxes, tag, segments, layerColor)

nSegments = size(segments,1);

for iSeg = 1:nSegments
    
    pts = segments(iSeg,1:4);
    color = segments(iSeg,6:end);
    
    line(pts([1 3]), pts([2 4]), 'Marker', 'none', 'LineWidth', 1.5, 'Color', color, 'Parent', hAxes, 'Tag', tag);
end