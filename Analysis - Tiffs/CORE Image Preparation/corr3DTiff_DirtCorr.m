% This script assumes no intensity rastering in z and relatively uniform
% intensity profile at early times. This script corrects for
%   - Dirt, non-uniform intensity profile
% Crop images, scale down for easier processing, (Ilastik) bright outlier
% detect, generate ill. profile, generate dirt image, (Ilastik) detect
% dirt, correct image intensity profiles (with dirt integrated, if
% possible); saves as 16bit and 8bit scaled down images. 

%% Input parameters
% Directory info
% homeDir = '<redacted original absolute path>';
homeDir = 'Session 88, Exp 1';
rawDir = fullfile(homeDir,'0 Raw Tifs');    
cropDir = fullfile(homeDir, '1 Cropped MATLAB');  
cropRescDir = fullfile(homeDir, '2 Cropped and Rescaled MATLAB'); 
outlierDir = fullfile(homeDir, '3 Ilastik Bright Removal');   
corrDir = fullfile(homeDir, '5 Illumination Corrected 16bit');     
corrDir8bit = fullfile(homeDir, '4 Illumination Corrected 8bit Downscaled');     
corrDirBleach = fullfile(homeDir, '6 Illumination Bleach Corrected 16bit');     
dirtDir = fullfile(homeDir,'Dirt Correction Base');

% File name info
rawName = 'Time%06i_raw560_E1.tif';
saveIndForm = 't%03i';      saveTagForm = '560';
croppedTag = 'cropped';
cropRescTag = 'cropRescale';
bgH5Tag = cropRescTag;          % Depends on what data you trained on
corrNameTag = 'illCorr16bit';
corr8bitTag = 'illCorr8bit';
corrBleachTag = 'illBleachCorr16bit';

% Select times to process
allTimes = 1:57;
bgTimes = 1:3;
dirtTimes = 2:3;
% Parameters for analysis
pixSize = 11*2/60;          % [.37 .37 .7]
voxDimRescale = [.52 .52 1];      % Used to ensure voxels are equally sized in x,y,z during image correction
% voxDimRescale = [0.3667 0.3667 1.5]/pixSize*1/2;      % Used to ensure voxels are equally sized in x,y,z during iamge correction
% ilastikTrainRescale = voxDimRescale/voxDimRescale(3);     % Builds off of scaling above to rescale images before Ilastik segmentation (smaller images -> faster segmentation)
ilastikTrainRescale = voxDimRescale*2/3;     % Rescale cropped images for Ilastik segmentation (smaller images -> faster segmentation)
coarseGridLen = 60;                         % Coarsegrain image for intensity correction
smallGFilt = 8; firstKern = 30;
% Image parameters
cropCorner = [5 15 1];
winSize = [750 735 101];
saveBool = 1;           % Save crop meta data
bitRescale = 10000;
cutOffs8bit = bitRescale*[.5, 3];
% Segmentation channel info
h5outChan = 2;
% Save every tif?
saveAll = 0;

%% Make directories and base name tags
corrDir8bit = fullfile(corrDir8bit,saveTagForm);
mkdir(cropDir); mkdir(cropRescDir); mkdir(outlierDir);  
% mkdir(corrDir);
mkdir(corrDir8bit); mkdir(corrDirBleach);   mkdir(dirtDir);
croppedName = sprintf('%s_%s_%s.tif',saveIndForm,croppedTag,saveTagForm);
cropRescName =  sprintf('%s_%s_%s.tif',saveIndForm,cropRescTag,saveTagForm);
bgH5Name =  sprintf('%s_%s_Probabilities_%s.h5',saveIndForm,bgH5Tag,saveTagForm);
corrName =  sprintf('%s_%s_%s.tif',saveIndForm,corrNameTag,saveTagForm);
corrName8bit =  sprintf('%s_%s_%s.tif',saveIndForm,corr8bitTag,saveTagForm);
corrNameBleach =  sprintf('%s_%s_%s.tif',saveIndForm,corrBleachTag,saveTagForm);

