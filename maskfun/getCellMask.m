% Francois Aguet, 02/17/2012

function mask = getCellMask(data, varargin)

ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('data', @isstruct);
ip.addParamValue('Overwrite', false, @islogical);
% ip.addParamValue('Sigma', []);
ip.addParamValue('Display', 'off', @(x) any(strcmpi(x, {'on', 'off'})));
ip.parse(data, varargin{:});

mask = cell(1,numel(data));
for i = 1:numel(data)
    
    aipPath = [data(i).source 'Detection' filesep 'avgProj.mat'];
    if ~(exist(aipPath, 'file')==2)
        df = floor(data(i).movieLength/50);
        fv = 1:df:data(i).movieLength;
        nf = numel(fv);
        aip = zeros(data(i).imagesize);
        mCh = strcmpi(data(i).source, data(i).channels);
        for k = 1:nf
            aip = aip + double(imread(data(i).framePaths{mCh}{fv(k)}));
        end
        aip = aip/nf;
        save(aipPath, 'aip');
    else
        load(aipPath);
    end
    
    if ~(exist([data(i).source 'Detection' filesep 'cellmask.tif'], 'file') == 2) || ip.Results.Overwrite
        mask{i} = computeMask(data(i), aip);%, ip.Results.Sigma);
        % save
        imwrite(uint8(mask{i}), [data(i).source 'Detection' filesep 'cellmask.tif'], 'tif', 'compression' , 'lzw');
    else
        fprintf('Cell mask has already been computed for %s\n', getShortPath(data(i)));
    end
end

if strcmpi(ip.Results.Display, 'on')
    for i = 1:numel(data)
        if ~isempty(mask{i})
            [ny,nx] = size(mask{i});
            B = bwboundaries(mask{i});
            B = sub2ind([ny nx], B{1}(:,1), B{1}(:,2));
            bmask = zeros([ny nx]);
            bmask(B) = 1;
            bmask = bwmorph(bmask, 'dilate');
            
            aipPath = [data(i).source 'Detection' filesep 'avgProj.mat'];
            load(aipPath);
            aip = scaleContrast(aip);
            aip(bmask==1) = 0;
            overlay = aip;
            overlay(bmask==1) = 255;
            overlay = uint8(cat(3, overlay, aip, aip));
            figure; imagesc(overlay); axis image; colormap(gray(256)); colorbar;
        end
    end
end



function mask = computeMask(data, aip)

aip = scaleContrast(aip, [], [0 1]);
g = filterGauss2D(aip, 5);

v = aip(:);

% di = diff(sort(v));
% di(di==0) = [];

[f_ecdf, x_ecdf] = ecdf(v);
x_ecdf = x_ecdf(2:end)';
f_ecdf = f_ecdf(2:end)';

x1 = interp1(f_ecdf, x_ecdf, 0.99);
v(v>x1) = [];

[f,xi] = ksdensity(v, 'npoints', 100); 

dx = xi(2)-xi(1);

ni = hist(v, xi);
ni = ni/sum(ni)/dx;

% local max/min
lmax = locmax1d(f, 3);
lmin = locmin1d(f, 3);

% max value
hmax = find(f==max(f), 1, 'first');

% identify min after first mode
if ~isempty(lmin)
    idx = find(lmin>lmax(1), 1, 'first');
    if ~isempty(idx) && lmin(idx)<hmax% && xi(lmax(1)) < xi(0.8*lmax(2))
        min0 = lmin(idx);
        T = xi(min0);
        mask = g>T;
    else
        mask = ones(data.imagesize);
    end
else
    mask = ones(data.imagesize);
end

% retain largest connected component
CC = bwconncomp(mask, 8);
compsize = cellfun(@(i) numel(i), CC.PixelIdxList);
mask = zeros(data.imagesize);
mask(CC.PixelIdxList{compsize==max(compsize)}) = 1;

% figure; 
% hold on;
% plot(xi, ni, 'k.-');
% plot(xi, f, 'r-');

% figure; imagesc(mask); axis image; colormap(gray(256)); colorbar;

% % vector bounds for projection line
% x0 = [interp1(f_ecdf, x_ecdf, 0.01) 0.01]';
% xN = [interp1(f_ecdf, x_ecdf, 0.99) 0.99]';
% 
% p = xN; % proj. vector
% p = p/norm(p);
% 
% N = 1e4;
% 
% xv = linspace(x0(1), xN(1), N);
% yv = interp1(x_ecdf, f_ecdf, xv);
% 
% X = [xv; yv];
% 
% xnorm = sqrt(sum(X.^2,1));
% theta = atan2(X(2,:),X(1,:)) - atan2(p(2),p(1));
% ynorm = sin(theta).*xnorm;
% 
% T = X(1,find(ynorm==min(ynorm), 1, 'first'));
% 
% mask = bf>T;
% 
% % close with PSF
% mCh = strcmpi(data.source, data.channels);
% if isempty(sigma)
%     sigma = getGaussianPSFsigma(data.NA, data.M, data.pixelSize, data.markers{mCh});
% end
% w = ceil(4*sigma);
% se = strel('disk', w, 0);
% mask = imclose(mask, se);
% 
% % retain largest connected component
% CC = bwconncomp(mask, 8);
% compsize = cellfun(@(i) numel(i), CC.PixelIdxList);
% mask = zeros(data.imagesize);
% mask(CC.PixelIdxList{compsize==max(compsize)}) = 1;

% figure; imagesc(mask); axis image; colormap(gray(256)); colorbar;

% load([data.source 'Detection' filesep 'detection_v2.mat']);
% ny = data.imagesize(1);
% nx = data.imagesize(2);
% 
% 
% borderIdx = [1:ny (nx-1)*ny+(1:ny) ny+1:ny:(nx-2)*ny+1 2*ny:ny:(nx-1)*ny];
% 
% % concatenate all positions
% X = [frameInfo.x];
% X = X(mCh,:);
% Y = [frameInfo.y];
% Y = Y(mCh,:);
% 
% mask = zeros(data.imagesize);
% mask(sub2ind(data.imagesize, round(Y), round(X))) = 1;
% 
% se = strel('disk', w, 0);
% mask = imclose(mask, se);
% mask = bwmorph(mask, 'clean');
% mask = imdilate(mask, se);
% 
% 
% % retain largest connected component
% CC = bwconncomp(mask, 8);
% compsize = cellfun(@(i) numel(i), CC.PixelIdxList);
% mask = zeros(ny,nx);
% mask(CC.PixelIdxList{compsize==max(compsize)}) = 1;
% 
% % add border within 'w'
% [yi,xi] = ind2sub([ny nx], find(mask==1));
% [yb,xb] = ind2sub([ny nx], borderIdx);
% idx = KDTreeBallQuery([xi yi], [xb' yb'], w);
% mask(borderIdx(cellfun(@(x) ~isempty(x), idx))) = 1;
% 
% mask = imclose(mask, se);
% 
% % fill holes
% CC = bwconncomp(~mask, 8);
% M = labelmatrix(CC);
% 
% % hole labels in image border
% borderLabels = unique(M(borderIdx));
% labels = setdiff(1:CC.NumObjects, borderLabels);
% idx = vertcat(CC.PixelIdxList{labels});
% mask(idx) = 1;
