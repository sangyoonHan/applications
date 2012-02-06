%
%
% Inputs:    data : 
%          tracks : structure containing 'tracks'
%


% Handles/settings are stored in 'appdata' of the figure handle

function hfig = trackDisplayGUI(data, varargin)
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('data', @isstruct);
ip.addOptional('tracks', cell(1,length(data.channels)), @(x) isstruct(x) || (iscell(x) && numel(x)==numel(data.channels)));
ip.parse(data, varargin{:});

handles.data = data;

% tracks = ip.Results.tracks;

% detect number of channels (up to 4)
nCh = length(data.channels);
handles.nCh = nCh;
% exclude master from list of channels
handles.mCh = find(strcmp(data.source, data.channels));
nt = length(ip.Results.tracks);
handles.colorMap = hsv2rgb([rand(nt,1) ones(nt,2)]);

if nCh>4
    error('Only data with up to 4 channels are supported.');
end
    
if isstruct(ip.Results.tracks)
    handles.tracks = cell(1,nCh);
    handles.tracks{1} = ip.Results.tracks;
else
    handles.tracks = ip.Results.tracks;
end

if ~isempty(handles.tracks{handles.mCh})
    handles.maxLifetime_f = max([handles.tracks{handles.mCh}.end]-[handles.tracks{handles.mCh}.start]+1);
else
    handles.maxLifetime_f = [];
end

handles.displayType = 'raw';
if ~all(cellfun(@(x) isempty(x), handles.tracks))
    handles.selectedTrack = ones(1,handles.nCh);
    handles.f = handles.tracks{handles.mCh}(1).start;
else
    handles.selectedTrack = [];
    handles.f = 2; % valid tracks start in frame 2 at the earliest
end


hfig = figure('Units', 'normalized', 'Position', [0.1 0.2 0.8 0.7],...
    'Toolbar', 'figure', 'ResizeFcn', @figResize,...
    'Color', get(0,'defaultUicontrolBackgroundColor'));

set(hfig, 'DefaultUicontrolUnits', 'pixels', 'Units', 'pixels');
pos = get(hfig, 'Position');


%---------------------
% Frames
%---------------------

handles.frameLabel = uicontrol('Style', 'text', 'String', ['Frame ' num2str(handles.f)], ...
    'Position', [20 pos(4)-40, 100 20], 'HorizontalAlignment', 'left');


% Slider
handles.frameSlider = uicontrol('Style', 'slider',...
    'Value', handles.f, 'SliderStep', [1/(data.movieLength-1) 0.05], 'Min', 1, 'Max', data.movieLength,...
    'Position', [20 60 0.6*pos(3) 20], 'Callback', {@frameSlider_Callback, hfig});

uicontrol('Style', 'text', 'String', 'Display: ',...
    'Position', [20 20, 80 20], 'HorizontalAlignment', 'left');

handles.frameChoice = uicontrol('Style', 'popup',...
    'String', {'Raw frames', 'Detection', 'RGB'},...
    'Position', [90 20 120 20], 'Callback', {@frameChoice_Callback, hfig});

% Checkboxes
handles.detectionCheckbox = uicontrol('Style', 'checkbox', 'String', 'Positions',...
    'Position', [250 35 140 20], 'HorizontalAlignment', 'left',...
    'Callback', {@refresh_Callback, hfig});
handles.labelCheckbox = uicontrol('Style', 'checkbox', 'String', 'Channel labels',...
    'Position', [250 10 140 20], 'HorizontalAlignment', 'left',...
    'Callback', {@refresh_Callback, hfig});
handles.trackCheckbox = uicontrol('Style', 'checkbox', 'String', 'Tracks', 'Value', true,...
    'Position', [390 35 100 20], 'HorizontalAlignment', 'left',...
    'Callback', {@refresh_Callback, hfig});
handles.gapCheckbox = uicontrol('Style', 'checkbox', 'String', 'Gaps',...
    'Position', [390 10 60 20], 'HorizontalAlignment', 'left',...
    'Callback', {@refresh_Callback, hfig});
handles.trackEventCheckbox = uicontrol('Style', 'checkbox', 'String', 'Births/Deaths',...
    'Position', [450 10 100 20], 'HorizontalAlignment', 'left',...
    'Callback', {@refresh_Callback, hfig});

handles.eapCheckbox = uicontrol('Style', 'checkbox', 'String', 'EAP status',...
    'Position', [560 10 100 20], 'HorizontalAlignment', 'left',...
    'Callback', {@refresh_Callback, hfig});

handles.trackChoice = uicontrol('Style', 'popup',...
    'String', {'Lifetime', 'Category', 'Random'},...
    'Position', [460 35 100 20], 'Callback', {@trackChoice_Callback, hfig});

