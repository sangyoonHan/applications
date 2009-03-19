function fsmParam=fsmDispScoreMaps(SCORE,fsmParam)
% fsmDispScoreMaps creates images with overlaid color-codes scores
% 
% SYNOPSIS   fsmParam=fsmDispScoreMaps(SCORE,fsmParam)
%
% INPUT      SCORE        : scores rearranged into a matrix with the form
%                           [t y x s]n     t : time point (frame)
%                                          y : y coordinate of the event position
%                                          x : x coordinate of the event position
%                                          s : score
%                                          n : total number of events
%
% OUTPUT     fsmParam     : general parameter structure (fsmParam might be updated by this function)
%
%
% REMARK : SCORE does not contain the scores generated by the temporal low-pass filtering!

if nargin~=2
    error('Two parameters expected');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% SET CONSTANTS
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set conversion factor score -> color class
bitDepth=log2(fsmParam.main.normMax+1);
if bitDepth==8
    convFactor=7.6e4; %
else                  %  
    convFactor=7.6e6; %      REMARK:   this value comes from the analysis of the 
                      %                score histograms of several experiments and is also
                      %                a function of the mean event distance. Therefore, 
                      %                CHANGE IT ONLY IF YOU HAVE A GOOD REASON.
end
yxOffset=[0 0];  % This offset is no longer used; but it made be in the future, so it is maintained

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% READ NEEDED PARAMETERS FROM fsmParam
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rootUserPath=fsmParam.main.path;
outFileList=fsmParam.specific.fileList;
firstImage=outFileList(1,:);
imgSize=fsmParam.specific.imgSize;
n=fsmParam.specific.imageNumber;
strg=fsmParam.specific.formString;
autoPolygon=fsmParam.prep.autoPolygon;
firstIndex=fsmParam.specific.firstIndex;
lastIndex=fsmParam.specific.lastIndex;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% CHANGE TO WORK PATH (CREATE IF NEEDED)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create subdirectory movie where all image files will be saved
if rootUserPath(end)==filesep
   userPath=[rootUserPath,'movies'];
else
   userPath=[rootUserPath,filesep,'movies'];
end

% Create temporary directory
if ~exist(userPath, 'dir')
   % Directory does not exist - create it
   if userPath(2)==':'
      % Drive letter specified
      mkdir(userPath(1:3),userPath(4:end));
   else
      mkdir(userPath);
   end
end

% Change to directory
oldDir=cd;
cd(userPath);
                            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% CHECK FOR THE EXISTANCE OF THE FIRST IMAGE
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist(firstImage, 'file')
   % Images have to be selected again
   [fName,dirName] = uigetfile('*.tif','Select first image');
   if(isa(fName,'char') && isa(dirName,'char'))
      %cd(dirName);
      [a, map]=imread([dirName,fName]);
      % Recover all file names from the stack
      outFileList=getFileStackNames([dirName,fName]);
      % Cut in case
      if length(outFileList)>n
          outFileList=outFileList(1:n);
      end
      outFileList=char(outFileList);
      % Copy outFileList into fsmParam
      fsmParam.specific.fileList=outFileList;
   else
       disp('Result display module interrupted by user.');
       return
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% CREATE COLORMAP FOR DISPLAY
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mapC=[   0         0         1.0000; % Blue
         0         0.0645    0.9677;
         0         0.1290    0.9355;
         0         0.1935    0.9032;
         0         0.2581    0.8710;
         0         0.3226    0.8387;
         0         0.3871    0.8065;
         0         0.4516    0.7742;
         0         0.5161    0.7419;
         0         0.5806    0.7097;
         0         0.6452    0.6774;
         0         0.7097    0.6452;
         0         0.7742    0.6129;
         0         0.8387    0.5806;
         0         0.9032    0.5484;
         %0         0.9677    0.5161; % Green
         1.0000    1.0000    1.0000; % White
         1.0000    0.8889         0; % Yellow
         1.0000    0.8254         0;
         1.0000    0.7619         0;
         1.0000    0.6984         0;
         1.0000    0.6349         0;
         1.0000    0.5714         0;
         1.0000    0.5079         0;
         1.0000    0.4444         0;
         1.0000    0.3810         0;
         1.0000    0.3175         0;
         1.0000    0.2540         0;
         1.0000    0.1905         0;
         1.0000    0.1270         0;
         1.0000    0.0635         0;
         1.0000         0         0]; % Red

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% CALCULATE THE MEAN ROI DIMENSION
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calculate the mean area of interest
if autoPolygon==1

    % Counter
    areaCounter=0;
    
    % Store the area to control whether autoPolygon failed
    totArea=prod(imgSize);  
    
    % Initializing progress bar
    h = waitbar(0,'Calculating mean event distance...');

    area=[];
    for i=1:n
        
        % Current index
        currentIndex=i+firstIndex-1;

        % Load black-and-white mask
        indxStr=sprintf(strg,currentIndex);   
        fName=[rootUserPath filesep 'bwMask' filesep 'bwMask' indxStr '.mat'];
        
        if exist(fName, 'file') == 2
            string=['load ' fName];
            eval(string);
            
            % Calculate current area
            currArea=sum(bwMask(:));
            
            % Check whether currArea==totArea - this means that autoPolygon failed
            if currArea~=totArea

                % Append this
                areaCounter=areaCounter+1;
                area(areaCounter)=currArea;
                
                clear bwMask;
                
            end
            
            
        end
        % Update wait bar
        waitbar(i/n,h);
        
        
    end
    
    % Close waitbar
    close(h);
    
    if ~isempty(area)
        imgArea=mean(area);
    else
        imgArea=prod(imgSize);
    end
    
