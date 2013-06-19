%% Preparing synthetic bead images

% reference image (500x500)
% reference image (300x200)
xmax=500;
ymax=500;
nPoints = 25000;
bead_r = 50; % nm
pixSize = 72; % nm/pix 90x
sigma = 1.6;
[refimg,bead_x, bead_y, ~, Av] = simGaussianBeads(xmax,ymax, sigma, ...
        'npoints', nPoints, 'Border', 'truncated','A',0.3+rand(1,nPoints));

% bead images
%% displacement field
E=8000;  %Young's modulus, unit: Pa
meshPtsFwdSol=2^10;
forceType = 'groupForce';

gridSpacing = 1;
xmin = gridSpacing;
ymin = gridSpacing;

[x_mat_u, y_mat_u]=meshgrid(xmin:gridSpacing:xmax,ymin:gridSpacing:ymax);

% % temporary - get the coordinates
% figure, imshow(ones(500))
% hold on
% fposxy = [];
% n = 0;
% % Loop, picking up the points.
% disp('Left mouse button picks points.')
% disp('Right mouse button picks last point.')
% but = 1;
% while but == 1
%     [xi,yi,but] = ginput(1);
%     plot(xi,yi,'ro')
%     n = n+1;
%     text(xi,yi-8,num2str(n));
%     fposxy(n,:) = [xi yi];
% end
% hold off

posNA = [139.0000  267.0000
  156.0000  232.0000
  184.0000  212.0000
  217.0000  200.0000
  246.0000  195.0000
  272.0000  199.0000
  297.0000  211.0000
  323.0000  231.0000
  346.0000  266.0000];
% focal adhesion
% % temporary - get the coordinates
% figure, imshow(ones(500))
% hold on
% plot(posNA(:,1),posNA(:,2),'bo')
% fposxy = [];
% n = 0;
% % Loop, picking up the points.
% disp('Left mouse button picks points.')
% disp('Right mouse button picks last point.')
% but = 1;
% while but == 1
%     [xi,yi,but] = ginput(1);
%     plot(xi,yi,'ro')
%     n = n+1;
%     text(xi,yi-8,num2str(n));
%     fposxy(n,:) = [xi yi];
% end
% hold off
posFA = [   42.0000  323.0000
   54.0000  319.0000
   96.0000  298.0000
  139.0000  288.0000
  180.0000  280.0000
  225.0000  276.0000
  263.0000  273.0000
  301.0000  275.0000
  331.0000  281.0000
  347.0000  279.0000
  381.0000  290.0000
  417.0000  303.0000
  455.0000  317.0000
   69.0000  359.0000
   91.0000  349.0000
  115.0000  337.0000
  129.0000  338.0000
  168.0000  327.0000
  186.0000  321.0000
  270.0000  318.0000
  288.0000  320.0000
  312.0000  323.0000
  361.0000  330.0000
  383.0000  337.0000
  423.0000  352.0000
  432.0000  363.0000];

