function imarisApp = viewMovieImaris(movieData3D,iChannel)
%VIEWMOVIEIMARIS opens the input 3D movie for viewing in Imaris
% 
% viewMovieImaris(movieData3D)
% viewMovieImaris(movieData3D,iChannel)
% imarisApp = viewMovieImaris(...);
%
% This function opens Imaris and loads a channel of the input MovieData3D for
% 3D viewing within imaris. Requires that imaris is installed locally.
% 
% Input:
% 
%   movieData3D - The MovieData3D object describing the movie to view.
% 
%   iChannel - The index of the channel to view in imaris. This
%   corresponds to the channel object's location within the channel array
%   in the MovieData3D.
% 
% Output:
%   
%   imarisApp - The handle to the imaris application. If deleted, imaris
%   will close.
%
%   Additionally, Imaris will be opened and then the images loaded and displayed.
%   
%Hunter Elliott
%10/2010
%

%% ------------ Parameters ------------- %%

vertSize = 2;%Radius of skeleton vertex spots in voxels
edgeSize = 1;%Radius of SPOTS for skeleton edges
%All appearance parameters have this format:  [R,G,B,1-alpha]
vertApp = [1 1 .1 0];%Raw skel vertex appearance
edgeApp = [1 1 .1 0];%Raw skel edge appaerance
vertAppP = [1 .1 .1 0];%Pruned skel vertex appearance
edgeAppP = [1 .1 .1 0];%Pruned skel edge appaerance
msApp = [.2 .2 1 .6];%Mask surface appearance

%% -------- Input -------- %%

if nargin < 1 || isempty(movieData3D) || ~isa(movieData3D,'MovieData3D')
    error('The first input must be a valid MovieData3D object!')
end

if nargin < 2 || isempty(iChannel)
    iChannel = 1;
elseif ~isequal(round(abs(iChannel)),iChannel) || numel(iChannel) > 1
    error('The iChannel argument must be a single, positive integer.')
end

%% -------- Init ------ %%

if ~isempty(movieData3D.pixelSize_) && ~isempty(movieData3D.zSpacing_)
    pixXY = movieData3D.pixelSize_;
    pixZ = movieData3D.zSpacing_;      
else
    %warn the user, and assume unit pixel sizes.
    warning('Migration3D:MissingVoxelDimensions',...
        'Pixel XY size and Z spacing not specified in input movieData3D! Display will assume symmetric voxels of size 1nm!');
    pixXY = 1;
    pixZ = 1;    
end

nChan = 1;

%Get the image file names etc
imageNames = movieData3D.getImageFileNames(iChannel);
imagePaths{1} = movieData3D.channels_(iChannel).channelPath_;
nImages = movieData3D.nFrames_;
chanCols = [1 0 0];
chanRange = [0 2e16-2];

%Start imaris and get app handle
imarisApp = imarisStartNew(nargout==0);

%Create a blank scene
imarisScene = imarisApp.mFactory.CreateDataContainer;
imarisApp.mSurpassScene = imarisScene;

%Add lighting and frame objects to scene
imarisScene.AddChild(imarisApp.mFactory.CreateLightSource); %add the light to the scene
imarisScene.AddChild(imarisApp.mFactory.CreateFrame); %add the frame to the scene

%Check if we have masks or skeletons as these will be additional channels
chanNames = {'Fluorescence','Masks'};%,'Skeleton'};
               
%Check for masks 
iSegProc = movieData3D.getProcessIndex('SegmentationProcess3D',1,1);
if ~isempty(iSegProc) && movieData3D.processes_{iSegProc}.checkChannelOutput(iChannel)
    disp('Masks found - displaying as additional channel.')
    nChan = nChan + 1;
    imagePaths{nChan} = movieData3D.processes_{iSegProc}.outFilePaths_{iChannel};
    imageNames{nChan} = movieData3D.processes_{iSegProc}.getOutMaskFileNames(iChannel);
    imageNames{nChan} = imageNames{nChan}{1};%De-cell this element
    chanCols = vertcat(chanCols,[1 1 1]);
    chanRange = vertcat(chanRange,[0 2]);%We make the range go to slightly above 1 so the masks are transparent
