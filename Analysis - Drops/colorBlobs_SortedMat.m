%% Save tifs of blobs that are color coded
% Takes in directory of labeled blobs and some data structure attributing
% labeled IDs to corresponding colors (ie ID -> volume)
% 2025-01-23

% baseDir = '<redacted original absolute path>';
baseDir = 'Session 84';
blobDir = fullfile(baseDir,'Filtered Blobs - Segmentations');
blobName = 'T%03i_filtIDs.tif';
dataDir = baseDir;
dataName ='ALL_trajSorted_BlobVolsInts.mat';
saveDir = fullfile(baseDir,'Filtered Blobs - Binarized Blobs');

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

selectTimes = 1:50;
selCol = 3;

%% Load data
load(fullfile(dataDir,dataName));
% maxField = max(sortedMat(:,selCol));
for tInd = 1:numel(selectTimes)

    currT = selectTimes(tInd);
    currBlobs = tiffreadVolume(fullfile(blobDir,sprintf(blobName,currT)));

    dataRows = sortedMat(:,2) == currT;
    maxField = sum(sortedMat(dataRows,selCol));
    currFieldVals = sortedMat(dataRows,selCol)/maxField*65000;
    % currFieldVals = sortedMat(dataRows,selCol);
    currIDs = sortedMat(dataRows,1);                % Expected to already be sorted
    if isempty(currIDs)
        continue
    end
    mapVector = zeros(max(currIDs),1);
    % mapVector(unique(currIDs)) = currFieldVals;
    mapVector = [0; mapVector];
    mappedMat = currBlobs + 1;
    mappedMat = mapVector(mappedMat);
    save3DTiff(uint8(mappedMat),fullfile(saveDir,sprintf('T%06i.tif',currT)));
end

%% Toshi suggestion: big object one color, other descendents other

