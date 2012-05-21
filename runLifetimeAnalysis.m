function [res] = runLifetimeAnalysis(data, varargin)

ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('data', @(x) isstruct(x) && numel(unique([data.framerate]))==1);
ip.addOptional('lb', [3:10 11 16 21 41 61 81 101 141]);
ip.addOptional('ub', [3:10 15 20 40 60 80 100 140 200]);
ip.addParamValue('Display', 'on', @(x) strcmpi(x, 'on') | strcmpi(x, 'off'));
ip.addParamValue('FileName', 'ProcessedTracks.mat', @ischar);
ip.addParamValue('Type', 'all', @ischar);
ip.addParamValue('Cutoff_f', 4, @isscalar);
ip.addParamValue('Print', false, @islogical);
ip.addParamValue('Buffer', 5);
ip.parse(data, varargin{:});
lb = ip.Results.lb;
ub = ip.Results.ub;
nd = length(data);
nc = numel(lb); % # cohorts

% median absolute deviation -> standard deviation
madFactor = 1/norminv(0.75, 0, 1);

% Extend all to max. movie length, in case of mismatch
Nmax = max([data.movieLength])-2;
buffer = ip.Results.Buffer;
cutoff_f = ip.Results.Cutoff_f;

mCh = strcmp(data(1).source, data(1).channels);
framerate = data(1).framerate;

firstN = 3:20;

% loop through data sets, load tracks, store max. intensities and lifetimes
res = struct([]);
% fprintf('Lifetime analysis (%s) - loading tracks:     ', getShortPath(data));
fprintf('Lifetime analysis - loading tracks:   0%%');
for i = 1:nd
    tracks = loadTracks(data(i), 'Mask', true, 'Category', 'all', 'Cutoff_f', cutoff_f);
    lifetimes_s = [tracks.lifetime_s];
    
    % Category statistics
    idx_Ia = [tracks.catIdx]==1;
    idx_Ib = [tracks.catIdx]==2;
    idx_IIa = [tracks.catIdx]==5;
    v = hist([tracks.catIdx], 1:8);
    v = v/numel(tracks);
    res(i).trackClassStats = v;
    
    % raw histograms
    N = data(i).movieLength-2*buffer;
    t = (cutoff_f:N)*framerate;
    lftHist_Ia = hist(lifetimes_s(idx_Ia), t);
    lftHist_Ib = hist(lifetimes_s(idx_Ib), t);
    lftHist_IIa = hist(lifetimes_s(idx_IIa), t);
    
    % apply correction
    % relative probabilities:
    % P(obs. lifetime==1) = N
    % P(obs. lifetime==N) = 1
    % => weighting:
    w = N./(N-cutoff_f+1:-1:1);
    pad0 = zeros(1,Nmax-N);
    lftHist_Ia =  [lftHist_Ia.*w  pad0];
    lftHist_Ib =  [lftHist_Ib.*w  pad0];
    lftHist_IIa = [lftHist_IIa.*w pad0];
    res(i).t = (cutoff_f:Nmax)*framerate;
    
    % Normalization
    res(i).lftHist_Ia = lftHist_Ia / sum(lftHist_Ia) / framerate;
    res(i).lftHist_Ib = lftHist_Ib / sum(lftHist_Ib) / framerate;
    res(i).lftHist_IIa = lftHist_IIa / sum(lftHist_IIa) / framerate;
   
    % birth/death statistics
    startsPerFrame_allTracks = hist([tracks.start], 1:data(i).movieLength);
    startsPerFrame_allTracks = startsPerFrame_allTracks(6:end-5);
    
    %-------------------------------------------------------------
    % Initiation density
    %-------------------------------------------------------------
    
    % Cell area
    px = data(i).pixelSize / data(i).M; % pixels size in object space
    mpath = [data(i).source 'Detection' filesep 'cellmask.tif'];
    mask = logical(imread(mpath));
    res(i).cellArea = sum(mask(:)) * px^2 / 1e-12; % in �m^2
    
    % in �m min^-1
    res(i).initDensity = [median(startsPerFrame_allTracks); madFactor*mad(startsPerFrame_allTracks, 1)]/data(i).framerate*60/res(i).cellArea;
    
    
    
    %-------------------------------------------------------------
    % Max. intensity distribution for cat. Ia tracks
    %-------------------------------------------------------------
    tracks = tracks([tracks.catIdx]==1);
    lifetimes_s = [tracks.lifetime_s];
    trackLengths = [tracks.end]-[tracks.start]+1;
    nt = numel(tracks);
    
    M = NaN(nt, data(i).movieLength);
    for k = 1:nt
        M(k,1:trackLengths(k)) = tracks(k).A(mCh,:);
    end
    res(i).M = M;
    for k = 1:nc
        % indexes within cohorts
        cidx = lb(k)<=lifetimes_s & lifetimes_s<=ub(k);
        res(i).maxA{k} = nanmax(M(cidx,:),[],2);
        for n = firstN
            res(i).(['maxA_f' num2str(n)]){k} = nanmax(M(cidx,1:n),[],2);
        end
        
        % lifetimes for given cohort
        res(i).lft{k} = lifetimes_s(cidx);
    end
    
    res(i).lft_all = lifetimes_s;
    res(i).maxA_all = nanmax(M,[],2);
    res(i).firstN = firstN;
    