end


%Initialize the volume data
volData = imarisApp.mFactory.CreateDataSet;
volData.Create('eTypeUint16',...
                movieData3D.imSize_(1),... %Image sizes
                movieData3D.imSize_(2),...
                movieData3D.nSlices_,...
                nChan,... %Number of Channels
                nImages); %Number of timepoints 
            
            
%Set the pixel sizes
volData.mExtendMinX = 0;
volData.mExtendMinY = 0;
volData.mExtendMinZ = 0;
volData.mExtendMaxX = volData.mSizeX * pixXY;
volData.mExtendMaxY = volData.mSizeY * pixXY;
volData.mExtendMaxZ = volData.mSizeZ * pixZ;
volData.mUnit = 'nm'; %Set units to nanometers

%String for setting frame times. 
oneFrame= movieData3D.timeInterval_/(24*60*60); %Fraction of day corresponding to one frame sec, for datestr.m use
yearString = '2000-01-01 ';%The year/date doesn't seem to matter, so I just use this generic one
msString = '.000'; %The miliseconds portion of the date string

%% ------- Load and Display all Images ----- %%

wtBar = waitbar(0,'Please wait, loading all images...');

for iImage = 1:nImages

    for iChan = 1:nChan
    
        if iImage == 1
            %Set channel color and range
            volData.SetChannelColor(iChan-1,...
                                        chanCols(iChan,1),...
                                        chanCols(iChan,2),...
                                        chanCols(iChan,3),0);                                 
            volData.SetChannelRange(iChan-1,...
                                            chanRange(iChan,1),...
                                            chanRange(iChan,2));
                                        
            volData.SetChannelName(iChan-1,chanNames{iChan});
            
        end
        
        %Load the image
        if iChan == 1
            currIm = stackRead([imagePaths{iChan} filesep imageNames{iChan}{iImage}]);
        else
            %Stackread doesn't support the bitpacking compression of
            %binary tifs
            currIm = uint16(tif3Dread([imagePaths{iChan} filesep imageNames{iChan}{iImage}]));
        end
    
        %Add it to the imaris scene
        volData.SetDataVolume(currIm,iChan-1,iImage-1); %Imaris indexes start at 0
        
    end
        
    %Get the time string for this frame
    if iImage == 1
        %Datestr.m doesn't return the last portion if it's all zeros...
        secString = '00:00:00';        
    else    
        %Use datestr to convert to hr:min:sec
        secString = datestr(1+(iImage-1)*oneFrame);
        secString = secString(13:end);
    end
    tString = [yearString secString msString];
    volData.SetTimePoint(iImage-1,tString);

    waitbar(iImage/nImages,wtBar);
    
end

%Add this volume data to the scene
imarisApp.mDataSet = volData;

%Adjust the camera so all the data is in view
imarisApp.mSurpassCamera.Fit;
imarisScene.AddChild(imarisApp.mFactory.CreateVolume);%Strangely enough, this is both necessary and sufficient to display the mDataSet in the newly created scene.
if ishandle(wtBar)
    close(wtBar);
end

%% ------------ Load and Display All Available Analysis --------------- %%