[ux, uy]=fwdSolution(x_mat_u,y_mat_u,E,xmin,xmax,ymin,ymax,...
    @(x,y) assumedForceAniso2D(1,x,y,139,267,150,420,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x,y,156,232,110*2,450*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x,y,184,212,60,500,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x,y,217,200,20,520,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x,y,246,195,0,550*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x,y,272,199,-30*2,510*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x,y,297,211,-75,495,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x,y,323,231,-100*2,440*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x,y,346,266,-140,400,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x,y,42,323,480,1600,500/108,2000/108,forceType)+...
    assumedForceAniso2D(1,x,y,54,319,400,1660,500/108,2100/108,forceType)+...
    assumedForceAniso2D(1,x,y,96,298,320,1720,500/108,2000/108,forceType)+...
    assumedForceAniso2D(1,x,y,139,288,240,1780,500/108,2300/108,forceType)+...
    assumedForceAniso2D(1,x,y,180,280,160,1840,500/108,2000/108,forceType)+...
    assumedForceAniso2D(1,x,y,225,276,80,1900,500/108,2400/108,forceType)+...
    assumedForceAniso2D(1,x,y,263,273,0,2000,550/108,2300/108,forceType)+...
    assumedForceAniso2D(1,x,y,301,275,-80,1900,600/108,2600/108,forceType)+...
    assumedForceAniso2D(1,x,y,331,281,-160,1840,500/108,2200/108,forceType)+...
    assumedForceAniso2D(1,x,y,347,279,-240,1780,400/108,2000/108,forceType)+...
    assumedForceAniso2D(1,x,y,381,290,-320,1720,600/108,2700/108,forceType)+...
    assumedForceAniso2D(1,x,y,417,303,-400,1660,500/108,2300/108,forceType)+...
    assumedForceAniso2D(1,x,y,455,317,-480,1600,450/108,2100/108,forceType)+...
    assumedForceAniso2D(1,x,y,69,359,600,2500,700/108,3000/108,forceType)+...
    assumedForceAniso2D(1,x,y,91,349,500,2600,600/108,2600/108,forceType)+...
    assumedForceAniso2D(1,x,y,115,337,400,2700,700/108,3500/108,forceType)+...
    assumedForceAniso2D(1,x,y,129,338,300,2800,700/108,3000/108,forceType)+...
    assumedForceAniso2D(1,x,y,168,327,200,2900,600/108,2600/108,forceType)+...
    assumedForceAniso2D(1,x,y,186,321,100,3000,600/108,3000/108,forceType)+...
    assumedForceAniso2D(1,x,y,270,318,0,3100,650/108,3500/108,forceType)+...
    assumedForceAniso2D(1,x,y,288,320,-100,3000,600/108,2600/108,forceType)+...
    assumedForceAniso2D(1,x,y,312,323,-200,2900,600/108,3000/108,forceType)+...
    assumedForceAniso2D(1,x,y,361,330,-300,2800,600/108,2600/108,forceType)+...
    assumedForceAniso2D(1,x,y,383,337,-400,2700,600/108,3500/108,forceType)+...
    assumedForceAniso2D(1,x,y,423,352,-500,2600,600/108,3000/108,forceType)+...
    assumedForceAniso2D(1,x,y,432,363,-600,2500,600/108,2600/108,forceType),...
    @(x,y) assumedForceAniso2D(2,x,y,139,267,150,420,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x,y,156,232,110*2,450*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x,y,184,212,60,500,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x,y,217,200,20,520,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x,y,246,195,0,550*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x,y,272,199,-30*2,510*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x,y,297,211,-75,495,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x,y,323,231,-100*2,440*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x,y,346,266,-140,400,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x,y,42,323,480,1600,500/108,2000/108,forceType)+...
    assumedForceAniso2D(2,x,y,54,319,400,1660,500/108,2100/108,forceType)+...
    assumedForceAniso2D(2,x,y,96,298,320,1720,500/108,2000/108,forceType)+...
    assumedForceAniso2D(2,x,y,139,288,240,1780,500/108,2300/108,forceType)+...
    assumedForceAniso2D(2,x,y,180,280,160,1840,500/108,2000/108,forceType)+...
    assumedForceAniso2D(2,x,y,225,276,80,1900,500/108,2400/108,forceType)+...
    assumedForceAniso2D(2,x,y,263,273,0,2000,550/108,2300/108,forceType)+...
    assumedForceAniso2D(2,x,y,301,275,-80,1900,600/108,2600/108,forceType)+...
    assumedForceAniso2D(2,x,y,331,281,-160,1840,500/108,2200/108,forceType)+...
    assumedForceAniso2D(2,x,y,347,279,-240,1780,400/108,2000/108,forceType)+...
    assumedForceAniso2D(2,x,y,381,290,-320,1720,600/108,2700/108,forceType)+...
    assumedForceAniso2D(2,x,y,417,303,-400,1660,500/108,2300/108,forceType)+...
    assumedForceAniso2D(2,x,y,455,317,-480,1600,450/108,2100/108,forceType)+...
    assumedForceAniso2D(2,x,y,69,359,600,2500,700/108,3000/108,forceType)+...
    assumedForceAniso2D(2,x,y,91,349,500,2600,600/108,2600/108,forceType)+...
    assumedForceAniso2D(2,x,y,115,337,400,2700,700/108,3500/108,forceType)+...
    assumedForceAniso2D(2,x,y,129,338,300,2800,700/108,3000/108,forceType)+...
    assumedForceAniso2D(2,x,y,168,327,200,2900,600/108,2600/108,forceType)+...
    assumedForceAniso2D(2,x,y,186,321,100,3000,600/108,3000/108,forceType)+...
    assumedForceAniso2D(2,x,y,270,318,0,3100,650/108,3500/108,forceType)+...
    assumedForceAniso2D(2,x,y,288,320,-100,3000,600/108,2600/108,forceType)+...
    assumedForceAniso2D(2,x,y,312,323,-200,2900,600/108,3000/108,forceType)+...
    assumedForceAniso2D(2,x,y,361,330,-300,2800,600/108,2600/108,forceType)+...
    assumedForceAniso2D(2,x,y,383,337,-400,2700,600/108,3500/108,forceType)+...
    assumedForceAniso2D(2,x,y,423,352,-500,2600,600/108,3000/108,forceType)+...
    assumedForceAniso2D(2,x,y,432,363,-600,2500,600/108,2600/108,forceType),'fft',[],meshPtsFwdSol); %,'conv',[],meshPtsFwdSol);

