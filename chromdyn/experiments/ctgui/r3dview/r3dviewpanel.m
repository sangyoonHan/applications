function fig = r3dviewpanel()
% This is the machine-generated representation of a Handle Graphics object
% and its children.  Note that handle values may change when these objects
% are re-created. This may cause problems with any callbacks written to
% depend on the value of the handle at the time the object was saved.
% This problem is solved by saving the output as a FIG-file.
%
% To reopen this object, just type the name of the M-file at the MATLAB
% prompt. The M-file and its associated MAT-file must be on your path.
% 
% NOTE: certain newer features in MATLAB may not have been saved in this
% M-file due to limitations of this format, which has been superseded by
% FIG-files.  Figures which have been annotated using the plot editor tools
% are incompatible with the M-file/MAT-file format, and should be saved as
% FIG-files.

load r3dviewpanel

h0 = figure('Color',[0.8 0.8 0.8], ...
	'Colormap',mat0, ...
	'FileName','E:\dthomann\matlab\chromtrack\r3dviewpanel.m', ...
	'MenuBar','none', ...
	'Name','r3d viewer', ...
	'NumberTitle','off', ...
	'PaperPosition',[18 180 576 432], ...
	'PaperUnits','points', ...
	'Position',[441 324 240 136], ...
	'Resize','off', ...
	'Tag','r3dviewcontrol', ...
	'ToolBar','none');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.8 0.8 0.8], ...
	'ListboxTop',0, ...
	'Position',[11.25 78.75 86.25 15], ...
	'String','Stack position:', ...
	'Style','text', ...
	'Tag','StaticText1');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'Callback','timeSlideCB', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'ListboxTop',0, ...
	'Position',[11.25 11.25 112.5 15], ...
	'Style','slider', ...
	'Tag','timeslider');
h1 = uicontrol('Parent',h0, ...
   'Units','points', ...
   'Callback','stackSlideCB', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'ListboxTop',0, ...
	'Position',[11.25 56.25 112.5 15], ...
	'Style','slider', ...
	'Tag','stackslider');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.8 0.8 0.8], ...
	'ListboxTop',0, ...
	'Position',[11.25 33.75 82.5 15], ...
	'String','Time point:', ...
	'Style','text', ...
	'Tag','StaticText2');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
   'Callback','rotateCB', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'ListboxTop',0, ...
	'Position',[135 78.75 28.5 16.5], ...
	'String','rotate', ...
	'Tag','swapdim');
h1 = uicontrol('Parent',h0, ...
   'Units','points', ...
   'Callback','stackEditCB', ...
	'BackgroundColor',[1 1 1], ...
	'ListboxTop',0, ...
	'Position',[135 56.25 22.5 15], ...
	'Style','edit', ...
	'Tag','stackedit');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'Callback','timeEditCB', ...
	'BackgroundColor',[1 1 1], ...
	'ListboxTop',0, ...
	'Position',[135 11.25 22.5 15], ...
	'Style','edit', ...
	'Tag','timeedit');
if nargout > 0, fig = h0; end