
%% GENERATE CONFIG

clear all; clc;

nCurves = 100; % 100
% nPoints = 40;
density = 20/200; % 30/200 40/200 1/7
offsetY = 500; % 500

types = 5;
for type=types
    switch(type)
        case 1
            VARS = 1; % Line
        case 2
            VARS = 1; % Arc
        case 3
            VARS = 1; % Spline
        case 4
            VARS = [10,20,50,100,200]; % Noise
        case 5
            VARS = [10,20,30,40,50]; % Distance
        case 6
            VARS = [15,30,45,60,75,90]; % Angle
    end
        
    % Get a list with all the .cfg-files in _sim
    path = 'Y:\fsm\harvard\data\Zhuang\_sim\';
    list = dir(path);
    itemIdx = 0;
    nConfig = numel(list)-2;
    items = cell(nConfig,2);
    for i=3:numel(list)
        if ~list(i).isdir
            if strcmp(list(i).name(end-3:end),'.cfg')
                % Config found
                itemIdx = itemIdx + 1;
                items{itemIdx,1} = [path list(i).name];
                items{itemIdx,2} = list(i).name(1:end-4);
            end
        end
    end
    items = items(1:itemIdx,:);
    
    for VAR=VARS
        
        for k=1:size(items,1)
            % Read the main cfg file
            configPath = items{k,1};
            cfg = Config.load(configPath);

            % Generate the data
            dat = Data();
            % dis = Show(dat);
            sim = Simulation(dat);

            % sim.setSamplingToRandom();
            sim.setSamplingToRegular();
            
            for c=1:nCurves
                switch(type)
                    case 1 % Line
                        % cP = [0 0 0; 200 0 0];
                        cP = [0 0 0; 300 0 0];
                    case 2 % Arc
                        % cP = [0 0 0; 100 75 0; 200 0 0];
                        cP = [0 -100 0; 150 100 0; 300 -100 0];
                    case 3 % Spline
                        % cP = [0 0 0; 100 100 0; 200 -100 0; 300 0 0];
                        % cP = [0 0 0; 100 75 0; 200 -75 0; 300 0 0];
                        cP = [0 0 0; 100 100 0; 200 -100 0; 300 0 0];
                    case 4 % Noise
                        % cP = [0 0 0; 100 100 0; 200 -100 0; 300 0 0];
                        % cP = [0 0 0; 100 75 0; 200 -75 0; 300 0 0];
                        cP = [0 0 0; 100 100 0; 200 -100 0; 300 0 0];
                        sim.setDomain([-100 -200+(c-1)*offsetY 0],[500 400 0]);
                        sim.addRandomNoise(VAR);
                    case 5 % Distance
                        % cP1 = [0 0 0; 200 0 0]; % Line
                        cP1 = [0 0 0; 300 0 0];
                        cP2 = cP1;
                        cP1(:,2) = cP1(:,2)+VAR/2;
                        cP2(:,2) = cP2(:,2)-VAR/2;
                        cP1(:,2) = cP1(:,2)+(c-1)*offsetY;
                        % sim.bezier(cP1,nPoints);
                        sim.bezierWithDensity(cP1,density);
                        % sim.bezierWithOrthogonalGaussianNoise2D(cP1,nPoints,cfg.modeVar);
                        dat.simModelBezCP = [dat.simModelBezCP {cP1}];
                        cP = cP2;
                    case 6 % Angle
                        R_plus = [cosd(VAR/2) -sind(VAR/2); sind(VAR/2) cosd(VAR/2)];
                        R_min = [cosd(-VAR/2) -sind(-VAR/2); sind(-VAR/2) cosd(-VAR/2)];
                        
                        % cP1 = [0 0 0; 200 0 0];
                        cP1 = [0 0 0; 300 0 0];
                        cP2 = cP1;
                        
                        center = (cP1(1,1:2)+cP1(end,1:2))/2;
                        cP1(:,1:2) = cP1(:,1:2)-[center;center];
                        cP2(:,1:2) = cP2(:,1:2)-[center;center];
                        
                        cP1(:,1:2) = cP1(:,1:2)*R_plus;
                        cP2(:,1:2) = cP2(:,1:2)*R_min;
                        
                        cP1(:,1:2) = cP1(:,1:2)+[center;center];
                        cP2(:,1:2) = cP2(:,1:2)+[center;center];
                        
                        cP1(:,2) = cP1(:,2)+(c-1)*offsetY;
                        % sim.bezier(cP1,nPoints);
                        sim.bezierWithDensity(cP1,density);
                        % sim.bezierWithOrthogonalGaussianNoise2D(cP1,nPoints,cfg.modeVar);
                        dat.simModelBezCP = [dat.simModelBezCP {cP1}];
                        cP = cP2;
                end
                cP(:,2) = cP(:,2)+(c-1)*offsetY;
                % sim.bezier(cP,nPoints);
                sim.bezierWithDensity(cP,density);
                % sim.bezierWithOrthogonalGaussianNoise2D(cP,nPoints,cfg.modeVar);
                dat.simModelBezCP = [dat.simModelBezCP {cP}];
            end
            
            sim.addGaussianNoise([cfg.errorX cfg.errorY 0]);
            pro = Processor(dat);
            pro.setErrorArray(cfg.errorX,cfg.errorY,cfg.errorZ);
            
            % Display data
            % dis.points();
            
            % Create folder and save cfg and dat file
            switch(type)
                case 1
                    configName = ['line_' items{k,2}];
                case 2
                    configName = ['arc_' items{k,2}];
                case 3
                    configName = ['spline_' items{k,2}];
                case 4
                    configName = [sprintf('noise_%04u_',VAR) items{k,2}];
                case 5
                    configName = [sprintf('distance_%04u_',VAR) items{k,2}];
                case 6
                    configName = [sprintf('angle_%04u_',VAR) items{k,2}];
            end
            cfg.configName = configName;
            parentFolder = 'Y:\fsm\harvard\data\Zhuang\_sim\';
            folderName = [configName '-'];
            mkdir(parentFolder,folderName);
            configPathOut = ['Y:\fsm\harvard\data\Zhuang\_sim\' folderName '\' configName '.cfg'];
            cfg.save(configPathOut);
            dataPathOut = ['Y:\fsm\harvard\data\Zhuang\_sim\' folderName '\' configName '.d.dat'];
            dat.save(dataPathOut);
            
        end
    end
    
    disp('==========================')
end


%% EVALUATE DATA

clear all; clc; format short;

offsetY = 500; % 500

% Get a list with all the .dat-files in _sim
path = 'Y:\fsm\harvard\data\Zhuang\_sim\';
list = dir(path);
itemIdx = 0;
nDataSets = numel(list)-2;
items = cell(nDataSets,2);
for i=3:numel(list)
    if list(i).isdir
        sublist = dir([path list(i).name '\']);
        for k=3:numel(sublist)
            if strcmp(sublist(k).name(end-3:end),'.cfg')
                % Config found - look for corresponding data file
                for j=3:numel(sublist)
                    if strcmp(sublist(j).name(end-5:end),'.p.dat')
                        itemIdx = itemIdx + 1;
                        items{itemIdx,1} = [path list(i).name '\' sublist(k).name];
                        items{itemIdx,2} = [path list(i).name '\' sublist(j).name];
                        items{itemIdx,3} = sublist(j).name;
                        break;
                    end
                end
                break;
            end
        end
    end
end
items = items(1:itemIdx,:);

output = cell(4,size(items,1)); 

% Loop through all the files
lineCounter = 1;    
arcCounter = 1;   
splineCounter = 1;  
distanceCounter = 1;  
angleCounter = 1;  
noiseCounter = 1;  
for i=1:size(items,1)
    
    % Read the .dat-file and .cfg-file
    cfg = Config.load(items{i,1});
    dat = Data.load(items{i,2});
    pro = Processor(dat);
    pro.dissolveClustersSmallerThan(5);
    
    fprintf('-------------\nFile: %s\n',items{i,1});
    
    modelBezCP = dat.modelBezCP;
    
    nModel = size(modelBezCP,1);
    idxModel = zeros(nModel,1);
    for m=1:nModel
        idxModel(m) = round(mean(modelBezCP{m}(:,2))/offsetY)+1;
    end
    
    nSimModel = length(dat.simModelBezCP);
    idxSimModel = zeros(nSimModel,1);
    for m=1:nSimModel
        idxSimModel(m) = round(mean(dat.simModelBezCP{m}(:,2))/offsetY)+1;
    end
    
    failed = false(max(idxSimModel),1);
    hausdorffDist = zeros(max(idxSimModel),1);
    
    for s=1:max(idxSimModel)
        nSimMod = nnz(idxSimModel == s);
        nMod = nnz(idxModel == s);
        
        if nMod ~= nSimMod
            % The number of models is not the same
            failed(s) = true;
        else
            % Compare the models pairwise
            m=find(idxModel == s);
            n=find(idxSimModel == s);
            
            for k=1:numel(m)     
                % Check model complexity
                if size(dat.simModelBezCP{n(k)},1) ~= size(modelBezCP{m(k)},1)
                    % The complexity of the models is not the same
                    % if isempty(strfind(items{i,1},'angle')) && isempty(strfind(items{i,1},'distance')) % All except angle and distance
                    if isempty(strfind(items{i,1},'angle')) % All except angle
                        failed(s) = true;
                    end
                end
            end
            if ~isempty(strfind(items{i,1},'angle')) % Angle only
                cP1 = modelBezCP{m(1)};
                cP2 = modelBezCP{m(2)};
                dist = segments_dist_3d (cP1(1,:)',cP1(end,:)',cP2(1,:)',cP2(end,:)');
                if dist > 1
                    failed(s) = true;
                end
            end
            if ~isempty(strfind(items{i,1},'distance')) % Distance only
                cP1 = modelBezCP{m(1)};
                cP2 = modelBezCP{m(2)};
                cPRef1 = dat.simModelBezCP{n(1)};
                dist = segments_dist_3d(cP1(1,:)',cP1(end,:)',cP2(1,:)',cP2(end,:)');
                center = mean(cPRef1(:,1));
                if ~(any(cP1(:,1) > center) && any(cP1(:,1) < center))
                    failed(s) = true;
                elseif ~(any(cP2(:,1) > center) && any(cP2(:,1) < center))
                    failed(s) = true;
                elseif dist < 1 % They are crossing
                    failed(s) = true;
                end
            end
        end
                
        if failed(s) == false
            % Compute the model distance
            nSamples = 1000;
            refPointsCell = cellfun(@(a) renderBezier(a,linspace(0,1,nSamples)'),dat.simModelBezCP(idxSimModel == s),'UniformOutput',0);
            refPoints = zeros(numel(refPointsCell)*nSamples,3);
            for m=1:numel(refPointsCell)
                refPoints((m-1)*nSamples+1:m*nSamples,:) = refPointsCell{m};
            end
            
            pointsCell = cellfun(@(a) renderBezier(a,linspace(0,1,nSamples)'),modelBezCP(idxModel == s),'UniformOutput',0);
            points = zeros(numel(pointsCell)*nSamples,3);
            for m=1:numel(pointsCell)
                points((m-1)*nSamples+1:m*nSamples,:) = pointsCell{m};
            end
            d = createDistanceMatrix(refPoints,points);
            % hausdorffDist(s) = max(min(d));
            d1 = min(d,[],1);
            d2 = min(d,[],2);
            hausdorffDist(s) = max([d1(:);d2(:)]);
        end
    end
        
    hausdorffDist = hausdorffDist(~failed);
    
    meanHausdorffDist = mean(hausdorffDist);
    stdDevHausdorffDist = sqrt(1/numel(hausdorffDist)*sum((hausdorffDist-meanHausdorffDist).^2));
    fractionOfFailedModels = nnz(failed)/numel(failed);
    nFailedModels = nnz(failed);
    [meanHausdorffDist;stdDevHausdorffDist;1-fractionOfFailedModels]
    
    %     figure(i);
    %     hist(hausdorffDist,20)
    
    if ~isempty(strfind(items{i,1},'line')) && isempty(strfind(items{i,1},'spline'))
        lineCounter = lineCounter + 1;  
        x = 2; y = lineCounter;
    elseif strfind(items{i,1},'arc')
        arcCounter = arcCounter + 1;  
        x = 8; y = arcCounter;
    elseif strfind(items{i,1},'spline')
        splineCounter = splineCounter + 1;  
        x = 14; y = splineCounter;
    elseif strfind(items{i,1},'distance')
        distanceCounter = distanceCounter + 1;  
        x = 20; y = distanceCounter;
    elseif strfind(items{i,1},'angle')
        angleCounter = angleCounter + 1;
        x = 26; y = angleCounter;
    elseif strfind(items{i,1},'noise')
        noiseCounter = noiseCounter + 1;  
        x = 32; y = noiseCounter;
    end
    % output(x,y) = items(i,3);
    output(x+1,y) = {meanHausdorffDist};
    output(x+2,y) = {stdDevHausdorffDist};
    output(x+3,y) = {1-fractionOfFailedModels};
    
end

xlswrite('C:\Users\PB93\Desktop\output.xls',output);

disp('==========================')

%% EVALUATE DATA (Noise special)

clear all; clc; format short;

offsetY = 500; % 500

overlapTH = 0.75;
distTH = 15;
nOverlapSamples = 100; 
nSamples = 1000; % Hausdorff

% Get a list with all the .dat-files in _sim
path = 'Y:\fsm\harvard\data\Zhuang\_sim\';
list = dir(path);
itemIdx = 0;
nDataSets = numel(list)-2;
items = cell(nDataSets,2);
for i=3:numel(list)
    if list(i).isdir
        sublist = dir([path list(i).name '\']);
        for k=3:numel(sublist)
            if strcmp(sublist(k).name(end-3:end),'.cfg')
                % Config found - look for corresponding data file
                for j=3:numel(sublist)
                    if strcmp(sublist(j).name(end-5:end),'.p.dat')
                        itemIdx = itemIdx + 1;
                        items{itemIdx,1} = [path list(i).name '\' sublist(k).name];
                        items{itemIdx,2} = [path list(i).name '\' sublist(j).name];
                        items{itemIdx,3} = sublist(j).name;
                        break;
                    end
                end
                break;
            end
        end
    end
end
items = items(1:itemIdx,:);

output = cell(4,size(items,1)); 

% Loop through all the files
noiseCounter = 1;  
for i=1:size(items,1)
    
    % Read the .dat-file and .cfg-file
    cfg = Config.load(items{i,1});
    dat = Data.load(items{i,2});
    pro = Processor(dat);
    pro.dissolveClustersSmallerThan(5);
    
    fprintf('-------------\nFile: %s\n',items{i,1});
    
    modelBezCP = dat.modelBezCP;
    
    nModel = size(modelBezCP,1);
    idxModel = zeros(nModel,1);
    for m=1:nModel
        idxModel(m) = round(mean(modelBezCP{m}(:,2))/offsetY)+1;
    end
    
    nSimModel = length(dat.simModelBezCP);
    idxSimModel = zeros(nSimModel,1);
    for m=1:nSimModel
        idxSimModel(m) = round(mean(dat.simModelBezCP{m}(:,2))/offsetY)+1;
    end
    
    failed = false(max(idxSimModel),1);
    hausdorffDist = zeros(max(idxSimModel),1);
    
    for s=1:max(idxSimModel)
        nSimMod = nnz(idxSimModel == s);
        nMod = nnz(idxModel == s);
        
        if 1 ~= nSimMod
            disp('Oops, the number of simulated models should be 1!');
        else
            % Compare the models pairwise
            m=find(idxModel == s);
            n=find(idxSimModel == s);
            
            cP_sim = dat.simModelBezCP{n};
            
            % For all the fragments
            failed_k = false(numel(m),1);
            for k=1:numel(m)    
                cP_mod = modelBezCP{m(k)};
                
                t = linspace(0,1,nOverlapSamples);
                
                pnts_mod = arrayfun(@(a) renderBezier(cP_mod,arcLengthToNativeBezierParametrization(cP_mod,a)),t,'UniformOutput',false);
                pnts_sim = arrayfun(@(a) renderBezier(cP_sim,arcLengthToNativeBezierParametrization(cP_sim,a)),t,'UniformOutput',false);
                
                [d_mod2sim,t_mod2sim] = cellfun(@(a) distancePointBezier(cP_sim,a),pnts_mod);
                [d_sim2mod,t_sim2mod] = cellfun(@(a) distancePointBezier(cP_mod,a),pnts_sim);
                                
                d_mod2sim_ok = d_mod2sim <= distTH;
                d_sim2mod_ok = d_sim2mod <= distTH;
               
                upPos_mod2sim = d_mod2sim_ok & ~circshift([d_mod2sim_ok(1:end-1),0],[1,1]);
                downPos_mod2sim = d_mod2sim_ok & ~circshift([0,d_mod2sim_ok(2:end)],[-1,-1]);
                
                upPos_sim2mod = d_sim2mod_ok & ~circshift([d_sim2mod_ok(1:end-1),0],[1,1]);
                downPos_sim2mod = d_sim2mod_ok & ~circshift([0,d_sim2mod_ok(2:end)],[-1,-1]);
                
                segLength_mod2sim = arrayfun(@(a,b) lengthBezier(cP_sim,a,b),t_mod2sim(upPos_mod2sim),t_mod2sim(downPos_mod2sim));
                segLength_sim2mod = arrayfun(@(a,b) lengthBezier(cP_mod,a,b),t_sim2mod(upPos_sim2mod),t_sim2mod(downPos_sim2mod));
                
                sim_overlaps_mod = sum(segLength_mod2sim)/lengthBezier(cP_sim);
                mod_overlaps_sim = sum(segLength_sim2mod)/lengthBezier(cP_mod);
                
                if (overlapTH > sim_overlaps_mod) || (overlapTH > mod_overlaps_sim)
                    failed_k(k) = true;
                end
            end
            if all(failed_k)
                failed(s) = true;
            else
                % For all the valid submodels compute the Hausdorff
                % distance
                refPoints = renderBezier(cP_sim,linspace(0,1,nSamples)');
                hausdorffDist_k = zeros(nnz(~failed_k),1);
                for k=find(~failed_k)
                    cP_mod = modelBezCP{m(k)};
                    points = renderBezier(cP_mod,linspace(0,1,nSamples)');                   
                    d = createDistanceMatrix(refPoints,points);
                    d1 = min(d,[],1);
                    d2 = min(d,[],2);                   
                    hausdorffDist_k(k) = max([d1(:);d2(:)]);
                end
                % Find the smallest Hausdorff distance
                hausdorffDist(s) = min(hausdorffDist_k);
            end
        end
                
    end
        
    hausdorffDist = hausdorffDist(~failed);
    
    meanHausdorffDist = mean(hausdorffDist);
    stdDevHausdorffDist = sqrt(1/numel(hausdorffDist)*sum((hausdorffDist-meanHausdorffDist).^2));
    fractionOfFailedModels = nnz(failed)/numel(failed);
    nFailedModels = nnz(failed);
    [meanHausdorffDist;stdDevHausdorffDist;1-fractionOfFailedModels]
    
    %     figure(i);
    %     hist(hausdorffDist,20)
    
    if strfind(items{i,1},'noise')
        noiseCounter = noiseCounter + 1;  
        x = 32; y = noiseCounter;
    end
    % output(x,y) = items(i,3);
    output(x+1,y) = {meanHausdorffDist};
    output(x+2,y) = {stdDevHausdorffDist};
    output(x+3,y) = {1-fractionOfFailedModels};
    
end

xlswrite('C:\Users\PB93\Desktop\output.xls',output);

disp('==========================')

%% Crop marks

idx = 17;
offsetY = 500;
xMin = -100; xMax = 400;
yMin = -200+(idx-1)*offsetY; yMax = 200+(idx-1)*offsetY;
% yMin = -250+(idx-1)*offsetY; yMax = 150+(idx-1)*offsetY; % Arc
corners = [xMin,yMin,0;xMin,yMax,0;xMax,yMin,0;xMax,yMax,0];
dis.imaris.displayPoints(corners,0,[1,0,0,0],'Corners');


%% Models to the back
% % % data.modelBezCP = cellfun(@(a) [a(:,1:2),-20*ones(size(a(:,3)))],data.modelBezCP,'UniformOutput',false);
data.modelBezCP = cellfun(@(a) [a(:,1:2),20*ones(size(a(:,3)))],data.modelBezCP,'UniformOutput',false);
dis.models
% data.simModelBezCP = cellfun(@(a) [a(:,1:2),-40*ones(size(a(:,3)))],data.simModelBezCP,'UniformOutput',false);
% dis.modelGroundTruth
% d = data.copy;
% d.points(:,3) = 10*ones(size(d.points(:,3)));
% dis2 = Show(d,dis.imaris);
% dis2.nullCluster
disp('Done')

%% Remove small models
pro = Processor(data);
pro.dissolveClustersSmallerThan(5);
dis.models
dis.nullCluster


%% Models to the back (Density vs. gaps)
zModels = min(data.points(:,3))-100;
zNull = max(data.points(:,3))+100;
data.modelBezCP = cellfun(@(a) [a(:,1:2),zModels*ones(size(a(:,3)))],data.modelBezCP,'UniformOutput',false);
dis.models

data.points(:,3) = zNull*ones(size(data.points(:,3)));
dis.nullCluster

%% 
mi = min(data.points(:,2));
ma = max(data.points(:,2));
low = 10;
high = 20;
lo = mi+low*(ma-mi)/100;
hi = mi+high*(ma-mi)/100;
modok = cellfun(@(a) any(a(:,2)<hi&a(:,2)>lo),data.modelBezCP);
simmodok = cellfun(@(a) any(a(:,2)<hi&a(:,2)>lo),data.simModelBezCP);
size(data.modelType)

data.modelBezCP = data.modelBezCP(modok);
data.clusters = data.clusters(modok);
data.simModelBezCP = data.simModelBezCP(simmodok);
data.modelType = data.modelType(modok);
size(data.modelType)



















