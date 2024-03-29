function [fname0, MDpixelSize_, MDtimeInterval_, wmax, tmax, rawActmap, actmap_outl, imActmap, actmap_outlSc] ...
            = mapOutlierImputation(MD, iChan, maxLayer, varargin) 
% mapOutlierImputation Get the input of MD, iChan and maxLayer and Give the
% corresponding 3-dim (window, layer, time frame) activity array in raw,
% outlier-removed (>5*sigma), and imputed forms.
%
% Usage:
%       [fname0, MDpixelSize_, MDtimeInterval_, wmax, tmax, rawActmap, actmap_outl, imActmap]
%       = mapOutlierImputation(MD, iChan, maxLayer, varargin)                
%
% Input:
%       MD          - a movieData object
%       iChan       - a channel index. If 0, the edge velocity is analyzed.
%                     iChan = 1x indicates the differenced map (X_t =
%                     X_{t-1}) of channel x.
%       maxLayer    - maximum layer to be analyzed
%
% Output:
%       fname0      - a suggested file name for the map. ['Chan', num2str(iChan)]
%       MDpixelSize_    - pixelSize of the movieData
%       MDtimeInterval_ - time interval of the movieData
%       wmax        - number of windows per layer or nSliceMax_
%       tmax        - number of time frames or MD.nFrames_
%       rawActmap   - 3-dim'l array (window, layer, time frame) of raw
%                   activities.
%       actmap_outl - 3-dim'l array of outlier-removed activities. Outliers
%                   are determined for each layer based on (|Z-score| > 5).
%       imActmap    - 3-dim'l array of activities in which missing values
%                   are imputed by using k-nearest neighbor method. If
%                   'impute' option is false, imActmap is the same as
%                   actmap_outl.
%
% Option:
%       impute      - if true, moderate missing values are imputed by using
%                   knnimpute.m function. Default is true.
%       WithN       - if true, it uses an alternative windowSampling result
%                   which is obtained by sampleMovieWindowsWithN.m and includes number
%                   of pixels for each windows. Default is false.
%       omittedWindows  
%                   - window index in which activities will be replaced by
%                   NaN. Default is null.
%       subFrames
%                   - specified frames will be only used.        
%       movingAvgSmoothing
%                   - input activities are minimally convolved with just
%                   adjacent activities, that is, by using 3 by 3 patch.
%
% Updated: J Noh, 2017/10/11, raw activities can be smoothed. New option is
% 'movingAvgSmoothing'.
% J Noh, 2017/08/26, To deal with differenced channels. 
% Jungsik Noh, 2017/05/23
% Jungsik Noh, 2016/10/24


ip = inputParser;
ip.addParameter('impute', true);
ip.addParameter('WithN', false);
ip.addParameter('omittedWindows', []);
ip.addParameter('Folding', false);
ip.addParameter('subFrames', []);
ip.addParameter('movingAvgSmoothing', false);


parse(ip, varargin{:});
p = ip.Results;


%%  getting Maps from channels (0 indicates the edge velocity)

disp(['==== Channel index: ', num2str(iChan), ' ===='])

% 2017/08 p.derivative
p.derivative = (iChan >= 10);
mdChan = mod(iChan, 10);

%fnameChan = double(p.derivative)*10 + iChan;
%fname0 = ['Chan', num2str(fnameChan)];

fname0 = ['Chan', num2str(iChan)];
disp(fname0)

MDpixelSize_ = MD.pixelSize_;
MDtimeInterval_ = MD.timeInterval_; 

% velmap
if mdChan == 0

    indPSP = MD.getProcessIndex('ProtrusionSamplingProcess');
    PSP = MD.getProcess(indPSP);
    WSPresult = PSP.loadChannelOutput();
    protmap = WSPresult.avgNormal;
    %size(protmap)
    velmap = protmap*MDpixelSize_/MDtimeInterval_;     %%%%    velocity as nm/sec

    disp('size of velocity map')
    size(velmap)  
    
    indWP = MD.getProcessIndex('WindowingProcess');
    WP = MD.getProcess(indWP);
    %WP.nBandMax_
    wmax = WP.nSliceMax_;
    tmax = MD.nFrames_;
    
    velmapShift = [nan(wmax, 1), velmap(:, 1:(tmax-1))];
    
    actmap = reshape(velmapShift, wmax, 1, tmax);
    maxLayer = 1;

% actmap
elseif p.WithN == true

    % load all channels.mat for allSamplesWithN
    iWinPackInd = MD.getPackageIndex('WindowingPackage');
    if ~isempty(iWinPackInd)
        tmp = MD.packages_{iWinPackInd}.outputDirectory_;
        samplingWithNDirectory_ = fullfile(tmp, 'window_sampling_WithN');
        if ~isdir(samplingWithNDirectory_)
            tmp = MD.outputDirectory_;
            samplingWithNDirectory_ = fullfile(tmp, 'window_sampling_WithN');
        end
    else
        samplingWithNDirectory_ = fullfile(MD.outputDirectory_, 'window_sampling_WithN');
    end
        
    fname = 'all channels.mat';
    inFilePaths = fullfile(samplingWithNDirectory_, fname);
    load(inFilePaths, 'allSamplesWithN');

actmap = allSamplesWithN(mdChan).avg;    
    
    disp('size of activity map')
    size(actmap)  

    indWP = MD.getProcessIndex('WindowingProcess');
    WP = MD.getProcess(indWP);
    %WP.nBandMax_
    wmax = WP.nSliceMax_;
    tmax = MD.nFrames_;

