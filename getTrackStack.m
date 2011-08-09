% stack = getTrackStack(data, track)
%     Returns the image data around a track in a 4-sigma window as a cell array
%     containing all channels.

% Francois Aguet, Jan 26 2011

function [stack, dx, dy] = getTrackStack(data, track, varargin)

ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('data', @isstruct);
ip.addRequired('track', @isstruct);
ip.addParamValue('Reference', 'frame', @(x) strcmpi(x, 'track') | strcmpi(x, 'frame'));
ip.addParamValue('WindowWidth', 4, @isscalar);
ip.addParamValue('Buffer', 5, @isscalar);
ip.parse(data, track, varargin{:});
buffer = ip.Results.Buffer;

nc = length(data.channels);
masterChannel = find(strcmp(data(1).source, data(1).channels));
slaveChannels = setdiff(1:nc, masterChannel);

sigma = getGaussianPSFsigma(data.NA, data.M, data.pixelSize, name2wavelength(data.markers{masterChannel}));
w = ceil(ip.Results.WindowWidth*sigma);

% buffer with 5 frames before and after
bStart = track.start - max(1, track.start-buffer);
bEnd = min(data.movieLength, track.end+buffer) - track.end;
idx = track.start-bStart:track.end+bEnd;
nf = length(idx);

stack = cell(nc,nf);

if isfield(track, 'startBuffer') && ~isempty(track.startBuffer)
    x = [track.startBuffer.x track.x track.endBuffer.x];
    y = [track.startBuffer.y track.y track.endBuffer.y];
else
    x = track.x;
    y = track.y;
end
if size(x,1)==1 % expand if master channel detection only
    x = repmat(x, [nc 1]);
    y = repmat(y, [nc 1]);
end

if strcmpi(ip.Results.Reference, 'frame')
    xi = repmat(round(mean(x,2)), [1 nf]);
    yi = repmat(round(mean(y,2)), [1 nf]);
else
    xi = round(x);
    yi = round(y);
end

% adjust w if track is close to image border
w = min([w min(xi(:))-1 min(yi(:))-1 data.imagesize(2)-max(xi(:)) data.imagesize(1)-max(yi(:))]);

% load all visible frames of this track and store
for c = [masterChannel slaveChannels]
    tifFiles = dir([data.channels{c} '*.tif*']);
    tifFiles = tifFiles(idx);
    for k = 1:nf
        frame = imread([data.channels{c} tifFiles(k).name]);
        stack{c,k} = frame(yi(c,k)-w:yi(c,k)+w, xi(c,k)-w:xi(c,k)+w);
    end
end

% return deviation
dx = x-xi;
dy = y-yi;
