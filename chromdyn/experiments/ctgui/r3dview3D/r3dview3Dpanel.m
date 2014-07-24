function fig = r3dview3Dpanel()
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

load r3dview3Dpanel

h0 = figure('Color',[0.8 0.8 0.8], ...
	'Colormap',mat0, ...
	'FileName','E:\dthomann\matlab\chromtrack\r3dview3D\r3dview3Dpanel.m', ...
	'MenuBar','none', ...
	'Name','r3d viewer', ...
	'NumberTitle','off', ...
	'PaperPosition',[18 180 576 432], ...
	'PaperUnits','points', ...
	'Position',[496 361 237 211], ...
	'Resize','off', ...
	'Tag','r3dviewcontrol', ...
	'ToolBar','none');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.8 0.8 0.8], ...
	'FontWeight','demi', ...
	'ListboxTop',0, ...
	'Position',[11.25 135 86.25 15], ...
	'String','Threshold:', ...
	'Style','text', ...
	'Tag','StaticText1');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'Callback','timeSlide3DCB', ...
	'ListboxTop',0, ...
	'Position',[11.25 11.25 112.5 15], ...
	'Style','slider', ...
	'Tag','timeslider');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'Callback','thresSlide3DCB', ...
	'ListboxTop',0, ...
	'Position',[11.25 56.25 112.5 15], ...
	'Style','slider', ...
	'Tag','thresslider');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.8 0.8 0.8], ...
	'FontWeight','demi', ...
	'ListboxTop',0, ...
	'Position',[11.25 33.75 82.5 15], ...
	'String','Time point:', ...
	'Style','text', ...
	'Tag','StaticText2');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[1 1 1], ...
	'Callback','thresEdit3DCB', ...
	'ListboxTop',0, ...
	'Position',[135 56.25 22.5 15], ...
	'Style','edit', ...
	'Tag','thresedit');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[1 1 1], ...
	'Callback','timeEdit3DCB', ...
	'ListboxTop',0, ...
	'Position',[135 11.25 22.5 15], ...
	'Style','edit', ...
	'Tag','timeedit');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
	'Callback','thresSlide3DCB', ...
	'ListboxTop',0, ...
	'Position',[11.25 101.25 112.5 15], ...
	'Style','slider', ...
	'Tag','upthresslider');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'Callback','thresEdit3DCB', ...
	'BackgroundColor',[1 1 1], ...
	'ListboxTop',0, ...
	'Position',[135 101.25 22.5 15], ...
	'Style','edit', ...
	'Tag','upthresedit');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.8 0.8 0.8], ...
	'ListboxTop',0, ...
	'Position',[7.5 120 45 15], ...
	'String','Upper:', ...
	'Style','text', ...
	'Tag','StaticText3');
h1 = uicontrol('Parent',h0, ...
	'Units','points', ...
	'BackgroundColor',[0.8 0.8 0.8], ...
	'ListboxTop',0, ...
	'Position',[7.5 75 45 15], ...
	'String','Lower:', ...
	'Style','text', ...
	'Tag','StaticText3');
if nargout > 0, fig = h0; end