iSkelProc = movieData3D.getProcessIndex('SkeletonizationProcess',1,1);
if ~isempty(iSkelProc) && movieData3D.processes_{iSkelProc}.checkChannelOutput(iChannel) ...
        && movieData3D.processes_{iSkelProc}.checkChannelSkeletonGraphs(iChannel)
    disp('Skeleton Graphs found, displaying.')        
    
    nVert = zeros(nImages,1);    
    nEdge = zeros(nImages,1);
    nPtsPerEdge = cell(nImages,1);
    nEdgePts = zeros(nImages,1);
    skgr(1:nImages) = struct('vertices',[],'edges',[],'edgePaths',[]);
    
    %Load the skeletons for each frame and count the verts and edges
    for iImage = 1:nImages        
        skgr(iImage) = movieData3D.processes_{iSkelProc}.loadSkeletonGraph(iChannel,iImage);
        nVert(iImage) = size(skgr(iImage).vertices,1);
        nEdge(iImage) = numel(skgr(iImage).edgePaths);            
        nPtsPerEdge{iImage} = cellfun(@(x)(size(x,1)),skgr(iImage).edgePaths);
        nEdgePts(iImage) = sum(nPtsPerEdge{iImage});
        
    end
    
    nEdgeTot = sum(nEdge);
    nEdgePtsTot = sum(nEdgePts);
    nVertTot = sum(nVert);
    nEdgeEdgesTot = nEdgePtsTot-nEdgeTot;
    
    vertXYZ = zeros(nVertTot,3);
    vertRad = ones(nVertTot,1) .* vertSize .* pixXY;
    vertTimes = zeros(nVertTot,1);
    
    edgeXYZ = zeros(nEdgePtsTot,3);
    edgeTimes = zeros(nEdgePtsTot,1);
    edgeEdges = zeros(nEdgeEdgesTot,2);
    edgeRad = ones(nEdgePtsTot,1) .* edgeSize .* pixXY;
    
    %Go through each frame and set up the spot matrices for passing to
    %imaris
    ciV = 1;
    ciE = 1;
    cieE = 1;
    for iImage = 1:nImages
                        
        currIndV = ciV:ciV+nVert(iImage)-1;%Indices for the vertices on this frame
        currIndE = ciE:ciE+nEdgePts(iImage)-1;%Indices for the edge paths on this frame
        
        vertTimes(currIndV) = iImage-1; %Time indices for vertices        
        vertXYZ(currIndV,1:2) = (skgr(iImage).vertices(:,1:2) -1) .* pixXY;%Scale the coordinates by pixel size, shift by one because imaris voxel coordinates start at zero
        vertXYZ(currIndV,3) = (skgr(iImage).vertices(:,3) -1) .* pixZ;
        
        edgeTimes(currIndE) = iImage-1;
        ciEP = ciE;
        ciEE = cieE;
        
        for iEdg = 1:nEdge(iImage)
            %Indices for the pts on the current edge
            currIndEP = ciEP:ciEP+nPtsPerEdge{iImage}(iEdg)-1;
            currIndEE = ciEE:ciEE+nPtsPerEdge{iImage}(iEdg)-2;
            
            if ~isempty(currIndEP) && ~isempty(currIndEE)%Make sure it's not a spur first
                edgeXYZ(currIndEP,1:2) = (skgr(iImage).edgePaths{iEdg}(:,1:2) -1) .* pixXY;
                edgeXYZ(currIndEP,3) = (skgr(iImage).edgePaths{iEdg}(:,3) -1) .* pixZ;

                %These edge path points are stored consecutively, so just
                %connect each subsequent point with an edge.
                edgeEdges(currIndEE,:) = [currIndEP(1:end-1)' currIndEP(2:end)']-1;%Shift indices by one for imaris
            end
            
            ciEP = ciEP + nPtsPerEdge{iImage}(iEdg);            
            ciEE = ciEE + nPtsPerEdge{iImage}(iEdg)-1;
        end
                               
        ciV = ciV + nVert(iImage);
        ciE = ciE + nEdgePts(iImage);
        cieE = cieE + nEdgePts(iImage) - nEdge(iImage); %There is one less edge than point for each skeleton branch
    end    
            
    %Create spots object for skeleton vertices
    imarisVertSpots = imarisApp.mFactory.CreateSpots;
    imarisVertSpots.mName = 'Skeleton Vertices';
    imarisVertSpots.SetColor(vertApp(1),vertApp(2),vertApp(3),vertApp(4));
    %Add the vertices to the scene as spots
    imarisVertSpots.Set(vertXYZ,vertTimes,vertRad);
    imarisApp.mSurpassScene.AddChild(imarisVertSpots);
    
    %Create spots object for skeleton edges
    imarisEdgeSpots = imarisApp.mFactory.CreateSpots;
    imarisEdgeSpots.mName = 'Skeleton Branches';
    imarisEdgeSpots.SetColor(edgeApp(1),edgeApp(2),edgeApp(3),edgeApp(4));
    %Add the vertices to the scene as spots
    imarisEdgeSpots.Set(edgeXYZ,edgeTimes,edgeRad);
    imarisEdgeSpots.SetTrackEdges(edgeEdges);
    imarisApp.mSurpassScene.AddChild(imarisEdgeSpots);        
    
