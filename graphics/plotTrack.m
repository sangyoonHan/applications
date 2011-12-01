% plotTrack(data, tracks, trackIdx, ch, varargin)
%
% INPUTS:   data : data structure
%          track : track structure
%        trackIdx : index of the track
%             ch : channel #
%     {varargin} : optional inputs:
%                      'Visible' : {'on'} | 'off' toggles figure visibility
%                      'Handle' : h, axis handle (for plotting from within GUI)
%                      'Print' : 'on' | {'off'} generates an EPS in 'data.source/Figures/'

% Francois Aguet, March 9 2011 (Last modified: 09/22/2011)

function plotTrack(data, track, ch, varargin)

%======================================
% Parse inputs, set defaults
%======================================
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('data', @isstruct);
ip.addRequired('track', @isstruct);
ip.addRequired('ch', @isnumeric);
ip.addParamValue('Visible', 'on', @(x) any(strcmpi(x, {'on', 'off'})));
ip.addParamValue('FileName', [], @ischar);
ip.addParamValue('Handle', []);
ip.addParamValue('Legend', 'hide', @(x) any(strcmpi(x, {'show','hide'})));
ip.addParamValue('Segment', 1, @isscalar);
ip.addParamValue('Background', 'on', @(x) any(strcmpi(x, {'on', 'off'})));
ip.addParamValue('BackgroundValue', 'zero', @(x) any(strcmpi(x, {'zero', 'data'})));
ip.addParamValue('Hues', []);
ip.addParamValue('Time', 'Movie', @(x) any(strcmpi(x, {'Movie', 'Track'})));
ip.addParamValue('XTick', []);
ip.addParamValue('YTick', []);
ip.addParamValue('XLim', []);
ip.addParamValue('DisplayMode', 'Screen', @(x) any(strcmpi(x, {'Print', 'Screen'})));
ip.parse(data, track, ch, varargin{:});

s = ip.Results.Segment;
hues = ip.Results.Hues;
if isempty(hues)
    hues = getFluorophoreHues(data.markers);
end

mCh = find(strcmp(data.channels, data.source));

if ~isempty(ip.Results.Handle)
    ha = ip.Results.Handle;
    standalone = false;
else
    hfig = figure('Visible', ip.Results.Visible);
    ha = axes('Position', [0.15 0.15 0.8 0.8]);
    standalone = true;
end

if strcmpi(ip.Results.Time, 'Track')
    dt = track.t{1}(1); % first segment always contains first time point
else
    dt = 0;
end


trackColor = hsv2rgb([hues(ch) 1 0.8]);
fillLight = hsv2rgb([hues(ch) 0.4 1]);
fillDark = hsv2rgb([hues(ch) 0.2 1]);

fillLightBuffer = hsv2rgb([hues(ch) 0.4 0.85]);
fillDarkBuffer = hsv2rgb([hues(ch) 0.2 0.85]);

% Significance thresholds
% sigmaT = icdf('normal', 1-alpha/2, 0, 1);
%sigmaL = icdf('normal', 0.95, 0, 1); % weaker, single-tailed
%sigmaH = icdf('normal', 0.99, 0, 1);
kLevel = norminv(1-0.05/2.0, 0, 1); % ~2 std above background


% Plot track
lh = NaN(1,9);