else
    
    imgArea=prod(imgSize);
    
end    

% Calculate the approximate mean event distance and sigma for the gaussian kernel
if fsmParam.track.tracker==3 % With the 3-frame tracker, 3 frames have no score; with a 2-frame tracker, only 2
    eventNumber=size(SCORE,1)/(n-3);   % We don't take into account the scores added for the time low-pass filtering
else
    eventNumber=size(SCORE,1)/(n-2);   % We don't take into account the scores added for the time low-pass filtering 
end
meanDistance=sqrt(imgArea/eventNumber);
% The mean event distance is the cutoff radius of the gaussian kernel
sigma=meanDistance/3;  % Cutoff radius is 3*sigma

% Sort for timepoint
SCORE=sortrows(SCORE,1:4);

% Add yxOffset to the positions
SCORE(:,2)=SCORE(:,2)+yxOffset(1);
SCORE(:,3)=SCORE(:,3)+yxOffset(2);

% Initializing progress bar
h = waitbar(0,'Generating score maps...');

% Create images
if fsmParam.track.tracker==3
    lastImage=n-2;
else
    lastImage=n-1;
end

% TODO: use makeQtMovie function
% add Axes option for each frame

for i=2:lastImage
	
    % Current index
    currentIndex=i+firstIndex-1;
    
	% Load image
	img=0.5+nrm(imread(char(outFileList(i,:))),1)/2;  

    if autoPolygon == 1
        % Load black-and-white mask
        indxStr=sprintf(strg,currentIndex);
        fName=[rootUserPath filesep 'bwMask' filesep 'bwMask' indxStr '.mat'];
        
        if exist(fName, 'file') == 2
            string=['load ' fName];
            eval(string);
        else
            bwMask=ones(size(img));
        end
    else
        bwMask=ones(size(img));
    end
    
	% Crop events referring to timepoint i
	eventsB=SCORE(find(SCORE(:,1) == i - 1),:);
	eventsI=SCORE(find(SCORE(:,1) == i),:);
	eventsA=SCORE(find(SCORE(:,1) == i + 1),:);
	
	% Weigh events (Gauss over 3 points, NOT NORMALIZED TO MAINTAIN CLASSES)
    %                                    ----------------------------------
	eventsB(:,4)=0.36*eventsB(:,4);
	eventsA(:,4)=0.36*eventsA(:,4);
	
	% Initialize empty score map
	scores=zeros(imgSize(1),imgSize(2));
	
	% Put scores to the right position
	for jI=1:size(eventsI,1)
		scores(eventsI(jI,2),eventsI(jI,3))=eventsI(jI,4);
	end
	% * ADD * scores from the previous timepoint
	for jB=1:size(eventsB,1)
		scores(eventsB(jB,2),eventsB(jB,3))=scores(eventsB(jB,2),eventsB(jB,3))+eventsB(jB,4);
	end
	% * ADD * scores from the next timepoint
	for jA=1:size(eventsA,1)
		scores(eventsA(jA,2),eventsA(jA,3))=scores(eventsA(jA,2),eventsA(jA,3))+eventsA(jA,4);
	end
	
	% Filter result with a gaussian kernel and the calculated sigma
	[cScores,M]=Gauss2D(scores,sigma);
	
    % Multiply with bwMask (to discard values outside the cell border)
    cScores=bwMask.*cScores;
    
    % Apply colormap
    img3C=applyColorMap(img,cScores,[-15 15],mapC,convFactor);

	% Display image
	fH=figure('Visible','off'); % get(fH, 'CurrentAxis')
	imshow(img3C);
    indxStr=sprintf(strg,currentIndex);   
	title(indxStr);
    
	% Change figure property 'InvertHardCopy' before saving
	set(gcf,'InvertHardCopy','off');
	
	%
	% SAVE IMAGE
	%
	string=strcat('print -djpeg100 score',indxStr,'.jpg');
	eval(string);
	hold off; 
	close(fH);
	
    % Update waitbar
    waitbar((i-1)/n,h);
end

% Save also first ald last (empty) images
img=0.5+nrm(imread(char(outFileList(1,:))),1)/2;  
fH=figure;
imshow(img);
indxStr=sprintf(strg,firstIndex);   
title(indxStr);
string=strcat('print -djpeg100 score',indxStr,'.jpg');
eval(string);
close(fH);
% Update waitbar
waitbar(i/n,h);

if fsmParam.track.tracker==3
    img=0.5+nrm(imread(char(outFileList(n-1,:))),1)/2;  
    fH=figure;
    imshow(img);
    indxStr=sprintf(strg,lastIndex-1);   
    title(indxStr);
    string=strcat('print -djpeg100 score',indxStr,'.jpg');
    eval(string);
	close(fH);
    % Update waitbar
    waitbar((n-1)/n,h);
end
%
img=0.5+nrm(imread(char(outFileList(n,:))),1)/2;  
fH=figure;
imshow(img);
indxStr=sprintf(strg,lastIndex);   
title(indxStr);
string=strcat('print -djpeg100 score',indxStr,'.jpg');
eval(string);
close(fH);
% Update waitbar
waitbar(n/n,h);
% Close waitbar
close(h);

% Back to old directory
cd(oldDir);
