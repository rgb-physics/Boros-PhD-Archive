%% Data directories
% labeledDir = '<redacted original absolute path>';
labeledDir = 'Session 84';
labeledName = 'BlobMat_t%03i_inheritedLabels.tif';
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 84';
imgName = 't%03i_illBleachCorr16bit_560.tif';

selectTimes = 25;
imgVoxSize = [.55 .55 .7];         % in um/pix
% imgVoxSize = [1.1 1.1 1.5];         % in um/pix
timeStep = 30/60;                          % Sec/frame
rBins = 1:100;

%% Iterate over times
storageStruct = struct();
binMat = zeros(numel(selectTimes),numel(rBins)-1);
for tInd = 1:numel(selectTimes)
    tic
    currT = selectTimes(tInd);
    % Load tifs
    loadLabels = (tiffreadVolume(fullfile(labeledDir,sprintf(labeledName,currT))));
    loadImg = tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT)));
    % Define conversion factors and voxel scale from labels and images
    if tInd == 1
        imgDims = size(loadImg);    labelDims = size(loadLabels);
        scaleFact = imgDims./labelDims;
        labelVoxSize = scaleFact.*imgVoxSize;
        distScale = mean(labelVoxSize);     % blob voxels should be cubic!
    end
    % Take distance transform of binarized labels
    % bwMat = bwdist(loadLabels == 0);
    labelsRS = imresize3(loadLabels,labelDims*distScale,'nearest');
    bwRS = bwdist(labelsRS == 0);
    [binMat(tInd,:),~,~] = histcounts(bwRS,rBins);
end

%% Consecutive erosion!
% Mask, erode, sub-sample labels by eroded (?), frac of vols vs. frac of IDs

%% Concatenate and sort by trajectory
allFrames = vertcat(storageStruct(:).Frames);
storeMat = zeros(numel(allFrames),4);
storeMat(:,2) = allFrames;
storeMat(:,3) = vertcat(storageStruct(:).Volumes);
storeMat(:,4) = vertcat(storageStruct(:).Ints);
storeMat(:,5) = vertcat(storageStruct(:).MinAx);
storeMat(:,1) = vertcat(storageStruct(:).ObjLabels);

[~,labelOrder] = sort(storeMat(:,1));
sortedMat = storeMat(labelOrder,:);
save(fullfile(labeledDir,'sortedTraj_IntsVolsMinRs.mat'),'sortedMat', 'imgDims', 'imgVoxSize', 'timeStep', "labelDims", 'labelVoxSize'  );
