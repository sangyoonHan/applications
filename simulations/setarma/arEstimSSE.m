function [sumSquareErr,sseGrad,errFlag] = arEstimSSE(unknown,arOrder,traj)
%ARESTIMSSE computes the sum of square prediction error for arLsGapEstim
%
%SYNOPSIS [sumSquareErr,sseGrad,errFlag] = arEstimSSE(unknown0,arOrder,traj)
%
%INPUT  unknown     : AR parameters and measurement error-free trajectory.
%       arOrder     : Order of proposed AR model.
%       traj        : Observed trajectory to be modeled (with measurement uncertainty).
%                     Missing points should be indicated with Inf.
%
%OUTPUT sumSquareErr: sum of square prediction errors.
%       sseGard     : vactor of partial derivatives of sumSquareErr.
%       errFlag   : 0 if function executes normally, 1 otherwise.
%
%Khuloud Jaqaman, February 2004

errFlag = 0;

%check if correct number of arguments were used when function was called
if nargin ~= nargin('arEstimSSE')
    disp('--arEstimSSE: Incorrect number of input arguments!');
    errFlag  = 1;
    arParam = [];
    return
end

%length of trajectory
trajLength = length(traj(:,1));

%check input data
if arOrder < 1
    disp('--arEstimSSE: Variable "arOrder" should be >= 1!');
    errFlag = 1;
end
[nRow,nCol] = size(unknown);
if nRow ~= trajLength+arOrder
    disp('--arEstimSSE: Variable "unknown" has the wrong length!');
    errFlag = 1;
end
if nCol ~= 1
    disp('--arEstimSSE: Variable "unknown" should be a column vector!');
    errFlag = 1;
end
if errFlag
    disp('--arEstimSSE: please fix input data!');
    return
end

%AR coefficients
arParam = unknown(1:arOrder)';

%measurement error-free trajectory
trajNoErr = unknown(arOrder+1:end);

%find points where data is available
indx = find(traj(:,1) ~= Inf);
indxLow = indx(find(indx <= arOrder)); %points at times <= arOrder
indx = indx(find(indx > arOrder)); %points at times > arOrder

%trajectory length for times smaller than arOrder excluding missing points
indxLowLength = length(indxLow);

%trajectory length for times greater than arOrder excluding missing points
indxLength = length(indx);

%map from original sequence to sequence without missing points
indxInv = zeros(trajLength-arOrder,1);
indxInv(indx) = [1:indxLength];

%set of observations
trajWithErr = [traj(indx,1); traj(indxLow,1); traj(indx,1)];

%previous points to be used in AR prediction xHat(t) + e(t) + mu(t) = sum_(i=1)^p[a_ix(t-i)]
prevPoints = zeros(indxLength,arOrder);
for i=1:indxLength
    j = indx(i);
    prevPoints(i,:) = trajNoErr(j-1:-1:j-arOrder)';
end

%get prediction errors
errVec = zeros(2*indxLength+indxLowLength,1);
errVec(1:indxLength) = prevPoints*arParam' - traj(indx,1);
errVec(indxLength+1:indxLength+indxLowLength) = trajNoErr(indxLow) - traj(indxLow);
errVec(indxLength+indxLowLength+1:end) = trajNoErr(indx) - traj(indx);

%weights obtained from measurement uncertainties and white noise variance
weights = zeros(2*indxLength+indxLowLength,1);
weights(1:indxLength) = traj(indx,2).^(-2);
weights(indxLength+1:indxLength+indxLowLength) = traj(indxLow,2).^(-2);
weights(indxLength+indxLowLength+1:end) = weights(1:indxLength);

%value of function to be minimized (sum of weighted square errors)
sumSquareErr = errVec'*(weights.*errVec)/2;

%initialize partial derivatives vector
sseGrad = zeros(size(unknown));

%partial derivatives w.r.t. AR coefficients
dummy = weights(1:indxLength).*errVec(1:indxLength);
sseGrad(1:arOrder) = prevPoints'*dummy;

%partial derivatives w.r.t. measurement error-free data points 
%AR part
for i=arOrder+1:length(sseGrad)-1
    j = i - arOrder;
    subIndx = indxInv(max(j+1,arOrder+1):min(j+arOrder,trajLength));
    subIndx = subIndx(find(subIndx));
    backShift = indx(subIndx) - j;
    sseGrad(i) = arParam(backShift)*(weights(subIndx).*errVec(subIndx));
end
%additional part
sseGrad(arOrder+indxLow) = sseGrad(indxLow) + weights(indxLength+1:indxLength+indxLowLength)...
    .*errVec(indxLength+1:indxLength+indxLowLength);
sseGrad(arOrder+indx) = sseGrad(indx) + weights(indxLength+indxLowLength+1:end)...
    .*errVec(indxLength+indxLowLength+1:end);