handles.trackButton = uicontrol('Style', 'pushbutton', 'String', 'Select track',...
    'Position', [20+0.6*pos(3)-100 30, 100 28], 'HorizontalAlignment', 'left',...
    'Callback', {@trackButton_Callback, hfig});


%---------------------
% Tracks
%---------------------

handles.trackLabel = uicontrol('Style', 'text', 'String', 'Track 1',...
    'Position', [40+0.6*pos(3) pos(4)-40, 100 20], 'HorizontalAlignment', 'left');

handles.trackSlider = uicontrol('Style', 'slider',...
    'Value', 1, 'SliderStep', [1 1], 'Min', 1, 'Max', 100,...
    'Position', [pos(3)-35 60 20 pos(4)-80],...
    'Callback', {@trackSlider_Callback, hfig});


% Output panel
ph = uipanel('Parent', hfig, 'Units', 'pixels', 'Title', 'Output', 'Position', [pos(3)-180 5 140 70]);

handles.printButton = uicontrol(ph, 'Style', 'pushbutton', 'String', 'Print figures',...
    'Units', 'normalized', 'Position', [0.1 0.5 0.8 0.45],...
    'Callback', {@printButton_Callback, hfig});

handles.movieButton = uicontrol(ph, 'Style', 'pushbutton', 'String', 'Make movie',...
    'Units', 'normalized', 'Position', [0.1 0.05 0.8 0.45],...
    'Callback', {@movieButton_Callback, hfig});
handles.outputPanel = ph;

% Montage panel
ph = uipanel('Parent', hfig, 'Units', 'pixels', 'Title', 'Montage', 'Position', [pos(3)-390 5 180 70]);
handles.montageButton = uicontrol(ph,'Style','pushbutton','String','Generate',...
    'Units','normalized', 'Position',[.1 .55 .6 .4],...
    'Callback', {@montageButton_Callback, hfig});     
handles.montageText = uicontrol(ph, 'Style', 'text', 'String', 'Align to: ',...
    'Units', 'normalized', 'Position', [0.1 0.1 0.35 0.4], 'HorizontalAlignment', 'left');
handles.montageOptions = uicontrol(ph, 'Style', 'popup',...
    'String', {'Track', 'Frame'},...
    'Units', 'normalized', 'Position', [0.45 0.1 0.5 0.4]);
handles.montageCheckbox = uicontrol('Style', 'checkbox', 'String', 'Show track',...
    'Position', [pos(3)-120 10, 100 20], 'HorizontalAlignment', 'left', 'Visible', 'off');
handles.montagePanel = ph;


setappdata(hfig, 'handles', handles);

%================================


handles.fAspectRatio = handles.data.imagesize(1) / handles.data.imagesize(2);


handles.detection = cell(1,nCh);
handles.dRange = cell(1,nCh);

detectionFile = [data.source 'Detection' filesep 'detection_v2.mat'];
if exist(detectionFile, 'file')==2
    load(detectionFile);
    handles.detection{handles.mCh} = frameInfo;
    if isfield(frameInfo, 'dRange')
        for c = 1:nCh
            M = arrayfun(@(x) x.dRange{c}, frameInfo, 'UniformOutput', false);
            M = vertcat(M{:});
            handles.dRange{c} = [min(M(:,1)) max(M(:,2))];
        end
    end
end

for c = 1:nCh
    if isempty(handles.dRange{c})        
        % determine dynamic range
        firstFrame = double(imread(data.framePaths{c}{1}));
        lastFrame = double(imread(data.framePaths{c}{data.movieLength}));
        handles.dRange{c} = [min(min(firstFrame(:)),min(lastFrame(:))) max(max(firstFrame(:)),max(lastFrame(:)))];
    end
end

% min/max track intensities
maxA = arrayfun(@(t) max(t.A, [], 2), handles.tracks{1}, 'UniformOutput', false);
maxA = [maxA{:}];
handles.maxA = zeros(1,nCh);
for c = 1:nCh
    [f_ecdf, x_ecdf] = ecdf(maxA(c,:));
    handles.maxA(c) = interp1(f_ecdf, x_ecdf, 0.975);
end
d = floor(log10(handles.maxA));
% y-axis unit
handles.yunit = round(handles.maxA ./ 10.^d) .* 10.^(d-1);
handles.maxA = ceil(handles.maxA ./ handles.yunit) .* handles.yunit;



% initialize handles
handles.trackMode = 'Lifetime';
handles.hues = getFluorophoreHues(data.markers);
handles.rgbColors = arrayfun(@(x) hsv2rgb([x 1 1]), handles.hues, 'UniformOutput', false);

settings.zoom = 1;
setappdata(hfig, 'settings', settings);