%% finding displacement at bead location
bead_ux = zeros(size(bead_x));
bead_uy = zeros(size(bead_y));
for k=1:nPoints
    [~,indcol_closest_x] = min(abs(x_mat_u(1,:)-bead_x(k)),[],2);
    [~,indrow_closest_y] = min(abs(y_mat_u(:,1)-bead_y(k)),[],1);
    row_bottom = max(1,indrow_closest_y-2);
    row_top = min(size(x_mat_u,2),indrow_closest_y+2);
    col_bottom = max(1,indcol_closest_x-2);
    col_top = min(size(y_mat_u,1),indcol_closest_x+2);
    loc_xmat = x_mat_u(row_bottom:row_top,col_bottom:col_top);
    loc_ymat = y_mat_u(row_bottom:row_top,col_bottom:col_top);
    loc_ux = ux(row_bottom:row_top,col_bottom:col_top);
    loc_uy = uy(row_bottom:row_top,col_bottom:col_top);
    bead_ux(k) = interp2(loc_xmat,loc_ymat,loc_ux,bead_x(k),bead_y(k));
    if isnan(bead_ux(k))
        bead_ux(k) = ux(indrow_closest_y,indcol_closest_x);
    end
    bead_uy(k) = interp2(loc_xmat,loc_ymat,loc_uy,bead_x(k),bead_y(k));
    if isnan(bead_uy(k))
        bead_uy(k) = uy(indrow_closest_y,indcol_closest_x);
    end
end

% pixelSize = 0.108; % assuming 60x objective um/pixel
beadimg = simGaussianBeads(xmax,ymax, sigma,'x',bead_x+bead_ux,'y',bead_y+bead_uy,'A',Av, 'Border', 'truncated');

dataPath='/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/Bead-tracking/multiForceTesting2';
imgPath=[dataPath filesep 'Beads'];
refPath=[dataPath filesep 'Reference'];
if ~exist(refPath,'dir')
    mkdir(imgPath);
    mkdir(refPath);
end

imwrite(uint16(refimg*2^16/max(max(refimg))),[refPath filesep 'img1ref.tif'],'tif')
imwrite(uint16(beadimg*2^16/max(max(beadimg))),[imgPath filesep 'img2bead.tif'],'tif')

%%  ------------------------ original force

force_x = assumedForceAniso2D(1,x_mat_u,y_mat_u,139,267,150,420,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,156,232,110*2,450*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,184,212,60,500,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,217,200,20,520,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,246,195,0,550*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,272,199,-30*2,510*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,297,211,-75,495,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,323,231,-100*2,440*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,346,266,-140,400,400/72,500/72,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,42,323,480,1600,500/108,2000/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,54,319,400,1660,500/108,2100/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,96,298,320,1720,500/108,2000/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,139,288,240,1780,500/108,2300/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,180,280,160,1840,500/108,2000/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,225,276,80,1900,500/108,2400/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,263,273,0,2000,550/108,2300/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,301,275,-80,1900,600/108,2600/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,331,281,-160,1840,500/108,2200/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,347,279,-240,1780,400/108,2000/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,381,290,-320,1720,600/108,2700/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,417,303,-400,1660,500/108,2300/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,455,317,-480,1600,450/108,2100/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,69,359,600,2500,700/108,3000/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,91,349,500,2600,600/108,2600/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,115,337,400,2700,700/108,3500/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,129,338,300,2800,700/108,3000/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,168,327,200,2900,600/108,2600/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,186,321,100,3000,600/108,3000/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,270,318,0,3100,650/108,3500/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,288,320,-100,3000,600/108,2600/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,312,323,-200,2900,600/108,3000/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,361,330,-300,2800,600/108,2600/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,383,337,-400,2700,600/108,3500/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,423,352,-500,2600,600/108,3000/108,forceType)+...
    assumedForceAniso2D(1,x_mat_u,y_mat_u,432,363,-600,2500,600/108,2600/108,forceType);
