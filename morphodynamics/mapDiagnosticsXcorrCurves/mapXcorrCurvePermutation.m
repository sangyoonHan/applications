function mapXcorrCurvePermutation(MD, iChan1, iChan2, chan1Name, chan2Name, layerMax, figuresDir, varargin) 
% mapXcorrCurvePermutation Perform cross correlation analysis between two
% channels. It plots cross correlation maps, their mean curves
% at each layer together with confidence bounds based on permutation, and a
% topograph of the cross correlations at lag 0. The cross correlations at
% lag h are Corr(chan1_{t+h}, chan2_t).
% It computes cross correlations in a fashion that can handle many NaN's 
% by utilizing nanXcorrMaps.m function.
%
% Usage:
%       mapXcorrCurvePermutation(MD, 2, 1, 'mDia1', 'Actin', 3, ...
%           fullfile(MD.outputDirectory_, 'mapCrossCorr'), 'impute', 1, 'parpoolNum', 4) 
%
% Input:
%       MD          - a movieData object
%       iChan1      - the 1st channel index
%       chan1Name   - a short name for channel1.
%       iChan2      - the 2nd channel index
%       chan2Name   - a short name for channel2.
%       layerMax    - maximum layer to be analyzed      
%       figuresDir  - a directory where plots are saved as png files
%
% Output: png files are saved in the figuresDir. 
%       
% Option:
%       figFlag     - if 'on', matlab figures are ploted. Default is 'off'.
%       lagMax      - the maximum lag to compute. Default is the number of
%                   time frames devided by 4.
%       fullRange   - if true, smoothed xcorr maps are given in [-1, 1]
%                   scale to compare multiple xcorr maps. Default is false.
%       impute      - if true, moderate missing values are imputed by using
%                   knnimpute.m function. Default is false.
%       parpoolNum  - number of local parallel pool used during permutation. Default is 4.
%       rseed       - input for running rng('default'); rng(rseed). Default
%                   is 'shuffle'. If it is a specific number, the permutation will give
%                   the same result.
%       numPerm     - number of permutation. Default is 1000.
%       WithN       - if true, it uses an alternative windowSampling result
%                   which is obtained by sampleMovieWindowsWithN.m and includes number
%                   of pixels for each windows. Default is false.
%       omittedWindows  
%                   - window index in which activities will be replaced by
%                   NaN. Default is null.
%       subFrames
%                   - specified frames will be only used.        
%
% Updated: J Noh, 2017/10/11, raw activities can be smoothed. New option is
% 'movingAvgSmoothing'.
% J Noh, 2017/10/06. impute default is now false.
% J Noh, 2017/08/26. To deal with differenced channels. 
%        iChan = 1x indicates the differenced map (X_t =X_{t-1}) of channel x.
% Jungsik Noh, 2017/05/23     
% Jungsik Noh, 2016/10/22



tmax = MD.nFrames_;

ip = inputParser; 
ip.addParameter('figFlag', 'off');
ip.addParameter('lagMax', round(tmax/4), @isnumeric);
ip.addParameter('fullRange', false);
ip.addParameter('parpoolNum', 4);
ip.addParameter('rseed', 'shuffle');
ip.addParameter('numPerm', 1000);
ip.addParameter('impute', false);
ip.addParameter('WithN', false);
ip.addParameter('subFrames', []);
ip.addParameter('omittedWindows', []);
ip.addParameter('movingAvgSmoothing', false);
ip.addParameter('topograph', 'on');


parse(ip, varargin{:})
p = ip.Results;

%figFlag = p.figFlag;

%%  figuresDir setup
if ~isdir(figuresDir); mkdir(figuresDir); end

tmptext = ['mapXcorrCurvePermutation_', 'inputParser.mat'];
save(fullfile(figuresDir, tmptext), 'p')


%%  getting Maps from channels 1, 2

[~, ~,MDtimeInterval_, wmax, tmax, ~, ~, imActmap1] ...
            = mapOutlierImputation(MD, iChan1, layerMax, 'impute', p.impute, ...
            'omittedWindows', p.omittedWindows, 'WithN', p.WithN, 'subFrames', p.subFrames, ...
            'movingAvgSmoothing', p.movingAvgSmoothing);

[~, ~, ~, ~, ~, ~, ~, imActmap2] ...
            = mapOutlierImputation(MD, iChan2, layerMax, 'impute', p.impute, ...
            'omittedWindows', p.omittedWindows, 'WithN', p.WithN, 'subFrames', p.subFrames, ...
            'movingAvgSmoothing', p.movingAvgSmoothing); 


%% variable set up

%imActmap1_layer = cell(1, layerMax);
%imActmap2_layer = cell(1, layerMax);

%for indL = 1:layerMax
%    imActmap1_layer{indL} = reshape(imActmap1{indL}, wmax, 1, tmax);
%end
%imActmap1_3dim = cat(2, imActmap1_layer{1:end});

%for indL = 1:layerMax
%    imActmap2_layer{indL} = reshape(imActmap2{indL}, wmax, 1, tmax);
%end
%imActmap2_3dim = cat(2, imActmap2_layer{1:end});
%%  to handle vel channel reads

if layerMax > 1
    if numel(imActmap1) == 1
        for indL = 2:layerMax; imActmap1{indL} = imActmap1{1}; end
    end
    if numel(imActmap2) == 1
        for indL = 2:layerMax; imActmap2{indL} = imActmap2{1}; end
    end
end


%%  input prepare and call xcorrCurvePermutationTest

ch1Actmap = imActmap1;
ch2Actmap = imActmap2;
ch1ActmapName = chan1Name;
ch2ActmapName = chan2Name;
%lagMax
fsaveName0 = ['Ch', num2str(iChan1), 'Ch', num2str(iChan2)];

xcorrMat = xcorrCurvePermutationTest(ch1Actmap, ch2Actmap, ch1ActmapName, ch2ActmapName, ...
              fsaveName0, MDtimeInterval_, figuresDir, ...
              'figFlag', p.figFlag, 'fullRange', p.fullRange, 'lagMax', p.lagMax, ...
              'numPerm', p.numPerm, 'parpoolNum', p.parpoolNum, 'rseed', p.rseed);
  


%%  Topographs of xcorr
if strcmp(p.topograph, 'on')

iWinProc = MD.getProcessIndex('WindowingProcess',1,0);

nBandMax_ = MD.processes_{iWinProc}.nBandMax_;
topoMap = nan(wmax, nBandMax_);

for indL = 1:layerMax
    tmp = xcorrMat{indL};
    tmp2 = tmp(:, p.lagMax+1);                % 7 = lagMax+1+h. lag=gef_t+..., stdN_t
    topoMap(:, indL) = tmp2;
end


title0 = ['xcorr(', chan1Name, '_{t}, ', chan2Name, '_t)'];   % lag = {t+ ...} 
topoFig_xcorrChan1Chan2 = topographMD(MD, tmax, 1, topoMap, title0, p.figFlag);
 

%%
saveas(topoFig_xcorrChan1Chan2, fullfile(figuresDir, ['/topoFig_xcorr_', fsaveName0, '.png']), 'png')  

end

%%
disp('====End of mapXcorrCurvePermutation====')


end