%=================================================
% Set initial values for sliders and checkboxes
%=================================================
if ~isempty([handles.tracks{:}]) && length(handles.tracks{handles.mCh}) > 1
    set(handles.trackSlider, 'Min', 1);
    nTracks = length(handles.tracks{handles.mCh});
    set(handles.trackSlider, 'Max', nTracks);
    set(handles.trackSlider, 'SliderStep', [1/(nTracks-1) 0.05]);
else
    set(handles.trackSlider, 'Visible', 'off');
end

if nCh > 2
    set(handles.('labelCheckbox'), 'Value', 1);
end




%=================================================
% Generate axes
%=================================================
% hFig = findall(0, '-regexp', 'Name', 'trackDisplayGUI')

handles = setupFrameAxes(handles);
dx = 1/23; % unit
dy = 1/12;
switch nCh
    case 1
        handles.tAxes{1} = axes('Parent', gcf, 'Position', [15*dx 6*dy 7*dx 5*dy], 'Box', 'on', 'XLim', [0 handles.data.movieLength]);
    case 2
        handles.tAxes{1} = axes('Parent', gcf, 'Position', [15*dx 7*dy 7*dx 4*dy], 'Box', 'on', 'XLim', [0 handles.data.movieLength]);
        handles.tAxes{2} = axes('Parent', gcf, 'Position', [15*dx 2*dy 7*dx 4*dy], 'Box', 'on', 'XLim', [0 handles.data.movieLength]);
    case 3
        handles.tAxes{1} = axes('Parent', gcf, 'Position', [15*dx 8.5*dy 7*dx 2.5*dy], 'Box', 'on', 'XLim', [0 handles.data.movieLength]);
        handles.tAxes{2} = axes('Parent', gcf, 'Position', [15*dx 5.25*dy 7*dx 2.5*dy], 'Box', 'on', 'XLim', [0 handles.data.movieLength]);
        handles.tAxes{3} = axes('Parent', gcf, 'Position', [15*dx 2*dy 7*dx 2.5*dy], 'Box', 'on', 'XLim', [0 handles.data.movieLength]);
    case 4        
        handles.tAxes{1} = axes('Parent', gcf, 'Position', [15*dx 9*dy 7*dx 2*dy]);
        handles.tAxes{2} = axes('Parent', gcf, 'Position', [15*dx 6.5*dy 7*dx 2*dy]);
        handles.tAxes{3} = axes('Parent', gcf, 'Position', [15*dx 4*dy 7*dx 2*dy]);
        handles.tAxes{4} = axes('Parent', gcf, 'Position', [15*dx 1.5*dy 7*dx 2*dy]);
end
xlabel('Time (s)');

% Colorbar
handles.cAxes = axes('Parent', gcf, 'Position', [10*dx 11.5*dy 4*dx dy/5], 'Visible', 'off');

%===========================
% initialize figures/plots
%===========================
for c = 1:nCh
    set(handles.fAxes{c}, 'XLim', [0.5 data.imagesize(2)+0.5], 'YLim', [0.5 data.imagesize(1)+0.5]);
end
linkaxes([handles.tAxes{:}], 'x');
axis([handles.fAxes{:}], 'image');

% save XLim diff. for zoom reference
handles.refXLimDiff = data.imagesize(2)-1;

%set(handles.figure1,'KeyPressFcn',@myFunction)
set(hfig, 'KeyPressFcn', @keyListener);

setappdata(hfig, 'handles', handles);
refreshFrameDisplay(hfig);
refreshTrackDisplay(hfig);

setColorbar(hfig, handles.trackMode);

set(zoom, 'ActionPostCallback', {@zoompostcallback, hfig});
% UIWAIT makes trackDisplayGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%===================================
% Context menu for each frame
%===================================
% for fi = 1:numel(handles.fAxes)
%     handles.hcmenu(fi) = uicontextmenu;
%     handles.himg(fi) = findall(handles.fAxes{fi},'Type','image');
%     uimenu(handles.hcmenu(fi), 'Label', 'Adjust contrast', @contrastCallback);
%     set(handles.himg(fi), 'uicontextmenu', handles.hcmenu(fi));
% end
% @(h,event) imcontrast(h)
%{@imcontrast, handles.himg(fi)}

% % Attach the context menu to axes
% himg = findall(handles.fAxes{:},'Type','image');
% for fi = 1:numel(himg)
%     set(himg(fi), 'uicontextmenu', handles.hcmenu);
%     
% end

function contrastCallback()
disp('test');


%===================================
% Automatic actions after zoom
%===================================
function zoompostcallback(~, eventdata, hfig)

settings = getappdata(hfig, 'settings');
handles = getappdata(hfig, 'handles');

