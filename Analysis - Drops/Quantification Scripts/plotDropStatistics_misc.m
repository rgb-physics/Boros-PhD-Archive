%% Load data
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 35, Exp 1';
dataName = 'storageStruct_scaleFact2_blobKern2_threshVal3.900000e-03.mat';
% blobDir = '<redacted original absolute path>';
blobDir = 'Session 35, Exp 1';
blobFileName = 'BlobMat_Time%06i_16bit.tif';
load(fullfile(dataDir,dataName));
selectTimes = 1:numel(storeStruct);
pixSize = storeStruct(1).PixSize;
timeSize = 30;

%% NEEDS SORTING AND CONSOLIDATING
%%

pixSize = 1.1;  %um
timeSize = 30;  %s

% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Count objects and get mean info
allCounts = zeros(numel(selectTimes),1);
maxVals = allCounts;
allMeans = allCounts;
allVars = allCounts;
numObjs = allCounts;
% figure
% hold on
for currT = 1:numel(selectTimes)

    currVols = storeStruct(currT).Vol*(pixSize^3);
    numObjs(currT) = numel(currVols);
    allCounts(currT) = numel(currVols);
    maxVals(currT) = max(currVols).^(1/3);
    allMeans(currT) = mean(currVols.^(1/3));
    allVars(currT) = std(currVols.^(1/3))/sqrt(numObjs(currT));

end
figure
scatter(selectTimes*timeSize, allMeans,'filled')
hold on
errorbar(selectTimes*timeSize, allMeans, allVars, 'o');
% scatter(selectTimes, maxVals, 'b')
set(gca, 'FontSize', 15)
xlabel('Time (s)')
ylabel('Mean radius (um)')
title('Mean drop radius over time')

%% Plot Distributions
binNum = 100;
currSelect = 1:20;
binStore = zeros(binNum, numel(currSelect));
edgeStore = zeros(binNum+1, numel(currSelect));
colorsMap = meldNcolors([0 0 1; 1 0 0], binNum);

figure
for currT = 1:numel(currSelect)
    
    currVols = storeStruct(currSelect(currT)).Vol*(pixSize^3);
%     currMin = max(0,(mean(currVols(:)) - 5*std(currVols(:))));
%     currMax = (mean(currVols(:)) + 5*std(currVols(:)));
    currMin = 300*pixSize^3;
    currMax = 20000*pixSize^3;
    edgeStore(:,currT) = currMin:(currMax-currMin)/binNum:currMax;
    binStore(:,currT) = histcounts(currVols(:),edgeStore(:,currT));

%     plot(edgeStore(2:end,currT), binStore(:,currT), 'Color', [currT/numel(currSelect) 0 (1-currT/numel(currSelect))],'LineWidth',max(1,5*(1-currT/numel(currSelect))));
%     plot(edgeStore(2:end,currT), binStore(:,currT)/mean(binStore(:,currT)), 'Color', [currT/numel(currSelect) 0 (1-currT/numel(currSelect))]);
    area(edgeStore(2:end,currT), binStore(:,currT), 'FaceColor', [currT/numel(currSelect) 0 (1-currT/numel(currSelect))]);
%     area(edgeStore(2:end,currT), binStore(:,currT)/sum(binStore(:,currT)), 'FaceColor', [currT/numel(currSelect) 0 (1-currT/numel(currSelect))]);
    hold on
    
end
colorbar
colormap(colorsMap)

%% Plot number of objects over time
figure
scatter(selectTimes*timeSize, numObjs,'filled')
xlabel('Time (s)')
ylabel('Number of objects')
set(gca, 'FontSize', 15)

%% Compare median and mean object volume
figure
skipFirst = 4;
medVols = allCounts;
meanVols = allCounts;
hold on
for currT = 1:50

    currVols = storeStruct(currT).Vol*(pixSize^3);
    medVols(currT) = median(currVols);
    meanVols(currT) = mean(currVols);

end
scatter(skipFirst:numel(medVols),medVols(skipFirst:end),'filled','r')
scatter(skipFirst:numel(meanVols),meanVols(skipFirst:end),'filled','b')
xlabel('Time (frame)')
ylabel('Volume (um^3)')
set(gca, 'FontSize', 15)
legend('Median volumes', 'Mean volumes')

%% Level sets of distance
distMat = bwdist(newBlobMat);
invDistMat = bwdist(~newBlobMat);
fullDistMat = invDistMat - distMat;

%%
levelSetVal = 2;
levelMat = consMatLnB(ones(size(fullDistMat)), round(fullDistMat) == levelSetVal);

%% Count number of elements below threshold volume
threshVol = 300;
colorsMap = meldNcolors([0 0 1; 1 0 0], numel(threshVol));
figure
hold on
for currThresh = 1:numel(threshVol)
    smallVals = zeros(1,numel(selectTimes));
    for currT = 1:numel(selectTimes)
        
        currVols = storeStruct(currT).Vol;
        smallVals(currT) = sum(sum(sum(currVols <= threshVol(currThresh))));
    
    end
    % figure
%     scatter(selectTimes,numObjs'-smallVals,20,[currThresh/numel(threshVol) 0 (1 - currThresh/numel(threshVol))],'filled')
    area(selectTimes,numObjs'-smallVals,'FaceColor',colorsMap(currThresh,:))
    xlabel('Time (frame)')
    ylabel('Count')
    title(sprintf('Cut off value %i',threshVol(currThresh)));
    set(gca,'FontSize',15)
end
%     histogram(currVols, 'DisplayStyle','stairs')

%% Plot mean volume over time
meanVols = zeros(numel(storeStruct),1);
stdVols = meanVols;
for tInd = 1:numel(storeStruct)
    meanVols(tInd) = mean(storeStruct(tInd).Vol);
    stdVols(tInd) = std(storeStruct(tInd).Vol);
end
scatter(selectTimes*timeSize, meanVols*pixSize^3, 'filled')
xlabel('Time (s)')
ylabel('Mean volume (um^3)')
set(gca,'FontSize', 15)
title('Mean Volume over time')
% errorbar(selectTimes*timeSize, meanVols*pixSize^3, stdVols'*pixSize^3./sqrt(numObjs), '.')
