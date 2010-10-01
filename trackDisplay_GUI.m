function varargout = trackDisplay_GUI(varargin)
% TRACKDISPLAY_GUI M-file for trackDisplay_GUI.fig
%      TRACKDISPLAY_GUI, by itself, creates a new TRACKDISPLAY_GUI or raises the existing
%      singleton*.
%
%      H = TRACKDISPLAY_GUI returns the handle to a new TRACKDISPLAY_GUI or the handle to
%      the existing singleton*.
%
%      TRACKDISPLAY_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRACKDISPLAY_GUI.M with the given input arguments.
%
%      TRACKDISPLAY_GUI('Property','Value',...) creates a new TRACKDISPLAY_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before trackDisplay_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to trackDisplay_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help trackDisplay_GUI

% Last Modified by GUIDE v2.5 28-Sep-2010 15:54:49

% Francois Aguet, September 2010

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @trackDisplay_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @trackDisplay_GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before trackDisplay_GUI is made visible.
function trackDisplay_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to trackDisplay_GUI (see VARARGIN)

data = varargin{1};
handles.data = data;
handles.tracks1 = varargin{2};
if numel(varargin)>2
    handles.tracks2 = varargin{3};
end

% dual channel
if isfield(handles.data, 'channel1')
    framesCh1 = dir([data.channel1 '*.tif']);
    frameListCh1 = cellfun(@(x) [data.channel1 x], {framesCh1.name}, 'UniformOutput', false);
    
    framesCh2 = dir([data.channel2 '*.tif']);
    frameListCh2 = cellfun(@(x) [data.channel2 x], {framesCh2.name}, 'UniformOutput', false);
    
    maskPath1 = [data.channel1 'Detection' filesep 'Masks' filesep];
    masksCh1 = dir([maskPath1 '*.tif']);
    maskListCh1 = cellfun(@(x) [maskPath1 x], {masksCh1.name}, 'UniformOutput', false);
    
    maskPath2 = [data.channel2 'Detection' filesep 'Masks' filesep];
    masksCh2 = dir([maskPath2 '*.tif']);
    maskListCh2 = cellfun(@(x) [maskPath2 x], {masksCh2.name}, 'UniformOutput', false);
    
    handles.nCh = 2;
    handles.frameListCh1 = frameListCh1;
    handles.frameListCh2 = frameListCh2;
    handles.maskListCh1 = maskListCh1;
    handles.maskListCh2 = maskListCh2;
    
    load([data.channel1 'Detection' filesep 'detectionResults.mat']);
    handles.detection1 = frameInfo;
    handles.dRange1 = [min([frameInfo.minI]) max([frameInfo.maxI])];
    load([data.channel2 'Detection' filesep 'detectionResults.mat']);
    handles.detection2 = frameInfo;
    handles.dRange2 = [min([frameInfo.minI]) max([frameInfo.maxI])];
% single channel
else
    framesCh1 = dir([handles.data.source '*.tif']);
    frameListCh1 = cellfun(@(x) [data. source x], {framesCh1.name}, 'UniformOutput', false);
    
    maskPath1 = [handles.data.source 'Detection' filesep 'Masks' filesep];
    masksCh1 = dir([maskPath1 '*.tif']);
    maskListCh1 = cellfun(@(x) [maskPath1 x], {masksCh1.name}, 'UniformOutput', false);
    
    handles.nCh = 1;
    handles.frameListCh1 = frameListCh1;
    handles.maskListCh1 = maskListCh1;
    
    load([data.source 'Detection' filesep 'detectionResults.mat']);
    handles.detection1 = frameInfo;
    handles.dRange1 = [min([frameInfo.minI]) max([frameInfo.maxI])];
end

% initialize handles
handles.f = 1;
handles.displayType = 'raw';
handles.visibleIdx = [];
handles.selectedTrack = [];

h = handles.('slider1');
set(h, 'Min', 1);
set(h, 'Max', data.movieLength);
set(h, 'SliderStep', [1/(data.movieLength-1) 0.05]);

