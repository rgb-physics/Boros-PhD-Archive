%% Plots output data from C_fil2ObjAlignmentQTensor3D.m
% inOnOutDir = '<redacted original absolute path>';
inOnOutDir = 'Session 83';
inOnOutName = 'Time%06i_Probabilities_smoothbin.tif';

% filDataDir = '<redacted original absolute path>';
filDataDir = 'Session 83';
filDataName = 'Filament Statistics %03i.mat';
selFields3D = {'Centroid','Volume','PrincipalAxisLength','EigenVectors'};
% alignDataDir = '<redacted original absolute path>';
alignDataDir = 'Session 83';
alignDataName = 'Time%03i_alignData.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 83';
mdDir = filDataDir;
mdName = 'FilamentDetect_metadata.mat';

% sparseDir = '<redacted original absolute path>';
sparseDir = 'Session 83';
sparseName = 'Time%06i_raw647_Probabilities.tif';

% statsSaveDir = '<redacted original absolute path>';
statsSaveDir = 'Session 83';
statsSaveName = 'OutInOn_BinnedStats.mat';

selTimes = 2:40;
outInOn = [1 2 3];
binVals = [0 100 200 300];

numBins = numel(binVals) - 1;
minVol = 20; minAR = 1.5; minLength = 4; 

%% Load metadata
load(fullfile(mdDir,mdName));

%% Iterate through time, calculate things at each frame
meanMat = zeros(numBins,numel(selTimes));
stdMat = meanMat; numMat = meanMat;
outInOnIndices = struct();  strLabels = {'Out','In','On'};
filterStruct = struct();
for tInd = 1:numel(selTimes)

    % Load current data
    currT = selTimes(tInd);
    load(fullfile(filDataDir,sprintf(filDataName,currT)));
    load(fullfile(alignDataDir,sprintf(alignDataName,currT)));
    currSparse = tiffreadVolume(fullfile(sparseDir,sprintf(sparseName,currT)));
    currSparse = double(imresize3(currSparse,imgSize,'nearest'));
    currSegs = tiffreadVolume(fullfile(inOnOutDir,sprintf(inOnOutName,currT)));
    currSegs = imresize3(currSegs,imgSize,'nearest');

    % Bin segmentations, then map indices to match outInOn order
    [~,~,binInds] = histcounts(currSegs,binVals);
    if tInd == 1
        mapVec = [0 outInOn];
        xyzDims = [imgSize(2:-1:1) imgSize(3)];
        testStrel = strel('sphere',1);
    end
    binInds = mapVec(binInds+1);

    % Define logic to select for specific classes of filaments
    sizeFilt = [rp3D.Volume] > minVol;            % pixels (allVols)
    arFilt = [rp3D.AspectRatios] > minAR;      % Ratio major/minor axes (aspectRatio)
    lengthFilt = [rp3D.PrincipalAxisLength(:,1)] > minLength;       % pixels (majAxes)
    generalFilt = sizeFilt & arFilt & lengthFilt & filterLogic;
    
    filterStruct(tInd).filter = generalFilt;
    filterStruct(tInd).minVol = minVol;
    filterStruct(tInd).ARCut = minAR;
    filterStruct(tInd).minLen = minLength;

    % Get indices of centers of mass
    rndCoMs = round([rp3D.Centroid]);
    comInds = sub2ind(imgSize,rndCoMs(:,2),rndCoMs(:,1),rndCoMs(:,3));

    % Iterate through each bin, get order parameter statistics
    for index = 1:numBins
        currROI = find(binInds == index);
        domainLogic = ismember(comInds,currROI) & generalFilt;
        meanMat(index,tInd) = mean(tensorAligns(domainLogic));
        stdMat(index,tInd) = std(tensorAligns(domainLogic));
        numMat(index,tInd) = sum(domainLogic);
        outInOnIndices(tInd).(strLabels{index}) = find(domainLogic);
        outInOnIndices(tInd).Filter = generalFilt;
    end

end 
outInOnIndices = addFieldsStruct(outInOnIndices,{'Frame'},mat2cell(selTimes,1,numel(selTimes)));

