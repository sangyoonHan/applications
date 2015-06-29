function tracksNA = readIntensityFromTracks(tracksNA,imgStack, attribute, varargin)
% tracksNA = readIntensityFromTracks(tracksNA,imgStack, attribute) records
% pixel intensity from imgStack for entire track, even after ANA state in the last x,y
% position, and store it to attribute in tracksNA (1 means ampTotal, 2
% means forceMag
% assumes that tracks reflects coordinates from stage-drift-corrected
% images. imgStack is also from SDC output.
ip =inputParser;
ip.addParamValue('extraLength',0,@isscalar); % selcted track ids
ip.parse(varargin{:});
extraLength=ip.Results.extraLength;
% get stack size
numFrames = size(imgStack,3);
w4 = 8;
sigma = max(tracksNA(1).sigma);
numTracks = numel(tracksNA);
% parfor_progress(numel(tracksNA));
progressText(0,'Re-reading and tracking individual tracks:');

% parfor k=1:numel(tracksNA)
for k=1:numTracks
%     startFrame = max(1, min(arrayfun(@(x) x.startingFrame,tracksNA))-extraLength);
%     endFrame = min(numFrames, max(arrayfun(@(x) x.endingFrame,tracksNA))+extraLength);
%     startFrame = max(1, tracksNA(k).startingFrame-extraLength);
%     endFrame = min(numFrames,tracksNA(k).endingFrame+extraLength);
%     curStartingFrame = tracksNA(k).startingFrame;
%     curEndingFrame = tracksNA(k).endingFrame;
%     tracksNA(k).startingFrameExtra = startFrame;
%     tracksNA(k).endingFrameExtra = endFrame;
%     curRange = curStartingFrame:curEndingFrame;
%     if extraLength==0
%         if attribute==1
%             tracksNA(k).ampTotal(curRange) = arrayfun(@(x) imgStack(round(tracksNA(k).yCoord(x)),round(tracksNA(k).xCoord(x)),x),curRange);
%         elseif attribute==2
%             tracksNA(k).forceMag(curRange) = arrayfun(@(x) imgStack(round(tracksNA(k).yCoord(x)),round(tracksNA(k).xCoord(x)),x),curRange);
%         end
%     else
    if attribute==1
        startFrame = max(1, tracksNA(k).startingFrame-extraLength);
        endFrame = min(numFrames,tracksNA(k).endingFrame+extraLength);
        curStartingFrame = tracksNA(k).startingFrame;
        curEndingFrame = tracksNA(k).endingFrame;
        % for the earlier time-points - going backward
        ii=curStartingFrame;
        x = tracksNA(k).xCoord(ii);
        y = tracksNA(k).yCoord(ii);
        A = tracksNA(k).amp(curStartingFrame);
        c = tracksNA(k).bkgAmp(curStartingFrame); 
        
        for ii=curStartingFrame:-1:startFrame
            curImg = imgStack(:,:,ii);
            p=-1;
%             curSigma = sigma;
%             pitFound = false;
            while p<=30
                oldP = p;
                p=p+1;
                pmP =ceil(p/2)*(-1)^oldP;
                curSigma = sigma*(20-pmP)/20; % increasing sigma by 5 percent per each iteration
                pitFound = false;
                curAlpha = 0.05+p/100;
                pstruct = fitGaussians2D(curImg, x, y, A, curSigma, c, 'xyac','Alpha',curAlpha);
                if ~isnan(pstruct.x) && abs(pstruct.x-x)<2 && abs(pstruct.y-y)<2 && pstruct.A>0 && pstruct.A<2*A
                    x = pstruct.x;
                    y = pstruct.y;
                    A = pstruct.A;
                    c = pstruct.c; 
                    xi = round(x);
                    yi = round(y);
                    xRange = xi-1:xi+1;
                    yRange = yi-1:yi+1;
                    curAmpTotal = curImg(yRange,xRange);
                    curAmpTotal = mean(curAmpTotal(:));
                    tracksNA(k).startingFrameExtra = ii;
                    tracksNA(k).xCoord(ii) = x;
                    tracksNA(k).yCoord(ii) = y;
                    tracksNA(k).amp(ii) = A;
                    tracksNA(k).bkgAmp(ii) = c;
                    tracksNA(k).ampTotal(ii) =  curAmpTotal;
                    tracksNA(k).presence(ii) =  1;
                    pitFound = true;
                    break
                end
            end
            if ii~=curStartingFrame && ~pitFound
                tracksNA(k).startingFrameExtra = ii+1;
                break
            elseif  ii==curStartingFrame && ~pitFound
                tracksNA(k).startingFrameExtra = ii;
                break
            end
        end
        % for the present period
        for ii=curStartingFrame+1:curEndingFrame;
            x = tracksNA(k).xCoord(ii);
            y = tracksNA(k).yCoord(ii);
            A = tracksNA(k).amp(curStartingFrame);
            c = tracksNA(k).bkgAmp(curStartingFrame); 
            xi = round(x);
            yi = round(y);
            xRange = xi-1:xi+1;
            yRange = yi-1:yi+1;
            curAmpTotal = curImg(yRange,xRange);
            curAmpTotal = mean(curAmpTotal(:));
            tracksNA(k).ampTotal(ii) =  curAmpTotal;

            curImg = imgStack(:,:,ii);
            p=-1;
            while p<=30
                oldP = p;
                p=p+1;
                pmP =ceil(p/2)*(-1)^oldP;
                curSigma = sigma*(20-pmP)/20; % increasing sigma by 5 percent per each iteration
%                 curSigma = sigma*(20-p)/20; % increasing sigma by 5 percent per each iteration
                pstruct = fitGaussians2D(curImg, x, y, A, curSigma, c, 'xyac');
                if ~isnan(pstruct.x) && abs(pstruct.x-x)<2 && abs(pstruct.y-y)<2 && pstruct.A>0 && pstruct.A<2*A
                    x = pstruct.x;
                    y = pstruct.y;
                    A = pstruct.A;
                    c = pstruct.c; 
                    xi = round(x);
                    yi = round(y);
                    xRange = xi-1:xi+1;
                    yRange = yi-1:yi+1;
                    curAmpTotal = curImg(yRange,xRange);
                    curAmpTotal = mean(curAmpTotal(:));
                    tracksNA(k).xCoord(ii) = x;
                    tracksNA(k).yCoord(ii) = y;
                    tracksNA(k).amp(ii) = A;
                    tracksNA(k).bkgAmp(ii) = c;
                    tracksNA(k).ampTotal(ii) =  curAmpTotal;
                    tracksNA(k).presence(ii) =  1;
                    break
                end
            end
        end
        % for the later time-points - going forward, x and y are already
        % set as a last point.
        for ii=(curEndingFrame+1):endFrame
            curImg = imgStack(:,:,ii);
            pitFoundEnd = false;
            p=-1;
            while p<=30
                oldP = p;
                p=p+1;
                pmP =ceil(p/2)*(-1)^oldP;
                curSigma = sigma*(20-pmP)/20; % increasing sigma by 5 percent per each iteration
                curAlpha = 0.05+p/100;
                pstruct = fitGaussians2D(curImg, x, y, A, curSigma, c, 'xyac','Alpha',curAlpha);
                if ~isnan(pstruct.x) && abs(pstruct.x-x)<2 && abs(pstruct.y-y)<2 && pstruct.A>0 && pstruct.A<2*A
                    x = pstruct.x;
                    y = pstruct.y;
                    A = pstruct.A;
                    c = pstruct.c; 
                    xi = round(x);
                    yi = round(y);
                    xRange = xi-1:xi+1;
                    yRange = yi-1:yi+1;
                    curAmpTotal = curImg(yRange,xRange);
                    curAmpTotal = mean(curAmpTotal(:));
                    tracksNA(k).endingFrameExtra = ii;
                    tracksNA(k).xCoord(ii) = x;
                    tracksNA(k).yCoord(ii) = y;
                    tracksNA(k).amp(ii) = A;
                    tracksNA(k).bkgAmp(ii) = c;
                    tracksNA(k).ampTotal(ii) =  curAmpTotal;
                    tracksNA(k).presence(ii) =  1;
                    pitFoundEnd = true;
                    break
                end
            end
            if ~pitFoundEnd
                tracksNA(k).endingFrameExtra = ii-1;
                break
            end
        end
        if startFrame==curStartingFrame
            tracksNA(k).startingFrameExtra = curStartingFrame;
        end
        if endFrame==curEndingFrame
            tracksNA(k).endingFrameExtra = curEndingFrame;
        end
    elseif attribute==2
        try
            startFrame = tracksNA(k).startingFrameExtra;
            endFrame = tracksNA(k).endingFrameExtra;
        catch
            startFrame = max(1, tracksNA(k).startingFrame-extraLength);
            endFrame = min(numFrames,tracksNA(k).endingFrame+extraLength);
        end
        for ii=startFrame:endFrame
            curImg = imgStack(:,:,ii);
            x = tracksNA(k).xCoord(ii);
            y = tracksNA(k).yCoord(ii);
            xi = round(x);
            yi = round(y);
            xRange = xi-1:xi+1;
            yRange = yi-1:yi+1;
            curAmpTotal = curImg(yRange,xRange);
            tracksNA(k).forceMag(ii) = mean(curAmpTotal(:));
        end        
    elseif extrapolState
        disp('Please choose 1 or 2 for attribute.')
    end
    progressText(k/(numTracks-1),'Re-reading and tracking individual tracks:');
%     parfor_progress;
end
end
%         for ii=startFrame:endFrame
%             curImg = imgStack(:,:,ii);
%             if ii<curStartingFrame
% %                 x = tracksNA(k).xCoord(curStartingFrame);
% %                 y = tracksNA(k).yCoord(curStartingFrame);
% %                 A = tracksNA(k).amp(curStartingFrame);
% %                 c = tracksNA(k).bkgAmp(curStartingFrame); 
%                 extrapolState=1;
%             elseif ii>curEndingFrame
% %                 x = tracksNA(k).xCoord(curEndingFrame);
% %                 y = tracksNA(k).yCoord(curEndingFrame);
%                 extrapolState=1;
%             else
%                 x = tracksNA(k).xCoord(ii);
%                 y = tracksNA(k).yCoord(ii);
%                 A = tracksNA(k).amp(curStartingFrame);
%                 c = tracksNA(k).bkgAmp(curStartingFrame); 
%                 extrapolState=0;
%             end
%             if attribute==1 && extrapolState %intensity
%                 xi = floor(x);
%                 xres = x-xi;
%                 yi = floor(y);
%                 yres = y-yi;
%                 curAmpTotal = curImg(yi,xi);
% %                 window = curImg(yi-w4:yi+w4, xi-w4:xi+w4);
% %                 [prmVect]=fitGaussianMixture2D(window,[x-xi+w4,y-yi+w4,A,sigma,c],'xyas');
% %                 [prmVect]=fitGaussianMixture2D(window,[x-xi+w4,y-yi+w4,curAmpTotal-min(window(:)),sigma,min(window(:))],'xyas');
%                 pstruct = fitGaussians2D(curImg, x, y, A, sigma, c, 'xyasc','WindowSize',8);
%                 if (abs(prmVect(1)-xres)<2 && abs(prmVect(2)-yres)<2 && prmVect(3)>0 && prmVect(3)<2*(curAmpTotal-min(window(:))))
%                     tracksNA(k).xCoord(ii) = xi + prmVect(1);
%                     tracksNA(k).yCoord(ii) = yi + prmVect(2);
%                     tracksNA(k).amp(ii) = prmVect(3);
%                     tracksNA(k).bkgAmp(ii) = prmVect(5);
%                     tracksNA(k).ampTotal(ii) =  prmVect(3)+prmVect(5);
%                 end
%                 tracksNA(k).ampTotal(ii) = curAmpTotal;
%             elseif attribute==1 && ~extrapolState %intensity
%                 xi = round(x);
%                 yi = round(y);
%                 xRange = xi-1:xi+1;
%                 yRange = yi-1:yi+1;
%                 curAmpTotal = curImg(yRange,xRange);
%                 tracksNA(k).ampTotal(ii) = mean(curAmpTotal(:));
% %                 curAmpTotal = curImg(yi,xi);
% %                 tracksNA(k).ampTotal(ii) = curAmpTotal;
%             elseif attribute==2 %forceMag
%                 xi = round(x);
%                 yi = round(y);
%                 xRange = xi-1:xi+1;
%                 yRange = yi-1:yi+1;
%                 curAmpTotal = curImg(yRange,xRange);
%                 tracksNA(k).forceMag(ii) = mean(curAmpTotal(:));
% %                 tracksNA(k).forceMag(ii) = curImg(round(y),round(x));
%             elseif extrapolState
%                 disp('Please choose 1 or 2 for attribute.')
%             end
%         end
%     end
% end
% end