%% Crop and rescale images 
if saveAll == 1
    currRange = (allTimes);
else
    currRange = bgTimes;
end
for tInd = 1:numel(currRange)
    currT = currRange(tInd);
    currTif = tiffreadVolume(fullfile(rawDir,sprintf(rawName,currT)));
    currCrop = cropTiffSave(currTif, cropCorner, winSize, 1, fullfile(cropDir,sprintf(croppedName,currT)));
    currScaled = imresize3(currCrop, size(currCrop).*voxDimRescale);
    if tInd == 1
        int1 = sum(currScaled(:));
    end
    save3DTiff(currScaled, fullfile(cropRescDir, sprintf(cropRescName,currT)));

    if saveBool == 1
        save(fullfile(cropDir, "metadata.mat"), "cropCorner", "winSize", '-mat')
        save(fullfile(cropRescDir, "metadata.mat"), "cropCorner", "winSize", "voxDimRescale", '-mat')
    end

end

%% Generate illumination correction profile (using Ilastik prob fields to remove outlier bright points)
% Probability fields to find outlier bright points must be in 
% Ilastik Bright Remove Folder (3)      
tic
firstImg = double(tiffreadVolume(fullfile(cropDir, sprintf(croppedName, allTimes(1)))));
[~,rescNameCore] = fileparts(fullfile(cropRescDir,cropRescName));
outlierName = [rescNameCore '_Probabilities.h5'];
% outlierName = 't001_cropRescale_560_Probabilities.h5';    
%Iterate over time
for tInd = 1:numel(bgTimes)
    currT = bgTimes(tInd);
    currScaled =  double(tiffreadVolume(fullfile(cropRescDir,sprintf(cropRescName,currT))));
    imgDims = size(currScaled);
    % House cleaning
    if tInd == 1
        gridSpace = round(min(imgDims)/coarseGridLen);
        [gridX, gridY, gridZ] = ndgrid(1:gridSpace:imgDims(1), 1:gridSpace:imgDims(2), 1:gridSpace:imgDims(3));
        gridInds = sub2ind(imgDims, gridX, gridY, gridZ);
        strelObj = strel('sphere',1);
    end
    %Load data set 1
    if tInd == 1
        %Instantiate
        scaledDownTots = zeros(size(gridX));
        totFilts = zeros(imgDims);
        highInt = sum(currScaled(:));
        totCounts = scaledDownTots;
        totCounts2 = totFilts;
        bleachRate = 1:numel(bgTimes);
    end
    % Load outlier probabilities, then threshold
    selectProbs = imbinarize(loadH5(fullfile(outlierDir,sprintf(outlierName,currT)),'/exported_data',2),0.5);
    selectProbs = imdilate(selectProbs,strelObj);
    % Remove outliers, from an Ilastik-trained data set
    selScale = consMatLnB(currScaled,~selectProbs);  
    % Downsample to grid while retaining holes
    gridImg = imresize3(selScale,size(gridX),'nearest');
    % gridImg = double(reshape(selScale(gridInds(:)), size(gridX))); 
    %Store all data in matrices
    scaledDownTots(:,:,:,tInd) = gridImg;
    totCounts = totCounts + double(logical(gridImg));
    totFilts = totFilts + selScale*bitRescale*highInt/sum(currScaled(:));
    bleachRate(tInd) = bitRescale*highInt/sum(currScaled(:));
    totCounts2 = totCounts2 + double(logical(selScale));
end
toc

%% Average and fill in ill. corr. profile using scattered interpolant
% Takes a minute+
tic
meanFiltResc = sum(scaledDownTots,4)./totCounts; meanFiltResc(totCounts == 0) = 0;
meanFilt = totFilts./(totCounts2*bitRescale); meanFilt(totCounts2 == 0) = 0;
corrResc = fillin3D(meanFiltResc);
smoothCorrResc = imgaussfilt3(corrResc,smallGFilt);
corrMat = imresize3(smoothCorrResc,size(currScaled));
patchMat = consMatLnB(corrMat, ~logical(meanFilt));
toc