force_y = assumedForceAniso2D(2,x_mat_u,y_mat_u,139,267,150,420,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,156,232,110*2,450*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,184,212,60,500,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,217,200,20,520,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,246,195,0,550*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,272,199,-30*2,510*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,297,211,-75,495,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,323,231,-100*2,440*2,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,346,266,-140,400,400/72,500/72,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,42,323,480,1600,500/108,2000/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,54,319,400,1660,500/108,2100/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,96,298,320,1720,500/108,2000/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,139,288,240,1780,500/108,2300/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,180,280,160,1840,500/108,2000/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,225,276,80,1900,500/108,2400/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,263,273,0,2000,550/108,2300/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,301,275,-80,1900,600/108,2600/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,331,281,-160,1840,500/108,2200/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,347,279,-240,1780,400/108,2000/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,381,290,-320,1720,600/108,2700/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,417,303,-400,1660,500/108,2300/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,455,317,-480,1600,450/108,2100/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,69,359,600,2500,700/108,3000/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,91,349,500,2600,600/108,2600/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,115,337,400,2700,700/108,3500/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,129,338,300,2800,700/108,3000/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,168,327,200,2900,600/108,2600/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,186,321,100,3000,600/108,3000/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,270,318,0,3100,650/108,3500/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,288,320,-100,3000,600/108,2600/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,312,323,-200,2900,600/108,3000/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,361,330,-300,2800,600/108,2600/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,383,337,-400,2700,600/108,3500/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,423,352,-500,2600,600/108,3000/108,forceType)+...
    assumedForceAniso2D(2,x_mat_u,y_mat_u,432,363,-600,2500,600/108,2600/108,forceType);
%-------------------------------------------

% run the TFM Package and obtain displacement field and force field

%--------------------------------------------
%% display original forcefield
    imSizeX = x_mat_u(end,end)-x_mat_u(1,1);
    imSizeY = y_mat_u(end,end)-y_mat_u(1,1);

    pos = [reshape(x_mat_u,[],1) reshape(y_mat_u(:,:),[],1)]; %dense
    disp_vec = [reshape(ux,[],1) reshape(uy,[],1)]; 
    force_vec = [reshape(force_x,[],1) reshape(force_y,[],1)]; 
    grid_mat(:,:,2) = y_mat_u;
    grid_mat(:,:,1) = x_mat_u;
    
    [~,tmat, ~, ~] = interp_vec2grid(pos+disp_vec, force_vec,[],grid_mat); %1:cluster size
    tnorm = (tmat(:,:,1).^2 + tmat(:,:,2).^2).^0.5;
    
    [XI,YI]=meshgrid(x_mat_u(1,1):x_mat_u(1,1,1)+imSizeX,y_mat_u(1,1):y_mat_u(1,1)+imSizeY);
    tsMap = griddata(x_mat_u,y_mat_u,tnorm,XI,YI,'cubic');
    tmin = min(min(tnorm));
    tmax = max(max(tnorm));

    h1=figure('color','w');
    set(h1, 'Position', [100 100 imSizeX*1.25 imSizeY])

    subplot('Position',[0 0 0.8 1])
    imshow(tsMap,[tmin tmax]), colormap jet;
    %quiver
    % unit vector plot
    hold on
    cfactor = 4;
    tmat_coarse = tmat(cfactor-round(cfactor/2):cfactor:xmax,cfactor-round(cfactor/2):cfactor:ymax,:);
    grid_mat_coarse = grid_mat(cfactor-round(cfactor/2):cfactor:xmax,cfactor-round(cfactor/2):cfactor:ymax,:);
    tmat_vecx = reshape(tmat_coarse(:,:,1),[],1);
    tmat_vecy = reshape(tmat_coarse(:,:,2),[],1);
    pos_vecx = reshape(grid_mat_coarse(:,:,1),[],1);
    pos_vecy = reshape(grid_mat_coarse(:,:,2),[],1);
    forceScale=0.25*max(sqrt(tmat_vecx.^2+tmat_vecy.^2));
