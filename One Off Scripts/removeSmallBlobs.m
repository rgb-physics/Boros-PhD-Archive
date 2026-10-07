% Quick script: filter through ID-ed blob tifs and sorted structures, using
% volumes to remove objects, save .tifs
% 2026-05-28 - Rémi Boros

% baseDir = '<redacted original absolute path>';
baseDir = 'Session 84';
filtDir = fullfile(baseDir,'Filtered Blobs - Segmentations');
baseName = 'T%03i_trajIDs.tif';
filtName = 'T%03i_filtIDs.tif';
dataMatDir = baseDir;
dataMatName = 'ALL_trajSorted_BlobVolsInts.mat';

allTimes = 1:50;
minVol = 200;

%% Load, remove, save
load(fullfile(dataMatDir,dataMatName));
volLogic = sortedMat(:,3) < minVol;

% Iterate over time, remove small objects
for tInd = 1:numel(allTimes)
%Load data
    currT = allTimes(tInd);
    currIDs = double(tiffreadVolume(fullfile(baseDir,sprintf(baseName,currT))));
% Isolate objects for current time
    tLogic = sortedMat(:,2) == currT;
    rmvInds = tLogic & volLogic;
    rmvIDs = sortedMat(rmvInds,1);
% Additionally, search for object IDs in image not stored in sortedMat
    allImgIDs = unique(currIDs(:));
    storedIDs = unique(sortedMat(tLogic,1));
    missingIDInds = ~(ismember(allImgIDs,storedIDs));
    missingIDs = allImgIDs(missingIDInds);
% Remove Blobs with "small" and "missing" IDs
    rmvBlobs = ismember(currIDs,[rmvIDs; missingIDs]);
    filtBlobs = consMatLnB(currIDs,~rmvBlobs);
% Save tif
    save3DTiff(uint16(filtBlobs),fullfile(filtDir,sprintf(filtName,currT)));

end

voxelVol = 1;
save(fullfile(filtDir,'metadata.mat'),'minVol','voxelVol')

