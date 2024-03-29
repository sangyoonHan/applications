%
% an approach to count single molecules
% 
% supplied input variables on workspace
%   -> tracksFinal as output from uTrack package
%   -> MD is the movie data file that is input into uTrack
%   
% US, 2013/01/30
%

% some basic definitions that are likely to be changed
%   tExp  ->  exposure time in seconds
% imSize  ->  image size in pixel
%    rep  ->  number of frames in activation cycle
tExp=0.1165;
imSize=[256,256];
rep=10;

movieLength = MD.nFrames_;
nTracks=numel(tracksFinal);

maxGap = 10;

%
% new struct 'track' with the following members:
%
%      coord  ->  coordinates and corresponding errors
%        com  ->  center of mass
%   timeInfo  ->  start, end, duration in frames
%  gapClosed  ->  gap closing used?
%     fromUV  ->  induced by UV activation?
%
track=repmat(...
    struct('coord',[],'com',[],'amp',[],'timeInfo',[],'gapClosed',false,'fromUV',false),nTracks,1);

% index of UV induced tracks
idxUV=false(nTracks,1);

% an index of which tracks span the whole movie
isDrift = false(nTracks,1);

% an index of which tracks have more than one point
isMany = false(nTracks,1);

%
isearly = false(nTracks,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                                             
%%%  bring tracksFinal in human-readable form
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:nTracks
    
    startF=min( tracksFinal(i).seqOfEvents(:,1) );
    stopF=max( tracksFinal(i).seqOfEvents(:,1) );
    
    track(i).timeInfo(1)=startF;
    track(i).timeInfo(2)=stopF;
    track(i).timeInfo(3)=stopF-startF+1;
    track(i).timeInfo(4)=double(MD.getReader().getMetadataStore().getPlaneDeltaT(0, startF-1));
    track(i).timeInfo(5)=double(MD.getReader().getMetadataStore().getPlaneDeltaT(0, stopF-1));
    track(i).timeInfo(6)=floor(startF/10)+1; %number of uv activations it has been exposed to
        
    if startF < 11
        isearly(i)=true;
    end
    
    % mark tracks right after UV activation
    if mod(startF,rep) == 1
        track(i).fromUV=true;
        idxUV(i)=true;
    end
    
    %mark tracks if they span the whole movie
    if track(i).timeInfo(3) >= 100
        isDrift(i)=true;
    end
    
    % coordinates, amplitudes and corresponding errors
    p=tracksFinal(i).tracksCoordAmpCG;
    [nrows,ncols]=size(p);
    tmp=reshape(p,8,ncols/8)';
    tmp(:,end+1)=[startF:stopF];
    track(i).coord=tmp(:,[1,2,5,6]);
    track(i).amp=tmp(:,[4,8,end]);
    % center of mass calculated as a weigthed mean
    idx=~isnan(tmp(:,1));
    tmp=tmp(idx,:);
    [nrows,ncols]=size(tmp);
    if( nrows > 1 )
        [wm,ws]=weightedStats(tmp(:,1:2),tmp(:,5:6),'s');
        track(i).com=[wm,ws,sqrt(sum(ws.^2))];
        isMany(i) = true;
    else
        track(i).com=[tmp(1:2), tmp(5:6), sqrt(sum(tmp(5:6).^2))];
    end
    % mark klusters with gap closing
    if any( isnan(tmp(:)) )
        track(i).gapClosed=true;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%  Drift correct the tracks
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %Only for perfect tracking of drift markers
% ind = find(isDrift);
% 
% drift = zeros(movieLength,2);
% trackUnCorrected = track;
% 
% if ~isempty(ind)
%     for i = 1:numel(ind)
%         x = track(ind(i)).coord(:,1);
%         y = track(ind(i)).coord(:,2);
%         drift(2:end,:) = drift(2:end,:) + [diff(x),diff(y)];
%     end
%     
%     drift = drift/numel(ind);
%     drift = cumsum(drift);
% end

ind = find(isDrift);

drift = zeros(movieLength,2);
trackUnCorrected = track;


if ~isempty(ind)
    numpnts = drift;
    
    for i = 1:numel(ind)
        x = track(ind(i)).coord(:,1);
        y = track(ind(i)).coord(:,2);
        
        if sum(isnan(x)) > 0
            x = gapInterpolation(x,maxGap)';
            y = gapInterpolation(y,maxGap)';
        end            
        
        t = track(ind(i)).timeInfo(1:2); %time range in frames
        drift(t(1)+1:t(2),:) = drift(t(1)+1:t(2),:) + [diff(x),diff(y)];
        numpnts(t(1)+1:t(2),:) = numpnts(t(1)+1:t(2),:) + ones(size(numpnts(t(1)+1:t(2),:)));
    end
    
    %makes sure that the first point is not neglected
    numpnts(1,:)=1;
    
    % finds points with no data to avoid divide by zero
    DriftMiss = find(numpnts(:,1) == 0);
    numpnts(DriftMiss,:)=1;
    
    if ~isempty(DriftMiss)
       ['We have a few (',num2str(numel(DriftMiss)),') missed frames of correction']
    end
    
    drift = drift./numpnts;
    drift = cumsum(drift);
end

for i =1:nTracks
    frames = track(i).amp(:,end);
    coord =track(i).coord;
    coord(:,[1,2]) = coord(:,[1,2]) - drift(frames,:);
    track(i).coord = coord;
    
    % Recaculate center of mass calculated as a weigthed mean
    idx=~isnan(coord(:,1));
    tmp = coord(idx,:);
    [nrows,ncols]=size(tmp);
    if( nrows > 1 )
        [wm,ws]=weightedStats(tmp(:,1:2),tmp(:,3:4),'s');
        track(i).com=[wm,ws,sqrt(sum(ws.^2))];
    else
        track(i).com=[tmp(1:2), tmp(3:4), sqrt(sum(tmp(3:4).^2))];
    end
    
end

track = track(~isDrift);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%  Removes points that appear in only 1 frame
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% trackCorrect = track; %saves drift corrected
 
%track = track(isMany);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%  Removes tracks that don't start imediately after activation
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

%track = track(idxUV);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%  Removes tracks that don't appear in the first frames of the movie
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%track = track(~isearly);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%  determine rates of the underlying photo-kinetics
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% start with distribution of ON times
timeON=vertcat(track.timeInfo);
%timeON=timeON(:,3)*tExp;
% timeON = timeON(:,5)-timeON(:,4);
% bins=0:tExp:max(timeON);
% [yON,xON]=hist(timeON,bins);
% 
% % create and fit CDF of ON times: 1-exp(-kc*x)
% % kc is the sum of the OFF and bleaching rate
% area=tExp*sum(yON);
% yONcdf=cumsum(yON)*tExp/area;
% 
% ft=fittype(@(kc,x) 1.0-exp(-kc*x));
% pini=( yONcdf(2)-yONcdf(1) )/( xON(2)-xON(1) );
% tonFit=fit(xON(3:end)',yONcdf(3:end)',ft,'StartPoint',pini);

%% continue with distribution of blinks

% group center of mass of tracks via mean-shift clustering
allCom=vertcat(track.com);
[clusterInfo,clusterMap]=MeanShiftClustering(allCom(:,1:2),0.5,'kernel','flat');

doesBlink = false(numel(clusterInfo),1);

lengthBlink=[];
lengthUnBlink=[];

for i=1:numel(clusterInfo)
    numPts=clusterInfo(i).numPoints;
    if numPts > 1
        doesBlink(i) = true;
    end
    tmp=[];
    tmp2=[];
    for k=1:numPts
        ptID=clusterInfo(i).ptIdData(k);
        placeHolder =[track(ptID).coord track(ptID).amp];
        [row,col]=size(placeHolder);
        tmp=vertcat(tmp,placeHolder);
        tmp2=vertcat(tmp2,track(ptID).timeInfo);
        
        if doesBlink(i)
            lengthBlink = [lengthBlink,row];
        else
            lengthUnBlink = [lengthUnBlink,row];
        end
    end
    clusterInfo(i).data=tmp;
    clusterInfo(i).time=tmp2;
    
    if size(tmp,1) > 1
        [wm,ws]=weightedStats(tmp(:,1:2),tmp(:,3:4),'s');
        clusterInfo(i).ptClusterCenter=[wm,ws,sqrt(sum(ws.^2))];
    else
        clusterInfo(i).ptClusterCenter=[tmp(1:4),sqrt(sum(tmp(3:4).^2))];
    end
end

figure, hist(lengthBlink,1:max(lengthBlink));
title('Length of tracks of blinking dyes');
xlim([0,50]);

figure, hist(lengthUnBlink,1:max(lengthUnBlink));
title('Length of tracks of "non-blinking dyes"');
xlim([0,50]);


%removes clusters composed of only 1 track
% should remove noise

 %  clusterInfoBack = clusterInfo;
  % clusterInfo = clusterInfo(doesBlink);


%% number of blinks, fit to CDF of geometric distribution
nBlinks=vertcat(clusterInfo.numPoints);
nBlinks=nBlinks-1;
[yBl,xBl]=hist(nBlinks,0:max(nBlinks));

area=sum(yBl);
yBlcdf=cumsum(yBl)/area;

% parameter of geometric distribution q = koff/(koff+kbleach)
ft=fittype('1.0-q^(x+1)');
pini=0.5;
blinkFit=fit(xBl',yBlcdf',ft,'StartPoint',pini);

%% calculate koff and kbleach from q and kc
% q=blinkFit.q;
% kc=tonFit.kc;
% 
% koff=q*kc;
% kbleach=kc-koff;
% 
% % error propagation
% tmp1=confint(blinkFit);
% q_err=q-tmp1(1);
% tmp2=confint(tonFit);
% kc_err=kc-tmp2(1);
% koff_err=sqrt( (kc*q_err)^2 + (q*kc_err)^2 );
% kbleach_err=sqrt( koff_err^2 + kc_err^2 );


%% continue with distribution of OFF times
toff=[];
tfirst=[];
twait=[];
toffuv=[];
tfirstuv=[];
twaituv=[];
% for k=1:numel(clusterInfo)
%     timeInfo=clusterInfo(k).time;
%     toff=vertcat(toff,timeInfo(2:end,1)-timeInfo(1:end-1,2));
%     toff=vertcat(toff,timeInfo(1,1));
% end

 for k=1:numel(clusterInfo)
     timeInfo=clusterInfo(k).time;
     twait=vertcat(twait,timeInfo(2:end,4)-timeInfo(1:end-1,5));
     toff=vertcat(toff,timeInfo(2:end,4)-timeInfo(1:end-1,5));
     toff=vertcat(toff,timeInfo(1,4));
     tfirst=vertcat(tfirst,timeInfo(1,4));
     
     %same but in the difference of number of UV pulses experienced
     twaituv=vertcat(twaituv,timeInfo(2:end,6)-timeInfo(1:end-1,6));
     toffuv=vertcat(toffuv,timeInfo(2:end,6)-timeInfo(1:end-1,6));
     toffuv=vertcat(toffuv,timeInfo(1,6));
     tfirstuv=vertcat(tfirstuv,timeInfo(1,6));
     
 end



%toff=toff*tExp;
[yOFF,xOFF]=hist(toff,tExp/2:tExp:max(toff)-tExp/2);
yOFFcdf=cumsum(yOFF)/sum(yOFF);

%fit wait times to a distribution that reflects Uv and Thermal
%reactivation
%pini=( yOFFcdf(2)-yOFFcdf(1) )/( xOFF(2)-xOFF(1) );
pini = mean( diff(yOFFcdf(1:30))./diff(xOFF(1:30)));

opte = fitoptions('Method','NonLinearLeastSquares','Lower',[0,0,0],'Upper',[1,1,1],'StartPoint',[pini,pini,0.5000]);
%opt = fitoptions('Method','NonLinearLeastSquares','Lower',[0,0,0],'Upper',[Inf,Inf,1],'StartPoint',[pini,1/max(xOFF),0.5000]);
opt = fitoptions('Method','NonLinearLeastSquares','Lower',[0,0],'Upper',[Inf,1],'StartPoint',[pini,0.5000]);
et=fittype(@(k1,k2,A,x) 1.0-A*exp(-k1*x)-(1-A)*exp(-k2*x),'options',opte);
%ft=fittype(@(k1,k2,A,x) A*(1.0-exp(-k1*x))+(1-A)*k2*x,'options',opt);
ft=fittype(@(k1,A,x) A*(1.0-exp(-k1*x))+(1-A)*x/max(xOFF),'options',opt);

%ft=fittype(@(k1,x) 1.0-exp(-k1*x));
[toffFit,goodnessOFF]=fit(xOFF',yOFFcdf',ft);
[toffFitE,goodnessOFFE]=fit(xOFF',yOFFcdf',et);

figure,subplot(2,1,1),bar(xOFF,yOFFcdf);
xlim([0,max(xOFF)]);
hold;
plot(toffFit,'predobs');
plot(toffFitE,'-g','predobs');
title('CDF of wait times');
hold;
subplot(2,1,2),plot(toffFit,xOFF',yOFFcdf','residuals');
hold;
subplot(2,1,2),plot(toffFitE,xOFF',yOFFcdf','-g.','residuals');
xlim([0,max(xOFF)]);
hold;

%now calculate the rate of first appearance
[yFirst,xFirst]=hist(tfirst,tExp/2:tExp:max(tfirst)-tExp/2);
yFirstcdf=cumsum(yFirst)/sum(yFirst);

%pini2=( yFirstcdf(2)-yFirstcdf(1) )/( xFirst(2)-xFirst(1) );
pini2 = mean( diff(yFirstcdf(1:30))./diff(xFirst(1:30)));
ft=fittype(@(k1,A,x) A*(1.0-exp(-k1*x))+(1-A)*x/max(xFirst),'options',opt);
[tfirstFit,goodnessFirst] = fit(xFirst',yFirstcdf',ft,'StartPoint',[toffFit.k1,0.5]);
[tfirstFitE,goodnessFirst] = fit(xFirst',yFirstcdf',et,'StartPoint',[pini2,pini2,0.5]);

figure,subplot(2,1,1),bar(xFirst,yFirstcdf);
xlim([0,max(xFirst)]);
hold
plot(tfirstFit,'predobs');
plot(tfirstFitE,'-g','predobs');
title('CDF of time to first appearance');
hold;
subplot(2,1,2),plot(tfirstFit,xFirst',yFirstcdf','residuals');
hold;
subplot(2,1,2),plot(tfirstFitE,xFirst',yFirstcdf','-g.','residuals');
xlim([0,max(xFirst)]);
hold;

%now calculate wait times without first appearances

[yWait,xWait]=hist(twait,tExp/2:tExp:max(twait)-tExp/2);
yWaitcdf=cumsum(yWait)/sum(yWait);

%pini3=( yWaitcdf(2)-yWaitcdf(1) )/( xWait(2)-xWait(1) );
pini3 = mean( diff(yWaitcdf(1:30))./diff(xWait(1:30)));
ft=fittype(@(k1,A,x) A*(1.0-exp(-k1*x))+(1-A)*x/max(xWait),'options',opt);
[tWaitFit,goodnessWait]=fit(xWait',yWaitcdf',ft,'StartPoint',[toffFit.k1,0.5]);
[tWaitFit,goodnessWait]=fit(xWait',yWaitcdf',et,'StartPoint',[pini3,pini3,0.5]);

%repeat above but in terms of number of uv activations
%
%
%

[yOFFuv,xOFFuv]=hist(toffuv,1:max(toffuv));
yOFFuvcdf=cumsum(yOFFuv)/sum(yOFFuv);

%fit wait times to a distribution that reflects Uv and Thermal
%reactivation
piniuv=( yOFFuvcdf(2)-yOFFuvcdf(1) )/( xOFFuv(2)-xOFFuv(1) );

%opt2 = fitoptions('Method','NonLinearLeastSquares','Lower',[0,0,0],'Upper',[1,1,1],'StartPoint',[piniuv,piniuv/10,0.5000]);
opt2 = fitoptions('Method','NonLinearLeastSquares','Lower',[0,0],'Upper',[Inf,1],'StartPoint',[piniuv,0.5000]);
opt2e = fitoptions('Method','NonLinearLeastSquares','Lower',[0,0,0],'Upper',[Inf,Inf,1],'StartPoint',[piniuv,piniuv,0.5000]);
et2=fittype(@(k1,k2,A,x) 1.0-A*exp(-k1*x)-(1-A)*exp(-k2*x),'options',opt2e);
%ft2=fittype(@(k1,k2,A,x) A*(1.0-exp(-k1*x))+k2*x,'options',opt2);
ft2=fittype(@(k1,A,x) A*(1.0-exp(-k1*x))+(1-A)*x/max(xOFFuv),'options',opt2);


%ft=fittype(@(k1,x) 1.0-exp(-k1*x));
[toffuvFit,goodnessOFFuv]=fit(xOFFuv',yOFFuvcdf',ft2);
[toffuvFitE,goodnessOFFuvE]=fit(xOFFuv',yOFFuvcdf',et2);

figure,subplot(2,1,1),bar(xOFFuv,yOFFuvcdf);
xlim([0,max(xOFFuv)]);
hold
plot(toffuvFit,'predobs');
plot(toffuvFitE,'-g','predobs');
title('CDF of wait times in uv activations');
hold;
subplot(2,1,2),plot(toffuvFit,xOFFuv',yOFFuvcdf','residuals');
hold;
subplot(2,1,2),plot(toffuvFitE,xOFFuv',yOFFuvcdf','-g','residuals');
xlim([0,max(xOFFuv)]);
hold;

%now calculate the rate of first appearance
[yFirstuv,xFirstuv]=hist(tfirstuv,1:max(tfirstuv));
yFirstuvcdf=cumsum(yFirstuv)/sum(yFirstuv);

pini2uv=( yFirstuvcdf(2)-yFirstuvcdf(1) )/( xFirstuv(2)-xFirstuv(1) );
ft2=fittype(@(k1,A,x) A*(1.0-exp(-k1*x))+(1-A)*x/max(xFirstuv),'options',opt2);
[tfirstuvFit,goodnessFirstuv] = fit(xFirstuv',yFirstuvcdf',ft2,'StartPoint',[toffuvFit.k1,0.5]);
[tfirstuvFitE,goodnessFirstuvE] = fit(xFirstuv',yFirstuvcdf',et2,'StartPoint',[pini2uv,pini2uv,0.5]);

figure,subplot(2,1,1),bar(xFirstuv,yFirstuvcdf);
xlim([0,max(xFirstuv)]);
hold
plot(tfirstuvFit,'predobs');
plot(tfirstuvFitE,'-g','predobs');
title('CDF of time to first appearance in uv activations');
hold;
subplot(2,1,2),plot(tfirstuvFit,xFirstuv',yFirstuvcdf','residuals');
hold;
subplot(2,1,2),plot(tfirstuvFitE,xFirstuv',yFirstuvcdf','-g','residuals');
xlim([0,max(xFirstuv)]);
hold;

%now calculate wait times without first appearances

[yWaituv,xWaituv]=hist(twaituv,1:max(twaituv));
yWaituvcdf=cumsum(yWaituv)/sum(yWaituv);

pini3uv=( yWaituvcdf(2)-yWaituvcdf(1) )/( xWaituv(2)-xWaituv(1) );
ft2=fittype(@(k1,A,x) A*(1.0-exp(-k1*x))+(1-A)*x/max(xWaituv),'options',opt2);
[tWaituvFit,goodnessWaituv]=fit(xWaituv',yWaituvcdf',ft2,'StartPoint',[toffuvFit.k1,0.5]);
[tWaituvFitE,goodnessWaituvE]=fit(xWaituv',yWaituvcdf',et2,'StartPoint',[pini3uv,pini3uv,0.5]);


%% Gets general time info for the movie

for i=0:movieLength-1
time(i+1)=double(MD.getReader().getMetadataStore().getPlaneDeltaT(0, i));
end


%% temporal dissection of clusters found via mean-shift


%% clear unused variables
clear startF stopF idx tmp i;
clear p nrows ncols;
clear tmp1 tmp2;

