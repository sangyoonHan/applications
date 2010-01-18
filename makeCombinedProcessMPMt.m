function [mpm_total] = makeCombinedProcessMPMt(imagesize, numf, plotOn, hotness ,varargin)
% make simulated MPM (with specified number of frames and imagesize) as a
% superposition of clustered and random processes
% INPUT:
% imagesize     image size, in format [sx,sy]
% numf          number of frames
% varargin      variable number of inputs; each input is a vector that
%               specifies a process; all vectors have the form
%               [ type   density    other descriptors ]
%               the individual descriptors are as follows
%       IF type = 1     random process
%                       density = point density per frame (this parameter
%                       is actually the lambda for the poisson distrubuted
%                       number of random events per frame)
%                       reshuffle = 1 if point density per frame is to be
%                       consevred given restrictions
%       IF type = 2     Cox cluster process (points are distributed
%                       with Gaussian intensity profile around parent)
%                       density = density of parent points per frame,
%                       additional descriptors for this process are
%                       lambda = average number of children per parent
%                       NOTE that child initiation around the parent is a
%                       Poisson process!!
%                       lag = time lag before parent can produce another
%                       child
%                       sigma = sigma of Gaussian distance distribution of
%                       children around parent
%                       sigmaDiff (optional) = sigma of random frame-to-
%                       frame displacement of parents (default =0)
%                       minParentDistance = minimum interparent distance
%                       (default = 0)
%                       reshuffle = 1 if point density per frame is to be
%                       consevred given restrictions
%       IF type = 3     Matern cluster process (points are distributed
%                       randomly in a disc around parent)
%                       other parameters: as in Cox cluster, sigma here is
%                       the radius of the disc
%       IF type = 4     inclusion process: the points generated by the
%                       processes above are restricted to the area INSIDE
%                       randomly distributed discs
%                       density = density of disc centers
%                       radius_raft = radius of discs
%                       percentRestrict = percent of points inside
%                       exclusion area that are restricted
%                       sigmaDiff = sigma of disc diffusion
%                       minParentDistance = minimum interparent distance
%                       (default = 0)
%       IF type = 5     exclusion process: the points generated by the
%                       processes above are restricted to the area OUTSIDE
%                       randomly distributed discs
%                       Parameters as for type=4
%
% Example:
% [mpm_total] = makeCombinedProcessMPMt([400 400], 300, [1 0.0002], [2 0.002 0.1 3 0.5]);
% creates a distribution that's a superposition of
% A: a random distribution with 0.0002*(400^2)=32 objects per frame, plus
% B: a Cox-clustered distribution with 320 parents, which move 0.5*randn pix
% per frame, where each parent has poissrnd(0.1) children, distributed with
% sigma=3 pix around the parent
%
% last modified: Dinah Loerke, July 1, 2009

%calculate simulation area
sx = imagesize(1);
sy = imagesize(2);
imarea = sx*sy;

% for simulating parent positions a larger area is used to avoid edge
% effects
sxLarge = sx+20;
syLarge = sy+20;
imareaLarge = sxLarge*syLarge;

% a buffer needs to be applied in order to match the positions in the small
% image to those on the larger image
buffer = (sxLarge-sx)/2;

% loop over processes, read process types
%allocate space
processDensities = nan(1,length(varargin));
proc = nan(1,length(varargin));
%for each input process
for i=1:length(varargin)
    %get process parameters
    vec = varargin{i};
    %save process intensities on a spearate vector for easy access
    processDensities(i) = vec(2);
    %get process types
    proc(i) = vec(1);
end
% processes with numbers 1-3 are point-generating processes, whereas
% numbers 4-5 are point-restricting (or excluding) processes
pos_generate = find(proc<=3);
pos_restrict = find(proc>3);

%calculate maximum expected number of points per frame
%for a parent-child this is the parent density times the area of the frame
%times the average children per frame per parent
%for a random process this is the expected number per frame
lengthPointsPerFrame = 1000;

%if no point restricting processes are specified...continue
% if isempty(pos_restrict)
%     disp('no point-restricting processes specified');
% else
    %allocate space for restricting processes
%    generatedPoints_restrictions = repmat(struct('mpm_restrict',[],'type',[]),length(pos_restrict),1);
%end

