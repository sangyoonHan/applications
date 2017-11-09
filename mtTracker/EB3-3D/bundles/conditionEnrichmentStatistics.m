function conditionEnrichmentStatistics(enrichmentProcesses,projProcesses,names,outputDirPlot,varargin)
% load scoring data associated to cells. A Cell of process list describes the conditions
ip = inputParser;
ip.CaseSensitive = false;
ip.KeepUnmatched = true;
ip.addParameter('shade',true);
ip.addParameter('printCellName',true);
ip.addParameter('projProcesses',[]);
ip.parse(varargin{:});
p=ip.Results;

if(~iscell(enrichmentProcesses))
    enrichmentProcesses={enrichmentProcesses};
end

mkClrDir(outputDirPlot);

% load score set in cells of cells
elevationCell=cell(1,length(enrichmentProcesses));
densityCell=cell(1,length(enrichmentProcesses));
distanceCell=cell(1,length(enrichmentProcesses));
ampCell=cell(1,length(enrichmentProcesses));
timeCell=cell(1,length(enrichmentProcesses));

% Define astral and polar region in a naive way
astralThresh=0;
polarThresh=0;
distBinning=[];

%% Condition structure for easier interpretation
for cIdx=1:length(enrichmentProcesses)
    condition.name=names{cIdx};
    condElevationCell=cell(1,length(enrichmentProcesses{cIdx}));
    condDistanceCell=cell(1,length(enrichmentProcesses{cIdx}));
	condDensityCell=cell(1,length(enrichmentProcesses{cIdx}));
    condAmpCell=cell(1,length(enrichmentProcesses{cIdx}));
    condTimeCell=cell(1,length(enrichmentProcesses{cIdx}));

	for pIdx=1:length(enrichmentProcesses{cIdx})
		tmp=load(enrichmentProcesses{cIdx}(pIdx).outFilePaths_{2});
		condElevationCell{pIdx}=tmp.elevations;
		condDensityCell{pIdx}=tmp.densities;
        condDistanceCell{pIdx}=tmp.poleDistances;
        polarDistBinning=tmp.polarDistBinning;
        astralDistBinning=tmp.astralDistBinning;
        condAmpCell{pIdx}=tmp.amps;
        condTimeCell{pIdx}=tmp.timesSteps;
        astralThresh=tmp.astralThresh;
        polarThresh=tmp.polarThresh;


	end
	elevationCell{cIdx}=condElevationCell;
	densityCell{cIdx}=condDensityCell;
    distanceCell{cIdx}=condDistanceCell;
    ampCell{cIdx}=condAmpCell;
    timeCell{cIdx}=condTimeCell;

end


%% Display elevation vs density data for MT only 
cmap=cool(length(enrichmentProcesses));
c={'r','b','g','y','k','o'};
scoresBin=-pi/2:0.1:pi/2;
nonEmptyProcess=find(cellfun(@(p) ~isempty(p),enrichmentProcesses));
meansDensitiesCell=cell(1,length(enrichmentProcesses));
Handles=[];
[Handle,~,F]=setupFigure(1,1,1,'AxesWidth',10,'AxesHeight',6);
hold on;
for cIdx=nonEmptyProcess
	for pIdx=1:length(enrichmentProcesses{cIdx})
		allElevs=vertcat(elevationCell{cIdx}{pIdx}{:});
	    allDens=vertcat(densityCell{cIdx}{pIdx}{:});
        
        % scale astral density to one
        allDens=allDens/mean(allDens(allElevs<0));
        
		[counts,edges,binIdx]=histcounts(allElevs,scoresBin);
		[means,meds,stds,orderedIndex,counts] = statPerIndx(allDens,binIdx+1);

		meansDensitiesCell{cIdx}=[meansDensitiesCell{cIdx}; means];
	end
    if(~isempty((meansDensitiesCell{cIdx})))
        if(size(meansDensitiesCell{cIdx},1)>1)
            y=meansDensitiesCell{cIdx};
            if(p.shade)
                H=shadedErrorBar(scoresBin(1:end),mean(y),std(y),{'Color',cmap(cIdx,:)});
                Handles=[Handles H];
            else
                plot(scoresBin(1:end),mean(y),[c{1} '-'],'Color',cmap(cIdx,:));
            end
        else
            plot(scoresBin(1:end),meansDensitiesCell{cIdx},[c{1} '-'],'Color',cmap(cIdx,:));
        end
    end