for s = 1:track.nSeg
    
    A = track.A{s}(ch,:);
    c = track.c{s}(ch,:);
    if strcmpi(ip.Results.BackgroundValue, 'zero')
        bgcorr = nanmean(c);
        c = c-bgcorr;
    else
        bgcorr = 0;
    end
    sigma_r = track.sigma_r{s}(ch,:);
    t = track.t{s} - dt;
    
    % alpha = 0.05 level
    if strcmpi(ip.Results.Background, 'on')
        lh(1) = fill([t t(end:-1:1)], [c c(end:-1:1)+kLevel*sigma_r(end:-1:1)],...
            fillDark, 'EdgeColor', 'none', 'Parent', ha);
    end
    hold(ha, 'on');
    
    gapIdx = arrayfun(@(x,y) x:y, track.gapStarts{s}, track.gapEnds{s}, 'UniformOutput', false);
    gapIdx = [gapIdx{:}];
    
    % plot amplitude std.
    sigma_a = track.A_pstd{s}(ch,:);
    
    rev = c+A-sigma_a;
    lh(2) = fill([t t(end:-1:1)], [c+A+sigma_a rev(end:-1:1)],...
        fillLight, 'EdgeColor', 'none', 'Parent', ha);
    
    % plot track
    ampl = A+c;
    if ch==mCh
        ampl(gapIdx) = NaN;
    end
    lh(3) = plot(ha, t, ampl, '.-', 'Color', trackColor, 'LineWidth', 1);
    
    % plot gaps separately
    if ch==mCh
        ampl = A+c;
        if ~isempty(gapIdx)
            % dashed line everywhere
            lh(4) = plot(ha, t, ampl, '--', 'Color', trackColor, 'LineWidth', 1);
            % plot gaps as white disks
            lh(5) = plot(ha, t(gapIdx), A(gapIdx)+c(gapIdx), 'o', 'Color', trackColor, 'MarkerFaceColor', 'w', 'LineWidth', 1);
        end
    end
    
    % plot background level
    if strcmpi(ip.Results.Background, 'on')
        lh(6) = plot(ha, t, c, '-', 'Color', trackColor);
    end    
end

% Plot start buffer
if isfield(track, 'startBuffer') && ~isempty(track.startBuffer.A{s})
    A = [track.startBuffer.A{s}(ch,:) track.A{s}(ch,1)];
    c = [track.startBuffer.c{s}(ch,:) track.c{s}(ch,1)]-bgcorr;
    
    sigma_a = [track.startBuffer.A_pstd{s}(ch,:) track.A_pstd{s}(ch,1)];
    sigma_r = [track.startBuffer.sigma_r{s}(ch,:) track.sigma_r{s}(ch,1)];
    t = [track.startBuffer.t{s} track.t{s}(1)] - dt;
    
    if strcmpi(ip.Results.Background, 'on')
        lh(12) = fill([t t(end:-1:1)], [c c(end:-1:1)+kLevel*sigma_r(end:-1:1)],...
            fillDarkBuffer, 'EdgeColor', 'none', 'Parent', ha);
    end

    rev = c+A-sigma_a;
    fill([t t(end:-1:1)], [c+A+sigma_a rev(end:-1:1)],...
        fillLightBuffer, 'EdgeColor', 'none', 'Parent', ha);
    
    lh(7) = plot(ha, t, A+c, '.--', 'Color', trackColor, 'LineWidth', 1);
    if strcmpi(ip.Results.Background, 'on')
        lh(8) = plot(ha, t, c, '--', 'Color', trackColor);
    end
end

% Plot end buffer
if isfield(track, 'endBuffer') && ~isempty(track.endBuffer.A{s})
    A = [track.A{s}(ch,end) track.endBuffer.A{s}(ch,:)];
    c = [track.c{s}(ch,end) track.endBuffer.c{s}(ch,:)]-bgcorr;
    
    sigma_a = [track.A_pstd{s}(ch,end) track.endBuffer.A_pstd{s}(ch,:)];
    sigma_r = [track.sigma_r{s}(ch,end) track.endBuffer.sigma_r{s}(ch,:)];
    t = [track.t{s}(end) track.endBuffer.t{s}] - dt;
    
    if strcmpi(ip.Results.Background, 'on')
        fill([t t(end:-1:1)], [c c(end:-1:1)+kLevel*sigma_r(end:-1:1)],...
            fillDarkBuffer, 'EdgeColor', 'none', 'Parent', ha);
    end
    
    rev = c+A-sigma_a;
    fill([t t(end:-1:1)], [c+A+sigma_a rev(end:-1:1)],...
        fillLightBuffer, 'EdgeColor', 'none', 'Parent', ha);
    
    lh(9) = plot(ha, t, A+c, '.--', 'Color', trackColor, 'LineWidth', 1);
    if strcmpi(ip.Results.Background, 'on')
        lh(10) = plot(ha, t, c, '--', 'Color', trackColor);
    end
