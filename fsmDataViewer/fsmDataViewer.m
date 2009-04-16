function fsmDataViewer

% Check fsmDataViewer is not already open
h = findall(0, 'Tag', 'fsmDataViewer');

if ~isempty(h) && ishandle(h)
    set(h, 'Visible', 'on');
    return;
end

% First time 'fsmDataViewer' so call the setup window.
settings = fsmDataViewerSetup;

if (isempty(settings))
    % The user has cancel
    return;
end

% Load channels
settings = loadSequence(settings);

% Set up the main figure (using imtool)
hFig = imtool(settings.sequence(:, :, :, 1), []);

% Unlock imtool axes children.
set(hFig, 'HandleVisibility', 'on');

% Set the title of the window
set(hFig, 'Name', ['fsmDataViewer: frame (' num2str(1) '/' num2str(settings.numFrames) ')' ]);

% Add a slider
sliderStep = [1 5] / settings.numFrames;

position = get(hFig, 'Position');

uicontrol(hFig, 'Style', 'slider', ...
    'Units', get(hFig, 'Units'),...
    'Value', sliderStep(1), ...
    'Min', sliderStep(1), ...
    'Max', 1, ...
    'SliderStep', sliderStep, ...
    'Callback', 'sliderShowFrame_Callback', ...
    'Tag', 'sliderShowFrame', ...
    'Position', [0,0,position(3),30]);
% 
% Attach the settings to the figure.
set(hFig, 'UserData', settings);
% 
% % Display layers of the first frame
% displayLayers(hFig, 1);
% 
% Relock imtool axes children.
set(hFig, 'HandleVisibility', 'callback');

end