%% Store all tifs to be used for dirt detection, scaled to have uniform total intensity
for tInd = 1:numel(dirtTimes)
    currT = dirtTimes(tInd);
    currMat = double(tiffreadVolume(fullfile(cropDir,sprintf(croppedName,currT))));
    if tInd == 1
        % Generate storage matrix for all layers for dirt analysis
        layerStoreScale = zeros([size(firstImg),numel(dirtTimes)]);
    end
    layerStoreScale(:,:,:,tInd) = currMat*sum(firstImg,'all')/sum(currMat,'all');
end

% Generate matrices of intensities and background intensities
startMat = patchMat + meanFilt;
medInt = double(median(layerStoreScale,4));
bgCorr = imgaussfilt3(startMat,firstKern);
upBGCorr = imresize3(bgCorr, size(currMat));
medInt = medInt*sum(upBGCorr(:))/sum(medInt(:));
scaledBGCorr = double(upBGCorr)*sum(medInt(:))/sum(double(upBGCorr(:)));

%% New scheme: generate dirt detect image
% Changed - 2025/03/11
% Accentuate texture/small features
scaledStart = imresize3(startMat,size(scaledBGCorr));
claheMat = scaledStart./imgaussfilt3(scaledStart,2);
accentMat = claheMat.*scaledStart;
% Remove background illumination profile
gCorrMat = accentMat./imgaussfilt3(accentMat,round(min(size(patchMat))/3));
% Get mean intensity along z
meanMat = mean(gCorrMat,3);       
% Rescale intensities
scaledDirt = meanMat/max(meanMat(:))*255;
save3DTiff(uint8(scaledDirt), fullfile(dirtDir,sprintf('Dirt Training Tiff - %s.tif',saveTagForm)));

%%                                                                       %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ILASTIK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                       %%
%% After training saved tif in Ilastik with 2 step, load here
dirtChan = 2;
dirtProbs = h5read(fullfile(dirtDir,sprintf('Dirt Training Tiff - %s_Probabilities.h5',saveTagForm)),'/exported_data');
% dirtProbs = h5read(fullfile(dirtDir,sprintf('Dirt Training Tiff - %s_Probabilities.h5',saveTagForm)),'/exported_data');
selData = permute(squeeze(dirtProbs(dirtChan,:,:)),[2 1]);
logicMat = repmat(imbinarize(selData),[1 1 size(firstImg,3)]);
% logicMat = false(size(logicMat));

%% Combine dirt correction with illumination profile with median intensities at dirt locations (illum. prof. and med. intensity should be properly scaled by now)
dirtSample = consMatLnB(medInt,logicMat);
newCorr = consMatLnB(scaledBGCorr,~logicMat) + dirtSample;
% If using Ilastik to correct for bright spots, correct bright spots in
% dirt streaks
rescSelectProbs = imresize3(selectProbs,size(logicMat));
dirtBrightMat = ~imdilate((logicMat&rescSelectProbs),strel('sphere',2));
% newCorr = consMatLnB(newCorr,dirtBrightMat) + consMatLnB(scaledBGCorr,~dirtBrightMat);
save3DTiff(uint16(newCorr), fullfile(homeDir,sprintf('CorrectionMatrix_withDirt - %s.tif',saveTagForm)));

