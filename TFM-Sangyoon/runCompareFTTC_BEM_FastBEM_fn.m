% [meanfMR,SEMfMR,regParams] = compareFTTC_BEM_FastBEM_fn('groupForce',3/100,...
% '/home/sh268/orchestra/home/Documents/TFM-simulation/n3g',forceMesh,forceMeshFastBEM,M,M_FastBEM,...
% '/home/sh268/orchestra/home/Documents/TFM-simulation/basisFunction5050E10kPa.mat');
% % n3g means noise= 3 percent and g = groupForce
% [meanfMRn5g,SEMfMRn5g,regParamsn5g] = compareFTTC_BEM_FastBEM_fn('groupForce',5/100,...
% '/home/sh268/orchestra/home/Documents/TFM-simulation/n5g',forceMesh,forceMeshFastBEM,M,M_FastBEM,...
% '/home/sh268/orchestra/home/Documents/TFM-simulation/basisFunction5050E10kPa.mat');
% % n1s means noise= 1 percent and g = groupForce
% 
% % For making new M and M_FastBEM 
% % For orchestra
% [meanfMRn1g,SEMfMRn1g,regParamsn1g] = compareFTTC_BEM_FastBEM_fn('groupForce',1/100,...
% '/home/sh268/Documents/TFM-simulation/n1g',forceMesh,forceMeshFastBEM,M,M_FastBEM,...
% '/home/sh268/Documents/TFM-simulation/basisFunction5050E10kPa.mat');
% % for desktop
% 
% [meanfMRn5g,SEMfMRn5g,regParamsn5g] = compareFTTC_BEM_FastBEM_fn('groupForce',5/100,...
% '/home/sh268/orchestra/home/Documents/TFM-simulation/n5g',[],forceMeshFastBEM,[],M_FastBEM,...
% '/home/sh268/orchestra/home/Documents/TFM-simulation/basisFunction5050E8000Pa.mat');
% 
% [meanfMRn10g,SEMfMRn10g,regParamsn10g] = compareFTTC_BEM_FastBEM_fn('groupForce',10/100,...
% '/home/sh268/orchestra/home/Documents/TFM-simulation/n10g',[],forceMeshFastBEM,[],M_FastBEM,...
% '/home/sh268/orchestra/home/Documents/TFM-simulation/basisFunction5050E8000Pa.mat');
% 
% [meanfMRn10g,SEMfMRn10g,regParamsn10g] = compareFTTC_BEM_FastBEM_fn('groupForce',10/100,...
% '/home/sh268/orchestra/home/Documents/TFM-simulation/n10g',forceMesh,forceMeshFastBEM,M,M_FastBEM,...
% '/home/sh268/orchestra/home/Documents/TFM-simulation/basisFunction5050E10kPa.mat');
% 
% [meanfMRn1g,SEMfMRn0g,regParamsn0g] = compareFTTC_BEM_FastBEM_fn('groupForce',0/100,...
% '/home/sh268/orchestra/home/Documents/TFM-simulation/n1g',[],[],[],[],...
% '/home/sh268/orchestra/home/Documents/TFM-simulation/basisFunction500500E8000Pa.mat');

[meanfMRn0g,SEMfMRn0g,regParamsn0g] = compareFTTC_BEM_FastBEM_fn('groupForce',0/100,...
'/home/sh268/Documents/TFM-simulation/n1g',[],[],[],[],...
'/home/sh268/Documents/TFM-simulation/basisFunction500500E8000Pa.mat');

[meanfMRn1g,SEMfMRn1g,regParamsn1g] = compareFTTC_BEM_FastBEM_fn('groupForce',1/100,...
'/home/sh268/Documents/TFM-simulation/n1g',[],forceMeshFastBEM,[],M_FastBEM,...
'/home/sh268/Documents/TFM-simulation/basisFunction500500E8000Pa.mat');

[meanfMRn5g,SEMfMRn5g,regParamsn5g] = compareFTTC_BEM_FastBEM_fn('groupForce',5/100,...
'/home/sh268/Documents/TFM-simulation/n5g',[],forceMeshFastBEM,[],M_FastBEM,...
'/home/sh268/Documents/TFM-simulation/basisFunction500500E8000Pa.mat');

[meanfMRn10g,SEMfMRn10g,regParamsn10g] = compareFTTC_BEM_FastBEM_fn('groupForce',10/100,...
'/home/sh268/Documents/TFM-simulation/n10g',[],forceMeshFastBEM,[],M_FastBEM,...
'/home/sh268/Documents/TFM-simulation/basisFunction500500E8000Pa.mat');

[pSRn5g,pSRerrn5g,regParamsn5g] = calculateForceFineMesh_fn('groupForce',5/100,...
    '/home/sh268/Documents/TFM-simulation/n5g',forceMeshFastBEM,[],M_FastBEM,[],...
    '/home/sh268/Documents/TFM-simulation/basisFunction500500E8000Pa.mat',...
    '/home/sh268/Documents/TFM-simulation/basisFunction500500E8000Pa.mat');

[pSRn5g100,pSRerrn5g100,regParamsn5g100] = calculateForceFineMeshImgScaled_fn(2,'groupForce',5/100,...
    '/home/sh268/Documents/TFM-simulation/n5g',forceMeshFastBEM,forceMeshFastBEMfine,M_FastBEM,M_FastBEMfine,...
    '/home/sh268/Documents/TFM-simulation/basisFunction500500E8000Pa.mat',...
    '/home/sh268/Documents/TFM-simulation/basisFunction250250E8000PaFine.mat');

