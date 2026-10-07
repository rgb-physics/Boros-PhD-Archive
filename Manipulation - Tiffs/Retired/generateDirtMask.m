% %% Data dir
% dataDir = 'Session 24, Exp 1';
% dirtDir = 'Session 24, Exp 1';
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 28, Exp 6';
% dirtDir = '<redacted original absolute path>';
dirtDir = 'Session 28, Exp 6';
dataNameForm = 'Time%06i_16bitcropped.tif';
selectTimes = 1:5;
xyCorr_zSlices = 1:90;
gKernel = 50;
rollingWin = 1;

%% For data with flickering light data in z
[gaussFilt3D,avgBleach,layerStore] = generateGaussCorrectionMask_3DTiff(dataDir, dataNameForm, selectTimes, xyCorr_zSlices, gKernel, rollingWin, 0);

% Scale layerstore by gaussians
scaledArray = bsxfun(@rdivide, permute(layerStore,[1 2 4 3]), double(gaussFilt3D));
% Get min projection
minProj = min(min(scaledArray,[],3),[],4);
% Manipulate projection
% Multiply by gaussian blurred copy, then square
gaussCopy = imgaussfilt(minProj,1);
currImg = (minProj.*gaussCopy).^2;
% Gauss correct
gaussCopy = imgaussfilt(currImg, gKernel);
currImg = currImg./gaussCopy;
% Scale 
scaledProj = (currImg - min(currImg(:)))/max(max((currImg - min(currImg(:)))))*(2^15);

%% For data uniformally illuminated in z
layerStore = generate4DLayerStore_ZandT(dataDir,dataNameForm,xyCorr_zSlices,selectTimes);
gaussStore = zeros(size(layerStore,1), size(layerStore,2),numel(xyCorr_zSlices));
meanProj = squeeze(mean(layerStore,4));     %convert to one gaussian per z layer
for currZ = 1:numel(xyCorr_zSlices)
    gaussStore(:,:,currZ) = imgaussfilt(double(meanProj(:,:,currZ)), gKernel);
end
scaledArray = meanProj./gaussStore;
meanArray = mean(scaledArray,3);
minProj = min(meanArray,mean(meanArray(:)));
scaledProj = (minProj - min(minProj(:)))/max(max((minProj - min(minProj(:)))))*(2^15);

%% Save as 2D tiff
imwrite(uint16(scaledProj),fullfile(dirtDir, 'DirtMask.tif'));
% gauss blur in imagej (2pix), divide, gauss blurr (2pix), convert to 8bit
% after adjusting contrast