% Choose default command line output for trackDisplay_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% initialize figures/plots
imagesc(imread(frameListCh1{1}), 'Parent', handles.('axes1'), handles.dRange1);
imagesc(imread(frameListCh2{1}), 'Parent', handles.('axes2'), handles.dRange2);
colormap(gray(256));
linkaxes([handles.axes1 handles.axes2]);
axis([handles.axes1 handles.axes2], 'image');
axis(handles.axes3, [0 handles.data.movieLength 0 1]);
box(handles.axes3, 'on');


% UIWAIT makes trackDisplay_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);



% --- Outputs from this function are returned to the command line.
function varargout = trackDisplay_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

f = round(get(hObject, 'value'));
set(hObject, 'Value', f);
set(handles.('text1'), 'String', ['Frame ' num2str(f)]);
handles.f = f;
guidata(hObject,handles);
refreshFrameDisplay(hObject, handles);
refreshTrackDisplay(handles);



function refreshFrameDisplay(hObject, handles)

cmap = jet(handles.data.movieLength);
f = handles.f;

% save zoom settings
XLim = get(handles.axes1, 'XLim');
YLim = get(handles.axes1, 'YLim');

if handles.nCh==2

    idx1 = find([handles.tracks1.start] <= f & f <= [handles.tracks1.end]);
    handles.visibleIdx1 = idx1;
    idx2 = find([handles.tracks2.start] <= f & f <= [handles.tracks2.end]);
    handles.visibleIdx2 = idx2;

    switch handles.displayType
        case 'raw'
            imagesc(imread(handles.frameListCh1{f}), 'Parent', handles.axes1, handles.dRange1);
            imagesc(imread(handles.frameListCh2{f}), 'Parent', handles.axes2, handles.dRange2);            
        case 'WT'
            imagesc(imread(handles.maskListCh1{f}), 'Parent', handles.axes1, handles.dRange1);
            imagesc(imread(handles.maskListCh2{f}), 'Parent', handles.axes2, handles.dRange2);
        case 'merge'
            overlayColor = [1 0 0];
            mask1 = double(imread(handles.maskListCh1{f}));
            mask2 = double(imread(handles.maskListCh2{f}));
            frame1 = double(imread(handles.frameListCh1{f}));
            frame2 = double(imread(handles.frameListCh2{f}));
            
            maskIdx= mask1~=0;
            chR = frame1;
            chR(maskIdx) = chR(maskIdx)*overlayColor(1);
            chG = frame1;
            chG(maskIdx) = chG(maskIdx)*overlayColor(2);
            chB = frame1;
            chB(maskIdx) = chB(maskIdx)*overlayColor(3);
            imRGB = uint8(cat(3, scaleContrast(chR, handles.dRange1), scaleContrast(chG, handles.dRange1), scaleContrast(chB, handles.dRange1)));
            imagesc(imRGB, 'Parent', handles.axes1);
           
            maskIdx= mask2~=0;
            chR = frame2;
            chR(maskIdx) = chR(maskIdx)*overlayColor(1);
            chG = frame2;
            chG(maskIdx) = chG(maskIdx)*overlayColor(2);
            chB = frame2;
            chB(maskIdx) = chB(maskIdx)*overlayColor(3);
            imRGB = uint8(cat(3, scaleContrast(chR, handles.dRange2), scaleContrast(chG, handles.dRange2), scaleContrast(chB, handles.dRange2)));
            imagesc(imRGB, 'Parent', handles.axes2);
    end
    axis(handles.axes1, 'image');
    axis(handles.axes2, 'image');
    
    % overlay tracks in first channel
    if isfield(handles, 'tracks1')
        hold(handles.axes1, 'on');
        for k = idx1
            fi = 1:f-handles.tracks1(k).start+1;
            plot(handles.axes1, handles.tracks1(k).x(1), handles.tracks1(k).y(1), '*', 'Color', cmap(handles.tracks1(k).lifetime,:));
            plot(handles.axes1, handles.tracks1(k).x(fi), handles.tracks1(k).y(fi), '-', 'Color', cmap(handles.tracks1(k).lifetime,:));
        end
