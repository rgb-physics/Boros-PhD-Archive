% This script takes in pixel segmentations of  3D tifs containing
% nucleation of drops and generates individual drop objects based on each
% segmentation, tracking centers over time
%% Data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 24, Exp 1';
dataNameForm = 'Rescaled_Time%06i_acOpt_Probabilities Stage 2.h5';
selectTimes = 25;
chanSel = 2;
binNum = 15;

%% Load data
currData = h5read(fullfile(dataDir,sprintf(dataNameForm,selectTimes(1))),'/exported_data');
chanData = squeeze(currData(chanSel,:,:,:));

%% Roughly binarize, then get object centers and axes
roughBin = imbinarize(chanData);
propVals = regionprops3(roughBin,'Centroid','PrincipalAxisLength','Orientation');

%% Generate ellipsoidal point clouds at each center with appropriate axes
obj1Cen = table2array(propVals(1,1));
obj1Lens = table2array(propVals(1,3));
obj1Angs = table2array(propVals(1,2));

%% 



% distTr = bwdist(roughBin);
% [binCounts,binEdges] = histcounts(distTr,binNum);

% scaledDT = distTr/max(distTr(:));
% strelObj = strel('sphere',25);
% erodedDT = imerode(1-scaledDT,strelObj);