%% Save statistics
save(fullfile(statsSaveDir,statsSaveName),'outInOnIndices','numMat','stdMat','meanMat','selTimes')

%% Load statistics
load(fullfile(statsSaveDir,statsSaveName));

%% Append order parameter to alignment statistic saved objects
figure
% binNums = .1:.1:(pi/2-.1);
selFrames = 2:50;
maxDim = 3;

% alignData = '<redacted original absolute path>';
alignData = 'Session 83';
alignName = 'Time%03i_alignData.mat';
% filDir = '<redacted original absolute path>';
filDir = 'Session 83';
filName = 'Filament Statistics %03i.mat';

allFrames = [outInOnIndices.Frame];

% Iterate through time, store dotFN and angleFN
for tInd = 1:numel(selFrames)
    currT = selFrames(tInd);
    roiTInd = allFrames == currT;
    load(fullfile(filDir,sprintf(filName,currT)), 'rp3D');          % Filament properties
    load(fullfile(alignData,sprintf(alignName,currT)),'bwGradAtCens');     % grads @ fil CoMs
    % Calculate dot product of filament director and surface normal
    currFils = [rp3D.Directors];
    currGrads = getUnitVecs(bwGradAtCens);
    dotFN2D = dot(currFils(:,1:2),currGrads(:,1:2),2);
    dotFN2D = sqrt(dotFN2D.^2);
    dotFN = dot(currFils,currGrads,2);
    dotFN = sqrt(dotFN.^2);
    % Get angle difference
    thetaFN2D = acos(dotFN2D);
    thetaFN = acos(dotFN);

    % Different order parameters
    orderParam = dotFN.^2 - 0.5;

    % Save
    save(fullfile(alignData,sprintf(alignName,currT)),"orderParam",'dotFN','thetaFN','dotFN2D','thetaFN2D','-append')

end

%% Histograms of angle diffs over time
figure
binNums = 40;
% binNums = .1:.1:(pi/2-.1);

allFrames = [outInOnIndices.Frame];
selFrames = [2 10 20 30 40];
dispStr = {'Out'};
% alignData = '<redacted original absolute path>';
alignData = 'Session 83';
alignName = 'Time%03i_alignData.mat';
deltaT = 0.5;
offSet = 4;
colorMat = othercolor('BuPu3',numel(selFrames)+offSet);
legLabels = cell(0);

for tInd = 1:numel(selFrames)
    currT = selFrames(tInd);
    storeInd = allFrames == currT;
    currLogic = outInOnIndices(storeInd).(dispStr{:});      % Already has general filter applied
    load(fullfile(alignData,sprintf(alignName,currT)),'dotFN','orderParam','thetaFN');

    % Histcounts
    [a,b] = histcounts(rad2deg(thetaFN(currLogic)),binNums);
    plot((b(1:(end-1)) + b(2:end))/2,a,'LineWidth',2);
    hold on

    hold on
    legLabels{tInd} = sprintf('%imin',round(deltaT*currT));
end

colororder(colorMat(offSet:end,:))
legend(legLabels)
xlabel('Separation Angle to Surface Normal (degrees)')
ylabel('Count')
set(gca,'FontSize',15)
xlim([0 90])

%% Mean + std order parameter over time
colorMat = min(1,[[100,0,100];  [230, 30, 165];  [0 180 100] ]/255); % watermelon
deltaT = .5;
meanMat = zeros(numBins,numel(selTimes));
stdMat = meanMat; numMat = meanMat;
strLabels = {'Out','In','On'};
allFrames = [outInOnIndices.Frame];
% Iterate over time 
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    storeInd = allFrames == currT;
    % Load alignData
    load(fullfile(alignData, sprintf(alignName,currT)),'orderParam','dotFN');
    % Iterate through each bin, get order parameter statistics
    for index = 1:numBins
        domainLogic = outInOnIndices(storeInd).(strLabels{index});
        meanMat(index,tInd) = mean(dotFN(domainLogic));
        stdMat(index,tInd) = std(dotFN(domainLogic));
        numMat(index,tInd) = sum(domainLogic);
    end
end