%     hq = quiver(pos_vecx,pos_vecy, tmat_vecx./forceScale,tmat_vecy./forceScale,0,'k');
    hq = quiver(pos_vecx-grid_mat(1,1,1),pos_vecy-grid_mat(1,1,2), tmat_vecx./forceScale,tmat_vecy./forceScale,0,'Color',[75/255 0/255 130/255]);

    subplot('Position',[0.8 0.1 0.1 0.8])
    axis tight
    caxis([tmin tmax]), axis off
    hc = colorbar('West');
    set(hc,'Fontsize',18)
    % saving
    % Set up the output file path
    outputFilePath = [dataPath filesep 'Heatmaps org'];
    tifPath = [outputFilePath filesep 'tifs'];
    figPath = [outputFilePath filesep 'figs'];
    epsPath = [outputFilePath filesep 'eps'];
    if ~exist(tifPath,'dir') || ~exist(epsPath,'dir')
        mkdir(tifPath);
        mkdir(figPath);
        mkdir(epsPath);
    end

    I = getframe(h1);
    imwrite(I.cdata, strcat(tifPath,'/stressMagTif','.tif'));
    hgsave(h1,strcat(figPath,'/stressMagFig','-v7.3'))
    print(h1,strcat(epsPath,'/stressMagEps.eps'),'-depsc2')

%% display original displacement field
    generateHeatmapFromGridData(x_mat_u,y_mat_u,ux,uy,dataPath)
    %% display measured displacement field
    % load displacement field
    displPath = '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/Bead-tracking/multiForceTesting/TFMPackage/displacementField';
    displFile ='/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/Bead-tracking/multiForceTesting/TFMPackage/displacementField/displField.mat';
    load(displFile)
    generateHeatmapFromField(displField,displPath,9.6)

    %% display measured displacement field
    % load displacement field
    displPath = '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/Bead-tracking/multiForceTesting/TFMPackage/displacementField cL=11';
    displFile ='/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/Bead-tracking/multiForceTesting/TFMPackage/displacementField cL=11/displField.mat';
    load(displFile)
    generateHeatmapFromField(displField,displPath,9.6)

        %% display measured corrected displacement field
    % load displacement field
    load('/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/Bead-tracking/multiForceTesting/TFMPackage/correctedDisplacementField/displField.mat')
    [reg_grid,~,~,spacing]=createRegGridFromDisplField(displField,2); %2=2 times fine interpolation
    [grid_mat,iu_mat,~,~] = interp_vec2grid(displField.pos, displField.vec,[],reg_grid);
    pos = [reshape(grid_mat(:,:,1),[],1) reshape(grid_mat(:,:,2),[],1)]; %dense
    disp_vec = [reshape(iu_mat(:,:,1),[],1) reshape(iu_mat(:,:,2),[],1)]; 

    umnorm = (iu_mat(:,:,1).^2 + iu_mat(:,:,2).^2).^0.5;
    umMap = griddata(grid_mat(:,:,1),grid_mat(:,:,2),umnorm,XI,YI,'cubic');
    ummin = min(min(umnorm));
    ummax = max(max(umnorm));

    h3=figure('color','w');
    subplot('Position',[0 0 0.8 1])
    imshow(umMap,[ummin ummax]), colormap jet;
    %quiver plot
    hold on
    hqm = quiver(displField.pos(:,1),displField.pos(:,2), displField.vec(:,1)./dispScale,displField.vec(:,2)./dispScale,0,'Color',[75/255 0/255 130/255]);
    
    subplot('Position',[0.8 0.1 0.1 0.8])
    axis tight
    caxis([ummin ummax]), axis off
    hc = colorbar('West');
    set(hc,'Fontsize',18)
    
    % saving
    % Set up the output file path
    outputFilePath = [dataPath filesep 'displacementField corrected'];
    tifPath = [outputFilePath filesep 'tifs'];
    figPath = [outputFilePath filesep 'figs'];
    epsPath = [outputFilePath filesep 'eps'];
    if ~exist(tifPath,'dir') || ~exist(epsPath,'dir')
        mkdir(tifPath);
        mkdir(figPath);
        mkdir(epsPath);
    end

    I = getframe(h3);
    imwrite(I.cdata, strcat(tifPath,'/displFieldMagTif','.tif'));
    hgsave(h3,strcat(figPath,'/displFieldMagFig','-v7.3'))
    print(h3,strcat(epsPath,'/displFieldMagEps.eps'),'-depsc2')
        %% display calculated force field
    % load displacement field
    forcePath = '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/Bead-tracking/multiForceTesting2/TFMPackage/forceField_L2_2nd Lcurve lambda';
    forceFile ='/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/Bead-tracking/multiForceTesting2/TFMPackage/forceField/forceField.mat';
    load(forceFile)
    generateHeatmapFromField(forceField,forcePath);