if ismember(eventdata.Axes, [handles.fAxes{:}])
    settings.zoom = handles.refXLimDiff / diff(get(eventdata.Axes, 'XLim'));
    for c = 1:length(settings.selectedTrackMarkerID)
        id = settings.selectedTrackMarkerID(c);
        if ~isnan(id)
            set(id, 'MarkerSize', 10*settings.zoom);
        end
    end
    setappdata(hfig, 'settings', settings);
end





function figResize(src,~)
pos = get(src, 'Position');
handles = getappdata(src, 'handles');

% frames
set(handles.frameLabel, 'Position', [20 pos(4)-40, 100 20]);
set(handles.frameSlider, 'Position', [20 60 0.6*pos(3) 20]);

% tracks
set(handles.trackLabel, 'Position', [40+0.6*pos(3) pos(4)-40, 100 20]);
set(handles.trackButton, 'Position', [20+0.6*pos(3)-100 30, 100 30]);
set(handles.trackSlider, 'Position', [pos(3)-35 60 20 pos(4)-80]);
set(handles.outputPanel, 'Position', [pos(3)-180 5 140 70]);
set(handles.montagePanel, 'Position', [pos(3)-390 5 180 70]);





function handles = setupFrameAxes(handles, N)

if nargin<2
    N = handles.nCh;
end

dx = 1/23; % unit
dy = 1/12;

if isfield(handles, 'fAxes') && ~isempty(handles.fAxes)
    cellfun(@(x) delete(x), handles.fAxes);
end
handles.fAxes = cell(1,N);
switch N
    case 1
        handles.fAxes{1} = axes('Parent', gcf, 'Position', [dx 2*dy 13*dx 9*dy]);
    case 2
        if handles.data.imagesize(1) > handles.data.imagesize(2) % horiz.
            handles.fAxes{1} = axes('Parent', gcf, 'Position', [dx 2*dy 6*dx 9*dy]);
            handles.fAxes{2} = axes('Parent', gcf, 'Position', [8*dx 2*dy 6*dx 9*dy]);
        else
            handles.fAxes{1} = axes('Parent', gcf, 'Position', [dx 7*dy 13*dx 4*dy]);
            handles.fAxes{2} = axes('Parent', gcf, 'Position', [dx 2*dy 13*dx 4*dy]);
        end
    case 3
        handles.fAxes{1} = axes('Parent', gcf, 'Position', [dx 7*dy 6*dx 4*dy]);
        handles.fAxes{2} = axes('Parent', gcf, 'Position', [8*dx 7*dy 6*dx 4*dy]);
        handles.fAxes{3} = axes('Parent', gcf, 'Position', [dx 2*dy 6*dx 4*dy]);
    case 4
        handles.fAxes{1} = axes('Parent', gcf, 'Position', [dx 7*dy 6*dx 4*dy]);
        handles.fAxes{2} = axes('Parent', gcf, 'Position', [8*dx 7*dy 6*dx 4*dy]);
        handles.fAxes{3} = axes('Parent', gcf, 'Position', [dx 2*dy 6*dx 4*dy]);
        handles.fAxes{4} = axes('Parent', gcf, 'Position', [8*dx 2*dy 6*dx 4*dy]);
end
linkaxes([handles.fAxes{:}]);



% % --- Outputs from this function are returned to the command line.
% function varargout = trackDisplayGUI_OutputFcn(~, ~, handles)
% % varargout  cell array for returning output args (see VARARGOUT);
% % hObject    handle to figure
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Get default command line output from handles structure
% varargout{1} = handles.output;



%===================================
% Plot frames with overlaid tracks
%===================================
function handles = refreshFrameDisplay(hfig)
disp('framedisplay call');
handles = getappdata(hfig, 'handles');
settings = getappdata(hfig, 'settings');

% save zoom settings
XLim = get(handles.fAxes{1}, 'XLim');
YLim = get(handles.fAxes{1}, 'YLim');

% zoomFactor = handles.refXLimDiff / diff(XLim);

f = handles.f;

mc = handles.mCh;

isRGB = strcmpi(handles.displayType, 'RGB');

if isRGB
    if length(handles.fAxes)>1
        handles = setupFrameAxes(handles, 1);
    end
    cvec = mc;
    
else 
    if length(handles.fAxes)~=handles.nCh
        handles = setupFrameAxes(handles);
    end
    cvec = 1:handles.nCh;
end
nAxes = length(cvec);

markerHandles = NaN(1, nAxes);
textHandles = NaN(1, nAxes);

