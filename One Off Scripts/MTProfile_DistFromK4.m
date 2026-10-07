% Take in frame of K4 and MT data, threshold K4 data, distance transform,
% get radial protein profiles

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 3';
mtName = 'LATEZIPPER0000.png';
k4Name = 'LATEZIPPER0001.png';

threshVal = 5;
logKern = 2;
pixSize = .3667;
binVals = 0:0.25:20;

%% Load data
mtTif = double(imread(fullfile(dataDir,mtName)));
k4Tif = double(imread(fullfile(dataDir,k4Name)));

%% Process image
procImg = (LOG((mtTif),logKern));
bwMask = procImg > threshVal;
% bwMask = k4Tif > threshVal;

%% Distance transform
distMat = bwdist(bwMask)*pixSize;

%% Bin
[countVec,~,indMat] = histcounts(distMat,binVals);

%% Iterate over bins and store intensity info
mtAvg = zeros(numel(binVals),1);
k4Avg = zeros(numel(binVals),1);
mtSTD = zeros(numel(binVals),1);
k4STD = zeros(numel(binVals),1);

for index = 1:numel(binVals)

    currLogic = indMat == index;
    mtAvg(index) = mean(mtTif(currLogic));
    k4Avg(index) = mean(k4Tif(currLogic));
    mtSTD(index) = std(mtTif(currLogic));
    k4STD(index) = std(k4Tif(currLogic));

end

%% Plot

figure
plot(binVals,mtAvg,'LineWidth',2,'Color',[.1 .1 .1])
hold on
plot(binVals,k4Avg,'LineWidth',2,'Color',[55 130 255]/255)
box on
xticklabels({''});
yticklabels({''});

figure
imagesc(bwMask)
xticklabels({''});
yticklabels({''});