end
lineToLegend=arrayfun(@(h) h.mainLine,Handles,'unif',0)
legend([lineToLegend{:}],names(nonEmptyProcess),'Location','northwest')
ylim([0,5])
xlim([-pi/2+0.05,1.5]);
xlabel('Elevation (rad)');
ylabel('Comet density (1/\mu m^3)')
hold off;
print([outputDirPlot  'enrichment.png'],'-dpng');
print([outputDirPlot  'enrichment.eps'],'-depsc');
close(F);


% Count and density function of distance to poles
% Overlay decay 
AstralK=1/2;
PolarK=0;

%distBinning=linspace(30,70,20);
coneVolumes=2*pi*(1-cos(pi/2-polarThresh))*polarDistBinning.^3/3;
polarVolumes=(coneVolumes(2:end)-coneVolumes(1:(end-1)));
coneVolumes=2*pi*(1-cos(pi/2+astralThresh))*astralDistBinning.^3/3;
astralVolumes=(coneVolumes(2:end)-coneVolumes(1:(end-1)));

astralXTicks=astralDistBinning(1:end-1)*0.1;
polarXTicks=polarDistBinning(1:end-1)*0.1;

relativeVolumeAstral=astralVolumes/astralVolumes(1);
relativeVolumePolar=polarVolumes/polarVolumes(1);

meansPolarDensitiesCell=cell(1,length(enrichmentProcesses));
meansAstralDensitiesCell=cell(1,length(enrichmentProcesses));
meansPolarIntCell=cell(1,length(enrichmentProcesses));
meansAstralIntCell=cell(1,length(enrichmentProcesses));
coneNormCountPolarCell=cell(1,length(enrichmentProcesses));
coneNormCountAstralCell=cell(1,length(enrichmentProcesses));
countPolarCell=cell(1,length(enrichmentProcesses));
countAstralCell=cell(1,length(enrichmentProcesses));
normAmpPolarCell=cell(1,length(enrichmentProcesses));
normAmpAstralCell=cell(1,length(enrichmentProcesses));
cmap=winter(2*length(enrichmentProcesses));

