%% After running BlobInertiaTensorCalcs.m, plot data
% 2026-02-18 - Rémi Boros
expNum = 5;
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 88, Exp 5';
IVDir = fullfile(baseDir,'\AnisotropyStats');
IVName = 'trajSorted_BlobVolsInts.mat';
rAniDir = fullfile(baseDir,'\RMinStats');
rAniName = 'trajSorted_RMin_Anisotropy.mat';

rField = 'MinAxStats';
faField = 'FAs';
sphField = 'Sphs';

selTimes = 1:50;
% Load 
load(fullfile(baseDir,IVName));
load(fullfile(baseDir,rAniName));

% %% Iterate over time, average of objects, then avg again
% % Weight object mean values by inverse variance accounts for skeleton size
% allTimes = unique([statStruct.Frame]);
% % Instantiate storage vectors
% numObjs = zeros(1,numel(allTimes));
% meanRs = numObjs; medianRs = numObjs;
% meanFAs = numObjs;  meanSphs = numObjs;
% % sortedMat: [ID, Frame, Vol (um^3), Int]
% objMeanRsAll = zeros(numel(statStruct),4);
% % volFracBool = 1; 
% skelScale = 1;      % Scale by size of skeleton?
% startInd = 1;
% % Define lambda for pooled variance correction
% lambda = 0.3;
% 
% % Iterate over all times
% for tInd = 1:numel(allTimes)
% 
%     currT = allTimes(tInd);
%     % Filter by time
%     currLogic = [statStruct.Frame] == currT;
%     currStruct = statStruct(currLogic);
%     pooledVar = double(std(vertcat(currStruct(:).MinAxStats)).^2);
%     % currVols = sortedMat(currLogic,3);  
%     meanMat = zeros(4,numel(currStruct));   %[count, r, FA, sph]
%     varMat = meanMat;
%     temp = varMat;
%     for index = 1:numel(currStruct)
%         meanMat(1,index) = numel(currStruct(index).skelSubInds);
%         meanMat(2,index) = mean([currStruct(index).MinAxStats]);
%         meanMat(3,index) = mean([currStruct(index).FAs]);
%         meanMat(4,index) = mean([currStruct(index).Sphs]);
%         varMat(1,index) = numel(currStruct(index).skelSubInds);
%         varMat(2,index) = std([currStruct(index).MinAxStats]).^2;
%         varMat(3,index) = std([currStruct(index).FAs]).^2;
%         varMat(4,index) = std([currStruct(index).Sphs]).^2;
%         temp(1,index) = varMat(1,index);
%         temp(2,index) = std(currStruct(index).MinAxStats)/sqrt(temp(1,index));
%     end
%     corrVar = varMat(2,:)*lambda + (1-lambda)*pooledVar;
%     if skelScale == 1
%         % validVars = 
%         weightNorms = 1./corrVar;
%         normFact = sum(weightNorms);
%         weightedMeans = meanMat(2,:).*weightNorms/normFact;
%         % weightNorms = 1./(varMat(2,:).^2);
%         % weightedMeans = meanMat(2,:).*weightNorms;
%     end
%     stopInd = startInd + numel(currStruct) - 1;
%     objMeanRsAll(startInd:stopInd,:) = [meanMat(1,:); meanMat(2,:); [currStruct.Frame]; [currStruct.BlobID]]'; 
%     startInd = stopInd + 1;
%     % Calculate and store means
%     meanRs(tInd) = mean(meanMat(2,:));
%     medianRs(tInd) = median(meanMat(2,:));
%     meanFAs(tInd) = mean(meanMat(3,:));
%     meanSphs(tInd) = mean(meanMat(4,:));
% 
% end
% scatter(allTimes*.5,medianRs,'filled')

%% Iterate over time, store mean quantities
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 88';
saveName = sprintf('E%i_T1-50_MeanR.png',expNum);
allTimes = unique([statStruct.Frame]);
% Instantiate storage vectors
numObjs = zeros(1,numel(allTimes));
meanRs = numObjs; medianRs = numObjs;
meanFAs = numObjs;  meanSphs = numObjs;

% Iterate over all times
for tInd = 1:numel(allTimes)
    
    currT = allTimes(tInd);
    % Filter by time
    currLogic = [statStruct.Frame] == currT;
    currStruct = statStruct(currLogic);
    % Concatenate field values from all skeletons at current time
    concatRs = vertcat(currStruct.(rField));
    concatFAs = vertcat(currStruct.(faField));
    concatSphs = vertcat(currStruct.(sphField));
    % Calculate and store means
    meanRs(tInd) = mean(concatRs);
    medianRs(tInd) = median(concatRs);
    meanFAs(tInd) = mean(concatFAs);
    meanSphs(tInd) = mean(concatSphs);

end
scatter(allTimes*.5,meanRs,'filled');
set(gca,'FontSize',15)
box on
xlabel('Time (min)')
ylabel('Mean Radius (um)')
ylim([0 16])
title(sprintf('Exp %i',expNum));
% saveas(gcf,fullfile(saveDir,saveName));

