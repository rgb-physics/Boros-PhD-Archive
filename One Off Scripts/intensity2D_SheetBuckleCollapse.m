%% Roughly estimate intensity statistics in sheet during buckle/collapse
% Cropped image, then segmented
% Data sets are 2D cross sections, preferably in x-z or y-z
% 2025-08-07 - Rémi Boros
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 25, Exp 5';
imgName = 'buckle_collapse_T%03i.tif';
segDir = fullfile(imgDir,'Segmentation');
segName = 'buckle_collapse_T%03i_Probabilities.h5';

% To estimate intensity conversion
% Load large fov over several times, then average total intensities over
% time. Divide by the size of the fov (assume cubic/square voxels)
% corrDir = '<redacted original absolute path>';
corrDir = 'Session 25, Exp 5';
corrImg = 'sideSlice_x1-338_y362_scaledDATA.tif';
tempImg = tiffreadVolume(fullfile(corrDir,corrImg));
intRho =  mean(squeeze(sum(sum(tempImg,1),2)))/prod(size(tempImg,[1 2]));
% Enter the total tubulin concentration
baseRho = 35;           %uM
% The ratio of tubulin concentration to mean intensity gives I units -> uM
int2uM = baseRho./intRho;

% Other parameters
selTimes = 0:49;
h5Chan = 2;
h5Thresh = 0.6;

%% Iterate through time, store images and segmenations (each is 2D)
for tInd = 1:numel(selTimes)
% Load
    currT = selTimes(tInd);
    currTif = tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT)));
    currSeg = loadH5(fullfile(segDir,sprintf(segName,currT)),'/exported_data',h5Chan);
% Store in matrix
    if tInd == 1
        storeImgs = zeros([size(binSeg) numel(selTimes)]);
        storeSegs = storeImgs;
    end
    storeImgs(:,:,tInd) = currTif;
    storeSegs(:,:,tInd) = currSeg;
end

%% statistics
% Split segmentations in sheets and backgrounds
logicMat = imbinarize(storeSegs,h5Thresh);

% Clean up logicMat
connObjs = bwconncomp(logicMat);
objVols = regionprops3(logicMat,'Volume');
[~,lrgObj] = max(table2array(objVols));
logicMat = logical(consMatLnB(ones(size(logicMat)),connObjs.PixelIdxList{lrgObj}));

subSamp = consMatLnB(storeImgs,logicMat);
bgSamp = consMatLnB(storeImgs,~logicMat);
% Get volumes of sheets at each time
sheetVols = squeeze(sum(sum(logicMat,1),2));
fovVol = prod(size(logicMat,[1 2]));

% Sample intensities
totInts = squeeze(sum(sum(storeImgs,1),2));
sheetInts = squeeze(sum(sum(subSamp,1),2));
bgInts = squeeze(sum(sum(bgSamp,1),2));

% Mean densities
sheetRho = sheetInts./sheetVols*int2uM;
bgRho = bgInts./(fovVol - sheetVols)*int2uM;
meanRhoTot = totInts./fovVol*int2uM;

%% Plot densities over time
deltaT = 0.5;
figure
scatter(selTimes*deltaT, sheetRho, 46, [.2 .2 .6],'*')
hold on
scatter(selTimes*deltaT, bgRho, 46, [.6 .2 .2],'x')
% scatter(selTimes*deltaT, meanRhoTot, 32, [.2 .2 .2], 'filled')
box on
xlabel('Time (+min)')
ylabel('[MT] (uM)')
legend('In Sheet','Background')
xlim([0 max(selTimes)*deltaT])
ylim([25 90])

% Fractional density change over time
% 1) estimate equilibrated density difference
meanDiff = mean(sheetRho(1:20)-bgRho(1:20));
% Plot
figure
% plot(selTimes*deltaT,movmean((sheetRho-bgRho)/meanDiff,4),'black')
% hold on
scatter(selTimes*deltaT,(sheetRho-bgRho)/meanDiff,26,[.2 .2 .2],'filled')
box on
xlabel('Time (+min)')
ylabel('Isheet-Ibg/Isheet-Ibgo')

%% compare heights of sheet over time
heightMat = repmat((1:size(logicMat,1))',1,size(logicMat,2));
meanProfiles = squeeze(nonZeroMean(logicMat.*heightMat,1));
% meanH = mean(meanProfiles,'all');
meanH = 60;

pkHs = max(meanH-meanProfiles,[],1);
valleyHs = min(meanH-meanProfiles,[],1);

figure
test = colormap('parula');
% plot( - meanProfiles(:,1:2:end))
plot(meanH - meanProfiles(:,1:2:end))
colororder(test(1:6:end,:))

%% Plot peaks, valleys, with rho

figure

yyaxis right
plot(selTimes*deltaT,movmean(pkHs,4),'black')
hold on
plot(selTimes*deltaT,movmean(valleyHs,4),'black')
ylabel('Distance from H_o')
temp = gca;
temp.YColor = 'black';

yyaxis left
scatter(selTimes*deltaT, sheetRho, 46, [.2 .2 .6],'*')
hold on
scatter(selTimes*deltaT, bgRho, 46, [.6 .2 .2],'x')
% scatter(selTimes*deltaT, meanRhoTot, 32, [.2 .2 .2], 'filled')
temp = gca;
temp.YColor = 'black';
box on
xlabel('Time (+min)')
ylabel('[MT] (uM)')
legend('In Sheet','Background')
xlim([0 max(selTimes)*deltaT])
ylim([20 100])


legend('In Sheet','Background','Peak Height','Valley Depth')