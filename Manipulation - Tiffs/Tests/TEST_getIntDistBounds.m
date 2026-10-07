%% This function uses the function LOG found in Sebastian Streichan's imasne repository
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 28, Exp 6';
% dirtDir = '<redacted original absolute path>';
dirtDir = 'Session 28, Exp 6';
dataNameForm = 'Time%06i_16bitcropped.tif';
selectTimes = 1:5;
dataTime = 150;
xyCorr_zSlices = 1:90;
gKernel = 15;
medianKernel = 50;
saveBool = 1;
selChan = 2;

%% Store all layers requested
layerStore = generate4DLayerStore_ZandT(dataDir,dataNameForm,xyCorr_zSlices,selectTimes);
storeDims = size(layerStore);

%% Intensity per layer over time
meanProj = squeeze(mean(layerStore,4));     %convert to one gaussian per z layer

%% Load test image
testIm = tiffreadVolume(fullfile(dataDir,sprintf(dataNameForm,dataTime)));

%%
if saveBool == 1

    save3DTiff(im2uint8(uint16(2*meanProj)), fullfile(dirtDir, 'MeanBG8bit.tif'));

end

%% Read .h5
currProbs = h5read(fullfile(dirtDir,'MeanBG8bit_Probabilities.h5'),'/exported_data');
selProbs = permute(squeeze(currProbs(selChan,:,:,:)),[2 1 3]);
outlierInds =  imbinarize(selProbs,.3);
subSel = consMatLnB(meanProj,~outlierInds);

%% Tophat filter for outliers
% gradsMat = LOG(meanProj,2);

%% Use local median to replace bright outliers
% outlierInds = imbinarize(meanProj, brightThresh);
% outlierInds = (gradsMat>10) | (gradsMat<-200);
locMedMat = movmedian(movmedian(movmedian(meanProj,medianKernel, 1),medianKernel,2),medianKernel,3);

%% Multiple loops to correct
corrMat = meanProj;
corrMat(outlierInds) = locMedMat(outlierInds);

%% Generate gaussians
gaussStore = zeros(size(layerStore,1), size(layerStore,2),numel(xyCorr_zSlices));
for currZ = 1:numel(xyCorr_zSlices)
    gaussStore(:,:,currZ) = imgaussfilt(double(corrMat(:,:,currZ)), gKernel);
end

%% Gauss Corr
gaussCorr = meanProj./gaussStore;

%% Find dirt
dirtMat = median(LOG(gaussCorr,2),3);
scaledDirt = (dirtMat - min(dirtMat(:)))/max(max((dirtMat - min(dirtMat(:)))))*255;

%% Save
imwrite(uint8(scaledDirt),fullfile(dirtDir, 'DirtMask.tif'));
