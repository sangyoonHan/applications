function sliderShowFrame_Callback

hFig = findall(0, '-regexp','Name','fsmDataViewer');
hSlider = findobj(hFig, 'Tag', 'sliderShowFrame');
settings = get(hFig, 'UserData');

sliderValue = get(hSlider, 'Value');
iFrame = round(sliderValue * settings.numFrames);

% Unlock imtool axes children.
set(hFig, 'HandleVisibility', 'on');

% Update the title of the window.
set(hFig, 'Name', ['fsmDataViewer: frame (' num2str(iFrame) '/'...
    num2str(settings.numFrames) ')' ]);

% Get the axes of imtool.
hAxes = get(hFig, 'CurrentAxes');

% Get the children of axes.
hContent = get(hAxes, 'Children');

% Find the image object in the list of children.
hImage = findobj(hContent, 'type', 'image');

if numel(hImage) ~= 1
    error('Current figure contain none or invalid image data.');
end

% Update the image data
% FIXME: this command remove the pixel region tool.
set(hImage, 'CData', settings.sequence(:, :, :, iFrame));

% Display layers
% displayLayers(hFig, iFrame);

% Relock imtool axes children.
set(hFig, 'HandleVisibility', 'callback');

end