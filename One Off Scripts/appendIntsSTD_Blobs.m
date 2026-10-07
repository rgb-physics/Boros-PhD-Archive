% From a sortedMat containing blob statistics, ID-ed blob .tifs, and
% intensity .tifs, calculate std of intensities per object and append this
% data
% 2026-05-31 - Rémi Boros

% baseDirs = {'<redacted original absolute path>',...
baseDirs = {'Session 88, Exp 1',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 2',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 3',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 4',...
    % '<redacted original absolute path>'};
    'Session 88, Exp 5'};
labeledNames = {'E1_T%03i_trajIDs.tif',...
    'E2_T%03i_trajIDs.tif',...
    'E3_T%03i_trajIDs.tif',...
    'E4_T%03i_trajIDs.tif',...
    'E5_T%03i_trajIDs.tif'};
for index = 1:numel(baseDirs)

baseDir = baseDirs{index};
statsDir = fullfile(baseDir,'\4 Tracked Blobs - PreFill');
statsName = 'trajSorted_BlobVolsInts.mat';
labeledDir = fullfile(baseDir,'4 Tracked Blobs - PreFill');
labeledName = labeledNames{index};
imgDir = fullfile(baseDir,'3 Illumination Bleach Corrected 16bit');
imgName = 't%03i_illBleachCorr16bit_560.tif';
saveName = 'ALL_trajSorted_BlobVolsIntsSTDs.mat';

load(fullfile(statsDir,statsName));
selectTimes = unique(sortedMat(:,2));

forceScale = 1;
morphKern = 2;

%% Iterate over times
storageStruct = struct();
% timeShft = 0;
    tic
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    if ~exist(fullfile(labeledDir,sprintf(labeledName,currT)),'file')
        continue
    end
% Load tifs
    ogLabels = (tiffreadVolume(fullfile(labeledDir,sprintf(labeledName,currT))));
    loadImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
% Define conversion factors and voxel scale from labels and images
    if tInd == 1
        imgDims = size(loadImg);    labelDims = size(ogLabels);
        scaleFact = imgDims./labelDims;
        labelVoxSize = scaleFact.*imgVoxSize;
        logicRescale = min(scaleFact)*forceScale;
        morphKernSc = round(morphKern*logicRescale);
        distScale = mean(labelVoxSize)/logicRescale;
        if abs(morphKern) > 0
            morphObj = strel('sphere',abs(morphKernSc));
        end
    end
% Rescale labels, then calculate distance transform (first time)
    rsLabels = imresize3(ogLabels,round(labelDims*logicRescale),'nearest');
    rsExtend = imdilate(rsLabels,morphObj); % used to sample blob surroundings
    % Get distance transform
    distLabs = bwdist(~logical(rsLabels));
% Erode or dilate to smooth boundaries, if requested
    morphMat = imgaussfilt3(distLabs,abs(morphKernSc));     % blur distance transform
    loadLabels = consMatLnB(rsExtend,morphMat > morphKernSc/2);    % threshold blurred EDT

% Get unique labels and their indices
    labelsVec = loadLabels(loadLabels>0);
    uniqueLabels = unique(labelsVec);
% Rescale tifs of IDs to og. image size, then bin with histcounts
    if ~isempty(uniqueLabels)
        [objVols,temp,resizedLabelInds] = ...
            histcounts(imresize3(loadLabels,size(loadImg),'nearest'),[uniqueLabels; inf]);
        uniqueLabels0 = [0; uniqueLabels];  % List of all unique object labels and 0 (background) as a map vector   
        rescaledLabels = uniqueLabels0(resizedLabelInds + 1);   % remap resized label matrix using map vector above     
    else                                                        % ^(prevents ID swaps when rescaling)^
        continue
    end
    % Instantiate storage vectors
    objInts = objVols;  stdInts = objVols;
    % objMinAx = objVols; objFAs = objVols;   objSphs = objVols;

% Statistics for each blob calculated below
    for currInd = 1:numel(uniqueLabels)
    % Get object intensities of each object
        currID = uniqueLabels(currInd);     % currBlob
        currLogic = (rescaledLabels == currID);
        objInts(currInd) = sum(loadImg(currLogic));
        stdInts(currInd) = std(loadImg(currLogic));
    % Store minor axis of each blob via selected method
        currLogic = (loadLabels == currID);
    end

    % Concatenate average/median values into single structure
    % Generate vector of frames
    frameVec = repmat(currT,numel(objVols),1);
    % Store data
    storageStruct(tInd).Frames = frameVec;
    storageStruct(tInd).ObjLabels = double(uniqueLabels);
    storageStruct(tInd).Ints = objInts';
    storageStruct(tInd).IntsSTD = stdInts';
    storageStruct(tInd).NumVox = objVols';
    storageStruct(tInd).Volumes = objVols'*prod(imgVoxSize);    %in um^3

end
toc
%% Concatenate all blob values 
allFrames = vertcat(storageStruct(:).Frames);
storeMat = zeros(numel(allFrames),4);
storeMat(:,2) = allFrames;
storeMat(:,3) = vertcat(storageStruct(:).Volumes);  %in units of image voxels (mult. by imgVoxVol to convert to um)
storeMat(:,4) = vertcat(storageStruct(:).Ints);
storeMat(:,5) = vertcat(storageStruct(:).IntsSTD);     % standard deviations of intensities
storeMat(:,6) = vertcat(storageStruct(:).NumVox);     % Number of voxels sampled
% storeMat(:,5) = vertcat(storageStruct(:).MinAx);
storeMat(:,1) = vertcat(storageStruct(:).ObjLabels);
% Sort data by trajectory
[~,labelOrder] = sort(storeMat(:,1));
sortedMat2 = storeMat(labelOrder,:);
sortedMat(:,5:6) = sortedMat2(:,5:6);


save(fullfile(statsDir,saveName),'sortedMat','imgDims', 'imgVoxSize', ...
    'timeStep', "labelDims", 'labelVoxSize', 'morphKern','forceScale'  );
end