fprintf('\b\b\b\b%3d%%', round(100*i/nd));
end
fprintf('\n');

%====================
% Threshold
%====================
% Rescale EDFs (correction for FP-fusion expression level)
a = rescaleEDFs({res.maxA_all}, 'Display', false);

% apply scaling
for i = 1:nd
    res(i).maxA = cellfun(@(x) a(i)*x, res(i).maxA, 'UniformOutput', false);
    for n = firstN
        fname = ['maxA_f' num2str(n)];
        res(i).(fname) = cellfun(@(x) a(i)*x, res(i).(fname), 'UniformOutput', false);
    end
end

% lifetime cohort: [5..10] seconds
% combine first 5 frames from all cohorts
xa = 0:40:360;
da = xa(2)-xa(1);
dxi = da/8;
xi = 0:dxi:xa(end)+da;

maxIntDistCat_f5 = horzcat(res.maxA_f5);
maxIntDistCat_f5 = vertcat(maxIntDistCat_f5{:});

ni = hist(maxIntDistCat_f5, xi);
ni = ni/sum(ni)/dxi;

[mu_g sigma_g xg g] = fitGaussianModeToHist(xi, ni);
T = norminv(0.99, mu_g, sigma_g);


% loop through data sets, apply max. intensity threshold
for i = 1:nd
    idx = res(i).maxA_all >= T;
    res(i).lftAboveT = res(i).lft_all(idx);
    res(i).lftBelowT = res(i).lft_all(~idx);
    
    
    N = data(i).movieLength-2*buffer;
    t = (cutoff_f:N)*framerate;
    lftHist_A = hist(res(i).lftAboveT, t);
    lftHist_B = hist(res(i).lftBelowT, t);
    
    % apply correction
    % relative probabilities:
    % P(obs. lifetime==1) = N
    % P(obs. lifetime==N) = 1
    % => weighting:
    w = N./(N-cutoff_f+1:-1:1);
    pad0 = zeros(1,Nmax-N);
    lftHist_A =  [lftHist_A.*w  pad0];
    lftHist_B =  [lftHist_B.*w  pad0];
    
    % Normalization
    res(i).lftHist_A = lftHist_A / sum(lftHist_A) / framerate;
    res(i).lftHist_B = lftHist_B / sum(lftHist_B) / framerate;
end


% Concatenate

% maxIntDistCat = struct([]);
% for k = 1:numel(lb)
%     tmp = vertcat(res.maxA);
%     maxIntDistCat(k).maxA = vertcat(tmp{:,k});
%     
%     ni = hist(maxIntDistCat(k).maxA, xi);
%     maxIntDistCat(k).ni = ni/sum(ni)/dxi;
%     
%     for n = firstN
%         fname = ['maxA_f' num2str(n)];
%         tmp = vertcat(res.(fname));
%         maxIntDistCat(k).(fname) = vertcat(tmp{:,k});
%         
%         ni = hist(maxIntDistCat(k).(fname), xi);
%         maxIntDistCat(k).(['ni_f' num2str(n)]) = ni/sum(ni)/dxi;
%     end
%     
%     tmp = vertcat(res.lft);
%     maxIntDistCat(k).lft = horzcat(tmp{:,k});
% 
% %     if lb(k)==ub(k)
% %         maxIntDistCat(k).cohortLabel = num2str(lb(k));
% %     else
% %         maxIntDistCat(k).cohortLabel = [num2str(lb(k)) ' - ' num2str(ub(k))];
% %     end
% end

t_hist = (cutoff_f:Nmax)*framerate;
meanHist_A =  mean(vertcat(res.lftHist_A),1);
meanHist_B =  mean(vertcat(res.lftHist_B),1);

fset = loadFigureSettings();
hf(1) = figure;
hold on;
hp(2) = plot(t_hist, meanHist_B, '.-', 'Color', 0.6*[1 1 1], 'LineWidth', 2, 'MarkerSize', 16);
hp(1) = plot(t_hist, meanHist_A, '.-', 'Color', 'k', 'LineWidth', 2, 'MarkerSize', 16);
axis([0 min(120, t_hist(end)) 0 0.05]);
set(gca, 'LineWidth', 2, fset.sfont{:}, fset.axOpts{:});
xlabel('Lifetime (s)', fset.lfont{:});
ylabel('Frequency', fset.lfont{:});
hl = legend(hp, 'Above threshold', 'Below threshold', 'Location', 'NorthEast');
set(hl, 'Box', 'off', fset.tfont{:});



return
    %====================
    % Histogram etc.
    %====================
%     lftHist = getLifetimeHistogram(data(k), tracks, Nmax, 'Cutoff_f', ip.Results.Cutoff_f, 'Buffer', ip.Results.Buffer);
%     res.lftHist_Ia{k} = lftHist.Ia;
%     res.lftHist_Ib{k} = lftHist.Ib;
%     res.lftHist_IIa{k} = lftHist.IIa;
%     
   
    

    
  
    %====================
    % Gap statistics
    %====================
    
