%% Take in analyzed data structures of in, on, out,, etc

% strDir = '<redacted original absolute path>';
strDir = 'Session 28, Exp 6';
strName = 'SplitRegions_Time%06i.mat';
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 28, Exp 6';
imgName = 't%03i_illBleachCorr16bit.tif';

% saveDir = '<redacted original absolute path>';
saveDir = 'Session 28, Exp 6';
saveName = 'Time%06i_topsheet.tif';

selTimes = 150:200;
dilKern = 1;
structVar = 'regionStruct';
selFields = {'TopSheet','TopRegion'};
% get matrix sizes from metadata
load(fullfile(strDir,'metadata.mat'));

if ~exist(saveDir,'dir')
    mkdir(saveDir)
end

%Rescale ints
% corrDir = '<redacted original absolute path>';
corrDir = 'Session 25, Exp 5';
corrName = 'Time%06i_intCorrected.tif';
corrBool = 0;

% Rescale, if requested
rsBool = 1;
rescaleFactor = 2*ogVoxSize/ogVoxSize(3);

%% 
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

if dilKern > 0
    dilObj = strel('sphere',dilKern);
end

for tInd = 1:numel(selTimes)

    % Load data
    currT = selTimes(tInd);
    currStruct = load(fullfile(strDir,sprintf(strName,currT)),structVar).(structVar);
    currTif = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
    % imgSize = size(currTif);

    if corrBool == 1
        currCorr = double(tiffreadVolume(fullfile(corrDir,sprintf(corrName,currT))));
        totalInt = sum(currCorr(:));
        currTif = currTif*totalInt/sum(currTif(:))*100;
    end

    % Generate logic matrix
    logicMat = false(segSize);
    for index = 1:numel(selFields)
        currInds = currStruct.(selFields{index});
        % indsIMG = rescaleCoords_Inds(currInds,segSize,imgSize);
        logicMat(currInds) = true;
        % currLogic = currStruct.(selFields{index});
        % logicMat = logicMat | imresize3(currLogic,imgSize,'nearest');
    end
    logicMat = imresize3(logicMat,imgSize,'nearest');
    if dilKern > 0
        logicMat2 = imdilate(logicMat,dilObj);
    end
    % Subsample
    outMat = consMatLnB(currTif,logicMat2);
    if rsBool == 1
        outMat = imresize3(outMat,size(outMat).*rescaleFactor,'nearest');
    end
    % Save tiff
    save3DTiff(uint16(outMat),fullfile(saveDir,sprintf(saveName,currT)));

end