for k = 1:nAxes
    
    cla(handles.fAxes{k}); % clear axis content
    
    % channel index for RGB display
    if isRGB
        cidx = 1:min(handles.nCh,3);
    else
        cidx = cvec(k);
    end
    
    if ~isempty(handles.tracks{k})
        chIdx = k;
    else
        chIdx = mc;
    end
    
    if get(handles.('detectionCheckbox'), 'Value') 
        detection = handles.detection{k}(f);
    else
        detection = [];
    end
    
    if get(handles.('trackCheckbox'), 'Value') && ~isempty(handles.tracks{cvec(k)})
        
        idx = [handles.tracks{cvec(k)}.start]<=f & f<=[handles.tracks{cvec(k)}.end];
        
        plotFrame(handles.data, handles.tracks{cvec(k)}(idx), f, cidx,...
            'Handle', handles.fAxes{cvec(k)}, 'iRange', handles.dRange,...
            'Mode', handles.displayType, 'DisplayType', handles.trackMode,...
            'ShowEvents', get(handles.trackEventCheckbox, 'Value')==1,...
            'ShowGaps', get(handles.gapCheckbox, 'Value')==1, 'Detection', detection);
    else
        plotFrame(handles.data, [], f, cidx,...
            'Handle', handles.fAxes{cvec(k)}, 'iRange', handles.dRange,...
            'Mode', handles.displayType, 'Detection', detection);
    end
    
    hold(handles.fAxes{k}, 'on');
    
    % plot selected track marker
    if ~isempty(handles.selectedTrack) && get(handles.('trackCheckbox'), 'Value') 
        t = handles.tracks{chIdx}(handles.selectedTrack(k));
        fi = f-t.start+1;
        if 1 <= fi && fi <= length(t.x)
            xi = t.x(chIdx,fi);
            yi = t.y(chIdx,fi);
            markerHandles(k) = plot(handles.fAxes{k}, xi, yi, 'ws', 'MarkerSize', 10*settings.zoom);
            textHandles(k) = text(xi+15, yi+10, num2str(handles.selectedTrack(k)), 'Color', 'w', 'Parent', handles.fAxes{k});            
        end
    end
    
    if ~isRGB && get(handles.('labelCheckbox'), 'Value')
        % plot channel name
        %[getDirFromPath(handles.data.channels{k}) '-' handles.data.markers{k}],...
        dx = 0.03;
        text(1-dx*handles.fAspectRatio, dx,...
            handles.data.markers{k},...
            'Color', handles.rgbColors{k}, 'Units', 'normalized',...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom',...
            'Parent', handles.fAxes{k});
    end
    
    % plot EAP status
    if ~isRGB && get(handles.('eapCheckbox'), 'Value') &&...
            isfield(handles.tracks{chIdx}, 'significantSignal') && cvec(k) ~= handles.mCh
        % all tracks
        tracks = handles.tracks{chIdx};
        % tracks visible in current frame
        idx = [tracks.start]<=f & f<=[tracks.end];
        tracks = tracks(idx);
        % EAP status
        eapIdx = [tracks.significantSignal];
        eapIdx = eapIdx(k,:);
        % relative position in track
        fIdx = f-[tracks.start]+1;
        x = arrayfun(@(i) tracks(i).x(k,fIdx(i)), 1:length(tracks));
        y = arrayfun(@(i) tracks(i).y(k,fIdx(i)), 1:length(tracks));
        
        plot(handles.fAxes{k}, x(eapIdx==1), y(eapIdx==1), 'go', 'MarkerSize', 8);
        plot(handles.fAxes{k}, x(eapIdx==0), y(eapIdx==0), 'ro', 'MarkerSize', 8);
    end
    
    hold(handles.fAxes{k}, 'off');
end 

settings.selectedTrackMarkerID = markerHandles;
settings.selectedTrackLabelID = textHandles;

% write zoom level
set(handles.fAxes{1}, 'XLim', XLim);
set(handles.fAxes{1}, 'YLim', YLim);

setappdata(hfig, 'settings', settings);
setappdata(hfig, 'handles', handles);




function setColorbar(hfig, mode)
handles = getappdata(hfig, 'handles');

