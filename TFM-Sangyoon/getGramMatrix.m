function [R,H]=getGramMatrix(forceMesh)
% this function obtains Gram matrix of the function hi(x) (basis function).
% Another output is Cholesky factorized matrix (R) of H.

H = zeros(2*forceMesh.numBasis); % both for x-direction and y-
% We make H for x-direction and copy later for y
xH = zeros(forceMesh.numBasis);

wtBar = waitbar(0,'Please wait, building Gram Matrix...');
for jj=1:forceMesh.numBasis
    plotClass=forceMesh.basis(jj).class;
    integrandx_jj = forceMesh.basisClass(plotClass).basisFunc(1).f_intp_x;% this is basically the same as integrandx_ii
    jjx = forceMesh.basis(jj).node(1);
    jjy = forceMesh.basis(jj).node(2);
    for ii=1:forceMesh.numBasis
        % definition of field boudary (this can be just an overlapped region)
        % center point of jj-th function
        % if ii-th node is among the neighbors (IDs) of the jj-th node,
        % calculate the integral between the two basis functions.
        if any(forceMesh.basis(ii).nodeID == [forceMesh.neigh(forceMesh.basis(jj).nodeID).cand forceMesh.basis(jj).nodeID])
            % get all 12 neighbor points from two nodes and get min and max
            allNeighPos = [forceMesh.neigh(forceMesh.basis(jj).nodeID).pos; forceMesh.neigh(forceMesh.basis(ii).nodeID).pos];
            xmin = min(allNeighPos(:,1));
            xmax = max(allNeighPos(:,1));
            ymin = min(allNeighPos(:,2));
            ymax = max(allNeighPos(:,2));
            % do the integral of jj-th function for debug - volume should
            % be 66.667 since the shape is pyramid now.
           iix = forceMesh.basis(ii).node(1);
           iiy = forceMesh.basis(ii).node(2);
           refineFactor = 1;%1e-1; %1e-1 was too slow
           [xmat,ymat] = meshgrid(xmin:refineFactor:xmax,ymin:refineFactor:ymax);
           zmat_jj = integrandx_jj(xmat-jjx,ymat-jjy);
           zmat_ii = integrandx_jj(xmat-iix,ymat-iiy);
           % convolution in zmat_jj .* zmat_ii
           xH(jj,ii) = sum(sum(zmat_jj.*zmat_ii))/(refineFactor^2);
%            % get it back to the original coordinates
%            figure, surf(xmat,ymat,zmat_jj)
%            figure, surf(xmat,ymat,zmat_ii)
%            integral2(integrandx_jj,xmin-jjx,xmax-jjx,ymin-jjy,ymax-jjy,'MaxFunEvals',10^10,'AbsTol',5e-10);
%            % we can use integral2, but it takes much more time. Thus we
%            stick with discrete method.
        end
    end
    % Update the waitbar
    if ishandle(wtBar)
        waitbar(jj/forceMesh.numBasis,wtBar,['Please wait, building Gram Matrix...' num2str(jj)]);
    end
end
close(wtBar)

xH=xH/max(xH(:)); % normalize it with max value.
H(1:forceMesh.numBasis,1:forceMesh.numBasis) = xH;
H(forceMesh.numBasis+1:2*forceMesh.numBasis,forceMesh.numBasis+1:2*forceMesh.numBasis) = xH;

%Cholesky factorization
xR = chol(xH);
R(forceMesh.numBasis+1:2*forceMesh.numBasis,forceMesh.numBasis+1:2*forceMesh.numBasis) = xR;
R(1:forceMesh.numBasis,1:forceMesh.numBasis) = xR;