for cIdx=nonEmptyProcess
    conditionEnrichmenData.name=names{cIdx};
    moviesStruct=[];
    for pIdx=1:length(enrichmentProcesses{cIdx})
        allDist=vertcat(distanceCell{cIdx}{pIdx}{:});
        allDens=vertcat(densityCell{cIdx}{pIdx}{:});
        allElevs=vertcat(elevationCell{cIdx}{pIdx}{:});
        allAmp=vertcat(ampCell{cIdx}{pIdx}{:});

        tmp=load(enrichmentProcesses{cIdx}(pIdx).outFilePaths_{2});
        allAzim=vertcat(tmp.azimuths{:});
        allKTAzim=vertcat(tmp.KTazimuths{:});
        allKTElev=vertcat(tmp.KTelevations{:});
        allKTDist=vertcat(tmp.KTpoleDistances{:});


        % separate astral and polar and sort function of distances
        [polarCounts,polarEdges,polarBinIdx]=histcounts(allDist(allElevs>polarThresh),polarDistBinning);
        [meanPolarDensities,medPolarDensities,stdPolarDensities]=statPerIndx(allDens(allElevs>polarThresh),polarBinIdx);
        [meanPolarAmp,medPolarAmp,stdPolarAmp,~,polarCount,sumPolarAmp]=statPerIndx(allAmp(allElevs>polarThresh),polarBinIdx);
        normalizedPolarCount=polarCounts./polarVolumes;
        normalizedPolarAmp=sumPolarAmp./polarVolumes;

        [astralCounts,astralEdges,astralBinIdx]=histcounts(allDist(allElevs<astralThresh),astralDistBinning);
        [meanAstralAmp,medAstralAmp,stdAstralAmp,~,astralCount,sumAstralAmp]=statPerIndx(allAmp(allElevs<astralThresh),astralBinIdx);
        [meanAstralDensities,medAstralDensities,stdAstralDensities]=statPerIndx(allDens(allElevs<astralThresh),astralBinIdx);
        normalizedAstralCount=astralCounts./astralVolumes;
        normalizedAstralAmp=sumAstralAmp./astralVolumes;
        
        % no scaling at first
        % allDens=allDens/mean(allDens(allElevs<0));  
        MD=enrichmentProcesses{cIdx}(pIdx).getOwner();

        meansPolarDensitiesCell{cIdx}=[meansPolarDensitiesCell{cIdx}; meanPolarDensities];
        meansAstralDensitiesCell{cIdx}=[meansAstralDensitiesCell{cIdx}; meanAstralDensities];
        coneNormCountPolarCell{cIdx}=[coneNormCountPolarCell{cIdx}; normalizedPolarCount];
        coneNormCountAstralCell{cIdx}=[coneNormCountAstralCell{cIdx}; normalizedAstralCount];
        countPolarCell{cIdx}=[countPolarCell{cIdx}; polarCounts];
        countAstralCell{cIdx}=[countAstralCell{cIdx}; astralCounts];
        normAmpAstralCell{cIdx}=[normAmpAstralCell{cIdx}; normalizedAstralAmp];
        normAmpPolarCell{cIdx}=[normAmpPolarCell{cIdx}; normalizedPolarAmp];
        meansAstralIntCell{cIdx}=[meansAstralIntCell{cIdx}; meanAstralAmp];
        meansPolarIntCell{cIdx}=[meansPolarIntCell{cIdx}; meanPolarAmp];

        movie.movieData=enrichmentProcesses{cIdx}(pIdx).getOwner().movieDataPath_;
        movie.poleDist=vertcat(distanceCell{cIdx}{pIdx}{:}); 
        movie.binningDistance=polarDistBinning; 
        movie.binnedCountAstral=astralCounts; 
        movie.binnedCountPolar=polarCounts; 
        movie.binnedCountAstralPerFrame=astralCounts/MD.nFrames_; 
        movie.binnedCountPolarPerFrame=polarCounts/MD.nFrames_; 
        movie.elevation=vertcat(elevationCell{cIdx}{pIdx}{:});
        movie.intensity=vertcat(ampCell{cIdx}{pIdx}{:});
        movie.density=vertcat(densityCell{cIdx}{pIdx}{:});;
        movie.azimuths=allAzim;
        movie.KTazimuths=allKTAzim;
        movie.KTelevations=allKTElev;
        movie.KTdist=allKTDist;
        movie.time=vertcat(timeCell{cIdx}{pIdx}{:});
        moviesStruct=[moviesStruct movie];
    end
    conditionEnrichmenData.movies=moviesStruct;    
end


