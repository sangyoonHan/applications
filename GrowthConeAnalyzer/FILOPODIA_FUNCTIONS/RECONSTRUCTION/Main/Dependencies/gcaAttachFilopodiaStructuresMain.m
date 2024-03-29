function [reconstruct,filoInfo,TSFigs,TSFigsReconAll] = gcaAttachFilopodiaStructuresMain(img,cleanedRidgesAll,veilStemMaskC,filoBranchC,protrusionC,varargin)
% gcaAttachFilopodiaStructures: 
% 
% 
%%
% INPUT: 
% img: (REQUIRED) : RxC double array
%    of image to analyze where R is the height (ny) and C is the width
%    (nx) of the input image
%
% cleanedRidgesAll : (REQUIRED) : RxC logical array (binary mask)
%    of filopodia (small-scale) ridges after removal of junctions and 
%    and very small size CC pieces where R is the height (ny) and C is 
%    the width (nx) of the input image
%
% veilStemMaskC: (REQUIRED)  RxC logical array (binary mask) 
%      of veil/stem reconstruction where R is the height (ny) and C is the width
%     (nx) of the  original input image
%
% protrusionC: (REQUIRED)
%     protrusionC: (OPTIONAL) : structure with fields:
%    .normals: a rx2 double of array of unit normal                               
%              vectors along edge: where r is the number of 
%              coordinates along the veil/stem edge
%
%    .smoothedEdge: a rx2 double array of edge coordinates 
%                   after spline parameterization: 
%                   where r is the number of coordinates along the veil/stem edge
%                   (see output: output.pixel_tm1_output in prSamProtrusion)
%     Default : [] , NOTE: if empty the field
%                    filoInfo(xFilo).orientation for all filodpodia attached
%                    to veil will be set to NaN (not calculated)- there will be a warning if
%                    to the user if this is the case
% output from the protrusion process (see getMovieProtrusion.m)
%
%% PARAMS: 
% % EMBEDDED ACTIN SIGNAL LINKING %
%      'maxRadiusLinkEmbedded' (PARAM) : Scalar 
%          Only embedded ridge candidate end points that are within this max 
%          search radius around each seed ridge endpoint are considered for matching.
%          Default: 10 Pixels
%          (Only applicable if 'detectEmbedded' set to 'true')
%          See: gcaReconstructEmbedded.m 
%                       gcaConnectEmbeddedRidgeCandidates.m 
%
%      'geoThreshEmbedded' (PARAM) : Scalar 
%          Only embedded ridge candidates meeting this geometric criteria
%          will be considered. 
%          Default: 0.9 
%          (Only applicable if 'detectEmbedded' set to 'true')
%           See: gcaReconstructEmbedded.m 
%                       gcaConnectEmbeddedRidgeCandidates.m 
%
%
%    % FILO CANDIDATE BUILDING %
%      'maxRadiusLink' : Scalar 
%         Maximum radius for connecting linear endpoints points of two 
%         filopodia candidates in the initial candidate building step of the 
%         algorithm
%         Default: 5 Pixels
%         See 
% 
%      'geoThreshLinear' (PARAM) : Scalar 
%          Only embedded ridge candidates meeting this geometric criteria
%          will be considered. 
%          Default: 0.9 
%
% OUTPUT:
% filoInfo: an nx1 structure where n = the number of filopodia in the image
%           (Here a "filopodia" is defined as the endpoint to a branch
%           point): However filopodia can be associated into "tracking
%           objects" which are filopodia branche groups. This indexing occurs dowstream of
%           the data structure.
%           ie each filo has a conIdx (or connectivity idx) and an
%           associated .type.. so far with the nested structures I found
%           this format the most amenable to data extraction and manipulation as opposed to
%           clustering this information "upstream" in the dataStructure: though I might end up changing it
%
%
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check Input
ip = inputParser;
ip.CaseSensitive = false;
ip.KeepUnmatched = true;
ip.addRequired('img');
ip.addRequired('cleanedRidgesAll',@islogical);
ip.addRequired('veilStemMaskC',@islogical); 
ip.addRequired('filoBranchC',@isstruct);
ip.addRequired('protrusionC');