end

iMgProc = movieData3D.getProcessIndex('MaskGeometry3DProcess',1,1);
if ~isempty(iMgProc) && movieData3D.processes_{iMgProc}.checkChannelOutput(iChannel)     
    
    disp('Mask surface geometry analysis found - displaying.')
        
    %Create object for adding surfaces
    imarisSurf = imarisApp.mFactory.CreateSurfaces;
    imarisSurf.mName = 'Smoothed Mask Surface';
    imarisSurf.SetColor(msApp(1),msApp(2),msApp(3),msApp(4));        
    
    for iImage = 1:nImages
        
        %Load the current surface geom file
        tmp =  movieData3D.processes_{iMgProc}.loadChannelOutput(iChannel,iImage);
        if iImage == 1
            %Get field names from first frame and then initialize array
            mg = repmat(tmp(1),nImages,1);
        end        
        
        if ~isempty(tmp)        
            mg(iImage) = tmp(1);%Just in case they have multiple objects
                
            %Extract the surface info for scaling etc.
            if ~movieData3D.processes_{iMgProc}.funParams_.PhysicalUnits

                vert = zeros(size(mg(iImage).SmoothedSurface.vertices));
                vert(:,2:-1:1) = (mg(iImage).SmoothedSurface.vertices(:,1:2) -1) .* pixXY;%The surface norms are returned in cartesian rather than matrix coord
                vert(:,3) = (mg(iImage).SmoothedSurface.vertices(:,3) -1) .* pixXY;%The properties already take into account the pixel aspect ratio, so we scale the z by the xy size also.
                faces = mg(iImage).SmoothedSurface.faces - 1;%Imaris indices start at 0
                norms = zeros(size(mg(iImage).SurfaceNorms));
                norms(:,2:-1:1) = (mg(iImage).SurfaceNorms(:,1:2) -1) .* pixXY;
                norms(:,3) = (mg(iImage).SurfaceNorms(:,3) -1) .* pixXY;

            else
                vert = zeros(size(mg(iImage).SmoothedSurface.vertices));
                vert(:,2:-1:1) = mg(iImage).SmoothedSurface.vertices(:,1:2) - pixXY;%No scaling, but shift for imaris voxel coord
                vert(:,3) = mg(iImage).SmoothedSurface.vertices(:,3) -pixZ;%The properties already take into account the pixel aspect ratio, so we scale the z by the xy size also.
                faces = mg(iImage).SmoothedSurface.faces - 1;%Imaris indices start at 0
                norms = zeros(size(mg(iImage).SurfaceNorms));
                norms(:,2:-1:1) = mg(iImage).SurfaceNorms(:,1:2) - pixXY;
                norms(:,3) = mg(iImage).SurfaceNorms(:,3) - pixZ;                        
            end
            imarisSurf.AddSurface(vert,faces,norms,iImage-1);                
        end
    
    end
    %Add the surfaces to the surpass scene
    imarisApp.mSurpassScene.AddChild(imarisSurf);
        
end

