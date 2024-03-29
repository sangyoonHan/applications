function constrForceField=createNetwork(constrForceField,frame)
i=frame;
% first delete all existing twoCellIntf:
constrForceField{i}.network=[];

% There are as many edges as two cell interfaces. Find the nodes to each
% edge:
for j=1:length(constrForceField{i}.twoCellIntf);
    edge{j}.intf         = constrForceField{i}.twoCellIntf{j}.pos;
    edge{j}.intf_internal= [];
    edge{j}.nVec_internal= [];
    edge{j}.nodes        = constrForceField{i}.twoCellIntf{j}.link;
    edge{j}.strPt        = constrForceField{i}.cell{edge{j}.nodes(1)}.center;
    edge{j}.endPt        = constrForceField{i}.cell{edge{j}.nodes(2)}.center;
    edge{j}.pos          = 0.5*(edge{j}.strPt + edge{j}.endPt);
    edge{j}.intf_internal_L=[]; % this length is in um    
    edge{j}.int   = [];   % will be filled in by perfIntMeasures
    
    edge{j}.dPixIntf= []; % Coarse-grained interface. Will be filled up by perfClusterAnalysis
    edge{j}.cntrs = [];   % Centers of Coarse-grained interface. Points for force/stress vectors. Will be filled up by perfClusterAnalysis
    edge{j}.f_vec = [];   % will be filled up by perfClusterAnalysis
    edge{j}.s_vec = [];   % will be filled up by perfClusterAnalysis    
    edge{j}.f1    = [NaN NaN];
    edge{j}.f2    = [NaN NaN];
    edge{j}.fc1   = [NaN NaN];   % will be filled up by perfClusterAnalysis
    edge{j}.fc2   = [NaN NaN];   % will be filled up by perfClusterAnalysis
    edge{j}.fc    = [NaN NaN];   % will be filled up by perfClusterAnalysis
    edge{j}.n_Vec = []; % will be filled up by perfClusterAnalysis
    edge{j}.char  = [];
end

% Determine the normal to the internal part of the interface:
for j=1:length(edge)
    intf=edge{j}.intf;
    % we check which part of it is within the detected cell
    % perimeter:    
    % \\Begin new code
    mask     = constrForceField{frame}.segmRes.mask; % this is the inner mask that has 0 at holes!
    indIntf  = sub2ind(size(mask),intf(:,2), intf(:,1));
    checkVec = mask(indIntf);
    cc       = bwconncomp(checkVec); 
    % There should be only one connected component!!! If there are more
    % than one, there might be issues at the intersection. Then choose the
    % longest piece:
    if length(cc.PixelIdxList)==1
        idxList=cc.PixelIdxList{1};
        if issorted(idxList)
            intf_internal=intf(idxList,:);
        else
            error('Pts along the interface are not sorted correctly');
        end
    elseif length(cc.PixelIdxList)>1
        % find the largest piece:
        pMax=1;
        lMax=length(cc.PixelIdxList{1});
        for p=2:length(cc.PixelIdxList)
            currl=length(cc.PixelIdxList{p});
            if currl>lMax
                pMax=p;
                lMax=currl;
            end
        end
        idxList=cc.PixelIdxList{pMax};
        if issorted(idxList)
            intf_internal=intf(idxList,:);
        else
            error('Pts along the interface are not sorted correctly');
        end        
    elseif length(cc.PixelIdxList)==0
        error('No internal interfaces!');
    end    
    % End new code\\
    
    % \\Begin old code
    %curve=constrForceField{frame}.segmRes.curve;
    %checkVec=inpolygon(intf(:,1),intf(:,2),curve(:,1),curve(:,2));
    % this interface has the same direction as edge{j}.intf: 
    %intf_internal=intf(checkVec,:);
    % \\End old code
    
    
    % the direct connection between start and end point:
    directConnect=intf_internal(end,:)-intf_internal(1,:);
    % the normal on the direct connection is also equivalent to the average
    % normal vector along the interface (calculate a unit vector):
    nVec_internal=[-directConnect(2),directConnect(1)]/norm(directConnect);

    edge{j}.intf_internal=intf_internal;
    edge{j}.nVec_internal=nVec_internal;
    
    
    % determine the length of the internal interface, substracting the
    % length of holes:
    pixSize_mu=constrForceField{frame}.par.pixSize_mu;
    if ~isfield(constrForceField{frame}.segmRes,'hole')
        % display('This is an old data set!')
        constrForceField{frame}.segmRes.hole=[];
    end
    currentLength=pixSize_mu*calcCurveLength(intf_internal,[],constrForceField{frame}.segmRes.hole);
    % store these value only temporally in the constrForceField
    % structure:
    edge{j}.intf_internal_L=currentLength; % this length is in um