%% Plot mean densities over time

allTs = unique(sortedMat(:,2));
rhoStore = zeros(2,numel(allTs));
for tInd = 1:numel(allTs)

    currT = allTs(tInd);
    tLogic = sortedMat(:,2) == currT;

    currCount = sum(tLogic);
    currInts = sortedMat(tLogic, 4);
    currVols = sortedMat(tLogic, 3);
    currRhos = currInts./currVols;
    rhoStore(1,tInd) = mean(currRhos);
    rhoStore(2,tInd) = std(currRhos)/sqrt(currCount);

end
errorbar(allTs*.5,rhoStore(1,:),rhoStore(2,:),'o','MarkerFaceColor',[1 0 0],'MarkerEdgeColor','none');
box on
xlabel('Time (min)')
ylabel('Density (units/um^3)')
set(gca,'FontSize',15)

%% Plot volume fraction occupied by objects over time
allTs = unique(sortedMat(:,2));
volFracs = zeros(1,numel(allTs));
imgSize = [750 735 94];     voxDims = [.55 .55 .7];
totalVol = prod(imgSize.*voxDims);
for tInd = 1:numel(allTs)

    currT = allTs(tInd);
    tLogic = sortedMat(:,2) == currT;

    currCount = sum(tLogic);
    currVols = sortedMat(tLogic, 3);
    sumVol = sum(currVols);
    volFracs(tInd) = sumVol/totalVol;

end
scatter(allTs*.5,volFracs,'filled','MarkerFaceColor',[0 0 0])
% errorbar(allTs*.5,rhoStore(1,:),rhoStore(2,:),'o','MarkerFaceColor',[1 0 0],'MarkerEdgeColor','none');
box on
xlabel('Time (min)')
ylabel('Volume Fraction (%)')
set(gca,'FontSize',15)

%% Distributions of object radii and densities at max density
minT = 16;      maxT = 36;
minTLogic = sortedMat(:,2) > minT;
maxTLogic = sortedMat(:,2) < maxT;
tLogic = minTLogic & maxTLogic;

subMat = sortedMat(tLogic,:);
uniqueIDs = unique(subMat(:,1));
for index = 1:numel(uniqueIDs)

    currID = uniqueIDs(index);
    idLogic = subMat(:,1) == currID;




end


%% BELOW IS OLD ARCHITECTURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 88, Exp 1';
% saveDir2 = '<redacted original absolute path>';
saveDir2 = 'Session 88, Exp 1';
if ~exist(saveDir,'dir')
    mkdir(saveDir);
    mkdir(saveDir2);
end
for tInd = 1:numel(selTimes)
% tInd = 1;
    currT = selTimes(tInd);
    % Load
    load(fullfile(dataDir,sprintf(dataName,currT)));
    load(fullfile(rminDir,sprintf(rminName,currT)));
    % Concatenate inertia data
    allBlobInds = [inertiaStore(:).BlobID];
    allSkelInds = [inertiaStore(:).SkelInd];
    allFAs = [inertiaStore(:).FracAni];
    allSphs = [inertiaStore(:).Sphericity];
    
    % Distributions
    [a,b]  = histcounts(allFAs, 0:.005:1);
    plot(b(2:end),a/sum(a));
    ylim([0 .15])
    xlim([0 1])
    title(sprintf('T%03i_FA.png',currT))
    saveas(gcf,fullfile(saveDir,sprintf('T%03i_AllBlobs_FA.png',currT)));

    % Distributions
    [a,b]  = histcounts(allSphs, 0:.01:1);
    plot(b(2:end),a/sum(a));
    ylim([0 .15])
    xlim([0 1])
    title(sprintf('T%03i_Sph.png',currT))
    saveas(gcf,fullfile(saveDir2,sprintf('T%03i_AllBlobs_Sph.png',currT)));
end

%% Plot various means
% Values averaged over all indices
% Values averaged over all indices in given blobs, then blob values
% averaged

meanFAs = zeros(1,numel(selTimes));
meanSphs = meanFAs;
meanRs = meanFAs;
for tInd = 1:numel(selTimes)
% tInd = 1;
    currT = selTimes(tInd);
    % Load
    load(fullfile(dataDir,sprintf(dataName,currT)));
    load(fullfile(rminDir,sprintf(rminName,currT)));
    % Concatenate inertia data
    allBlobInds = [inertiaStore(:).BlobID];
    allSkelInds = [inertiaStore(:).SkelInd];
    allFAs = [inertiaStore(:).FracAni];
    allSphs = [inertiaStore(:).Sphericity];
    % concat all rmin from this time
    allRs = vertcat(rMinStats(:).MinAxStats);
    % 
    temp1 = allFAs(~isnan(allFAs));
    temp2 = allSphs(~isnan(allSphs));
    temp3 = allRs(~isnan(allRs));
    meanFAs(tInd) = mean(temp1);
    meanSphs(tInd) = mean(temp2);
    meanRs(tInd) = mean(temp3);

