function [reconstruct,filoInfo,TSFigs] = gcaAttachFilopodiaStructuresMain(img,cleanedRidgesAll,veilStemMaskC,filoBranchC,varargin)
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
% protrusionC: (OPTIONAL)
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
% 
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
ip.addOptional('protrusionC',[]);

% Parameters
ip.addParameter('maxRadiusInitialConnectLink',10); 
ip.addParameter('maxRadiusLinkFiloOutsideVeil',10); 

ip.addParameter('maxRadiusLinkEmbedded',10); 


ip.addParameter('detectEmbedded',true); 
ip.parse(img,cleanedRidgesAll,veilStemMaskC,filoBranchC,varargin{:});
p = ip.Results; 
p = rmfield(p,{'img','veilStemMaskC','protrusionC','filoBranchC'}); 
%% Initiate 
countFigs = 1; 
maxTh =  filoBranchC.filterInfo.maxTh ;
maxRes = filoBranchC.filterInfo.maxRes ;

% load protrusionVectors from the body
if  ~isempty(ip.Results.protrusionC)
    protrusionC = ip.Results.protrusionC{1};
    % load([protrusion filesep 'protrusion_vectors.mat']);
    normalC = protrusionC.normals; % need to load the normal input from the smoothed edges in order  to calculation the filopodia body orientation
    smoothedEdgeC = protrusionC.smoothedEdge;
else
    display(['No Protrusion Vectors Found: No Orientation Calculations of Filopodia Relative to' ...
        'Veil will be Performed']);
end
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

%% INTERNAL LINKING OPTION: NOTE option should only be turned on for life-act images 
if ip.Results.detectEmbedded == true; %
    
    % Create the seed extra-veil ridge seed for the subsequent embedded reattachment steps 
    % Get rid of non connected component ridge response 
    filoExtSeedForInt = double(getLargestCC(filoExtAll));
    % Take out the edge mask
    filoExtSeedForInt = filoExtSeedForInt.*~edgeMask;
    
    % Get embedded ridge candidates
    internalFilo = cleanedRidgesAll.*veilStemMaskC; %   
    
   % Clean the embedded filo candidates/seed and perform linkage. 
   [maskPostConnect1,TSFigs,reconstructInternal] =  gcaReconstructEmbedded(img,maxTh,edgeMask,filoExtSeedForInt,internalFilo,p); 

else % do not perform internal filopodia matching use the original
    maskPostConnect1 = double(getLargestCC(filoExtAll)); %

end % if ~isempty(detectEmbedded) 
%% START EXTERNAL FILOPODA RECONSTRUCT 
%Record information for the troubleshooting reconstruction movie making
filoSkelPreConnectExt = (filoTips |edgeMask);

reconstruct.input = filoExtAll; % don't input the internal filo for the reconstruct
%% DOCUMENT THE FILOPODIA INFORMATION FROM THE HIGH CONFIDENCE 'SEED' -
% and any internal (ie veil embedded) actin bundles matched in the
% previous step if that option was selected.

CCFiloObjs = bwconncomp(maskPostConnect1);

% that attempts to categorize filo
% filter out small filo
csizeTest = cellfun(@(x) length(x),CCFiloObjs.PixelIdxList);
CCFiloObjs.PixelIdxList(csizeTest<ip.Results.CCFilt) = []; % MAKE a parameter filters out pixels CCs that are less than 3 pixels 
CCFiloObjs.NumObjects = CCFiloObjs.NumObjects - sum(csizeTest<ip.Results.CCFilt);% originally 3 