%TEMP - There is massive code duplication between displaying the raw skeletons and
%displaying the pruned ones here...Probably should fix at some point...HLE
iPruneProc = movieData3D.getProcessIndex('SkeletonPruningProcess',1,1);
if ~isempty(iPruneProc) && movieData3D.processes_{iPruneProc}.checkChannelOutput(iChannel)        
    
    disp('Pruned skeleton graphs found, displaying.')        
    
    nVert = zeros(nImages,1);
    nEdge = zeros(nImages,1);
    nPtsPerEdge = cell(nImages,1);
    nEdgePts = zeros(nImages,1);
    skgrPruned(1:nImages) = struct('vertices',[],'edges',[],'edgePaths',[]);
    
    %Load the skeletons for each frame and count the verts and edges
    for iImage = 1:nImages
        skgrPruned(iImage) = movieData3D.processes_{iPruneProc}.loadChannelOutput(iChannel,iImage);
        nVert(iImage) = size(skgrPruned(iImage).vertices,1);
        nEdge(iImage) = numel(skgrPruned(iImage).edgePaths);            
        nPtsPerEdge{iImage} = cellfun(@(x)(size(x,1)),skgrPruned(iImage).edgePaths);
        nEdgePts(iImage) = sum(nPtsPerEdge{iImage});        
    end
    
    nEdgeTot = sum(nEdge);
    nEdgePtsTot = sum(nEdgePts);
    nVertTot = sum(nVert);
    nEdgeEdgesTot = nEdgePtsTot-nEdgeTot;
    
    vertXYZ = zeros(nVertTot,3);
    vertRad = ones(nVertTot,1) .* vertSize .* pixXY;
    vertTimes = zeros(nVertTot,1);
    
    edgeXYZ = zeros(nEdgePtsTot,3);
    edgeTimes = zeros(nEdgePtsTot,1);
    edgeEdges = zeros(nEdgeEdgesTot,2);
    edgeRad = ones(nEdgePtsTot,1) .* edgeSize .* pixXY;
    
    %Go through each frame and set up the spot matrices for passing to
    %imaris
    ciV = 1;
    ciE = 1;
    cieE = 1;
    for iImage = 1:nImages
                        
        currIndV = ciV:ciV+nVert(iImage)-1;%Indices for the vertices on this frame
        currIndE = ciE:ciE+nEdgePts(iImage)-1;%Indices for the edge paths on this frame
        
        vertTimes(currIndV) = iImage-1; %Time indices for vertices        
        vertXYZ(currIndV,:) = (skgrPruned(iImage).vertices -1) .* pixXY;%Scale the coordinates by the xy pixel size only, because they have been converted to symmetric-voxel coordinates        
        
        edgeTimes(currIndE) = iImage-1;
        ciEP = ciE;
        ciEE = cieE;
        
        for iEdg = 1:nEdge(iImage)
            %Indices for the pts on the current edge
            currIndEP = ciEP:ciEP+nPtsPerEdge{iImage}(iEdg)-1;
            currIndEE = ciEE:ciEE+nPtsPerEdge{iImage}(iEdg)-2;
            
            if ~isempty(currIndEP) && ~isempty(currIndEE)%Make sure it's not a spur first
            
                edgeXYZ(currIndEP,:) = (skgrPruned(iImage).edgePaths{iEdg} -1) .* pixXY;            

                %These edge path points are stored consecutively, so just
                %connect each subsequent point with an edge.
                edgeEdges(currIndEE,:) = [currIndEP(1:end-1)' currIndEP(2:end)']-1;%Shift indices by one for imaris
            end

            ciEP = ciEP + nPtsPerEdge{iImage}(iEdg);            
            ciEE = ciEE + nPtsPerEdge{iImage}(iEdg)-1;
        end
                               
        ciV = ciV + nVert(iImage);
        ciE = ciE + nEdgePts(iImage);
        cieE = cieE + nEdgePts(iImage) - nEdge(iImage); %There is one less edge than point for each skeleton branch
    end    
            
    %Create spots object for skeleton vertices
    imarisPruneVertSpots = imarisApp.mFactory.CreateSpots;
    imarisPruneVertSpots.mName = 'Pruned Skeleton Vertices';
    imarisPruneVertSpots.SetColor(vertAppP(1),vertAppP(2),vertAppP(3),vertAppP(4));
    %Add the vertices to the scene as spots
    imarisPruneVertSpots.Set(vertXYZ,vertTimes,vertRad);
    imarisApp.mSurpassScene.AddChild(imarisPruneVertSpots);
    
    %Create spots object for skeleton edges
    imarisPruneEdgeSpots = imarisApp.mFactory.CreateSpots;
    imarisPruneEdgeSpots.mName = 'Pruned Skeleton Branches';
    imarisPruneEdgeSpots.SetColor(edgeAppP(1),edgeAppP(2),edgeAppP(3),edgeAppP(4));
    %Add the vertices to the scene as spots
    imarisPruneEdgeSpots.Set(edgeXYZ,edgeTimes,edgeRad);
    imarisPruneEdgeSpots.SetTrackEdges(edgeEdges);
    imarisApp.mSurpassScene.AddChild(imarisPruneEdgeSpots);        
    
end


