%% This script prepares spinning disk data for analysis in Ilastik
%It is assumed that images have been split into 3D single channel tifs
%before running. After this, the script removes rastering in z (pertinent
%for spinning disk 647 data), corrects for intensity variations in x-y
%using gaussian blurring, corrects for bleaching over time, and removes
%dirt. A set of 8bit 3D tifs are saved optimized for active contouring by
%scaling doubles by values inputted by the user and a 16bit set containing
%all data are saved

%NOTE: Consider correcting intensity by using a single gaussian
%illumination, scaled in time by the bleach rate and in z by the median
%intensity profile. Do this ONLY for 8bit images for segmentation
%facilitation. For no data loss images, scale by the profile with no
%changes for z or t and then deconvolve for z kernel adjustment (or
%visaversa). Leave time changes alone as they are real potentially.
%Consider accounting for bleaching after the fact

%% Data directory info
%Data info
% basePath = '<redacted original absolute path>';
basePath = 'Session 32';
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 32';
% dataDir = fullfile(basePath, 'Cropped Split Tifs');
dataNameForm = 'Time%06i_raw647.tif';
acSaveDir = fullfile(basePath,'Ilastik Optimized 8bit');
acSaveName = 'Time%06i_acOpt.tif';
noDataLossDir = fullfile(basePath, 'Corrected 16bit Split Times');
noDataLossName = 'Time%06i_16bit.tif';
%Path for dirt correction (Ilastik pixel segmentation is used)
% DirtPath = '<redacted original absolute path>';
DirtPath = 'Session 28, Exp 6';
DirtName = 'DirtMask_Object Predictions.h5';

%Parameter info
selectTimes = 1:200;
subSampleTimes = 1:5;
%Parameters for raster correction
rastCorr = 1;
polyDeg = 20;       %used for fitting for raster correction
rastSaveDir = fullfile(basePath,"Raster Corrected");
rastSaveName = 'Time%06i_rastCorr.tif';
%Parameters for xy gaussian correction
xyCorr_zSlices = 1:90;
rollingWin = 1;
gKernel = 50;       %Kernel size for gaussian blurring
mKernel = 50;       %Kernel size for median neighborhood blurring
lKernel = 2;        %Kernel size for top hat
outlierSigma = 4;   %Number of sigma from mean for which data is considered an outlier (in raw data)
strelKern = 2;
scaleStrel = strel("sphere",strelKern);
%Parameters for image rescaling to 8bit
min8bit = .3;
max8bit = .9;
min16bit = 0;
max16bit = 1.8;
downScale8bit = 2;
%Parameters for dirt removal/object classification info
objChanNum = 1;

%% Generate directories
mkdir(acSaveDir)
mkdir(noDataLossDir)

%% Section A: Raster Correction
if rastCorr == 1
    mkdir(rastSaveDir)
    %Iterate through time
    for currT = 1:numel(selectTimes)
    
        %load a tif
        currTif = tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm,selectTimes(currT))));
    
        %Deraster
        deRastered = rasterCorrectionZ_3DTiff(currTif, polyDeg, 1, fullfile(rastSaveDir,sprintf(rastSaveName,selectTimes(currT))));
    end
end

%% Section B: Prepare for Dirt Removal and Gaussian XY Correction
%Define gaussian filter to be applied to images
if rastCorr == 1
    [gaussFilt3D,avgBleach] = generateGaussCorrectionMask_3DTiff(rastSaveDir, rastSaveName, selectTimes, xyCorr_zSlices, gKernel, rollingWin, 0);
else
    layerStore = generate4DLayerStore_ZandT(dataDir,dataNameForm,xyCorr_zSlices,subSampleTimes);
%     meanProj = squeeze(mean(layerStore,4));     %convert to one gaussian per z layer
    gaussFilt3D = generateGaussCorrectionPerZ(layerStore, outlierSigma, gKernel, mKernel, lKernel);
end

%% Section C: Dirt Removal and Gaussian XY Correction + Rescaling
% Load and define dirt voxels and data voxels
DirtData = squeeze(h5read(fullfile(DirtPath,DirtName),'/exported_data'))';
% DirtData = squeeze(DirtData(objChanNum,:,:))';
DirtData(DirtData~=objChanNum) = 0;
DilDirt = imdilate(DirtData, scaleStrel);
[xDirt, yDirt] = find(DilDirt == objChanNum);
[xData, yData] = find(DilDirt == 0);
tic
%Iterate through frames
for currT = 1:numel(selectTimes)

    %Load current time point
    if rastCorr == 1
        currTiff = double(tiffreadVolume(fullfile(rastSaveDir, sprintf(rastSaveName,selectTimes(currT)))));
        currGauss = gaussFilt3D(:,:,currT);
        currGauss3D = double(repmat(currGauss, [1 1 size(currTiff,3)]));    
    else
        currTiff = double(tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm,selectTimes(currT)))));
        currGauss3D = gaussFilt3D;
    end

    %%%% DIRT REMOVAL
    %Using scatteredInterpolant objects, remove dirt
    for currZ = 1:size(currTiff,3)
        currDataInds = sub2ind(size(currTiff), xData, yData, currZ*ones(numel(xData),1));
        currDirtInds = sub2ind(size(currTiff), xDirt, yDirt, currZ*ones(numel(xDirt),1));
        currData = double(currTiff(currDataInds));
        interpObj = scatteredInterpolant(xData(:), yData(:), currData(:));
        currTiff(currDirtInds) = interpObj(xDirt, yDirt);
    end

    %%%% GAUSSIAN CORRECTION
    %Apply Gaussian correction
    scaledImg = currTiff./currGauss3D;

    %Scale for 8bit conversion
    maxVal = max8bit;
    minVal = min8bit;

    boundedImg = max(min(scaledImg, maxVal), minVal);
    zeroedImg = boundedImg - minVal;
    rescaledImg = zeroedImg/max(zeroedImg(:));
    acPreppedImg = imresize3(uint8(rescaledImg*255),1/downScale8bit);

    %Scale for 16bit conversion
    maxVal = max16bit;
    minVal = min16bit;

    boundedImg = max(min(scaledImg, maxVal), minVal);
    zeroedImg = boundedImg - minVal;
    rescaledImg = zeroedImg/max(zeroedImg(:));
    allInfoImg = uint16(rescaledImg*(2^15-1));

    %%%% SAVE DATA
    savePathAC = fullfile(acSaveDir,sprintf(acSaveName,selectTimes(currT)));
    savePathAll = fullfile(noDataLossDir,sprintf(noDataLossName,selectTimes(currT)));
    save3DTiff(acPreppedImg, savePathAC)
    save3DTiff(allInfoImg, savePathAll)

end
toc
% Is it worth doing this for 20x data? Is it worth doing this for 60x
% droplet data?