end
    
% Each cell represents one node. Find the edges to each node:
for k=1:length(constrForceField{i}.cell)
    % the position of each node is the center of mass of the cell:
    node{k}.pos  =constrForceField{i}.cell{k}.center;
        
    % the force at each node is the residual force of that cell:
    node{k}.vec  =constrForceField{i}.cell{k}.stats.resForce.vec;
        
    % the force magnitude of each node is the magnitude of the residual force of that cell:
    node{k}.mag  =constrForceField{i}.cell{k}.stats.resForce.mag;
    
    % the sum of force magnitudes over the footprint of a cell:
    node{k}.sumFmag  =constrForceField{i}.cell{k}.stats.sumForceMag;
    
    % the elastic energy of each node is the energy invested by each cell
    % to deform the substrate:
    if isfield(constrForceField{i}.cell{k}.stats,'elEnergy')
        node{k}.elE  =constrForceField{i}.cell{k}.stats.elEnergy;
    else
        node{k}.elE  =[];
    end
    
    % the area the cell in um^2:
    if isfield(constrForceField{i}.cell{k},'cellArea')
        node{k}.area =constrForceField{i}.cell{k}.cellArea;
    else
        node{k}.area =[];
    end
    
    % the specification of the cells/nodes, e.g. myosin marker:
    if isfield(constrForceField{i}.cell{k}.stats,'spec')
        node{k}.spec =constrForceField{i}.cell{k}.stats.spec;
	node{k}.type =constrForceField{i}.cell{k}.stats.type;
    else
        node{k}.spec =[];
	node{k}.type =[];
    end
    
    % find the edges and neighbors to each node:
    node{k}.edges=[];
    node{k}.neigh=[];
    for j=1:length(edge)    
        
        if ~isempty(intersect(k,edge{j}.nodes))
            % determine all edges:
            node{k}.edges=horzcat(node{k}.edges,j);
            
            % determine all neighboring nodes:
            node{k}.neigh=union(node{k}.neigh, edge{j}.nodes);
            % remove the node itself from its neighbors list:
            node{k}.neigh(node{k}.neigh==k)=[];
        end
        
        % degree of connectivity:
        node{k}.deg=length(node{k}.edges);
        
    end
end

% Do some simple statistics on the network:
maxMag=0;
numMyo=0;
for k=1:length(node)
    %find the largest force magnitude
    currMag=node{k}.mag;
    if currMag>maxMag
        maxMag=currMag;
    end    
    numMyo=numMyo+node{k}.spec;
end

constrForceField{i}.network.edge                 = edge;
constrForceField{i}.network.node                 = node;
constrForceField{i}.network.stats.maxMag         = maxMag;
constrForceField{i}.network.stats.numMyo         = numMyo;
constrForceField{i}.network.stats.numCells       = length(node); % This works because there are no empty nodes (as in the tracked network!)
constrForceField{i}.network.stats.errs           = []; % will be filled in by cluster analysis.

if isfield(constrForceField{i},'errorSumForce')
    % This should be the case for all newer datasets!
    constrForceField{i}.network.stats.errorSumForce  = constrForceField{i}.errorSumForce;
    constrForceField{i}.network.stats.sumForceMagCl  = constrForceField{i}.sumForceMagCl;
else
    errorSumForce.vec=zeros(1,2);
    for nodeId=1:length(node)
        errorSumForce.vec=errorSumForce.vec+node{nodeId}.vec;
    end
    errorSumForce.mag=sqrt(sum((errorSumForce.vec).^2));
    errorSumForce.method='indirect';
    
    constrForceField{i}.network.stats.errorSumForce  = errorSumForce;
end