end


% legend
if strcmpi(ip.Results.Legend, 'show')
    lh(11) = plot(-20:-10, rand(1,11), 'o--', 'MarkerSize', 7, 'LineWidth', 2, 'Color', trackColor, 'MarkerFaceColor', 'w');
    %l = legend(lh([2 5 1]), ['Amplitude ch. ' num2str(ch)], ['Background ch. ' num2str(ch)], '\alpha = 0.95 level', 'Location', 'NorthEast');
    l = legend(lh([3 2 11 6 1 12 8]), 'Intensity', 'Intensity uncertainty', 'Gap', 'Background intensity', 'Significance level (\alpha = 0.95)', 'Buffer', 'Buffer intensity', 'Location', 'NorthEast');
    %legend(l, ip.Results.Legend);
end


% set bounding box
if isfield(track, 'startBuffer') && ~isempty(track.startBuffer)
    bStart = size(track.startBuffer.A{s},2);
else
    bStart = 0;
end
if isfield(track, 'endBuffer') && ~isempty(track.endBuffer)
    bEnd = size(track.endBuffer.A{s},2);
else
    bEnd = 0;
end
tlength = track.end+bEnd - track.start-bStart + 1;



if ~isempty(ip.Results.XTick)
    XTick = ip.Results.XTick;
    set(ha, 'XTick', XTick, 'XLim', [XTick(1) XTick(end)]);
end
if ~isempty(ip.Results.XLim)
    set(ha, 'XLim', ip.Results.XLim);
end

if ~isempty(ip.Results.YTick)
    YTick = ip.Results.YTick;
    YLim = [YTick(1) YTick(end)];
    YTick(YTick<0) = [];
    set(ha, 'YTick', YTick, 'YLim', YLim);
else
    YTick = get(ha, 'YTick');
    YTick(YTick<0) = [];
    set(ha, 'YTick', YTick, 'Layer', 'top');
    % set(ha, 'XLim', ([track.start-bStart-0.1*tlength track.end+bEnd+0.1*tlength]-1)*data.framerate);

end



box off;


% Bigger fonts, line widths etc
if standalone
    tfont = {'FontName', 'Helvetica', 'FontSize', 20};
    sfont = {'FontName', 'Helvetica', 'FontSize', 20};
    lfont = {'FontName', 'Helvetica', 'FontSize', 24};
    
    if strcmpi(ip.Results.Legend, 'show')
        set(l, tfont{:});
    end
    
    set(gca, 'LineWidth', 2, sfont{:}, 'TickDir', 'out');
    xlabel('Time (s)', lfont{:})
    ylabel('Intensity (A.U.)', lfont{:});
end

if strcmpi(ip.Results.DisplayMode, 'Print')
    for k = lh([3 4 6 7:10])
        if ~isnan(k)
            set(k, 'LineWidth', 2);
        end
    end
    
    for k = lh([3 7 9])
        if ~isnan(k)
            set(k, 'MarkerSize', 21);
        end
    end
    
    if ~isnan(lh(5))
        set(lh(5), 'MarkerSize', 7, 'LineWidth', 2);
    end
end
    


if ~isempty(ip.Results.FileName)
    fpath = [data.source 'Figures' filesep];
    if ~(exist(fpath, 'dir')==7)
        mkdir(fpath);
    end
    print(hfig, '-depsc2', '-r300', [fpath ip.Results.FileName]);
end

if strcmp(ip.Results.Visible, 'off')
    close(hfig);
end
