%This is a script file that displays reconstructed boundary force overlaid to the domain force map.

if ~isdir([reslDir filesep 'bndfFig'])
   success = mkdir(reslDir,'bndfFig');
   if ~success
      error('trouble making directory.')
   end
end
bndfFigDir = [reslDir filesep 'bndfFig'];

bndfTifDir = [reslDir filesep 'bndfTif'];
if ~isdir([reslDir filesep 'bndfTif'])
   success = mkdir(reslDir,'bndfTif');
   if ~success
      error('trouble making directory.')
   end
end
bndfTifDir = [reslDir filesep 'bndfTif'];

%Find the maximum force.
maxF = 0;

answer = input('Select time steps (0 for all):');
if isempty(answer) | answer == 0
   selTimeSteps = 1:numDTimePts;

   bdfMapFile = [reslDir filesep 'bdfMap' filesep 'bdfMap.mat'];
   if exist(bdfMapFile,'file')
      load(bdfMapFile);
      numInd = find(~isnan(bdfMap));
      maxF = max(maxF,max(bdfMap(numInd)));

      selTimeSteps = [0 selTimeSteps];
   end
else
   selTimeSteps = answer;
   if selTimeSteps == -1
      selTimeSteps = 0;
   end
end

answer = input('Select edges to display (0 for all):');
if isempty(answer) | answer == 0
   edgToDisplay = 0;
else
   edgToDisplay = answer;
end


for ii = 1:length(selTimeSteps)
   jj = selTimeSteps(ii);
   
   if jj == 0
      imgIndex = [];
      dispImgIndex = firstImgIndex;
   else
      imgIndex = imgIndexOfDTimePts(jj);
      dispImgIndex = max(firstImgIndex,imgIndex);
   end
   
   %Load the saved body force map.
   indexStr = sprintf(imgIndexForm,imgIndex);
   bdfMapFile = [reslDir filesep 'bdfMap' filesep 'bdfMap' indexStr '.mat'];
   load(bdfMapFile);
   
   numInd = find(~isnan(bdfMap));
   maxF = max(maxF,max(bdfMap(numInd)));
end

%Load detected cell edge files;
edge_sp_array_x = [];
edge_sp_array_y = [];
pixel_edge      = [];
if strcmp(markCellEdge,'yes') && isdir(edgeDir)
   edge_splineFile = [edgeDir filesep 'edge_spline.mat'];
   pixel_edgeFile  = [edgeDir filesep 'pixel_edge.mat'];
   if exist(edge_splineFile,'file') && exist(pixel_edgeFile,'file')
      s = load(edge_splineFile);
      edge_sp_array_x = s.edge_sp_array_x;
      edge_sp_array_y = s.edge_sp_array_y;

      s = load(pixel_edgeFile);
      pixel_edge = s.pixel_edge;
   end
end