% %         startIdx = f==[handles.tracks1.start];
% %         startX = [handles.tracks1(startIdx).x];
% %         startY = [handles.tracks1(startIdx).y];
% %         startIdx = [handles.tracks1(startIdx).lifetime];
% %         startIdx = cumsum(startIdx)-startIdx+1;
% %         startX = startX(startIdx);
% %         startY = startY(startIdx);
% %         plot(handles.axes1, startX, startY, 'o', 'Color', cmap(handles.tracks1(k).lifetime,:), 'LineWidth', 1.5, 'MarkerSize', 15);
% %         
%         endIdx = f==[handles.tracks1.end];
%         startX = [handles.tracks1(startIdx).x];
%         startY = [handles.tracks1(startIdx).y];
        
        
%         dpos = 
%         idx1 = find();
%         plot(handles.tracks1(f==[handles.tracks1.end]).x(end)
    end

    % overlay tracks in second channel only if two track sets are available
    if isfield(handles, 'tracks2')
        hold(handles.axes2, 'on');
        for k = idx2
            fi = 1:f-handles.tracks2(k).start+1;
            plot(handles.axes2, handles.tracks2(k).x(1), handles.tracks2(k).y(1), '*', 'Color', cmap(handles.tracks2(k).lifetime,:));
            plot(handles.axes2, handles.tracks2(k).x(fi), handles.tracks2(k).y(fi), '-', 'Color', cmap(handles.tracks2(k).lifetime,:));
        end
    end

    % plot selected track marker
    if length(handles.selectedTrack)==2
        t = handles.tracks1(handles.selectedTrack(1));
        ci = f-t.start+1;
        if 1 <= ci && ci <= t.lifetime
            plot(handles.('axes1'), t.x(ci), t.y(ci), 'ro', 'MarkerSize', 15);
            text(t.x(ci), t.y(ci), num2str(handles.selectedTrack(1)), 'Color', [1 0 0], 'Parent', handles.('axes1'));
        end
        t = handles.tracks2(handles.selectedTrack(2));
        ci = f-t.start+1;
        if 1 <= ci && ci <= t.lifetime
            plot(handles.('axes2'), t.x(ci), t.y(ci), 'ro', 'MarkerSize', 15);
            text(t.x(ci), t.y(ci), num2str(handles.selectedTrack(2)), 'Color', [1 0 0], 'Parent', handles.('axes2'));
        end
    end
    
    % show detection COM values
    if get(handles.('checkbox1'), 'Value')
        plot(handles.('axes1'), handles.detection1(f).xcom, handles.detection1(f).ycom, 'x', 'Color', hsv2rgb([0/360 0.5 0.5]));
        plot(handles.('axes2'), handles.detection2(f).xcom, handles.detection2(f).ycom, 'x', 'Color', hsv2rgb([0/360 0.5 0.5]));
    end
    hold(handles.('axes2'), 'off');
else
    plot(handles.('axes2'), handles.detection(f).xcom, handles.detection(f).ycom, 'x', 'Color', hsv2rgb([120/360 0.5 0.5]));
end
% write zoom level
set(handles.axes1, 'XLim', XLim);
set(handles.axes1, 'YLim', YLim);
guidata(hObject,handles);



function refreshTrackDisplay(handles)

if ~isempty(handles.selectedTrack)

    h = handles.('axes3');
    XLim = get(h, 'XLim');
    YLim = get(h, 'YLim');
    
    sTrack = handles.tracks1(handles.selectedTrack(1));
    hold(h, 'off');
    
    bStart = length(sTrack.startBuffer);
    bEnd = length(sTrack.endBuffer);
    t = sTrack.start-bStart:sTrack.end+bEnd;
    A = [sTrack.startBuffer sTrack.A sTrack.endBuffer];
    c = [sTrack.c(1)*ones(1,bStart) sTrack.c sTrack.c(end)*ones(1,bEnd)];
    
    plot(h, t, A+c, 'r');
    %plot(h, sTrack.t, sTrack.A + sTrack.c, 'r');
    hold(h, 'on');
    plot(h, t, c, 'k');
    %plot(h, sTrack.t, sTrack.c, 'k');
    %plot(h, sTrack.t, sTrack.c + 3*sTrack.cStd, 'k--');
    
    sTrack = handles.tracks2(handles.selectedTrack(2));
    t = sTrack.start-bStart:sTrack.end+bEnd;
    A = [sTrack.startBuffer sTrack.A sTrack.endBuffer];
    c = [sTrack.c(1)*ones(1,bStart) sTrack.c sTrack.c(end)*ones(1,bEnd)];
    plot(h, t, A+c, 'b');
    plot(h, t, c, 'b--');
    %plot(h, sTrack.t, sTrack.A + sTrack.c, 'b');
    
    
    ybounds = get(h, 'YLim');
    plot(h, [handles.f handles.f], ybounds, '--', 'Color', 0.7*[1 1 1]);
    
    %xlim(h, [0 handles.data.movieLength]);
    legend(h, 'Amplitude', 'Background');
    % retain zoom level
    set(h, 'XLim', XLim);
end




% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1

refreshFrameDisplay(hObject, handles);



% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set focus for next input
axes(handles.('axes1')); % linked to axes2, selection possible in both
[x,y] = ginput(1);

% mean position of visible tracks
idx = handles.visibleIdx1;
np = length(idx);
mu_x = zeros(1,length(np));
mu_y = zeros(1,length(np));
for k = 1:np
    fi = 1:handles.f-handles.tracks1(idx(k)).start+1;
    mu_x(k) = mean(handles.tracks1(idx(k)).x(fi));
    mu_y(k) = mean(handles.tracks1(idx(k)).y(fi));
end
% nearest point
d = sqrt((x-mu_x).^2 + (y-mu_y).^2);
handles.selectedTrack(1) = idx(d==min(d));

% mean position of visible tracks
idx = handles.visibleIdx2;
np = length(idx);
mu_x = zeros(1,length(np));
mu_y = zeros(1,length(np));
for k = 1:np
    fi = 1:handles.f-handles.tracks2(idx(k)).start+1;
    mu_x(k) = mean(handles.tracks2(idx(k)).x(fi));
    mu_y(k) = mean(handles.tracks2(idx(k)).y(fi));
end
% nearest point
d = sqrt((x-mu_x).^2 + (y-mu_y).^2);
handles.selectedTrack(2) = idx(d==min(d));

guidata(hObject,handles);
axis(handles.axes3, [0 handles.data.movieLength 0 1]);
refreshFrameDisplay(hObject, handles);
refreshTrackDisplay(handles)



% --- Executes on button press in montageButton.
function montageButton_Callback(hObject, eventdata, handles)
% hObject    handle to montageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(handles.selectedTrack)
    t = handles.tracks1(handles.selectedTrack(1));
    % load all visible frames of this track and store
    
    tifFiles1 = dir([handles.data.source '*.tif*']);
    tifFiles2 = dir([handles.data.channel2 '*.tif*']);
    
    % buffer with 5 frames before and after
    buffer = 5;
    bStart = t.start - max(1, t.start-buffer);
    bEnd = min(handles.data.movieLength, t.end+buffer) - t.end;
    
    xi = round(t.x);
    yi = round(t.y);
    xi = [xi(1)*ones(1,bStart) xi xi(end)*ones(1,bEnd)];
    yi = [yi(1)*ones(1,bStart) yi yi(end)*ones(1,bEnd)];
    
    tifFiles1 = tifFiles1(t.start-bStart:t.end+bEnd);
    tifFiles2 = tifFiles2(t.start-bStart:t.end+bEnd);
    nf = length(tifFiles1);
    sigma = 1.628;
    w = ceil(4*sigma);
    window = cell(length(handles.selectedTrack),nf);
    for k = 1:nf
        frame = imread([handles.data.source tifFiles1(k).name]);
        window{1,k} = frame(yi(k)-w:yi(k)+w, xi(k)-w:xi(k)+w);
        if length(handles.selectedTrack)==2
            frame = imread([handles.data.channel2 tifFiles2(k).name]);
            window{2,k} = frame(yi(k)-w:yi(k)+w, xi(k)-w:xi(k)+w);
        end
    end
    montagePlot(window, 12);
end



% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1

contents = cellstr(get(hObject,'String'));
switch contents{get(hObject,'Value')}
    case 'Raw frames'
        handles.displayType = 'raw';
    case 'Detection'
        handles.displayType = 'WT';
    case 'Overlay'
        handles.displayType = 'merge';
end
guidata(hObject,handles);
refreshFrameDisplay(hObject, handles);



% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