if ~isempty(handles.tracks{handles.mCh})
    switch mode
        case 'Lifetime'
            maxLft_f = 160;
            df = maxLft_f-120;
            dcoord = 0.25/df;
            cmap = [jet(round(120/handles.data.framerate)); (0.5:-dcoord:0.25+dcoord)' zeros(df,2)];
            imagesc(reshape(cmap, [1 size(cmap)]), 'Parent', handles.cAxes);
            axis(handles.cAxes, 'xy');
            set(handles.cAxes, 'Visible', 'on', 'YTick', [],...
                'XTick', [1 20:20:120 maxLft_f]*handles.data.framerate,...
                'XTickLabel', [1 20:20:120 handles.data.movieLength / handles.data.framerate]);
            text(80, 2.5, 'Lifetime (s)', 'HorizontalAlignment', 'center', 'Parent', handles.cAxes);
        case 'Category'
            xlabels = {'valid', 'rej. gaps', 'cut', 'persistent',...
                'valid', 'rej. gaps', 'cut', 'persistent'};
            cmap = [0 1 0; 1 1 0; 1 0.5 0; 1 0 0; 0 1 1; 0 0.5 1; 0 0 1; 0.5 0 1];
            imagesc(reshape(cmap, [1 size(cmap)]), 'Parent', handles.cAxes);
            axis(handles.cAxes, 'xy');
            set(handles.cAxes, 'Visible', 'on', 'YTick', [], 'XTick', 1:8, 'XTickLabel', xlabels,...
                'TickLength', [0 0]);
            rotateXTickLabels(handles.cAxes, 'Angle', 45, 'AdjustFigure', false);
            text(2.5, 2.5, 'Single tracks', 'HorizontalAlignment', 'center', 'Parent', handles.cAxes);
            text(6.5, 2.5, 'Compound tracks', 'HorizontalAlignment', 'center', 'Parent', handles.cAxes);
        otherwise
            set(handles.cAxes, 'Visible', 'off');
            cla(handles.cAxes);
    end
end



%=========================
% Plot tracks
%=========================
function refreshTrackDisplay(hfig)

handles = getappdata(hfig, 'handles');

if ~isempty(handles.selectedTrack)
    
    for ci = 1:handles.nCh
        %handles.tAxes
        h = handles.tAxes{ci};
        %cla(h);
        hold(h, 'off');

        if ~isempty(handles.tracks{ci})
            sTrack = handles.tracks{ci}(handles.selectedTrack(1));
        else
            sTrack = handles.tracks{handles.mCh}(handles.selectedTrack(1));
        end
        
        if size(sTrack.A, 1)==1
            cx = 1;
        else
            cx = ci;
        end
        
        plotTrack(handles.data, sTrack, cx, 'Handle', h, 'Time', 'Movie', 'YTick', -handles.yunit(ci):handles.yunit(ci):handles.maxA(ci));
        box on;
        %l = findobj(gcf, 'Type', 'axes', 'Tag', 'legend');
        %set(l, 'FontSize', 7);
                     
        % plot current frame position
        ybounds = get(h, 'YLim');
        plot(h, ([handles.f handles.f]-1)*handles.data.framerate, ybounds, '--', 'Color', 0.7*[1 1 1], 'HandleVisibility', 'off');
        %axis(handles.tAxes{ci}, [0 handles.data.movieLength ybounds]);
        hold(h, 'off');
        
        % display result of classification, if available
        %if isfield(handles.tracks{1}, 'cStatus')
        %    cStatus = handles.tracks{1}(handles.selectedTrack(1)).cStatus(2);
        %    if cStatus == 1
        %        set(handles.statusLabel, 'String', 'Ch. 2: EAF+');
        %    else
        %        set(handles.statusLabel, 'String', 'Ch. 2: EAF-');
        %    end
        %end
        %pos = get(handles.
        %aspectRatio = 
        dx = 0.03;
        if isfield(handles.tracks{1}, 'significantSignal')
            s = handles.tracks{1}(handles.selectedTrack).significantSignal;
            if s(ci)==1
                slabel = 'yes';
                scolor = [0 0.8 0];
            else
                slabel = 'no';
                scolor = [0.8 0 0];
            end
            text(1-dx, 1-dx,...
                ['Significant: ' slabel],...
                'Color', scolor, 'Units', 'normalized',...
                'HorizontalAlignment', 'right', 'VerticalAlignment', 'top',...
                'Parent', handles.tAxes{ci});
        end
        
        %     if ~isRGB && get(handles.('labelCheckbox'), 'Value')
        %         dx = 0.03;
        %         text(1-dx*handles.fAspectRatio, dx,...
        %             handles.data.markers{k},...
        %             'Color', handles.rgbColors{k}, 'Units', 'normalized',...
        %             'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom',...
        %             'Parent', handles.fAxes{k});
        %     end
        
        
    end
    
    xlabel(h, 'Time (s)');
end
setappdata(hfig, 'handles', handles);


%========================
% Callback functions
%========================

function refresh_Callback(~,~,hfig)
refreshFrameDisplay(hfig);



% function frameSlider_CreateFcn(hObject, ~, ~)
% if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor',[.9 .9 .9]);
% end


function frameSlider_Callback(hObject, ~, hfig)
f = round(get(hObject, 'value'));
set(hObject, 'Value', f);
handles = getappdata(hfig, 'handles');
set(handles.frameLabel, 'String', ['Frame ' num2str(f)]);
handles.f = f;
setappdata(hfig, 'handles', handles);
refreshFrameDisplay(hfig);
refreshTrackDisplay(hfig);



function trackButton_Callback(~, ~, hfig)

handles = getappdata(hfig, 'handles');

% set focus for next input
axes(handles.fAxes{1}); % linked to axes2, selection possible in both
[x,y] = ginput(1);

for c = 1:handles.nCh
    % mean position of visible tracks
    if ~isempty(handles.tracks{c})
        chIdx = c;
    else
        chIdx = handles.mCh;
    end
    % track segments visible in current frame
    f = handles.f;
    idx = find([handles.tracks{chIdx}.start]<=f & f<=[handles.tracks{chIdx}.end]);
    if ~isempty(idx)
        np = arrayfun(@(i) numel(i.t), handles.tracks{chIdx}(idx)); % points in each track
        nt = numel(idx);
        
        maxn = max(np);
        X = NaN(maxn, nt);
        Y = NaN(maxn, nt);
        F = NaN(maxn, nt);
        
        for k = 1:nt
            i = 1:np(k);
            X(i,k) = handles.tracks{chIdx}(idx(k)).x;
            Y(i,k) = handles.tracks{chIdx}(idx(k)).y;
            F(i,k) = handles.tracks{chIdx}(idx(k)).f;
        end
        
        X(F~=f) = NaN;
        Y(F~=f) = NaN;
        mu_x = nanmean(X,1); % average position for compound tracks
        mu_y = nanmean(Y,1);

        % nearest point
        d = sqrt((x-mu_x).^2 + (y-mu_y).^2);
        handles.selectedTrack(c) = idx(d==nanmin(d));
    end
end

set(handles.trackSlider, 'Value', handles.selectedTrack(1));
set(handles.trackLabel, 'String', ['Track ' num2str(handles.selectedTrack(1))]);

setappdata(hfig, 'handles', handles);
% axis(handles.axes3, [0 handles.data.movieLength 0 1]);
refreshFrameDisplay(hfig);
refreshTrackDisplay(hfig);



% --- Executes on button press in montageButton.
function montageButton_Callback(~, ~, hfig)
handles = getappdata(hfig, 'handles');

% Creates a montage based on the master track
if ~isempty(handles.selectedTrack)
    fprintf('Generating montage...');
    options = get(handles.montageOptions, 'String');
    
    itrack = handles.tracks{handles.mCh}(handles.selectedTrack(1));
    [stack, xa, ya] = getTrackStack(handles.data, itrack,...
        'WindowWidth', 6, 'Reference', options{get(handles.montageOptions, 'Value')});
    
    if get(handles.montageCheckbox, 'Value')
        plotTrackMontage(itrack, stack, xa, ya, 'Labels', handles.data.markers, 'Mode', 'gray');
    else
        plotTrackMontage(itrack, stack, xa, ya, 'Labels', handles.data.markers, 'Mode', 'gray');
    end
    fprintf(' done.\n');
else
    fprintf('Cannot create montage: no track selected.');
end



% --- Executes on selection change in popupmenu1.
function frameChoice_Callback(hObject, ~, hfig)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1

handles = getappdata(hfig, 'handles');

contents = cellstr(get(hObject,'String'));
switch contents{get(hObject,'Value')}
    case 'Raw frames'
        handles.displayType = 'raw';
    case 'RGB'
        handles.displayType = 'RGB';
    case 'Detection'
        handles.displayType = 'mask';
end
setappdata(hfig, 'handles', handles);
refreshFrameDisplay(hfig);



function trackChoice_Callback(hObject, ~, hfig)
handles = getappdata(hfig, 'handles');
contents = cellstr(get(hObject, 'String'));
handles.trackMode = contents{get(hObject,'Value')};
setColorbar(hfig, handles.trackMode);
setappdata(hfig, 'handles', handles);
refreshFrameDisplay(hfig);



function trackSlider_Callback(hObject, ~, hfig)
handles = getappdata(hfig, 'handles');

t = round(get(hObject, 'value'));
set(hObject, 'Value', t);
set(handles.trackLabel, 'String', ['Track ' num2str(t)]);

handles.selectedTrack = t * ones(1,handles.nCh);

% if track not visible, jump to first frame
t = handles.tracks{1}(t);
if handles.f < t.start || handles.f > t.end
    handles.f = t.start;
    % set frame number
    set(handles.frameLabel, 'String', ['Frame ' num2str(handles.f)]);
    % set frame slider
    set(handles.frameSlider, 'Value', handles.f);
end

setappdata(hfig, 'handles', handles);

refreshFrameDisplay(hfig);
refreshTrackDisplay(hfig);






% --- Executes on button press in printButton.
function printButton_Callback(~, ~, hfig)
% hObject    handle to printButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fprintf('Printing...');
handles = getappdata(hfig, 'handles');

for ch = 1:handles.nCh
    if ~isempty(handles.tracks{ch})
        tracks = handles.tracks{ch};
    else
        tracks = handles.tracks{handles.mCh};
    end
    plotTrack(handles.data, tracks(handles.selectedTrack(ch)), ch,...
        'FileName', ['track_' num2str(handles.selectedTrack(ch)) '_ch' num2str(ch) '.eps'],...
        'Visible', 'off', 'Legend', 'hide');
end




% if get(handles.('trackCheckbox'), 'Value') && ~isempty(handles.tracks{cvec(k)})
%         plotFrame(handles.data, handles.tracks{cvec(k)}, f, cidx,...
%             'Handle', handles.fAxes{cvec(k)}, 'iRange', handles.dRange,...
%             'Mode', handles.displayType, 'DisplayType', handles.trackMode,...
%             'ShowEvents', get(handles.trackEventCheckbox, 'Value')==1,...
%             'ShowGaps', get(handles.gapCheckbox, 'Value')==1,...
%             'Colormap', handles.colorMap);
%     else
%         plotFrame(handles.data, [], f, cidx,...
%             'Handle', handles.fAxes{cvec(k)}, 'iRange', handles.dRange,...
%             'Mode', handles.displayType);
%     end


if strcmp(handles.displayType, 'RGB')
    plotFrame(handles.data, handles.tracks{handles.mCh}, handles.f, 1:min(handles.nCh,3),...
        'iRange', handles.dRange, 'Mode', handles.displayType,...
        'ShowDetection', get(handles.('detectionCheckbox'), 'Value')==1,...
        'ShowEvents', get(handles.trackEventCheckbox, 'Value')==1,...
        'ShowGaps', get(handles.gapCheckbox, 'Value')==1,...
        'Print', 'on', 'Visible', 'off');
else
    for c = 1:handles.nCh
        if get(handles.('detectionCheckbox'), 'Value')==1
            detection = handles.detection{c}(handles.f);
        else
            detection = [];
        end
        plotFrame(handles.data, handles.tracks{c}, handles.f, c,...
            'iRange', handles.dRange, 'Mode', handles.displayType,...
            'Detection', detection,...
            'ShowEvents', get(handles.trackEventCheckbox, 'Value')==1,...
            'ShowGaps', get(handles.gapCheckbox, 'Value')==1,...
            'Print', 'on', 'Visible', 'off');     
    end
end


h = handles.montageOptions;
options = get(h, 'String');
itrack = handles.tracks{handles.mCh}(handles.selectedTrack(1));
[stack, xa, ya] = getTrackStack(handles.data, itrack,...
        'WindowWidth', 5, 'Reference', options{get(h, 'Value')});
fpath = [handles.data.source 'Figures' filesep 'track_' num2str(handles.selectedTrack(1)) '_montage.eps'];
plotTrackMontage(itrack, stack, xa, ya, 'Labels', handles.data.markers, 'Visible', 'off', 'epsPath', fpath, 'Mode', 'gray');

fprintf(' done.\n');



function movieButton_Callback(~, ~, hfig)

handles = getappdata(hfig, 'handles');
makeMovieCME(handles.data, handles.tracks{handles.mCh}, 'Mode', handles.displayType,...
    'ShowDetection', get(handles.('detectionCheckbox'), 'Value')==1,...
    'ShowEvents', get(handles.trackEventCheckbox, 'Value')==1,...
    'ShowGaps', get(handles.gapCheckbox, 'Value')==1,...
    'Displaytype', handles.trackMode);


function keyListener(src, evnt)

handles = getappdata(src, 'handles');

itrack = handles.selectedTrack(1);

trackSelect = false;
switch evnt.Key
    case 'uparrow'
        if itrack < numel(handles.tracks{1})
            itrack = itrack + 1;
        end
        trackSelect = true;
    case 'downarrow'
        if itrack > 1
            itrack = itrack - 1;
        end
        trackSelect = true;
    case 'leftarrow'
        if handles.f>1
            handles.f = handles.f-1;
        end
    case 'rightarrow'
        if handles.f<handles.data.movieLength
            handles.f = handles.f+1;
        end
end

if trackSelect
    handles.selectedTrack = itrack * ones(1,handles.nCh);
    set(handles.trackSlider, 'Value', itrack);
    set(handles.trackLabel, 'String', ['Track ' num2str(itrack)]);
    % if track not visible, jump to first frame
    t = handles.tracks{1}(itrack);
    if handles.f < t.start || handles.f > t.end
        handles.f = t.start;
    end
end

% set frame number
set(handles.frameLabel, 'String', ['Frame ' num2str(handles.f)]);
% set frame slider
set(handles.frameSlider, 'Value', handles.f);

setappdata(src, 'handles', handles);

refreshFrameDisplay(src);
refreshTrackDisplay(src);

