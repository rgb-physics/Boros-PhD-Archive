%% This function takes in the height and intensity profiles of layers and correlates them
% field1Dir = '<redacted original absolute path>';
field1Dir = 'Session 25, Exp 5';
field2Dir = '';
field1Name = 'BotSurface_heightInfo.tif';
field2Name = '';
ringBin = 165;       %Number of bins to average over radially 
numBins = 30;       %Number of bins to split log of structure factor into
subWin = 165;       %window size of inner region to query
pixelScale = 11*4/60;
selectTimes = 1:100;

%% Load data
fieldData = double(tiffreadVolume(fullfile(field1Dir,field1Name)));
fieldDims = size(fieldData);
subWin = min(subWin, min(fieldDims(1:2)/2));

%% Shift field vals about 0
meanField = mean(mean(fieldData,1),2);
shiftedField = double(fieldData) - repmat(meanField, [size(fieldData,1), size(fieldData,2) 1]);

%% Iterate over time and get spatial correlation per time point
allMeanCorrs = zeros(ringBin, size(fieldData,3));
for currT = 1:size(fieldData,3)
    allMeanCorrs(:,currT) = radialAutoCorr(shiftedField(:,:,currT), ringBin, subWin);
end

%% Plot over time
figure
for index = 1:size(allMeanCorrs,2)
    plot(pixelScale*(1:size(allMeanCorrs,1)),allMeanCorrs(:,index),'Color',[index/size(allMeanCorrs,2) 0 (1 - index/size(allMeanCorrs,2))])
    hold on
end
xlabel('\Deltar(x,y) (um)')
ylabel('Radially averaged spatial autocorrelation in h (normalized)')
set(gca,'FontSize',15)


%% Get static structure factor averaged over all times
sfTensor = zeros(2*subWin+1,2*subWin+1,numel(selectTimes));
radialTensorStatic = repmat( generateRadialMatrix( [2*subWin+1 2*subWin+1], ringBin ), [1 1 numel(selectTimes)]);
radialMat = generateRadialMatrix(size(structFact),ringBin);
% Generate structure factors at each time and store in structure factor tensor
for currT = 1:numel(selectTimes)
    %Generate factor for current t
    currField = shiftedField(:,:,selectTimes(currT));
    sfTensor(:,:,currT) = generateStaticStructureFactor(currField,subWin);
end
% Average radially over all times
meanSF = zeros(numBins,1);
for currBin = 1:ringBin
    meanSF(currBin) = mean(sfTensor( radialTensorStatic == currBin ), 'all');
end

%% Plot loglog structure factor and logbin to appropriately view slopes
winSize = size(structFact,1)*pixelScale;
binSpacing = winSize/2 * 1/ringBin;        %Max window/2 scaled by pixel size and divided by number of bins
waveNums = (1:ringBin)*1/(winSize/2);
[logMeanWaveNums, logMeanSFs] = loglogBin(waveNums,meanSF,numBins);

colorVec = 1:numel(logMeanSFs);

figure
subplot(1,2,1)
% plot(log(waveNums), log(meanSF));
loglog(waveNums,meanSF);
hold on
% scatter((logMeanWaveNums), (logMeanSFs),'filled')
scatter(exp(logMeanWaveNums),exp(logMeanSFs),40,colorVec,'filled')
set(gca,'FontSize',15)
xlabel('Log Wave Number (1/um)')
ylabel('Log Structure Factor')

subplot(1,2,2)
approxSlopes = diff(logMeanSFs)./diff(logMeanWaveNums);
% scatter(logMeanWaveNums(2:end)/log(10),approxSlopes,'filled')
scatter(exp(logMeanWaveNums(2:end)),movmean(approxSlopes,3),40,colorVec(2:end),'filled')
set(gca,'XScale','log','FontSize',15)
xlabel('Log Wave Number (1/um)')
ylabel('Structure Factor Slope')

% moving average data
% avgedLogMeanSFs = movmean(logMeanSFs,4);
% approxSlopes = diff(avgedLogMeanSFs)./diff(logMeanWaveNums);

%% Plot static structure factor for each time separately
%Radially average
meanSFAll = zeros(ringBin,numel(selectTimes));
figure
for currT = 1:numel(selectTimes)
    for currBin = 1:ringBin
        [rows2D, cols2D] = ind2sub(size(radialMat), find(radialMat == currBin));
        inds3D = sub2ind(size(radialTensorStatic), rows2D(:), cols2D(:), currT*ones(numel(rows2D),1));
        meanSFAll(currBin,currT) = mean(sfTensor( inds3D ), 'all');
    end
    loglog(meanSFAll(:,currT),'Color',[currT/numel(selectTimes) 0 (1 - currT/numel(selectTimes))])
    hold on
end
set(gca,'XScale','log','FontSize',15)
xlabel('Log Wave Number (1/um)')
ylabel('Log Structure Factor')


%% 
