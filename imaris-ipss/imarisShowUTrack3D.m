function iceConn = imarisShowUTrack3D(MD)
%IMARISSHOWUTRACK3D temporary wrapper to show u-track 3D results in imaris
%
% iceConn = imarisShowUTrack3D(MovieDataObject)
%
% Because philippe's new u-track stuff doesn't yet have class definitions
% etc. this is a temporary wrapper to ease displaying tracking results in
% imaris
%
%Hunter Elliott
%11/28/2016

iceConn = movieViewerImaris(MD,'UseImarisFileReader',true);

outputDir = MD.notes_;%Workaround for using kludgy script...
detections = load([outputDir filesep 'detection.mat']);
detections = detections.movieInfo;

imarisShowDetections(detections,iceConn);

%Just hard-coding this because hopefully it will eventually have process
%classes...
tracks = load([outputDir filesep 'tracks' filesep 'tracksHandle.mat']);
tracks = tracks.tracks;

imarisShowTracks(tracks,iceConn);