figure
filtMatLogic = numMat > 100;
filtMat = meanMat; filtMat(~filtMatLogic) = NaN;
% plot(timeVec,filtMat','LineWidth',2)
for index = 1:size(meanMat,1)
    currColor = colorMat(index,:);
    plotMeanStdPoly(filtMat(index,:),stdMat(index,:)./sqrt(numMat(index,:)),selTimes*deltaT,currColor,0.4,'black');
    % plotMeanStdPoly(filtMat(index,:),stdMat(index,:)./numMat(index,:),timeVec,currColor,0.4,'black');
end
xlabel('Time (min)')
ylabel('Average Alignment')
% legend(legLabels)
set(gca,'FontSize',15)
box on
% ylim([0 1])
xlim([0 20])
legend({'Out','In','On'})

% colororder(colorMat)
figure
plot(selTimes*deltaT,numMat','LineWidth',2)
xlabel('Time (min)')
ylabel('Number of Filaments')
% legend(legLabels{1:2:6})
set(gca,'FontSize',15)
colororder(colorMat)
legend({'Out','','In','','On'})


%% OLD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot order parameter
colorMat = min(1,[[100,0,100];  [230, 30, 165];  [0 180 100] ]/255); % watermelon
deltaT = .5;
figure
filtMatLogic = numMat > 100;
filtMat = meanMat; filtMat(~filtMatLogic) = NaN;
% plot(timeVec,filtMat','LineWidth',2)
for index = 1:size(meanMat,1)
    currColor = colorMat(index,:);
    plotMeanStdPoly(filtMat(index,:),stdMat(index,:)./sqrt(numMat(index,:)),selTimes*deltaT,currColor,0.4,'black');
    % plotMeanStdPoly(filtMat(index,:),stdMat(index,:)./numMat(index,:),timeVec,currColor,0.4,'black');
end
xlabel('Time (min)')
ylabel('Average Alignment')
% legend(legLabels)
set(gca,'FontSize',15)
box on
% ylim([0 1])
xlim([0 20])
legend({'Out','','In','','On'})

% colororder(colorMat)
figure
plot(selTimes*deltaT,numMat','LineWidth',2)
xlabel('Time (min)')
ylabel('Number of Filaments')
% legend(legLabels{1:2:6})
set(gca,'FontSize',15)
colororder(colorMat)
legend({'Out','','In','','On'})

%% Histograms of angles/alignments over time
figure
binNums = 40;
% binNums = .1:.1:(pi/2-.1);

allFrames = [outInOnIndices.Frame];
selFrames = [2 10 20 30 40];
dispStr = {'In'};
% alignData = '<redacted original absolute path>';
alignData = 'Session 83';
alignName = 'Time%03i_alignData.mat';
% filDir = '<redacted original absolute path>';
filDir = 'Session 83';
filName = 'Filament Statistics %03i.mat';
deltaT = 0.5;
offSet = 4;
colorMat = othercolor('BuPu3',numel(selFrames)+offSet);
legLabels = cell(0);

for tInd = 1:numel(selFrames)
    currT = selFrames(tInd);
    storeInd = allFrames == currT;
    currLogic = outInOnIndices(storeInd).(dispStr{:});
    load(fullfile(alignData,sprintf(alignName,currT)));
    load(fullfile(filDir,sprintf(filName,currT)));

    % Try calculating n x f' - n . f / 2 + 1/2 explicitly
    currFils = [rp3D.Directors];
    currGrads = getUnitVecs(bwGradAtCens);

    maxDim = 3;
    dotFN = dot(currFils(:,1:maxDim),currGrads(:,1:maxDim),2);
    dotFN = sqrt(dotFN.^2);
    [a,b] = histcounts(rad2deg(acos(dotFN(currLogic))),binNums);
    plot((b(1:(end-1)) + b(2:end))/2,a,'LineWidth',2);
    hold on

    hold on
    legLabels{tInd} = sprintf('%imin',round(deltaT*currT));
end
colororder(colorMat(offSet:end,:))
legend(legLabels)
xlabel('Separation Angle to Surface Normal (degrees)')
ylabel('Count')
set(gca,'FontSize',15)
xlim([0 90])

