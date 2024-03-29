function tracksNA = calculateTrackSlopes(tracksNA,tInterval)
% tracksG1 = calculateTrackSlopes(tracksG1) calculates slopes of force and
% amplitude from first minute or half lifetime.
% Sangyoon Han, December, 2015

tIntervalMin = tInterval/60;
prePeriodFrame = ceil(10/tInterval); %pre-10 sec
for k=1:numel(tracksNA)
    sF=max(tracksNA(k).startingFrameExtra-prePeriodFrame,tracksNA(k).startingFrameExtraExtra);
    
%     eF=tracksNA(k).endingFrameExtra;
    curLT = tracksNA(k).lifeTime;
    halfLT = ceil(curLT/2);
    earlyPeriod = min(halfLT,floor(60/tInterval)); % frames per a minute or half life time

    lastFrame = min(tracksNA(k).endingFrameExtraExtra,sF+earlyPeriod+prePeriodFrame-1);
    lastFrameFromOne = lastFrame - sF+1;
    
    [~,curM] = regression(tIntervalMin*(1:lastFrameFromOne),tracksNA(k).amp(sF:lastFrame));
    tracksNA(k).earlyAmpSlope = curM; % in a.u./min
    [curForceR,curForceM] = regression(tIntervalMin*(1:lastFrameFromOne),tracksNA(k).forceMag(sF:lastFrame));
%         figure, plot(tIntervalMin*(1:lastFrameFromOne),tracksNA(k).forceMag(sF:lastFrame))
%         figure, plotregression(tIntervalMin*(1:lastFrameFromOne),tracksNA(k).forceMag(sF:lastFrame))
    tracksNA(k).forceSlope = curForceM; % in Pa/min
    tracksNA(k).forceSlopeR = curForceR; % Pearson's correlation coefficient
end