%     binEdges = [0:20:120 data(k).movieLength-data(k).framerate];
%     nb = length(binEdges)-1;
%     gapsPerTrack_Ia = zeros(1,nb);
%     gapsPerTrack_Ib = zeros(1,nb);
%     gapsPerTrack_IIa = zeros(1,nb);
%     for b = 1:nb
%         tidx = binEdges(b)<=lifetimes_s & lifetimes_s<binEdges(b+1);
%         gapsPerTrack_Ia(b) = mean(arrayfun(@(i) sum(i.gapVect), tracks(idx_Ia & tidx)));
%         gapsPerTrack_Ib(b) = mean(arrayfun(@(i) sum(i.gapVect), tracks(idx_Ib & tidx)));
%         gapsPerTrack_IIa(b) = mean(arrayfun(@(i) sum(i.gapVect), tracks(idx_IIa & tidx)));
%     end
%     res.gapsPerTrack_Ia{k} = gapsPerTrack_Ia;
%     res.gapsPerTrack_Ib{k} = gapsPerTrack_Ib;
%     res.gapsPerTrack_IIa{k} = gapsPerTrack_IIa;




%-------------------------
% Mean histogram
%-------------------------
t_hist = (cutoff_f:Nmax)*framerate;

% Class percentages
C = vertcat(res.trackClassStats);
v = mean(C,1);
v_std = std(C,[],1);

meanHist_Ia =  mean(vertcat(res.lftHist_Ia),1);
meanHist_Ib =  mean(vertcat(res.lftHist_Ib),1);
meanHist_IIa = mean(vertcat(res.lftHist_IIa),1);



%-------------------------
% Assign output
%-------------------------
% res.t = t_hist;
% res.meanHist_Ia = meanHist_Ia;
% res.source = {data.source};

if strcmpi(ip.Results.Display, 'on')
    fset = loadFigureSettings();
    
   
    % mean histograms (main classes)
    hf(1) = figure;
    hold on;
    hp(3) = plot(t_hist, meanHist_IIa, '.-', 'Color', 0.6*[1 1 1], 'LineWidth', 2, 'MarkerSize', 16);
    hp(2) = plot(t_hist, meanHist_Ib, '.-', 'Color', hsv2rgb([0 1 0.8]), 'LineWidth', 2, 'MarkerSize', 16);
    hp(1) = plot(t_hist, meanHist_Ia, '.-', 'Color', 'k', 'LineWidth', 2, 'MarkerSize', 16);
    axis([0 min(120, t_hist(end)) 0 0.05]);
    set(gca, 'LineWidth', 2, fset.sfont{:}, 'Layer', 'top');
    xlabel('Lifetime (s)', fset.lfont{:});
    ylabel('Frequency', fset.lfont{:});
    hl = legend(hp, 'Single tracks, valid', 'Single tracks, rejected', 'Compound tracks', 'Location', 'NorthEast');
    set(hl, 'Box', 'off', fset.tfont{:});
    
    
    
     % classes
%     hf(2) = plotTrackClasses(v', v_std', 'FaceColor', fset.cfTrackClasses, 'EdgeColor', fset.ceTrackClasses);
    
    
    
    % gap statistics
%     ce = fset.ceTrackClasses([1 2 5],:);
%     cf = fset.cfTrackClasses([1 2 5],:);
%     xlabels = arrayfun(@(b) [num2str(binEdges(b)) '-' num2str(binEdges(b+1)) ' s'], 1:numel(binEdges)-1, 'UniformOutput', false);
    
    
%     M_Ia = vertcat(res.gapsPerTrack_Ia{:});
%     M_Ib = vertcat(res.gapsPerTrack_Ib{:});
%     M_IIa = vertcat(res.gapsPerTrack_IIa{:});
%     
%     M = [mean(M_Ia,1); mean(M_Ib,1); mean(M_IIa,1)]';
%     S = [std(M_Ia,[],1); std(M_Ib,[],1); std(M_IIa,[],1)]';
%     
%     hf(3) = figure; barplot2(M, S, 'FaceColor', cf, 'EdgeColor', ce,...
%         'XLabels', xlabels, 'XLabel', 'Lifetime cohort', 'YLabel', 'gaps/track');
    
end

if ip.Results.Print
    
    fpath = cell(1,nd);
    for k = 1:nd
        [~,fpath{k}] = getCellDir(data(k));
    end
    fpath = unique(fpath);
    if numel(fpath)>1
        fprintf('Figures could not be printed.');
    else
        fpath = [fpath{1} 'Figures' filesep];
        [~,~] = mkdir(fpath);
        print(hf(1), '-depsc2', [fpath 'trackClassDistribution.eps']);
        print(hf(2), '-depsc2', [fpath 'meanLftHist_classes.eps']);
        print(hf(3), '-depsc2', [fpath 'gapStatistics.eps']);
    end
end