%for desktop
matlabpool
[pSRn5g100,pSRerrn5g100,regParamsn5g100] = calculateForceFineMeshImgScaled_fn(2,'groupForce',5/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/n5g',[],[],[],[],...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction500500E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction250250E8000PaFine.mat');

[pSRn5g100small,pSRerrn5g100small,regParamsn5g100small] = calculateForceFineMeshImgScaled_fn(2,'groupForce',5/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/n5gsmall',[],[],[],[],...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction500500E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction250250E8000PaFine.mat');
[pSRn5g100smallol,pSRerrn5g100smallol,regParamsn5g100smallol] = calculateForceFineMeshImgScaled_fn(2,'groupForce',5/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/n5gsmallonelarge',[],[],[],[],...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction500500E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction250250E8000PaFine.mat');

[pSRn5g100smallmore,pSRerrn5g100smallmore,regParamsn5g100smallmore] = calculateForceFineMeshImgScaled_fn(2,'groupForce',5/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/n5gsmallmore',[],[],[],[],...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction500500E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction250250E8000PaFine.mat');

[pSRn5g100smallL,pSRerrn5g100smallL,regParamsn5g100smalL] = calculateForceFineMeshImgScaled_fn(2,'groupForce',5/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/n5gsmallL',[],[],[],[],...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction500500E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction250250E8000PaFine.mat');

[pSRn1g100smallwith1n,pSRerrn1g100smallwith1n,regParamsn1g100smallwith1n] = calculateForceFineMeshImgScaled_fn(2,'groupForce',1/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/n1gsmallwith1normRegularization',...
    forceMeshFastBEM,forceMeshFastBEMfine,M_FastBEM,M_FastBEMfine,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction500500E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction250250E8000PaFine.mat');

[pSRn1g150CG,pSRerrn1g150CG,regParamsn1g150CG] = calculateForceCG(3,'groupForce',1/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/n1g150CG',...
    [],[],[],[],...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction500500E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction250250E8000PaFine.mat');

[pSRn1g100with1n,pSRerrn1g100with1n,regParamsn1g100with1n] = calculateForceFineMeshImgScaled_fn(2,'groupForce',1/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/n1gwith1norm1e-3',...
    forceMeshFastBEM,forceMeshFastBEMfine,M_FastBEM,M_FastBEMfine,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction100100E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction100100E8000PaFine.mat');

[pSRn1g50with1n,pSRerrn1g50with1n,regParamsn1g50with1n] = calculateForceFineMeshImgScaled_fn(1,'groupForce',1/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/5050n1gwith1norm1e-3',...
    [],[],[],[],...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000PaFine.mat');

[pSRn1g50with1n1e_2,pSRerrn1g50with1n1e_2,regParamsn1g50with1n1e_2] = calculateForceFineMeshImgScaled_fn(1,'groupForce',1/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/5050n1gwith1norm1e-2',...
    forceMeshFastBEM,forceMeshFastBEMfine,M_FastBEM,M_FastBEMfine,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000PaFine.mat');

[pSRn1g50with1n1e_4,pSRerrn1g50with1n1e_4,regParamsn1g50with1n1e_4] = calculateForceFineMeshImgScaled_fn(1,'groupForce',1/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/5050n1gwith1norm1e-4',...
    forceMeshFastBEM,forceMeshFastBEMfine,M_FastBEM,M_FastBEMfine,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000PaFine.mat');

[pSRn1g50with1n1e_4tol5e_4,pSRerrn1g50with1n1e_4tol5e_4,regParamsn1g50with1n1e_4tol5e_4] = calculateForceFineMeshImgScaled_fn(1,'groupForce',1/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/5050n1gwith1norm1e-4tol5e_5',...
    forceMeshFastBEM,forceMeshFastBEMfine,M_FastBEM,M_FastBEMfine,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000PaFine.mat');

[pSRn1g50L,pSRerrn1g50L,regParamsn1gL] = calculateForceFineMeshImgScaled_fn(1,'groupForce',1/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/5050n1gL',...
    forceMeshFastBEM,forceMeshFastBEMfine,M_FastBEM,M_FastBEMfine,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000PaFine.mat');

[pSRn2g50L,pSRerrn2g50L,regParamsn2gL] = calculateForceFineMeshImgScaled_fn(1,'groupForce',2/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/5050n2gL',...
    forceMeshFastBEM,forceMeshFastBEMfine,M_FastBEM,M_FastBEMfine,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000PaFine.mat');

[pSRn5gL,pSRerrn5gL,regParamsn5gL] = calculateForceFineMeshImgScaled_fn(1,'groupForce',5/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/5050n5gL',...
    forceMeshFastBEM,forceMeshFastBEMfine,M_FastBEM,M_FastBEMfine,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000Pa.mat',...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000PaFine.mat');

testForceReconstruction('groupForce',1/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/5050n1g',...
    forceMeshFastBEMfine,M_FastBEMfine,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000PaFine.mat');

testForceReconstruction('groupForce',5/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/5050n5g',...
    forceMeshFastBEMfine,M_FastBEMfine,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000PaFine.mat');

testForceReconstruction('groupForce',5/100,...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/5050n5g',...
    [],[],...
    '/files/.retain-snapshots.d7d-w0d/LCCB/fsm/harvard/analysis/Sangyoon/TFM-Simulation/basisFunction5050E8000PaFine.mat');