%if no point generating processes specified...stop, there is nothing to
%simulate
if isempty(pos_generate)
    error('no point-generating processes specified');
else
    %allocate space for restricting processes
    generatedPoints = repmat(struct('mpm',zeros(lengthPointsPerFrame,numf*2),'mpm_parents',[],'type',[],'parentTimer',[]),length(pos_generate),1);
end

%% NOW LOOP OVER ALL RESTRICTING PROCESSES
%if any restriction processes are specified
if ~isempty(pos_restrict)
    % loop over all point-restricting processes
    for i=1:length(pos_restrict)
        % current generating parameters
        cvec = varargin{pos_restrict(i)};
        % first position: distribution type
        vi_type = cvec(1);
        % second position: intensity of the process (number of points or
        % parents
        vi_int = cvec(2);
        switch vi_type
            % distribution is raft-shaped inclusion or exclusion, i.e. a
            % restriction of previous data rather than added new data
            case {4,5}
                
                % third value is radius of disc (in pixel)
                radius_raft = cvec(3);
                
                % fourth value (optional) is the percent of points the area restricts
                if length(cvec)>3
                    percentRestrict = cvec(4);
                else
                    percentRestrict = 1;
                end

                % fifth value (optional) is sigma of raft diffusion (also
                % in pixel)
                if length(cvec)>4
                    sigma_diff = cvec(5);
                else
                    sigma_diff = 0;
                end
                
                % sixth value (optional) is the minimum distance between
                % the centroids of parent processes
                if length(cvec)>5
                    minDist = cvec(6);
                else
                    minDist = 0;
                end

                %generate mpm for point restricting process...that is, x
                %and y posiiton of each point restricting process
                %for each frame of the simulation
                %parents processes are simulated over a larger area to
                %avoid edge effects
                [mpm_restrict] = generateRestrictions(numf,[sxLarge syLarge],vi_int,minDist,sigma_diff,buffer);

                if vi_type==4
                    generatedPoints_restrictions(i).type = [ 4, radius_raft, percentRestrict];
                else
                    generatedPoints_restrictions(i).type = [ 5, radius_raft, percentRestrict];
                end

                %store mpm
                generatedPoints_restrictions(i).mpm_restrict = mpm_restrict;
            otherwise
                error('unknown process identification number');
        end % of case/switch
    end % of for i-loop
end %if restriction  process exists

%% POINT GENERATING PROCESSES
%now that we have simulted all point restricting processes for each frame,
%we go frame by frame into point generating processes and keep those points
%which are not restricted

%for every frame
for t=1:numf

    %make MPM out of restrictions where every two columns represent x and y
    %positions of restriction process (for example if two restriction
    %processes exist then the mpm should have the comlumns [x1 y1 x2 y2]
    %where each row entry represents a parent in each process
    restrictionsType = [];
    restrictionsMPM = [];
    if exist('generatedPoints_restrictions','var')
        for irestrict = 1:length(generatedPoints_restrictions)
            mpmRestrictCurr = generatedPoints_restrictions(irestrict).mpm_restrict(:,2*t-1:2*t);
            if size(mpmRestrictCurr,1) > size(restrictionsMPM,1)
                restrictionsMPM = padarray(restrictionsMPM,[size(mpmRestrictCurr,1)-size(restrictionsMPM,1) 0],nan,'post');
            else
                mpmRestrictCurr = padarray(mpmRestrictCurr,[-size(mpmRestrictCurr,1)+size(restrictionsMPM,1) 0],nan,'post');
            end
            restrictionsMPM = [restrictionsMPM mpmRestrictCurr];
            %also make matrix specifying restriction type and radius
            restrictionsType = [restrictionsType generatedPoints_restrictions(irestrict).type'];
        end
    end

    % loop over all point-generating processes
    for i=1:length(pos_generate)

        % current generating parameters
        cvec = varargin{pos_generate(i)};
        % first position: distribution type
        vi_type = cvec(1);
        % second position: intensity of the process (number of points or
        % parents
        vi_int = cvec(2);

        %get parameters and set parents if necessary
        switch vi_type
            % distribution is random or saffarian hotspot
            case { 1}

                % if random process we care about the
                % points themselevs
                % number of points is intensity times area
                nump = poissrnd(vi_int);

                % third value (optional) is determines whether point
                % density is to be conserved given restrictions
                if length(cvec) > 2
                    reshuffle = cvec(3);
                else
                    reshuffle = 0;
                end

                % fourth value (optional) is the restriction radius
                % after a nucleation has taken place
                if length(cvec) > 3
                    restrictRad = cvec(4);
                else
                    restrictRad = 0;
                end


                % fourth value is the time restriction imposed after
                % nucleation on furthe nucleations
                if length(cvec) > 4
                    restrictLambdaRand = cvec(5);
                else
                    restrictLambdaRand = 0;
                end

                % fifth value is the time lag before parent is allowed
                % to have succeeding children
                if length(cvec) > 5
                    restrictLagRand = cvec(6);
                else
                    restrictLagRand = 0;
                end

                % distribution is cluster (of raft or Cox type)
            case { 2, 3}

                %if parent process we follow instead the number of parents
                %because this is the number we set instead of the child density
                % number of points is intensity times area
                nump = round(vi_int * imareaLarge);

                % third value is number of daughters per mother
                nump_lambda = cvec(3);

                % fourth value is the time lag before parent is allowed
                % to have succeeding children
                nump_int = cvec(4);

                % fourth value is sigma of distribution (in pixel)
                sigma_cluster = cvec(5);

                % fifth value (optional) is sigma of parent diffusion (also
                % in pixel)
                if length(cvec)>5
                    sigma_diff = cvec(6);
                else
                    sigma_diff = 0;
                end

                if length(cvec)>6
                    parentMinDistance = cvec(7);
                else
                    parentMinDistance = 0;
                end

                if length(cvec)>7
                    parentLifeTime = cvec(8);
                    % since a lifetime of zero makes no sense switch to and
                    % infinite lifetime
                    if parentLifeTime == 0
                        parentLifeTime = inf;
                    end
                else
                    parentLifeTime = Inf;
                end

                % ninth value (optional) is determines whether point
                % density is to be conserved given restrictions
                if length(cvec) > 8
                    reshuffle = cvec(9);
                else
                    reshuffle = 0;
                end
                % in the first frame, define the positions of the parent
                % points; in subsequent frames, re-use the original parent
                % positions or let them diffuse as specified
                % NOTE: to avoid edge effects, parent points have to be
                % simulated outside of the image, too
                if nump == 0
                    error('not enough parents in frame')
                    %initiate parents
                elseif t == 1
                    %initiate parent mpm in output structure
                    generatedPoints(i).mpm_parents = zeros((numf/parentLifeTime+1)*nump,2*numf);
                    % initieate timer for lifetime of parent and for time
                    % elapsed since last child
                    %parentTimer = repmat([parentLifeTime 1/nump_lambda],nump,1).*rand(nump,2);
                    %the minus ones and plus ones is so that the minimum is
                    %1, which in the program translates to a minimum of one
                    %frame
                    parentTimer = round(repmat([parentLifeTime-1 numf-1],nump,1).*rand(nump,2))+1;
                    % initiate parent positions
                    [mpm_mother_start] = makeParentMPM(nump,[sxLarge syLarge],parentMinDistance, buffer);
                    mpm_generatedMothers = mpm_mother_start;
                    % numChilds = zeros(size(mpm_generatedMothers),1);
                    %store parent positions
                    generatedPoints(i).mpm_parents(1:size(mpm_generatedMothers,1),1:2)  = mpm_generatedMothers;
                else
                    % fill subsequent time positions
                    livingParentID = find(generatedPoints(i).mpm_parents(:,2*t-2) ~= 0);
                    %mpm_mother_prev = generatedPoints(i).mpm_parents(livingParentID,2*t-3:2*t-2);
                    mpm_mother_prev = generatedPoints(i).mpm_parents(livingParentID,1:2);
                    mpm_generatedMothers = diffuseParentMPM(mpm_mother_prev,sigma_diff);
                    % redraw dead parents
                    [mpm_generatedMothers,parentTimer,redrawnID] = redrawParentMPM(mpm_generatedMothers,parentTimer,parentLifeTime,[sxLarge syLarge],parentMinDistance,buffer);
                    %store new parents starting at the row under the last
                    %recorded parent position from the previous frame
                    generatedPoints(i).mpm_parents(livingParentID(end)+1:livingParentID(end)+length(redrawnID),2*t-1:2*t)  = mpm_generatedMothers(redrawnID,:);
                    %make a dummy mpm for parents that represents the new
                    %generated mpm, but with the redrawn parents zeroed
                    %(putting this mpm back into the data structure should
                    %reupdate parents that were not redrawn while zeroing those
                    %that did
                    mpmMotherDummy = mpm_generatedMothers;
                    mpmMotherDummy(redrawnID,:) = 0;
                    generatedPoints(i).mpm_parents(livingParentID,2*t-1:2*t) = mpmMotherDummy;
                end
            %Saffarian hotspot process
            case 2.1
                
                %if parent process we follow instead the number of parents
                %because this is the number we set instead of the child density
                % number of points is intensity times area
                nump = poissrnd(vi_int * imareaLarge);
                
                % third value is number of daughters per mother
                nump_child = cvec(3);
                
                %fourth value is the time gap between nucleations in frames
                nucleation_gap = cvec(4);
                
                 % fifth value is sigma of distribution (in pixel)
                sigma_cluster = cvec(5);
                
                % generate random distribution
                    x_mpm = 1+(sx-1)*rand(nump,1);
                    y_mpm = 1+(sy-1)*rand(nump,1);
                    %store resulting mpm
                    mpm_generatedMothers = [x_mpm y_mpm];
                
        end %of switch

        % if specified, generate more points
        % while per frame density for point generating process is not
        % met
        looplimit = 150;
        %initiate looping counter for reshuffle function so that points are
        %not redrwan forever if they can't be fit unto the frame due to
        %restrictions
        loopcount = 0;
        %store generated points for each point generating process and for
        %each frame
        mpm_generatedPoints = [];
        while nump ~= 0 && (loopcount == 0 || reshuffle && loopcount < looplimit)

            % GENERATE POINTS
            switch vi_type
                % distribution is random
                case 1
                    % generate random distribution
                    x_mpm = 1+(sx-1)*rand(nump,1);
                    y_mpm = 1+(sy-1)*rand(nump,1);
                    %store resulting mpm
                    mpm_points_curr = [x_mpm y_mpm];
                    % saffarian process
                case 2.1
                    mpm_points_curr = makeSaffarianProcessMPM(mpm_generatedMothers,nump_child,nucleation_gap,sigma_cluster,imagesize);
                    % distribution is cluster (of raft or Cox type)
                case { 2, 3}
                    % generate daughters
                    if vi_type==2
                        [mpm_points_curr, parentTimer(:,2) ]= makeCoxProcessMPM(mpm_generatedMothers,parentTimer(:,2),nump_lambda,nump_int,sigma_cluster,imagesize,numf,hotness);
                    else
                        [mpm_points_curr, parentTimer(:,2) ]= makeRaftProcessMPM(mpm_generatedMothers,parentTimer(:,2),nump_lambda,nump_int,sigma_cluster,imagesize);
                    end
       
            end % of switch/case

            %RESTRICT POINTS IF RESTRICTIONS ARE PRESENT
            if ~isempty(pos_restrict)
                [mpm_points_curr] = makeExcludedOrIncludedMPM(mpm_points_curr,restrictionsMPM,restrictionsType);
            end
            if ~isempty(generatedPoints(proc(pos_generate)==1)) && t~=1 && restrictRad ~= 0
                [mpm_points_curr] = restrictMPMBasedOnResources(mpm_points_curr,generatedPoints(proc==1),restrictRad,restrictLambdaRand,restrictLagRand,t);
            end

            %STORE GENERATED POINTS
            mpm_generatedPoints = [mpm_generatedPoints; mpm_points_curr];

            % CALCULATE HOW MANY POINTS ARE MISSING
            switch vi_type
                %if random process number of points is image area times
                %process density
                case 1
                    nump = nump - size(mpm_points_curr,1);
                case 2.1
                    nump = 0; 
                otherwise
                    %if parent process the density is the process
                    %density times the image area times the average
                    %number of children per parent
                    nump = round(vi_int * imarea * nump_lambda) - size(mpm_generatedPoints,1);
            end
            %update loop count
            loopcount = loopcount + 1;
        end %of while density not met

        if loopcount  == looplimit
            disp('could not reach specified point density');
        end

        %if first frame record type of point generating process
        if t == 1
            generatedPoints(i).type = vi_type;
        end

        %if points were generated
        if vi_type == 2.1
            findEmptyRow = find(max(generatedPoints(i).mpm,[],2) == 0,1,'first');
            generatedPoints(i).mpm(findEmptyRow:findEmptyRow+size(mpm_generatedPoints,1)-1,...
                2*t-1:min(2*(t-1)+size(mpm_generatedPoints,2),numf*2)) = ...
                mpm_generatedPoints(:,1:min(size(mpm_generatedPoints,2),(numf+1)*2-2*t));
        elseif loopcount ~= 0
            %record positions on mpm
            generatedPoints(i).mpm(1:size(mpm_generatedPoints,1),2*t-1:2*t)  = mpm_generatedPoints(:,1:2);
        end %of if points generated
        %NOTE: if points were not generated then the initiated mpm will
        %contain zeros for this frame

        %     for ipar = 1:size(mpm_generatedMothers,1)
        %         numChilds(ipar) = numChilds(ipar) + length(find(mpm_generatedPoints(:,3)==ipar));
        %     end %of for each parent

    end % of for i-loop for point generating processes
end % of for t

%% put results together
mpm_total = [];
for impm = 1:length(generatedPoints)
    mpm_total = [mpm_total ; generatedPoints(impm).mpm];
end
%% plot results
if plotOn
    figure

    for t=1:numf
        for p=1:length(pos_generate)
            ct = generatedPoints(p).type;
            cmpm = generatedPoints(p).mpm;
            if ct==1
                plot(cmpm(:,2*t-1),cmpm(:,2*t),'b.'); hold on
            else
                cmpm_moth = generatedPoints(p).mpm_parents;
                plot(cmpm(:,2*t-1),cmpm(:,2*t),'g.'); hold on;
                plot(cmpm_moth(:,2*t-1),cmpm_moth(:,2*t),'cx');
            end
        end

        for p=1:length(pos_restrict)
            ct = generatedPoints_restrictions(p).type;
            cmpm_res = generatedPoints_restrictions(p).mpm_restrict;

            plot(cmpm_res(:,2*t-1),cmpm_res(:,2*t),'mx');
        end

        hold off;
        axis([1 sx 1 sy]);
        pause(0.1);

    end
end %of if plot is on


end % of function


%%       ==================================================================


function [mpm_daughters,childTimeDiff] = makeCoxProcessMPM(mpm_mothers, childTimeDiff,nump_lambda,nump_int,sigma,imagesize,numf, hotness)

sx = imagesize(1);
sy = imagesize(2);

nmp = size(mpm_mothers,1);
nms = (size(mpm_mothers,2)/2);

% NOTE: the mother points can lie outside the specified image size (in
% simulations, this can be necessary to avoid edge effects) - in any case,
% the daughter points are only retained if they come to lie inside the
% image

% the lambda parameter is dependent on the time past since last child
t = childTimeDiff;
%parents with a value of zero in the counter will have a lambda of 0
%timers will surpass numf.....change these to a maximum (in terms of the
%maximum possible lambda) since these are due
t(t==0)=1;
t(t>numf) = numf;
%nump_lambda = linspace(0,nump_lambda,numf/10);
nump_lambda = hotness;
% in a cox process, the number of daughters per mother is
% poisson-distributed
%lambda_Poiss = min(max(nump_lambda*t-nump_int,0),1);
vec_nump = poissrnd(nump_lambda(t));

%vec_nump(t <= nump_int) = zeros(length(find(t <= nump_int)),1);

% loop over number of samples
for s=1:nms

    % initialize daughter points
    cmpm_daughters = zeros(1,3);

    %loop over all mother points
    for n=1:nmp

        % position of current mother cluster center
        centerpoint = mpm_mothers(n,2*s-1:2*s);
        % current number of daughters from poisson distribution
        numd = vec_nump(n);

        if numd>0

            %generate vector length of mother-daughter distance NOTE randn
            lenDis = sigma*randn(numd,1);

            %generate angle NOTE rand
            angle = 2*pi*rand(numd,1);

            %resulting endpoint for this daughter point
            endx = centerpoint(1) + lenDis .* sin(angle);
            endy = centerpoint(2) + lenDis .* cos(angle);

            cmpm = [endx endy repmat(n,length(endx),1)];

            cmpm_daughters = [cmpm_daughters ; cmpm];
            childTimeDiff(n) = 0;
        else
            childTimeDiff(n) = childTimeDiff(n) + 1;
        end

    end

    px0 = (cmpm_daughters(:,1)>1);
    py0 = (cmpm_daughters(:,2)>1);
    pxi = (cmpm_daughters(:,1)<sx);
    pyi = (cmpm_daughters(:,2)<sy);

    cmpm_daughters = cmpm_daughters(px0 & py0 & pxi & pyi,:);
    csx = size(cmpm_daughters);

    if s==1
        mpm_daughters = cmpm_daughters;
    else
        mpm_daughters((1:csx),((2*s-1):2*s)) = cmpm_daughters;
    end


end % of for s

end % of function



%%       ==================================================================

function [mpm_daughters,childTimeDiff] = makeRaftProcessMPM(mpm_mothers,childTimeDiff,nump_lambda,nump_int,sigma,imagesize)

sx = imagesize(1);
sy = imagesize(2);

nmp = size(mpm_mothers,1);
nms = (size(mpm_mothers,2)/2);

% the lambda parameter is dependent on the time past since last child
t = childTimeDiff;
% in a cox process, the number of daughters per mother is
% poisson-distributed
%lambda_Poiss = min(max(nump_lambda*t-nump_int,0),1);
vec_nump = poissrnd(nump_lambda,nmp,1);
vec_nump(t <= nump_int) = zeros(length(find(t <= nump_int)),1);


% loop over number of samples
for s=1:nms

    %positions of mother cluster centers
    cmpm_daughters = zeros(1,3);


    %loop over all mother points
    for n=1:nmp

        centerpoint = mpm_mothers(n,2*s-1:2*s);
        numd = vec_nump(n);

        if numd>0

            %generate vector length of mother-daughter distance NOTE rand
            lenDis = sigma*rand(numd,1);

            %generate angle NOTE rand
            angle = 2*pi*rand(numd,1);

            %resulting endpoint for this daughter point
            endx = centerpoint(1) + lenDis .* sin(angle);
            endy = centerpoint(2) + lenDis .* cos(angle);

            cmpm = [endx endy repmat(n,length(endx),1)];

            cmpm_daughters = [cmpm_daughters ; cmpm];
            childTimeDiff(n) = 0;
        else
            childTimeDiff(n) = childTimeDiff(n) + 1;
        end

    end

    px0 = (cmpm_daughters(:,1)>1);
    py0 = (cmpm_daughters(:,2)>1);
    pxi = (cmpm_daughters(:,1)<sx);
    pyi = (cmpm_daughters(:,2)<sy);

    cmpm_daughters = cmpm_daughters(px0 & py0 & pxi & pyi,:);
    csx= size(cmpm_daughters);

    if s==1
        mpm_daughters = cmpm_daughters;
    else
        mpm_daughters((1:csx),((2*s-1):2*s)) = cmpm_daughters;
    end

end % of for s

end % of function

%%  =======================================================================
function mpm_daughters = makeSaffarianProcessMPM(mpm_mothers,nump_child,nucleation_gap,sigma,imagesize)

sx = imagesize(1);
sy = imagesize(2);

nmp = size(mpm_mothers,1);
nms = (size(mpm_mothers,2)/2);

% NOTE: the mother points can lie outside the specified image size (in
% simulations, this can be necessary to avoid edge effects) - in any case,
% the daughter points are only retained if they come to lie inside the
% image

%vec_nump(t <= nump_int) = zeros(length(find(t <= nump_int)),1);

% loop over number of samples
for s=1:nms

    % initialize daughter points
    cmpmx = [];
    cmpmy = cmpmx;

    %loop over all mother points
    for n=1:nmp

        % position of current mother cluster center
        centerpoint = mpm_mothers(n,2*s-1:2*s);
        % current number of daughters from poisson distribution
        numd = nump_child;

        if numd>0

            %generate vector length of mother-daughter distance NOTE randn
            lenDis = sigma*randn(numd,1);

            %generate angle NOTE rand
            angle = 2*pi*rand(numd,1);

            %resulting endpoint for this daughter point
            endx = centerpoint(1) + lenDis .* sin(angle);
            endy = centerpoint(2) + lenDis .* cos(angle);

            cmpmx = [cmpmx ;endx'];
            cmpmy = [cmpmy ;endy'];

        end

    end

%     if any(cmpmx<1 | cmpmy<1 | cmpmx>sx | cmpmy>sy)
%         keyboard
%     end
    
    cmpmx(cmpmx<1 | cmpmy<1 | cmpmx>sx | cmpmy>sy) = 0;
    cmpmy(cmpmx<1 | cmpmy<1 | cmpmx>sx | cmpmy>sy) = 0;

    mpm_daughters = zeros(nmp,numd*2+2*nucleation_gap*(numd-1)); 
    mpm_daughters(:,1:(2+2*nucleation_gap):end) = cmpmx;
    mpm_daughters(:,2:(2+2*nucleation_gap):end) = cmpmy;



end % of for s

end % of function

%%  =======================================================================
function [mpmNew] = makeParentMPM(nump,area,minDist, buffer, existingParentMPM)

%This function takes an existing parent mpm and makes a given number of
%additional parents in a given area at a given minimum distance from each
%other and from the existing parent mpm
%NOTE: The buffer is used to match up parents in the larger frame to the
%children in the smaller frame (see begining of function)
%NOTE: New parents are placed to be beyond the minimum distance from older
%parents and themselves; older parent positions are kept


sxLarge = area(1);
syLarge  = area(2);

% generate random distribution of mothers, in area with
% a buffer of +10 on all sides of the image
x_mother = 1+(sxLarge-1)*rand(nump,1) - buffer;
y_mother = 1+(syLarge-1)*rand(nump,1) - buffer;
mpmNew = [x_mother y_mother];


%calculate distance between new pareants and old parents
if nargin < 5 || isempty(existingParentMPM)
    new2oldDist = [];
else
    new2oldDist = distMat2(mpmNew,existingParentMPM);
end
%calculate distance between new parents
new2newDist = distMat2(mpmNew,mpmNew);
new2newDist(new2newDist==0) = nan;
parentDistance = [new2oldDist new2newDist];
%if any of these distances are smaller than minimum
%specified parent distance then redraw those
%only allow this to loop for so long
loopcount = 0;
while any(min(parentDistance,[],2) < minDist) && loopcount ~=50
    %find parents within minimum distance
    findParent = find(min(parentDistance,[],2) < minDist);
    %redraw new parents within minimum distance
    x_redraw = 1+(sxLarge-1)*rand(length(findParent),1) - buffer;
    y_redraw = 1+(syLarge-1)*rand(length(findParent),1) - buffer;
    %store redrawn values
    mpmNew(findParent,:) = [x_redraw y_redraw];
    %update loop count
    loopcount = loopcount + 1;
    %calculate distance between new pareants and old parents
    new2oldDist = distMat2(mpmNew,existingParentMPM);
    %calculate distance between new parents
    new2newDist = distMat2(mpmNew,mpmNew);
    new2newDist(new2newDist==0) = nan;
    parentDistance = [new2oldDist new2newDist];
end

%stop after 50 loops
if loopcount == 50
    error('could not place all parents beyond minimum distance from each other')
end

end %of function make parent mpm

%%  =======================================================================
function [mpm_mother_curr] = diffuseParentMPM( mpm_mother_prev,sigma_diff)
mpm_mother_curr = mpm_mother_prev + sigma_diff*randn(size(mpm_mother_prev,1),2);
end % of function diffuse parents

%%  =======================================================================
function [mpm_restrict] = generateRestrictions(nFrame,imageSize,restrictionDensity,minDist,diffusivity,buffer)
% number of points is intensity times area
area = imageSize(1)*imageSize(2);
nump = round(restrictionDensity * area);
%create variable space
mpm_restrict = nan(nump,2*nFrame);
%for each frame
for iframe = 1:nFrame
    if iframe == 1
        % in the first frame, define the positions of the raft
        % points; in subsequent frames, re-use the original raft
        % positions or let them diffuse as specified
        % NOTE: to avoid edge effects, rafts have to be
        % simulated outside of the image, too
        [mpm_raft_start] = makeParentMPM(nump,imageSize,minDist, buffer);
        mpm_restrict(:,1:2) = mpm_raft_start;
    else
        mpm_raft_prev = mpm_restrict(:,2*iframe-3:2*iframe-2);
        mpm_restrict(:,iframe*2-1:iframe*2) = diffuseParentMPM( mpm_raft_prev,diffusivity);
    end
end %for each frame
end %of function

%%  =======================================================================
function [restrictedMPM] = makeExcludedOrIncludedMPM(unrestrictedMPM,restrictionsMPM,restrictionsType)

mpm_pt_use = unrestrictedMPM;

for irestriction = 1:size(restrictionsType,2)
    % determine distances of all daughter points from the central point
    dm = distMat2(mpm_pt_use(:,1:2),restrictionsMPM(:,irestriction*2-1:irestriction*2));
    dm_min = min(dm,[],2);

    % inclusive: exclude points that are outside radius from rafts
    if restrictionsType(1,irestriction)==4
        fpos_stat = find(dm_min > restrictionsType(2,irestriction));
        % exclusive: exclude points that are within radius from
        % rafts
    else
        fpos_stat = find(dm_min <= restrictionsType(2,irestriction));
    end

    %number of points to exclude is the total number of points that are
    %found within/outside exclusion multiplied by the percent to be
    %excluded
    number2Restrict = restrictionsType(3, irestriction);
    fpos_stat = randsample(fpos_stat,round(length(fpos_stat)*number2Restrict));
    mpm_pt_use(fpos_stat,:) = [];

end %of for each type of restriction
restrictedMPM = mpm_pt_use;
end %of function

%% ========================================================================
function [mpm_points_curr] = restrictMPMBasedOnResources(mpm_points_curr,generatedPoints,restrictRad,restrictLambdaRand,restrictLagRand,t)

%for now let's just set a hard time cutoff for the resource restriction
%for the number of frames the lag is for, this part of the code requires
%the lag to be one less since
restrictLagRand = restrictLagRand -1;
%put together all relevant restrictions into an mpm
mpmRestrict = [];
%for each point generating process
for igen = 1:length(generatedPoints)
    %if time lag is greater than
    restrictingPointsX = nonzeros(generatedPoints(igen).mpm(:,max(2*t-2*restrictLagRand-1,1):2:2*t-1));
    restrictingPointsY = nonzeros(generatedPoints(igen).mpm(:,max(2*t-2*restrictLagRand,1):2:2*t));
    mpmRestrict = [mpmRestrict; restrictingPointsX restrictingPointsY];
end %of for each point generating process

%measure distance from points to restrictions
% determine distances of all daughter points from the central point
dm = distMat2(mpm_points_curr(:,1:2),mpmRestrict);
dm_min = min(dm,[],2);

%find points that fall withiin restriction
%restrict mpm
mpm_points_curr(dm_min <= restrictRad,:) = [];

end %of function

%% ========================================================================
function [mpm_generatedMothers,parentLifeCount,findParents] = redrawParentMPM(mpm_generatedMothers,parentLifeCount,parentLifeTime,area,minDist, buffer)
%this function takes a one frame-long mpm and a lifetime vector
%each row of the mpm corresponds to the same row in the lifetime vector
%parents that have outlived their usefulness are redrawn

%find parents to redraw
findParents = find(parentLifeCount(:,1) > parentLifeTime);
nump = length(findParents);
%redraw parents
[mpmNewParents]= makeParentMPM(nump,area,minDist, buffer, mpm_generatedMothers);
%update positions of parents to be redrawn with new positions
mpm_generatedMothers(findParents,:) = mpmNewParents;
%update parent life count
parentLifeCount(:,1) = parentLifeCount(:,1) + 1;
%reset time counters for parents that disappear
parentLifeCount(findParents,:) = 0;
end %of function