% FILO CANDIDATE CLEANING  
ip.addParameter('minCCRidgeOutsideVeil',3);
ip.addParameter('filterBasedOnVeilStemAttachedDistr',true); % flag to filter 
% candidates based on the filter response of the seed candidates 

% FILO CANDIDATE BUILDING %
% Pass to: gcaConnectLinearRidges.m
ip.addParameter('maxRadiusLink',5); % initial connect
ip.addParameter('geoThresh',0.9, @(x) isscalar(x));     


% TRADITIONAL FILOPODIA/BRANCH RECONSTRUCT           
% Pass to: gcaConnectFiloBranch.m
ip.addParameter('maxRadiusConnectFiloBranch',15); 
ip.addParameter('geoThreshFiloBranch',0.5);

% EMBEDDED ACTIN SIGNAL LINKING %
ip.addParameter('detectEmbedded',true);
% Pass To: gcaReconstructEmbedded
    ip.addParameter('maxRadiusLinkEmbedded',10);
    ip.addParameter('geoThreshEmbedded',0.5,@(x) isscalar(x));
    ip.addParameter('curvBreakCandEmbed',0.05,@(x) isscalar(x));

% OVERLAYS 
ip.addParameter('TSOverlaysRidgeCleaning',false); 
ip.addParameter('TSOverlaysReconstruct',false); 

ip.parse(img,cleanedRidgesAll,veilStemMaskC,filoBranchC,protrusionC,varargin{:});
p = ip.Results; 
p = rmfield(p,{'img','veilStemMaskC','protrusionC','filoBranchC'}); 
%% Initiate 
countFigs = 1; 
maxTh =  filoBranchC.filterInfo.maxTh ;
maxRes = filoBranchC.filterInfo.maxRes ;
[ny,nx] = size(img); 

if isfield(protrusionC,'normalsRotated'); 
     normalC = protrusionC.normalsRotated; % need to load the normal input from the smoothed edges in order  to calculation the filopodia body orientation
else 
    normalC = protrusionC.normal; 
end 
     smoothedEdgeC = protrusionC.smoothedEdge;

TSFigs =[]; 
TSFigsReconAll = []; 
TSFigs2 = []; 
%% Extract Information 
% MASK OF EXTERNAL FILOPODIA RIDGE CANDIDATES
filoTips = cleanedRidgesAll.*~veilStemMaskC;

% VEIL/STEM MASK (NO FILL)
neuriteEdge = bwboundaries(veilStemMaskC);
edgeMask = zeros(size(img));
idx  = cellfun(@(x) sub2ind(size(img),x(:,1),x(:,2)),neuriteEdge,'uniformoutput',0);
idx = vertcat(idx{:});
edgeMask(idx) = 1;

% get the outline of the veil/stem estimation and all the ridge candidates
% outside the veil
filoExtAll = (filoTips|edgeMask);

%% INTERNAL LINKING OPTION: NOTE option should only be turned on for actin stained images
TSFigs1 = [];
p.TSOverlays = p.TSOverlaysReconstruct;
if ip.Results.detectEmbedded; 
    
    % Create the seed extra-veil ridge seed for the subsequent embedded reattachment steps
    % Get rid of non connected component ridge response
    filoExtSeedForInt = double(getLargestCC(filoExtAll));
    % Take out the edge mask
    filoExtSeedForInt = filoExtSeedForInt.*~edgeMask;
    
    % Get embedded ridge candidates
    internalFilo = cleanedRidgesAll.*veilStemMaskC; %
    
    % Clean the embedded filo candidates/seed and perform linkage.
    [maskPostConnect1,TSFigs1,reconstructInternal] =  gcaReconstructEmbedded(img,maxTh,edgeMask,filoExtSeedForInt,internalFilo,p);
    %% Embedded Troubleshooting Plots: Figure out where these should best go.
    makeSummary =0;
    if makeSummary  == 1
        mkdir([pwd filesep 'Steps']);
        
        if ~isempty(TSFigs1)
            
            mkdir('Summary');
            type{1} = '.tif';
            type{2} = '.fig';
            for iType = 1:numel(type)
                arrayfun(@(x) saveas(TSFigs1(x).h,...
                    [pwd filesep 'Steps' filesep num2str(x,'%02d') TSFigs1(x).name  type{iType}]),1:length(TSFigs1));
            end
        end
    end
    