%Creat color map
% cMap = colormap('jet');
%cMap = [[zeros(10,1) linspace(0,0.95,10).' linspace(1,0.05,10).']]; %Blue
%cMap = [cMap; [ones(30,1) linspace(1,0,30).' zeros(30,1)]]; %Yellow to red.
numColors = 128;

%Blue-Green to yellow.
cMap = [linspace(0,1,numColors/2).' ...
   linspace(0.5,1,numColors/2).' ...
   linspace(0.5,0.05,numColors/2).'];
%Yellow to red.
cMap = [cMap; [ones(numColors/2,1) ...
   linspace(1,0,numColors/2).' zeros(numColors/2,1)]];

figH = figure;
backStr = '';
for ii = 1:length(selTimeSteps)
   jj = selTimeSteps(ii);

   localStartTime = cputime;

   for kk = 1:length(backStr)
      fprintf(1,'\b');
   end
   backStr = sprintf('   Time step %d ... ',jj);
   fprintf(1,backStr);

   if jj == 0
      imgIndex = [];
      dispImgIndex = firstImgIndex;
   else
      imgIndex = imgIndexOfDTimePts(jj);
      dispImgIndex = max(firstImgIndex,imgIndex);
   end

   frameNo = dispImgIndex-firstImgIndex+1;
   if length(numAvgFrames) == numDTimePts
      if jj == 0
         curNumAvgFrames = numAvgFrames(1);
      else
         curNumAvgFrames = numAvgFrames(jj);
      end
   else
      curNumAvgFrames = numAvgFrames;
   end

   %Get the overlaid images of selected image channel.
   stackedImg = double(imread(imgFileList{imgChannel}{frameNo}));
   for k = 1:curNumAvgFrames-1
      stackedImg = stackedImg + double(imread(imgFileList{imgChannel}{k+frameNo}));
   end
   stackedImg = stackedImg/curNumAvgFrames;

   maxImgI = max(stackedImg(:));
   minImgI = min(stackedImg(:));
   if minImgI < maxImgI
      stackedImg = (stackedImg-minImgI)/(maxImgI-minImgI);
      stackedImg(find(stackedImg>imgIRange(2))) = imgIRange(2);
      stackedImg(find(stackedImg<imgIRange(1))) = imgIRange(1);
   end

   %Get the dimension of the cell image.
   pixelX = [1:size(stackedImg,2)];
   pixelY = [1:size(stackedImg,1)];

   iDispFieldFileName = ['iDispField' sprintf(imgIndexForm,imgIndex) '.mat'];
   iDispFieldFile     = [iDispFieldDir filesep iDispFieldFileName];
   s = load(iDispFieldFile);
   iDispField = s.iDispField;

   gridY = iDispField.gridY;
   gridX = iDispField.gridX;
   %Load the saved body force map.
   indexStr = sprintf(imgIndexForm,imgIndex);
   bdfMapFile = [reslDir filesep 'bdfMap' filesep 'bdfMap' indexStr '.mat'];
   load(bdfMapFile);

   % cMap = colormap('jet');
   %cMap = [[zeros(10,1) linspace(0,0.95,10).' linspace(1,0.05,10).']]; %Blue
   %cMap = [cMap; [ones(30,1) linspace(1,0,30).' zeros(30,1)]]; %Yellow to red.
   numColors = 128;

   %Blue-Green to yellow.
   cMap = [linspace(0,1,numColors/2).' ...
      linspace(0.5,1,numColors/2).' ...
      linspace(0.5,0.05,numColors/2).'];
   %Yellow to red.
   cMap = [cMap; [ones(numColors/2,1) ...
      linspace(1,0,numColors/2).' zeros(numColors/2,1)]];

   numInd = find(~isnan(bdfMap));
   maxBDF = bdfColorDispRange(2)*maxF;
   minBDF = bdfColorDispRange(1)*maxF;
   bdfImg = imDataMapOverlay(stackedImg,bdfMap,[minBDF maxBDF],cMap);

   figure(figH); hold off;
   imshow(bdfImg,[]); hold on;

   if ~isempty(pixel_edge)
      %We use the middle frame of each moving time window for plotting
      % the cell edge since the force represent the average over the time window.
      edgeFrameID = ceil((2*frameNo+curNumAvgFrames-1)/2);
      plot(pixel_edge{edgeFrameID}(:,1),pixel_edge{edgeFrameID}(:,2),cellEdgeColor);
   end
   
   if strcmp(markMixZone,'yes')
      %Load the saved mix zone force map.
      mixfMapFile = [reslDir filesep 'mixfMap' filesep 'mixfMap' indexStr '.mat'];
      load(mixfMapFile);
      mixZoneInd = find(~isnan(mixfMap));

      mixBW = zeros(size(mixfMap));
      mixBW(mixZoneInd) = 1;
      mixZoneBnd = bwboundaries(mixBW);
      for k = 1:length(mixZoneBnd)
         plot(mixZoneBnd{k}(:,2),mixZoneBnd{k}(:,1),'w','LineWidth',1);
      end

      %Also draw some grey dots in the mixed region.
      gridInd = sub2ind(size(mixBW),round(gridY),round(gridX));
      mixGridInd = find(mixBW(gridInd)==1);
      dotH = plot(gridX(mixGridInd),gridY(mixGridInd),'w.');
      set(dotH,'Color',[0.7 0.7 0.7],'LineWidth',3);
   end

   forceFieldFile = [forceFieldDir filesep 'forceField' ...
      sprintf(imgIndexForm,imgIndex) '.mat'];
   s = load(forceFieldFile);
   forceField = s.forceField;

   bfDisplayPx = forceField.p(:,1);
   bfDisplayPy = forceField.p(:,2);

   %We show the flow field calculated with the reconstructed domain force and the reconstructed
   %boundary force on the first chosen edge where boundary force is to be displayed.
   if jj == 0 | edgToDisplay == 0
      edgNo = 1;
   else
      edgNo = edgToDisplay(1);
   end
   recDispU1   = iDispField.bndF_rv{edgNo}(:,1);
   recDispU2   = iDispField.bndF_rv{edgNo}(:,2);
   if strcmp(showFlowVec,'yes')
      quiver(bfDisplayPx,bfDisplayPy, ...
         recDispU1*dispScale,recDispU2*dispScale,0,'y');
   end

   bndF = forceField.bndF;
   if jj == 0 | edgToDisplay == 0
      for k = 1:length(bndF)
         quiver(bndF(k).p(1,:),bndF(k).p(2,:),bndF(k).fx*tfScale,bndF(k).fy*tfScale,0,'r');
      end
   else
      for k = 1:length(edgToDisplay)
         edgNo = edgToDisplay(k);
         quiver(bndF(edgNo).p(1,:),bndF(edgNo).p(2,:),bndF(edgNo).fx*tfScale,bndF(edgNo).fy*tfScale,0,'r');
      end
   end

   titleStr = sprintf(['Boundary Force\n' 'Time Step: %d Image Index: %d'], ...
      jj,imgIndex);
   title(titleStr);
   
   %Save the figure
   bndfFigFile = [bndfFigDir filesep 'bndfFig' indexStr '.fig'];
   saveas(figH,bndfFigFile,'fig');   
   
   bndfTifFile = [bndfTifDir filesep 'bndfTif' indexStr '.tif'];
   print(figH,'-dtiffnocompression',bndfTifFile);
end
fprintf(1,'\n');