else 

    indWSP = MD.getProcessIndex('WindowSamplingProcess');
    WSP = MD.getProcess(indWSP);
    WSPresult = WSP.loadChannelOutput(mdChan);  % Set channel of  ...
    actmap = WSPresult.avg;                    % actmap > rawActmap, actmap_outl, imActmap

    disp('size of activity map')
    size(actmap)  

    indWP = MD.getProcessIndex('WindowingProcess');
    WP = MD.getProcess(indWP);
    %WP.nBandMax_
    wmax = WP.nSliceMax_;
    tmax = MD.nFrames_;

end

%% p.derivative option  (old)

%% Omit windows

if numel(p.omittedWindows) > 0
    actmap(p.omittedWindows, :,:) = NaN;
end


%% Omit time frames

if numel(p.subFrames) > 0
    actmap = actmap(:,:, p.subFrames);
    tmax = size(actmap, 3);             %%% update tmax
end


%% if Folding

if p.Folding == 1

    if mod(tmax, 2) == 1
        tmax = tmax + 1;
        [a, b, ~] = size(actmap);
        actmap = cat(3, actmap, nan(a, b));
    end
    foldedMap = nan(wmax, maxLayer, tmax/2);

    for w = 1:wmax
    for l = 1:maxLayer
        for t = 1:(tmax/2)
            foldedMap(w, l, t) = mean([actmap(w, l, 2*t-1), actmap(w, l, 2*t)], 'omitnan');
        end
    end
    end
    actmap = foldedMap;
    tmax = size(foldedMap, 3);
    MDtimeInterval_ = MDtimeInterval_ * 2;

end



%%  Activity Map Outlier & remove windows
%% omitWin, subFr, Folding -> outlierAdj -> (movAvgSmoothing) -> Diff (smoothing again) -> (impute)

rawActmap = cell(1, maxLayer);
actmap_outl = cell(1, maxLayer);

for indL = 1:maxLayer
    disp(['==== ', num2str(indL), ' Layer ===='])  

    rawActmap{indL} = squeeze(actmap(:, indL, :));
    inputmap = rawActmap{indL};

    disp('# of NaN in map:')
    disp( sum(isnan(inputmap(:))) )

    disp('summary:')
    disp( summary(inputmap(:)) )
    m0 = mean(inputmap(:), 'omitnan'); %disp(m0)
    std0 = std(inputmap(:), 'omitnan'); %disp(std0)

    % 5*sigma
    [r, c] = find(abs(inputmap-m0)/std0 > 5);
    disp('row, column of outliers:')
    disp([r, c])
    actmap_outl{indL} = inputmap;
    actmap_outl{indL}(abs(inputmap-m0)/std0 > 5) = NaN; 

    disp('upper/lower threshold for outliers:')
    disp(m0+5*std0)
    disp(m0-5*std0)
    disp('num of outlier')
    disp( sum(sum(abs(inputmap-m0)/std0 > 5)) )

end



%% movAvg smoothing

if (p.movingAvgSmoothing == true)
    actmap_outl2 = actmap_outl;
    
    gaussianFilter = fspecial('gaussian', 3, 0.5);   %% minimal gaussian filtering
    
    for l = 1:maxLayer
        tmp = actmap_outl{l};    
        actmap_outl2{l} = nanconv(tmp, gaussianFilter, 'edge', 'nanout');
    end
    actmap_outl = actmap_outl2;
end


%% 10/18/2017 (temp)

if (p.movingAvgSmoothing > 0) & (p.movingAvgSmoothing < 1)
    actmap_outl2 = actmap_outl;
    smParam = p.movingAvgSmoothing;

    for indL = 1:maxLayer
        actmap_outl2{indL} = smoothActivityMap(actmap_outl{indL}, 'SmoothParam', smParam, 'UpSample', 1); 
    end
    actmap_outl = actmap_outl2;
end






%% p.derivative option 

if (p.derivative == true)
    actmap_outl2 = actmap_outl;
    for l = 1:maxLayer
        tmp = actmap_outl{l};
        difftmp = diff(tmp, [], 2);   % time-wise difference operation
        actmap_outl2{l} = [nan(size(tmp, 1), 1), difftmp];
    end
    actmap_outl = actmap_outl2;

    if iChan == 10
        for l = 1:maxLayer
            actmap_outl{l} = actmap_outl{l} ./ MDtimeInterval_;
        end
    end

%%%%%  Smoothing again the differences

    if (p.movingAvgSmoothing == true)
        actmap_outl2 = actmap_outl;

        gaussianFilter = fspecial('gaussian', 3, 0.5);   %% minimal gaussian filtering
        for l = 1:maxLayer
            tmp = actmap_outl{l};
            actmap_outl2{l} = nanconv(tmp, gaussianFilter, 'edge', 'nanout');
        end
        actmap_outl = actmap_outl2;
    end

end




%%  scaling the activity map

actmap_outlSc = cell(1, maxLayer);
for indL = 1:maxLayer
    
    actmap_outlCell = num2cell(actmap_outl{indL}, 2);
    actmap_outlZ = cellfun(@(x) nanZscore(x), actmap_outlCell, 'UniformOutput', false);
    actmap_outlSc{indL} = cell2mat(actmap_outlZ);
    
    % CentMap ...
    %actmap_outlSc{indL} = detrend(actmap_outl{indL}', 'constant')';
end




%%  Imputation (used as an input of computations), later maybe restricted

if p.impute == 1

    imActmap = cell(1, maxLayer);
    for indL = 1:maxLayer
        mat = actmap_outl{indL};
        imActmap{indL} = myknnimpute(mat')';     % Note tha double transeposes are necessary.
    end
else 
    imActmap = actmap_outl;
end


% if iChan==0, re-define output variables: not necessary


end