%% Mean density vs pole distance.
[Handle,~,F]=setupFigure(1,1,1,'AxesWidth',10,'AxesHeight',6);
hold on;
shadeHandles=[];
predHandles=[];
minDist=2;  
fitXTicks=astralXTicks(astralXTicks>=minDist);
astralK=0; 
for cIdx=nonEmptyProcess
    % minMeans=min([meansAstralIntCell{cIdx}(:)' meansPolarIntCell{cIdx}(:)']);
    % maxMeans=max([meansAstralIntCell{cIdx}(:)' meansPolarIntCell{cIdx}(:)']);
    % meansAstralIntCell{cIdx}=(meansAstralIntCell{cIdx}-minMeans)./(maxMeans-minMeans);
    % meansPolarIntCell{cIdx}=(meansPolarIntCell{cIdx}-minMeans)./(maxMeans-minMeans);
    
    %X = linsolve([exp(-XTicks*AstralK)'],mean(meansAstralIntCell{cIdx})');
    [f,B]=catastropheRateFit(mean(meansAstralIntCell{cIdx}(:,astralXTicks>=minDist)),fitXTicks);
    predictedAstral= f(B,astralXTicks);
    astralK=B(2); 

    % A=sum(mean(meansAstralIntCell{cIdx}))./sum(exp(-astralXTicks*AstralK));
    % predictedAstral= A*exp(-astralXTicks*AstralK);

    %X = linsolve([exp(-XTicks*AstralK)'],mean(meansPolarIntCell{cIdx})');
    A=sum(mean(meansPolarIntCell{cIdx}))./sum(exp(-polarXTicks*AstralK));
    predictedPolar= A*exp(-polarXTicks*AstralK);    
    
    if(~isempty((meansAstralIntCell{cIdx})))
        shadeHandle=plotOrShade(Handle(1),astralXTicks,meansAstralIntCell{cIdx},p.shade,cmap(1,:));
        shadeHandles=[shadeHandles shadeHandle];
        % pH=plot(Handle(1),astralXTicks,predictedAstral);
        % predHandles=[predHandles pH];
    end    
    
    if(~isempty((meansPolarIntCell{cIdx})))
        shadeHandle=plotOrShade(Handle(1),polarXTicks,meansPolarIntCell{cIdx},p.shade,cmap(end,:));
        shadeHandles=[shadeHandles shadeHandle];
        % pH=plot(Handle(1),polarXTicks,predictedPolar);
        % predHandles=[predHandles pH];
    end
end
lineToLegend=arrayfun(@(h) h.mainLine,shadeHandles,'unif',0)
legend([lineToLegend{:} predHandles],{'Astral','Polar',['predAstral K: ' num2str(astralK)]},'Location','northeast')
% ylim([0,4])
xlim([0 7]);
xlabel('Pole distance (\mu m)');
ylabel(Handle,'Mean Intensties');
hold off;
printPNGEPSFIG(F,outputDirPlot,'meanIntensities');
%close(F);

%% Count vs pole distance
[Handle,~,F]=setupFigure(1,1,1,'AxesWidth',10,'AxesHeight',6);
hold on;
shadeHandles=[];
predHandles=[];
astralK=0;
for cIdx=nonEmptyProcess
    lcountAstralCell=countAstralCell{cIdx};
    lcountPolarCell=countPolarCell{cIdx};

    lcountAstralCell=vertcat(conditionEnrichmenData(cIdx).movies.binnedCountAstralPerFrame);
    lcountPolarCell=vertcat(conditionEnrichmenData(cIdx).movies.binnedCountPolarPerFrame);

    [f,B]=catastropheRateFitCount(mean(lcountAstralCell(:,astralXTicks>=minDist)),fitXTicks);
    predictedAstral= f(B,astralXTicks);
    astralK=B(2);
    conditionEnrichmenData.predictedAstralCount=predictedAstral;
    conditionEnrichmenData.catastropheModel=f;
    conditionEnrichmenData.catastropheModelParam=B;

    A=sum(mean(lcountPolarCell))./sum(exp(-polarXTicks*PolarK));
    predictedPolar= A*exp(-polarXTicks*PolarK);
    if(~isempty((lcountAstralCell)))
        shadeHandle=plotOrShade(Handle(1),astralXTicks,lcountAstralCell,p.shade,cmap(1,:));
        shadeHandles=[shadeHandles shadeHandle];
        pH=plot(Handle(1),astralXTicks,predictedAstral);
        predHandles=[predHandles pH];
    end    

    if(~isempty((lcountPolarCell)))
        shadeHandle=plotOrShade(Handle(1),polarXTicks,lcountPolarCell,p.shade,cmap(2,:));
        shadeHandles=[shadeHandles shadeHandle];
    end
end
lineToLegend=arrayfun(@(h) h.mainLine,shadeHandles,'unif',0)
legend([lineToLegend{:} predHandles],{'Astral','Polar',['predAstral K:' num2str(astralK)]},'Location','northeast')
% ylim([0,4])
xlim(Handle,[0 7]);
xlabel('Pole distance (\mu m)');
ylabel(Handle,'Comet counts');
printPNGEPSFIG(F,outputDirPlot,'cometCount');
hold off;

%% Proximal and distal counts
[Handle,~,F]=setupFigure(1,1,1,'AxesWidth',10,'AxesHeight',6);
shadeHandles=[];
predHandles=[];
for cIdx=nonEmptyProcess
        lcountAstralCell=countAstralCell{cIdx};
        lcountPolarCell=countPolarCell{cIdx};        

        decayAmps=sum((lcountAstralCell),2)./sum(exp(-astralXTicks*AstralK));
        predictedAstral= decayAmps*exp(-astralXTicks*AstralK);
        lowDistances=(astralXTicks<=median(astralXTicks));
        highDistances=(astralXTicks>=median(astralXTicks));
        
        if(~isempty((lcountAstralCell)))
            notBoxPlot([sum(lcountAstralCell(:,lowDistances),2) sum(lcountAstralCell(:,highDistances),2) sum(predictedAstral(:,highDistances),2)]);
        end
end
ylabel('Astral Comet counts');
Handle.XTickLabel={'Proximal','Distal','Predicted'};
printPNGEPSFIG(F,outputDirPlot,'cometCountBoxAstral');

%% Proximal and distal counts in Polar area
[Handle,~,F]=setupFigure(1,1,1,'AxesWidth',10,'AxesHeight',6,'XSpace',[3 0.75 0.5]);
shadeHandles=[];
predHandles=[];
validDistances=polarXTicks(polarXTicks>=minDist);
for cIdx=nonEmptyProcess
        lcountPolarCell=countPolarCell{cIdx};
        lowDistances=(polarXTicks<=median(validDistances))&(polarXTicks>=minDist);
        highDistances=(polarXTicks>=median(validDistances))&(polarXTicks>=minDist);
        
        if(~isempty((lcountPolarCell)))
            notBoxPlot([sum(lcountPolarCell(:,lowDistances),2) sum(lcountPolarCell(:,highDistances),2)]);
        end
end
ylabel(Handle,'Polar Comet counts');
Handle.XTickLabel={'Proximal','Distal'};
printPNGEPSFIG(F,outputDirPlot,'cometCountBoxPolar');

% Polar distance vs cone normalized comet count
[Handle,~,F]=setupFigure(1,1,1,'AxesWidth',10,'AxesHeight',6);
hold on;
shadeHandles=[];
predHandles=[];
for cIdx=nonEmptyProcess  
%     coneNormCountAstralCell{cIdx}=coneNormCountAstralCell{cIdx}./repmat(coneNormCountAstralCell{cIdx}(:,1),1,size(coneNormCountAstralCell{cIdx},2));
%     coneNormCountPolarCell{cIdx}=coneNormCountPolarCell{cIdx}./repmat(coneNormCountPolarCell{cIdx}(:,1),1,size(coneNormCountPolarCell{cIdx},2));
%     
    A=sum(mean(coneNormCountAstralCell{cIdx}))./sum(exp(-astralXTicks*AstralK));
    predictedAstralNormCount= A*exp(-astralXTicks*AstralK);
    
    if(~isempty((coneNormCountAstralCell{cIdx})))
        shadeHandle=plotOrShade(Handle(1),astralXTicks,coneNormCountAstralCell{cIdx},p.shade,cmap(1,:));
        shadeHandles=[shadeHandles shadeHandle];
        pH=plot(Handle(1),astralXTicks,predictedAstralNormCount);
        predHandles=[predHandles pH];
    end    

    if(~isempty((coneNormCountPolarCell{cIdx})))
        shadeHandle=plotOrShade(Handle(1),polarXTicks,coneNormCountPolarCell{cIdx},p.shade,cmap(2,:));
        shadeHandles=[shadeHandles shadeHandle];
    end
end
lineToLegend=arrayfun(@(h) h.mainLine,shadeHandles,'unif',0)
legend([lineToLegend{:} predHandles],{'Astral','Polar','predAstral'},'Location','northeast')
% ylim([0,4])
xlim([0 7]);
xlabel('Pole distance (\mu m)');
ylabel(Handle,'Normalized comet counts per vol (1/\mu m^3)');
hold off;
printPNGEPSFIG(F,outputDirPlot,'normCometCount');
%close(F);

% Pole distance vs comet count
[H,~,F]=setupFigure(1,1,1,'AxesWidth',10,'AxesHeight',6);
hold on;
shadeHandles=[];
predHandles=[];
for cIdx=nonEmptyProcess
         A=sum(mean(meansAstralDensitiesCell{cIdx}))./sum(exp(-astralXTicks*AstralK)./relativeVolumeAstral);
        predictedAstralAmp= A*exp(-astralXTicks*AstralK)./relativeVolumeAstral;
        
        if(~isempty((meansAstralDensitiesCell{cIdx})))
            shadeHandles=plotOrShade(H(1),astralXTicks,meansAstralDensitiesCell{cIdx},p.shade,cmap(1,:));
            shadeHandles=[shadeHandles shadeHandle];
            pH=plot(H(1),astralXTicks,predictedAstralAmp);
            predHandles=[predHandles pH];
        end
        
        if(~isempty((meansPolarDensitiesCell{cIdx})))
            shadeHandle=plotOrShade(H(1),polarXTicks,meansPolarDensitiesCell{cIdx},p.shade,cmap(1,:));
            shadeHandles=[shadeHandles shadeHandle];
        end
end
lineToLegend=arrayfun(@(h) h.mainLine,shadeHandles,'unif',0)
legend([lineToLegend{:} predHandles],{'Astral','Polar','predAstral'},'Location','northeast')
% ylim([0,4])
xlim([0 7]);
xlabel('Pole distance (\mu m)');
ylabel(H,'Comet density (1/\mu m^3)');
hold off;
printPNGEPSFIG(F,outputDirPlot,'SphereDensityVsDistance');
%close(F)

% normalized intensity vs Pole distance 
[HAmp,~,FAmp]=setupFigure(1,1,1,'AxesWidth',10,'AxesHeight',6);
hold on;
shadeHandles=[];
predHandles=[];
astralK=0;
for cIdx=nonEmptyProcess
        if(~isempty((normAmpAstralCell{cIdx})))
            shadeHandles=plotOrShade(HAmp(1),astralXTicks,normAmpAstralCell{cIdx},p.shade,cmap(1,:));
            shadeHandles=[shadeHandles shadeHandle];
            % pH=plot(HAmp(1),astralXTicks,predictedAstralAmp);
            % predHandles=[predHandles pH];
        end
        
        if(~isempty((normAmpPolarCell{cIdx})))
            shadeHandle=plotOrShade(HAmp(1),polarXTicks,normAmpPolarCell{cIdx},p.shade,cmap(end,:));
            shadeHandles=[shadeHandles shadeHandle];
        end
end
lineToLegend=arrayfun(@(h) h.mainLine,shadeHandles,'unif',0)
legend([lineToLegend{:} predHandles],{'Astral','Polar',['predAstral K:' num2str(astralK)]},'Location','northeast')
% ylim([0,4])
xlim([0 7]);
xlabel('Pole distance (\mu m)');
ylabel(HAmp,'Normalized intensity');
hold off;
printPNGEPSFIG(F,outputDirPlot,'normAmpVsDistance');

%% Count function of elevation
radianBin=-pi/2:0.1:pi/2;
for cIdx=nonEmptyProcess
    for pIdx=1:length(conditionEnrichmenData.movies)
        [counts,edges,binIdx]=histcounts(conditionEnrichmenData(cIdx).movies(pIdx).elevation,radianBin);
        conditionEnrichmenData.movies(pIdx).binnedCountvsElevation=counts;
        conditionEnrichmenData.movies(pIdx).binningElevation=radianBin;
    end
end
save(fullfile(outputDirPlot,'conditionEnrichmenData.mat'),'conditionEnrichmenData');

%% Display Elevation vs Azimuth heatmap at the KT interface
% normalized intensity vs Pole distance 
[H,~,H]=setupFigure(1,length(nonEmptyProcess),length(nonEmptyProcess),'AxesWidth',10,'AxesHeight',6);
hold on;
for cIdx=nonEmptyProcess
    % +Tips overlay
    allAzim=vertcat(conditionEnrichmenData(cIdx).movies.azimuths);
    allElev=vertcat(conditionEnrichmenData(cIdx).movies.elevations);
    allKTPoleDistance=vertcat(conditionEnrichmenData(cIdx).movies.elevations);
    prctile(allKTPoleDistance,0.5);       
end
xlabel('');
ylabel(HAmp,'Normalized intensity');
hold off;
printPNGEPSFIG(F,outputDirPlot,'normAmpVsDistance');



%% Projection display

%% For each conditon, display elevation vs density
for cIdx=nonEmptyProcess
    rsize=[300 400];
    cellPlate=cell(ceil(length(enrichmentProcesses{cIdx})/2),2);
	for pIdx=1:length(enrichmentProcesses{cIdx})
        img=imread(sprintfPath(projProcesses{cIdx}(pIdx).outFilePaths_{2},1));
        plotImg=imread(enrichmentProcesses{cIdx}(pIdx).outFilePaths_{1});
        img=imresize(img,rsize);
        plotImg=imresize(plotImg,rsize);
        if(p.printCellName)
            movieName=enrichmentProcesses{cIdx}(pIdx).getOwner().outputDirectory_;
            movieName=strrep(movieName,'/analysis','');
            movieName=strrep(movieName,'/deskew','');
            movieName=strsplit(movieName,'/');
            movieName=[movieName{end-1} ' ' movieName{end}];
            %plotImg=AddTextToImage(plotImg,movieName,size(plotImg));
            plotImg=AddTextToImage(plotImg,movieName,[1 50],[0 0 0], 'Arial',16);
        end
        cellPlate{ceil(pIdx/2),2-mod(pIdx,2)}=[plotImg img];
    end
    emptyMovie=cellfun(@(c) isempty(c),cellPlate);
    if(any(emptyMovie(:)))
        cellPlate{emptyMovie}=uint8(zeros(rsize(1),2*rsize(2),3));
    end
    imwrite(horzcat(vertcat(cellPlate{:,1}),vertcat(cellPlate{:,2})),[outputDirPlot 'plate_' names{cIdx} '.png']);
end

%% For each conditon, display density vs pole dist 
for cIdx=nonEmptyProcess
    rsize=[200 400];
    cellPlate=cell(ceil(length(enrichmentProcesses{cIdx})/2),2);
	for pIdx=1:length(enrichmentProcesses{cIdx})
        img=imread(sprintfPath(projProcesses{cIdx}(pIdx).outFilePaths_{2},1));
        plotImg=imread(enrichmentProcesses{cIdx}(pIdx).outFilePaths_{4});
        img=imresize(img,rsize);
        plotImg=imresize(plotImg,rsize);
        cellPlate{ceil(pIdx/2),2-mod(pIdx,2)}=[plotImg img];
        % imwrite([plotImg img],[outputDirPlot 'plate_density_' names{cIdx} '-' num2str(pIdx) '.png']);
    end
    emptyMovie=cellfun(@(c) isempty(c),cellPlate);
    if(any(emptyMovie(:)))    
        cellPlate{emptyMovie}=uint8(zeros(rsize(1),2*rsize(2),3));
    end
    imwrite(horzcat(vertcat(cellPlate{:,1}),vertcat(cellPlate{:,2})),[outputDirPlot 'plate_density_' names{cIdx} '.png']);
end

printProjProcessArray([projProcesses],'polars',outputDirPlot,names)
printProjProcessArray([p.projProcesses],'astrals',outputDirPlot,names)
printProcessArray([projProcesses p.projProcesses],enrichmentProcesses,3,outputDirPlot,names)
printProcessArray([projProcesses p.projProcesses],enrichmentProcesses,5,outputDirPlot,names)
printProcessArray([projProcesses p.projProcesses],enrichmentProcesses,6,outputDirPlot,names)
printProcessArray([projProcesses p.projProcesses],enrichmentProcesses,7,outputDirPlot,names)


function printProcessArray(processProjCellArray,enrichmentProcesses,outputIndex,outputDirPlot,names)
%% For each conditon, display intensity vs pole dist 
for cIdx=1:length(enrichmentProcesses)
    rsize=[200 400];
    cellPlate=cell(ceil(length(enrichmentProcesses{cIdx})/2),2);
	for pIdx=1:length(enrichmentProcesses{cIdx})
        plotImg=imread(enrichmentProcesses{cIdx}(pIdx).outFilePaths_{outputIndex});
        plotImg=imresize(plotImg,rsize);
        img=plotImg;
        for pcIdx=1:length(processProjCellArray)
            pr=processProjCellArray(pcIdx);
            tmpimg=imread(sprintfPath(pr{cIdx}(pIdx).outFilePaths_{2},1));
            tmpimg=imresize(tmpimg,rsize);
            img=[img tmpimg];
        end
        cellPlate{ceil(pIdx/2),2-mod(pIdx,2)}=img;
        [~,graphName,~]=fileparts(enrichmentProcesses{cIdx}(pIdx).outFilePaths_{outputIndex});
        % imwrite(img,[outputDirPlot 'plate_' graphName '_' names{cIdx} '-' num2str(pIdx) '.png']);
    end
    emptyMovie=cellfun(@(c) isempty(c),cellPlate);
    if(any(emptyMovie(:)))    
        cellPlate{emptyMovie}=uint8(zeros(rsize(1),3*rsize(2),3));
    end
    [~,graphName,~]=fileparts(enrichmentProcesses{cIdx}(1).outFilePaths_{outputIndex});
    imwrite(horzcat(vertcat(cellPlate{:,1}),vertcat(cellPlate{:,2})),[outputDirPlot 'plate_' graphName '_' names{cIdx} '.png']);
end
function printProjProcessArray(processCellArray,graphName,outputDirPlot,names,platesize)
%% For each conditon, display intensity vs pole dist 
for cIdx=1:length(processCellArray(1))
    firstCond=processCellArray(1);
    firstCond=firstCond{cIdx};
    rsize=[200 400];
    if(nargin<5)
        cellPlate=cell(ceil(length(firstCond)),1);
    else
        cellPlate=cell(platesize);
    end
	for pIdx=1:length(firstCond)
        img=[];
        for pcIdx=1:length(processCellArray)
            pr=processCellArray(pcIdx);
            pr=pr{cIdx};
            tmpimg=imread(sprintfPath(pr(pIdx).outFilePaths_{2},1));
            tmpimg=imresize(tmpimg,rsize);
            img=[img tmpimg];
        end
        cellPlate{pIdx}=img;
        % imwrite(img,[outputDirPlot 'plate_' graphName '_' names{cIdx} '-' num2str(pIdx) '.png']);
    end
    emptyMovie=cellfun(@(c) isempty(c),cellPlate);
    if(any(emptyMovie(:)))    
        cellPlate{emptyMovie}=uint8(zeros(rsize(1),3*rsize(2),3));
    end
    imwrite(vertcat(cellPlate{:,1}),[outputDirPlot 'plate_' graphName '_' names{cIdx} '.png']);
end

function shadeHandles=plotOrShade(h,XTicks,measure,shade,cmap)
c={'r','b','g','y','k','o'};
shadeHandles=[];
if(size(measure,1)>1)
    y=measure;
    if(shade)
        axes(h);
        shadeHandles=shadedErrorBar(XTicks,mean(y),std(y),{'Color',cmap(1,:)});
    else
        plot(XTicks,mean(y),[c{1} '-'],'Color',cmap(1,:));
    end
else
    plot(XTicks,measure,[c{1} '-'],'Color',cmap(1,:));
end
function [f,B]=catastropheRateFitCount( dataPoint,fitXTicks)

    f = @(b,x) b(1).*exp(-b(2).*x);
    nrmrsd = @(b) norm(dataPoint - f(b,fitXTicks));     % Residual Norm Cost Function
    B0 = [max(dataPoint) 0.5 ];                                            % Choose Appropriate Initial Estimates
    [B,rnrm] = fminsearch(nrmrsd, B0); 
    disp(['Estimated Catastrophe Rate: ' num2str(B(2))])

function [f,B]=catastropheRateFit( dataPoint,fitXTicks)

    f = @(b,x) b(1).*exp(-b(2).*x) + b(3);
    nrmrsd = @(b) norm(dataPoint - f(b,fitXTicks));     % Residual Norm Cost Function
    B0 = [max(dataPoint) 0.5 min(dataPoint)];                                            % Choose Appropriate Initial Estimates
    [B,rnrm] = fminsearch(nrmrsd, B0); 
    disp(['Estimated Catastrophe Rate: ' num2str(B(2))])