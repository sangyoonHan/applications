function mask = maskFromSteerable(steerable)
    thresh = thresholdRosin(steerable.res(:));
    threshOtsu = thresholdOtsu(steerable.nms( steerable.nms ~= 0));
    threshNms = thresholdRosin(steerable.nms( steerable.nms ~= 0));
    justNms = steerable.nms( steerable.nms ~= 0);
%    mask = steerable.res > thresh;
%    mask = mask | steerable.nms > thresh/2;
    mask = hysteresisThreshold(steerable.res,prctile(justNms,95),prctile(justNms,70));
    mask = imclose(mask,strel('disk',10));
    mask = imfill(mask,'holes');
    mask = imopen(mask,strel('disk',50));
    cc = bwconncomp(mask);
    rp = regionprops(cc,'Area');
    [maxArea,maxIdx] = max([rp.Area]);
    mask(:) = 0;
    % if the largest area detected is less than 60% of total area
    if(maxArea < 0.6*numel(steerable.res))
        mask(cc.PixelIdxList{maxIdx}) = 1;
    end
end