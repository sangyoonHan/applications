%This script file shows the animation of identified body force over time.

%Load the identified body force.
load([resultPath 'bfId']);

%Get the image of the cell.
rawI = cell(numTimeSteps,1);
for jj = 1:numTimeSteps
   rawI{jj} = imread(imgFile{jj});
end

M = vectorFieldAnimate([bfDisplayPx bfDisplayPy],recBF,10000/2, ...
   'bgImg',rawI{1},'vc','r');
