%% Directory info
% ???? - 2023/11/02
% h5Dir = '<redacted original absolute path>';
h5Dir = 'Session 56, Exp 1';
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 56, Exp 1';
% saveDirBase = '<redacted original absolute path>';
saveDirBase = 'Session 56, Exp 1';
saveSubDir =  {''};

for dirInd = 1:numel(saveSubDir)
    if ~isfile(fullfile(saveDirBase,saveSubDir{dirInd}))
        mkdir(fullfile(saveDirBase,saveSubDir{dirInd}))
    end
end

h5Name = 'PassOne_t%03i_16bitSubSamp_Probabilities Stage 2.h5';
imgName = 't%03i_illBleachCorr16bit.tif';
saveName = 't%03i_16bitSubSamp.tif';

selectTimes = 55;
probThresh = {.33};
probChan = {[2 3]};

% Resize mode 0: no rescale; resize mode1: downscale; resize mode2: upscale
% resizeModes = [2 1];
resizeModes = 1;

% Boolean for patching holes through xy scanning
fill2D = 0;

%% Another lazy for loop
for iterInd = 1:numel(h5SubDirs)

currh5Dir = fullfile(h5Dir,h5SubDirs{iterInd});
currProbChans = probChan{iterInd};
currThresh = probThresh{iterInd};
h5Name = h5Names{iterInd};

%% Lazy for loop
for rsInd = 1:numel(resizeModes)
resizeMode = resizeModes(rsInd);
saveDir = fullfile(saveDirBase,saveSubDir{rsInd},h5SubDirs{iterInd});
    if ~isfile(saveDir)
        mkdir(saveDir);
    end
%% Iterate, sample, save
conn2D = zeros(3,3,3);
conn2D(10:18) = 1;
for tInd = 1:numel(selectTimes)

    % Prepare data for current time point
    currT = selectTimes(tInd);
    currH5Name = fullfile(currh5Dir,sprintf(h5Name,currT));
    if ~isfile(currH5Name)
        continue
    end
    currImg = tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT)));
    selSegs = loadH5(currH5Name,'/exported_data',currProbChans);
    for chanInd = 1:numel(currProbChans)
        binSegs = imbinarize(selSegs(:,:,:,chanInd),currThresh);
        filledSegs = imfill(binSegs,'holes');
        selSegs(:,:,:,chanInd) = filledSegs;
    end
    filledSegs = logical(sum(selSegs,4));

    % Match segmentation and image dims, if necessary
    if resizeMode == 0
        if sum(size(filledSegs) == size(currImg)) < numel(size(filledSegs))
            fprintf('Error: segmentation and image dimensions do not match! Time %i\n',currT)
            break
        end
        newDims = size(currImg);
    elseif resizeMode == 1
        newDims = min(size(filledSegs),size(currImg));
    elseif resizeMode == 2
        newDims = max(size(filledSegs),size(currImg));
        currImg = imresize3(currImg, max(size(filledSegs),size(currImg)));
    end
    %Rescale image
    currImg = imresize3(currImg, newDims);
    filledSegs = imresize3(filledSegs, newDims);

    % 2D Fill holes (slower and may not always be correct to do)
    % Note that this method tends to overestimate outer perimeters
    if fill2D == 1
        % Iterate through each dimension and fill holes in 2D planes
        for index = 1:3
            filledSegs = logical(imfill(double(filledSegs),conn2D));
            conn2D = permute(conn2D, [2 3 1]);
        end
            save3DTiff(uint8(filledSegs),fullfile(saveDir,sprintf(['PatchedSeg_' saveName],currT)));
    end
    
    % Display progress
    if mod1b(tInd,10) == 1
        fprintf('Current Time Point: %i\n', currT)
    end
    
    % Save new tif
    save3DTiff(consMatLnB(currImg, filledSegs),fullfile(saveDir,sprintf(saveName,currT)));
end

end
end