end

%% Plot the averages
figure
ax = gca;
yyaxis left
scatter(selTimes/2,meanFAs,35,'MarkerFaceColor',[.7 .3 .3],'MarkerEdgeColor','none','Marker','diamond')
hold on
scatter(selTimes/2,meanSphs,35,'MarkerFaceColor',[.2 .6 .3],'MarkerEdgeColor','none','Marker','^')
ylim([0 1])
ylabel('Anisotropy Metrics')
yyaxis right
scatter(selTimes/2,meanRs,20,'MarkerFaceColor',[0.2 0 .8],'MarkerEdgeColor','none')
box on
ylabel('Mean R_{eff} (\mum)')
ylim([0 16])
xlabel('Time (min)')
ax.YAxis(1).Color = [0 0 0];
ax.YAxis(2).Color = [0 0 0];
set(gca,'FontSize',15)
title(sprintf('S88 Exp%s',dataDir(19)))

%% Average over objects first (?)
load(fullfile(baseDir,'sortedTraj_IntsVolsMinRs_ErodedScaled2.mat'),'sortedMat');
timeVecR = sortedMat(:,2);
objVecR = sortedMat(:,1);

for tInd = 1:numel(selTimes)
    
    currT = selTimes(tInd);
    % Load
    load(fullfile(dataDir,sprintf(dataName,currT)));

    for objInd = 1:numel(unqObjs)



    end


end

%%
% baseDirs = {'<redacted original absolute path>',...
baseDirs = {'Session 88, Exp 1',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 2',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 3',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 4',...
    % '<redacted original absolute path>'};
    'Session 88, Exp 5'};

loadName1 = 'trajSorted_BlobVolsInts.mat';
loadName2 = 'trajSorted_RMin_Anisotropy.mat';
selTimes = 1:50;

for dirInd = 1:numel(baseDirs)
    
    baseDir = baseDirs{dirInd};
    blobDir = fullfile(baseDir, '4 Tracked Blobs');

    % grab median vales
    load(fullfile(blobDir,loadName1));
    load(fullfile(blobDir,loadName2));
    
    unqIDs = unique([statStruct(:).BlobID]);

    medVals = zeros(size(sortedMat,1),3);
    % meanVals = zeros

    for index = 1:numel(statStruct)
        
        medVals(index,1) = median(statStruct(index).MinAxStats);
        medVals(index,2) = median(statStruct(index).FAs);
        medVals(index,3) = median(statStruct(index).Sphs);

    end

    % Average object stats over time (NOT weighted by size)
    meanVals = zeros(numel(selTimes),3);
    for tInd = 1:numel(selTimes)
        
        currT = selTimes(tInd);
        timeLogic = find(sortedMat(:,2) == currT);

        messyMat = [];
        for index = 1:numel(timeLogic)
            messyMat = [messyMat statStruct(timeLogic(index)).MinAxStats];


        end
        meanVals(tInd,:) = mean(medVals(timeLogic,:),1);


    end

    figure
    ax = gca;
    yyaxis left
    scatter(selTimes/2,meanFAs,35,'MarkerFaceColor',[.7 .3 .3],'MarkerEdgeColor','none','Marker','diamond')
    hold on
    scatter(selTimes/2,meanSphs,35,'MarkerFaceColor',[.2 .6 .3],'MarkerEdgeColor','none','Marker','^')
    ylim([0 1])
    ylabel('Anisotropy Metrics')
    yyaxis right
    scatter(selTimes/2,meanRs,20,'MarkerFaceColor',[0.2 0 .8],'MarkerEdgeColor','none')
    box on
    ylabel('Mean R_{eff} (\mum)')
    ylim([0 16])
    xlabel('Time (min)')
    ax.YAxis(1).Color = [0 0 0];
    ax.YAxis(2).Color = [0 0 0];
    set(gca,'FontSize',15)
    title(sprintf('S88 Exp%s',dataDir(19)))

end



%% 
% 
% unqBlobs = unique(allBlobInds);
% for index=  1:max(allBlobInds)
% 
% currBlob = unqBlobs(index);
% % test - load a blob
% % index = 1;
% currRs = rMinStats(index).MinAxStats;
% 
% currBlobInds = allBlobInds == currBlob;
% currFAs = allFAs(currBlobInds);
% currSphs = allSphs(currBlobInds);
% skelInds = allSkelInds(currBlobInds);
% 
% [a,b]  = histcounts(currFAs, 0:.01:1);
% plot(b(2:end),a/sum(a));
% ylim([0 .15])
% xlim([0 1])
% title(sprintf('T%03i_Blob%03i_FA.png',currT,currBlob))
% saveas(gcf,fullfile(saveDir,sprintf('T%03i_Blob%03i_FA.png',currT,currBlob)));
% 
% % look at statistics by blob
% 
% end
% 