%% Temp - use 560 mask to patch 488
% % ogCorr = double(tiffreadVolume(fullfile('Session 63, Exp 4','CorrectionMatrix_withDirt - 560.tif')));
% tempBG = double(tiffreadVolume(fullfile('Session 32','t020_illBleachCorr16bit_647.tif')));
% test = imgaussfilt3(tempBG,50)/sum(tempBG(:));
% % bgTop = tempBG(:,)
% 
% % currCrop = cropTiffSave(tempBG, cropCorner, winSize, 0, '');
% cropTop = imgaussfilt(min(tempBG(:,:,5:6),[],3),25);
% cropBot = imgaussfilt(min(tempBG(:,:,(end-5):(end-3)),[],3),25);
% bgStack = cropTop;        bgStack(:,:,2) = cropBot;
% stackRS = imresize3(bgStack,size(tempBG));
% 
% currScaled = imresize3(currCrop, size(currCrop).*voxDimRescale);
% 
% tempDir = 'Session 63, Exp 4';
% img560 = 't001_cropRescale_560.tif';
% img488 = 't001_cropRescale_488.tif';
% temp1 = double(tiffreadVolume(fullfile(tempDir,img560)));
% temp2 = double(tiffreadVolume(fullfile(tempDir,img488)));
% % zScale = 
% testTop = imgaussfilt(min(temp2(:,:,2:3),[],3),25);
% testBot = imgaussfilt(temp2(:,:,end),25);
% testStack = testTop;        testStack(:,:,2) = testBot;
% stackRS = imresize3(testStack,size(ogCorr));
% newCorr = stackRS;

%% Load an old correction matrix
% newCorr = double(tiffreadVolume(fullfile(homeDir,sprintf('CorrectionMatrix_withDirt - %s.tif',saveTagForm))));

%% Iterate through time and save ill. corr. rescaled images
firstImg = double(tiffreadVolume(fullfile(cropDir, sprintf(croppedName, bgTimes(1)))));
for tInd = 1:numel(allTimes)
    currT = allTimes(tInd);
    if saveAll == 1
        currImg = double(tiffreadVolume(fullfile(cropDir, sprintf(croppedName, currT))));
    else
        currTif = tiffreadVolume(fullfile(rawDir,sprintf(rawName,currT)));
        currImg = double(cropTiffSave(currTif, cropCorner, winSize, 0));
    end
    currCorr = currImg./newCorr*bitRescale;
    bleachCorr = currCorr * sum(firstImg(:))/sum(currImg(:));
    currCorr8bit = max(0, bleachCorr - cutOffs8bit(1))*255/abs(diff(cutOffs8bit));
    rescaledCorr = imresize3(currCorr8bit, round(size(currCorr).*ilastikTrainRescale));
    % save3DTiff(uint16(currCorr), fullfile(corrDir, sprintf(corrName, currT)));
    save3DTiff(uint8(rescaledCorr), fullfile(corrDir8bit, sprintf(corrName8bit, currT)));
    save3DTiff(uint16(bleachCorr), fullfile(corrDirBleach, sprintf(corrNameBleach, currT)));
end

%% RETIRED
% %% median of scaled images
% % Retured - 2025/3/11
% % Gaussian smooth: final illumination profile
% bgCorr = imgaussfilt3(patchMat + meanFilt,firstKern);
% upBGCorr = imresize3(bgCorr, size(currMat));
% medInt = double(median(layerStoreScale,4));
% % medInt = medInt*sum(upBGCorr(:))/sum(medInt(:));
% scaledBGCorr = double(upBGCorr)*sum(medInt(:))/sum(double(upBGCorr(:)));
% 
% save3DTiff(uint16(upBGCorr), fullfile(homeDir,sprintf('CorrectionMatrix - %s.tif',saveTagForm)));
% 
% %% Find dirt over median image intensities over time
% % Retured - 2025/3/11
% tophatVals = median(LOG(medInt,4),3);
% scaledDirt = (tophatVals - min(tophatVals(:)))/max(max((tophatVals - min(tophatVals(:)))))*255;
% save3DTiff(uint8(scaledDirt), fullfile(dirtDir,sprintf('Dirt Training Tiff - %s.tif',saveTagForm)));