else % do not perform internal filopodia matching use the original
    maskPostConnect1 = double(getLargestCC(filoExtAll)); %
    
end % if ~isempty(detectEmbedded)
%% START EXTERNAL FILOPODA RECONSTRUCT 
% Record information for the troubleshooting reconstruction movie making
filoSkelPreConnectExt = (filoTips |edgeMask);

reconstruct.input = filoExtAll; % don't input the internal filo for the reconstruct
%% DOCUMENT THE FILOPODIA INFORMATION FROM THE HIGH CONFIDENCE 'SEED' 
% (as well as any internal (ie veil embedded) actin bundles matched in the
% previous step if that option was selected).

CCFiloObjs = bwconncomp(maskPostConnect1);

% filter out small filo (Think this is a bug) here check... 
csizeTest = cellfun(@(x) length(x),CCFiloObjs.PixelIdxList);
CCFiloObjs.PixelIdxList(csizeTest<ip.Results.minCCRidgeOutsideVeil) = []; 
CCFiloObjs.NumObjects = CCFiloObjs.NumObjects - sum(csizeTest<ip.Results.minCCRidgeOutsideVeil);

[ filoInfo ] = gcaRecordFilopodiaSeedInformation( CCFiloObjs,img,filoBranchC,edgeMask,veilStemMaskC,normalC,smoothedEdgeC,p); %

%% Reconstruct the external filopodia network from the initial seed