[ filoInfo ] = gcaRecordFilopodiaSeedInformation( CCFiloObjs,img,maxRes,maxTh,edgeMask,veilStemMaskC,analInfoC,normalC,smoothedEdgeC); %% NOTE fix input here!!

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
    
    %[xyCoordsSeedFilo] = vertcat(filoInfo(:).coordsXY); % this includes
    %projections forward.
    
    yx  = vertcat(neuriteEdge{:});
    xyCoordsNeurite = [yx(:,2),yx(:,1)];
    
    xySeed = [xyCoordsSeedFilo;xyCoordsNeurite];
    % label the neuriteEdge with 1 and 2
    % create own label mat to ensure your labels are what you think they
    % are!
    for iFilo = 1:numel(filoInfo)
        if ~isnan(filoInfo(iFilo).Ext_pixIndicesBack)
            labelMatSeedFilo(filoInfo(iFilo).Ext_pixIndicesBack) = iFilo+2;
        end
    end
    
    if ~isfield(analInfoC.bodyEst,'pixIndThickBody');
        % add
        thickBodyMask = logical(analInfoC.masks.thickBodyMask);
        analInfoC.bodyEst.pixIndThickBody = find(thickBodyMask==1);
        neuriteEdgeMask = analInfoC.masks.neuriteEdge;
        thinBodyMask = neuriteEdgeMask.*~thickBodyMask;
        analInfoC.bodyEst.pixIndThinBody = find(thinBodyMask==1);
    end
    
    labelMatSeedFilo(analInfoC.bodyEst.pixIndThickBody) = 1; % label thick parts of body as 1
    labelMatSeedFilo(analInfoC.bodyEst.pixIndThinBody) = 2; % label thin parts of body as 2
    
    % labelMatSeedFilo(sub2ind(size(img),neuriteEdge{1}(:,1),neuriteEdge{1}(:,2))) = 1; % the edge is labeled 1
    % this is how you will know if it is backbone
    filoMask = labelMatSeedFilo>0; % heres the new filopodia mask
    reconstruct.seedMask{reconIter} = filoMask;   % always record..
    
    
    
    
    % Get the coordinates of the filo+NeuriteBody 'skel': those filo not attached to
    % body should be included
    %  endpoints = double((filoSkelPreConnect.* (conv2(sumKernel, sumKernel', padarrayXT(filoSkelPreConnect, [1 1]), 'valid')-1))==1); % mask version
    %  [ye,xe] = find(endpoints~=0); % coords of endpoints
    %
    CC = bwconncomp(filoSkelPreConnect|links|linksPre); % connect and refilter candidates
    %labels = double(labelmatrix(CC));
    
    numPix = cellfun(@(x) numel(x),CC.PixelIdxList);
    
    % find and prun the unattached candidates
    %get rid of small CCs lower than x number of pixels and your largest CC
    % maybe make the top ten percent of response etc need to get reattached
    
    %NEW 20141026
    
    maskSeed = zeros([ny,nx]);
    maskSeed(vertcat(CC.PixelIdxList{numPix==max(numPix)}))= 1;
    seedFilos = maskSeed.*~bodyMask;
    CCSeeds = bwconncomp(seedFilos);
    respValuesSeed = cellfun(@(x) maxRes(x),CCSeeds.PixelIdxList,'uniformoutput',0);
    meanRespValuesSeed= cellfun(@(x) mean(x), respValuesSeed);
    sizeSeed = cellfun(@(x) length(x),CCSeeds.PixelIdxList);
    
    % % %     figure;
    % % %     scatter(sizeSeed,meanRespValuesSeed,10,'k','filled');
    
    hold on
    
    CC.PixelIdxList(numPix==max(numPix))= []; % filter out the new seed
    CC.NumObjects = CC.NumObjects -1; % note should make there be a criteria for intensity a
    if reconIter ==1
        
        % get the response of the pieces
        respValuesCand =   cellfun(@(x) maxRes(x),CC.PixelIdxList,'uniformoutput',0);
        meanRespValuesCand = cellfun(@(x) mean(x),respValuesCand);
        sizeCand = cellfun(@(x) length(x), CC.PixelIdxList);
        % get the response of the high confidence seeds
        % % %       scatter(sizeCand,meanRespValuesCand,10,'r','filled');
        % % %       figure
        cutoff = prctile(meanRespValuesSeed,5); % SEE if it is this filtering step here. for frame 120
        % % %
        % % %
        % % %
        % % %       weakCandMask = zeros(ny,nx);
        % % %       strongCandMask = zeros(ny,nx);
        % % %
        toExclude = (meanRespValuesCand<cutoff & sizeCand<10) | sizeCand<=2;%%% NOTE: MARIA YOU ARE INTRODUCING SOME PARAMS HERE 
        % % %
        % % %       weakCandMask(vertcat(CC.PixelIdxList{toExclude} ))=1;
        % % %       strongCandMask(vertcat(CC.PixelIdxList{~toExclude}))=1 ;
        % % %       imshow(-img,[])
        % % %       hold on
        % % %       spy(weakCandMask,'r',10);
        % % %       spy(strongCandMask,'g',10);
        % % %       spy(maskSeed,'b',10);
        % % %          close gcf
        
        % erase these candidates completely so they will not be considered in
        % future iterations
        filoSkelPreConnect(vertcat(CC.PixelIdxList{toExclude'}))= 0;
        CC.PixelIdxList(toExclude') = [];
        CC.NumObjects = CC.NumObjects -sum(toExclude);%
        % erase from filoSkelPreConnect
        
    end
    
    % keep on iterating until no more viable candidates
    % check the number of objects here
    if (CC.NumObjects == 0 || status ==0)
        
        break % flag to break loop i snot more viable candidates/linkages
    end
    
    
    % as well
    % prune junctions this will help infinitely later as you will know what
    % type of pieces you will be connnected in the reconstruction will only
    % have two end points
    
    % make mask of candiates for reattachment
    candidateMask1 = labelmatrix(CC) >0;
    candidateMask1 = double(candidateMask1);
    
    if reconIter ==1
        reconstruct.CandMaskPreCluster = candidateMask1;
    end
  
    CCCandidates = bwconncomp(candidateMask1);
   
    
    
    labelMatCanFilo = labelmatrix(CCCandidates);
    candidateMask1 = labelMatCanFilo>0;
    % now the endpoints are indexed according to the CC Candidates so as
    % unite edges can record the info
    
    
    EPCandidateSort = cellfun(@(x) getEndpoints(x,size(img)),CCCandidates.PixelIdxList,'uniformoutput',0);
    
    if reconIter ==1 % only do this initial clustering step for the first iteration... hmmm need to make sure
        % don't loose this information though
        [ candidateMask1,linkMask,EPCandidateSort,labelMatCanFilo,madeLinks] = connectLinearStructures(EPCandidateSort,maxTh,candidateMask1,labelMatCanFilo,[0.95,0.95,0.95],5);
        % it might be easiest just to recalculate the new end points from the
        % new labelMatrix
        
        postClustLabels = unique(labelMatCanFilo(labelMatCanFilo~=0));
        numLabels = length(postClustLabels);
        pixIdxCand = arrayfun(@(i) find(labelMatCanFilo==postClustLabels(i)), 1:numLabels, 'uniformoutput',0);
        EPCandidateSort = cellfun(@(x) getEndpoints(x,size(maxTh)),pixIdxCand,'uniformoutput',0);
        
        
        
        reconstruct.CandMaskPostCluster = candidateMask1;
        reconstruct.clusterlinks = linkMask;
        linksPre = linkMask;
        % add these points to the mask
        
    end % if reconIt ==1
    
    
    
    %get rid segments that might not have canonical endpoints as these
    %are very likely noise.
    filoSkelPreConnectFiltered = (filoMask | candidateMask1 );
    
    nonCanonical = cellfun(@(x) length(x(:,1))~=2,EPCandidateSort);
    
    nonCanonicalIdx = find(nonCanonical==1);
    idxRemove = arrayfun(@(x) find(labelMatCanFilo == nonCanonicalIdx(x)),1:length(nonCanonicalIdx),'uniformoutput',0);
    labelMatCanFilo(vertcat(idxRemove{:})) = 0;
    EPCandidateSort =  EPCandidateSort(~nonCanonical) ;
    
    % get rid of those with no EPs
    nonEmpty = cellfun(@(x) ~isempty(x),EPCandidateSort);
    EPCandidateSort = EPCandidateSort(nonEmpty);
    % if no more viable candidates break the while loop
    if isempty(EPCandidateSort)
        break
    end
    
    
    % have a gate that is set to 10 pixels so far (things beyond that distance will
    % not be considered)
    
    [outputMasks,filoInfo,status] = gcaConnectExternalFilopodia(xySeed,EPCandidateSort,ip.Results.maxRadiusExternal,labelMatCanFilo,labelMatSeedFilo,filoSkelPreConnectFiltered,filoInfo,maxRes,maxTh,img,normalC,smoothedEdgeC);
    if status == 1 ;
        %           % note filoInfo will be updated and this will be used to remake the seed
        reconstruct.output{reconIter} = outputMasks;
        links = (links|outputMasks.links);
        
        
        
        
    end % if status
    
    reconIter = reconIter+1; % always go and save new "seed" from data structure even if reconstruction ended
    display(num2str(reconIter))
    
    
end % while
% results1stRound = getLargestCC(filoSkelBranchingFilo);
end

function [coords] = getEndpoints(pixIdx,size)

endpoints = zeros(size);
endpoints(pixIdx)=1;
sumKernel = [1 1 1];
% find endpoints of the floating candidates to attach (note in the
% future might want to prune so that the closest end to the
% body is the only one to be re-attatched: this will avoid double connections)
endpoints = double((endpoints.* (conv2(sumKernel, sumKernel', padarrayXT(endpoints, [1 1]), 'valid')-1))==1);
[ye,xe] = find(endpoints~=0);
coords(:,1) = xe;
coords(:,2) = ye;
end