%% L-curve analysis for L2 0th
disp('calculating L-curve with L2 0th...')
load('/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/Bead-tracking/multiForceTesting2/TFMPackage/forceField/BEMParams.mat');
MpM = M'*M;
[eyeWeights,~] =getGramMatrix(forceMesh);
% original force at force base nodes
xminf = forceMesh.basis(1).node(1);
yminf = forceMesh.basis(1).node(2);
gridSpacingf = forceMesh.basis(2).node(2)-forceMesh.basis(1).node(2);
xmaxf = forceMesh.basis(end).node(1);
ymaxf = forceMesh.basis(end).node(2);

force_x_f = force_x(xminf:gridSpacingf:xmaxf,yminf:gridSpacingf:ymaxf);
force_y_f = force_y(xminf:gridSpacingf:xmaxf,yminf:gridSpacingf:ymaxf);

force_x_vec_f=reshape(force_x_f,[],1);
force_y_vec_f=reshape(force_y_f,[],1);
force_0=vertcat(force_x_vec_f,force_y_vec_f);

lambda=10.^(-9:0.125:-3);
rho=zeros(length(lambda),1);
eta=zeros(length(lambda),1);
fErr=zeros(length(lambda),1);
fCoeff=zeros(size(M,2),length(lambda));
for i=1:length(lambda);
  fCoeff(:,i)=(MpM+lambda(i)*eyeWeights)\(M'*u);
  rho(i)=norm(M*fCoeff(:,i)-u); %residual norm
  eta(i)=norm(eyeWeights*fCoeff(:,i),1); % semi norm
  % force error
  fErr(i)=norm(fCoeff(:,i)-force_0);
  disp([num2str(i) 'out of ' num2str(length(lambda))]);
end

%% Find the corner of the Tikhonov L-curve
[reg_corner,ireg_corner,kappa]=regParamSelecetionLcurve(rho,eta,lambda);
[~,fminIdx]=min(fErr);

save([dataPath '/LcurveL2-0th.mat'],'rho','eta','fErr','reg_corner','ireg_corner','lambda','fCoeff','fminIdx','-v7.3');

%% Plot the sparse deconvolution L-curve.
hLcurve = figure;
set(hLcurve, 'Position', [50 300 800 400])
subplot(1,2,1)
loglog(rho,eta,'k-');
xlabel('Residual Norm ||Gm-d||_{2}');
ylabel('Simi-Norm ||Lm||_{2}');
hold on
% mark and label the corner
H=loglog(rho(ireg_corner),eta(ireg_corner),'ro');
set(H,'markersize',6)
H=text(rho(ireg_corner),1.1*eta(ireg_corner),...
    ['    ',num2str(lambda(ireg_corner),'%5.1e')]);
set(H,'Fontsize',7);
subplot(1,2,2)
loglog(lambda,rho/max(rho(:)),'g')
hold on
loglog(lambda,eta/max(eta(:)),'b')
loglog(lambda,fErr/max(fErr(:)),'r')
% [~,fminIdx]=min(fErr);
loglog(lambda(fminIdx),fErr(fminIdx)/max(fErr(:)),'ko')
loglog(reg_corner,rho(ireg_corner)/max(rho(:)),'g*')
hold on
loglog(reg_corner,eta(ireg_corner)/max(eta(:)),'b*')
loglog(reg_corner,fErr(ireg_corner)/max(fErr(:)),'r*')
% axis([1e-2 100 0.001 1e8])
disp('Printing L-curve...')
% print -deps2 nameSave
print(hLcurve,[imgPath '/Lcurve.eps'],'-depsc')
hgexport(hLcurve,strcat(imgPath,'Lcurve'),hgexport('factorystyle'),'Format','tiff')
hgsave(hLcurve,strcat(imgPath,'Lcurve'),'-v7.3')
%% showing force for L2
[fx,fy,x_out,y_out]=calcForcesFromCoef(forceMeshFastBEM,fCoeff(:,37),grid_mat_f(:,:,1),grid_mat_f(:,:,2),'new');
generateHeatmapFromGridData(x_out,y_out,fx,fy,[dataPath filesep 'L2forcemap at Lcorner'])
[fx,fy,x_out,y_out]=calcForcesFromCoef(forceMeshFastBEM,fCoeff(:,31),grid_mat_f(:,:,1),grid_mat_f(:,:,2),'new');
generateHeatmapFromGridData(x_out,y_out,fx,fy,[dataPath filesep 'L1forcemap at fErr minimum'])