%%%% INITIATE THE ITERATIVE WHILE LOOP %%%%
numViableCand =1; % flag to continue with reconstruction interations as there are viable candidates to attach
filoSkelPreConnect = double(filoSkelPreConnectExt); % initial skeleton before linking : includes all candidates
filoSkelPreConnect = bwmorph(filoSkelPreConnect,'spur');
links = zeros(size(img)); % initiate link matrix
reconIter = 1; % initiate recording reconstruction iterations
linksPre = zeros(size(img));
%%%% BEGIN ITERATING THE REATTACHMENT PROCESS %%%%
status = 1;
while numViableCand >0  % stop the reconstruction process when no more candidates that meet a certain criteria are found
   
    % make a label matrix that corresponds to the filoInfo data structure
    % above (this will be updated each iteration)
    labelMatSeedFilo = zeros(size(img));
    pixIndicesSeedFilo = vertcat(filoInfo(:).Ext_pixIndicesBack); % only used the pixel indices measured not the one
    % projected forward
    [yCoordsSeed, xCoordsSeed]= ind2sub(size(img),pixIndicesSeedFilo);
    
    xyCoordsSeedFilo = [xCoordsSeed, yCoordsSeed];
  
    yx  = vertcat(neuriteEdge{:});
    xyCoordsNeurite = [yx(:,2),yx(:,1)];
    
    xySeed = [xyCoordsSeedFilo;xyCoordsNeurite];
    % label the neuriteEdge with 1 
    % create a labelMat to ensure your labels are what you think they
    % are
   
    for iFilo = 1:numel(filoInfo)
        if ~isnan(filoInfo(iFilo).Ext_pixIndicesBack)
            labelMatSeedFilo(filoInfo(iFilo).Ext_pixIndicesBack) = iFilo+1; %the veilStem will be labeled 1 
        end
    end
    
    labelMatSeedFilo(sub2ind(size(img),neuriteEdge{1}(:,1),neuriteEdge{1}(:,2))) = 1; % the edge is labeled 1
    % this is how you will know if it is the seed 
    filoMask = labelMatSeedFilo>0; % heres the new filopodia mask
    reconstruct.seedMask{reconIter} = filoMask;   % always record..
    
    CC = bwconncomp(filoSkelPreConnect|links|linksPre); % connect and refilter candidates
    
    numPix = cellfun(@(x) numel(x),CC.PixelIdxList);
 
    maskSeed = zeros([ny,nx]);
    maskSeed(vertcat(CC.PixelIdxList{numPix==max(numPix)}))= 1;
    seedFilos = maskSeed.*~veilStemMaskC;
    CCSeeds = bwconncomp(seedFilos);
    respValuesSeed = cellfun(@(x) maxRes(x),CCSeeds.PixelIdxList,'uniformoutput',0);
    meanRespValuesSeed= cellfun(@(x) mean(x), respValuesSeed);
    %sizeSeed = cellfun(@(x) length(x),CCSeeds.PixelIdxList);

    hold on
    
    CC.PixelIdxList(numPix==max(numPix))= []; % filter out the new seed
    CC.NumObjects = CC.NumObjects -1; %
    %% Only need to perform filtering if it is the first iteration. 
    if reconIter ==1
        
        sizeCand = cellfun(@(x) length(x), CC.PixelIdxList);
   
        %% Optional filterBasedOnVeilAttachedDistr
        % Option to filter candidate filopodia segments by considereing the 
        % distribution of mean response values of those candidate segments directly 
        % attached to the veilStem.  If the N of seed candidates is sufficient, we 
        % assume there is likely some false positives in this distribution, 
        % therefore if a candidate filopodia segment has a NMS response lower than 
        % the 5th percentile of the these seed values, we assume it is a good 
        % indication that the unattached candidate is likewise a false positive 
        % if segment piece is < 10 pixels. 
  
        if ip.Results.filterBasedOnVeilStemAttachedDistr
            
          
            % get the average response of each connected component
            % filopodia candidate for attachment 
            respValuesCand =   cellfun(@(x) maxRes(x),CC.PixelIdxList,'uniformoutput',0);
            meanRespValuesCand = cellfun(@(x) mean(x),respValuesCand);
            
            
            % estimate a low value response cut-off for the unattached filopodia candidates based on the 
            % population of mean response values for filopodia attached to the veil/stem
            cutoff = prctile(meanRespValuesSeed,5); %
            toExclude = (meanRespValuesCand<cutoff & sizeCand<10) | sizeCand<=2; %% need to change this based on the 'minCCRidgeOutsideVeil'
         
            %% TSFigs
            if ip.Results.TSOverlaysRidgeCleaning
                TSFigs2(countFigs).h = setFigure(nx,ny);
                TSFigs2(countFigs).name = 'Thresholding_Candidates_Based_On_Seed';
                TSFigs2(countFigs).group = 'Reconstruct_FiloBranch';
                % % %
                weakCandMask = zeros(ny,nx);
                strongCandMask = zeros(ny,nx);
                
                weakCandMask(vertcat(CC.PixelIdxList{toExclude} ))=1;
                strongCandMask(vertcat(CC.PixelIdxList{~toExclude}))=1 ;
                imshow(-img,[])
                hold on
                spy(weakCandMask,'r',10);
                spy(strongCandMask,'k',10);
                spy(maskSeed,'b',10);
                % % %          close gcf
                countFigs = countFigs +1;
            end
          
            if ip.Results.TSOverlaysRidgeCleaning
                TSFigs2(countFigs).h  = setAxis;
                TSFigs2(countFigs).name = 'Thresholding_Candidates_Based_On_Seed_Hist';
                TSFigs2(countFigs).group = 'Reconstruct_FiloBranch';
                
                totalPop = [meanRespValuesSeed meanRespValuesCand];
           
                subplot(3,1,1);
                count = hist(meanRespValuesSeed,20);
                hist(meanRespValuesSeed,20);
                hold on
                line([cutoff,cutoff],[0,max(count)],'color','r');
                xlabel('Mean Ridge Filter Response of Veil Attached Filopodia');
                axis([0,max(totalPop),0,max(count)]);
                subplot(3,1,2);
                
                
                count = hist(meanRespValuesCand,20);
                hist(meanRespValuesCand,20);
                line([cutoff,cutoff],[0,max(count)],'color','r');
                axis([0,max(totalPop),0,max(count)]);
                ylabel('Count');
                xlabel('Mean Ridge Filter Response of Candidates');
     
                subplot(3,1,3);
                scatter(meanRespValuesCand,sizeCand,10,'k','filled');
                hold on
                scatter(meanRespValuesCand(toExclude),sizeCand(toExclude),10,'r','filled');
                line([cutoff,cutoff],[0,max(sizeCand)],'color','r');
                xlabel({'Mean Ridge Filter Response ' 'Per Candidate'});
                ylabel('Size of Candidate Ridge (Pixels)');
                axis([0,max(totalPop),0,max(sizeCand)]);
                countFigs = countFigs +1;
                
            end % if TSOverlaysRidgeCleaning
        else 
             toExclude = sizeCand<=2;% need to change this based on the 'minCCRidgeOutsideVeil'
        end % if ip.Results.filterBasedOnVeilStemAttachedDistr
            %% remove these candidates
            filoSkelPreConnect(vertcat(CC.PixelIdxList{toExclude'}))= 0;
            CC.PixelIdxList(toExclude') = [];
            CC.NumObjects = CC.NumObjects -sum(toExclude);%             
    end % recon iter == 1 
%%  Keep on iterating until no more viable candidates
    % check the number of objects here
    if (CC.NumObjects == 0 || status ==0)
        
        break % flag to break loop if no more viable candidates/linkages
    end
    
    if reconIter ==1 % only do this initial clustering step for the first iteration
        
        candidateMask1 = labelmatrix(CC) >0;
        candidateMask1 = double(candidateMask1);
        
        reconstruct.CandMaskPreCluster = candidateMask1;
         
        CCCandidates = bwconncomp(candidateMask1);
        
        labelMatCanFilo = labelmatrix(CCCandidates);
        
        % now the endpoints are indexed according to the CC Candidates so as
        % unite edges can record the info
        
        EPCandidateSort = cellfun(@(x) getEndpoints(x,size(img),0,1),CCCandidates.PixelIdxList,'uniformoutput',0);
 
        [candidateMask1,linkMask,EPCandidateSortLinked, pixIdxPostConnectLinked,status,TSFigs3] = gcaConnectLinearRidgesMakeGeneric(EPCandidateSort,labelMatCanFilo,img,p);
        
        if status == 0 % no links
            pixIdxPostConnect = CCCandidates.PixelIdxList; 
        else 
            % update
            pixIdxPostConnect = pixIdxPostConnectLinked; 
            EPCandidateSort = EPCandidateSortLinked; 
        end 
       
        %%
        reconstruct.CandMaskPostCluster = candidateMask1;
        reconstruct.clusterlinks = linkMask;
        linksPre = linkMask;
        % add these points to the mask       
    end % if reconIt ==1

    if isempty(EPCandidateSort)
        break
    end
    
    nonCanonical = cellfun(@(x) length(x(:,1))~=2,EPCandidateSort);
    pixIdxPostConnect = pixIdxPostConnect(~nonCanonical);
    EPCandidateSort =  EPCandidateSort(~nonCanonical) ;
    
    % get rid of those with no endpoints 
    nonEmpty = cellfun(@(x) ~isempty(x),EPCandidateSort);
    EPCandidateSort = EPCandidateSort(nonEmpty);
    pixIdxPostConnect = pixIdxPostConnect(nonEmpty);
   
    %% Perform the connections.
    before = vertcat(pixIdxPostConnect{:});
    
    [outputMasks,filoInfo,status,pixIdxPostConnect,EPCandidateSort, TSFigs4] = gcaConnectFiloBranch(xySeed,EPCandidateSort,pixIdxPostConnect, labelMatSeedFilo,filoInfo,maxRes,maxTh,img,normalC,smoothedEdgeC,p);
    after = vertcat(pixIdxPostConnect{:}); 
  
    for i = 1:length(TSFigs4)
        TSFigs4(i).ReconIt = reconIter;
    end
    TSFigsRecon{reconIter} = TSFigs4;
    clear TSFigs4
    %%
    if status == 1 ;
        % note filoInfo will be updated and this will be used to remake the seed
        reconstruct.output{reconIter} = outputMasks;
        links = (links|outputMasks.links);
    end % if status
 
    reconIter = reconIter+1; % always go and save new "seed" from data structure even if reconstruction ended
    
end % while numViaCand

%%
if ip.Results.TSOverlaysReconstruct
    
    TSFigsReconAll = horzcat(TSFigsRecon{:});
    TSFigs = [TSFigs1 TSFigs3]; % these are the figure from the embedded 
    % and the linear connections. 
end
if ip.Results.TSOverlaysRidgeCleaning
    TSFigs = [TSFigs TSFigs2]; % TSFigs2 are from the ridge cleaning
end
end

