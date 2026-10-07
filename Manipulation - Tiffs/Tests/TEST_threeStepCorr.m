%% Load, crop and scale, gauss sub with small kernel, smooth, bin/thresh, generate sparse grid of indices, get indices in "background", divide, fit scattered interpolant
%% Load
% homeDir = '<redacted original absolute path>';
homeDir = 'Session 28, Exp 6';
dataDir = fullfile(homeDir,'Raw Split');
cropDir = fullfile(homeDir,'Cropped MATLAB');
cropRescDir = fullfile(homeDir, 'Cropped and Rescaled MATLAB');
gBlurDir = fullfile(homeDir, 'Gauss Blur 1');
gCorrDir = fullfile(homeDir, 'Gauss Corr 1');
dataNameForm = 'Time%06i_raw.tif';
selectTimes = 1:292;
smallKern = 5;
scaleFacts = [.5 .5 2];             %consider .25 .25 1 in future
cropCorner = [30 4 1];
winSize = [774 761 90];
smoothKern = 2;

%% Crop and scale
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    currTif = tiffreadVolume(fullfile(dataDir,sprintf(dataNameForm,currT)));
    currCrop = cropTiffSave(currTif, cropCorner, winSize, 1, fullfile(cropDir,sprintf('t%03i_cropped.tif',currT)));
    currScale = imresize3(currCrop, size(currCrop).*scaleFacts);
    if tInd == 1
        int1 = sum(currScale(:));
    end
    save3DTiff(currScale, fullfile(cropRescDir, sprintf('t%03i_cropRescale.tif',currT)));
end

%% Small Gauss Kernel Smooth + Correct
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    currTif = double(tiffreadVolume(fullfile(cropRescDir,sprintf('t%03i_cropRescale.tif',currT))));
    currGauss = imgaussfilt3(currTif,smallKern);
    save3DTiff(uint16(currGauss), fullfile(gBlurDir,sprintf('t%03i_gblur.tif',currT)));
    gCorr = currTif./currGauss*sum(currTif(:)/int1*(2^(15.5)));
    save3DTiff(uint16(gCorr), fullfile(gCorrDir,sprintf('t%03i_gCorr.tif',currT)));
end

%% Averaged over times
%% Load
totFilt = zeros(size(currScale));
strelSize = 4;
strelObj = strel('sphere',strelSize);
for tInd = 1:numel(selectTimes)
currT = selectTimes(tInd);
gCorr = double(tiffreadVolume(fullfile(gCorrDir,sprintf('t%03i_gCorr.tif',currT))));
currScale =  double(tiffreadVolume(fullfile(cropRescDir,sprintf('t%03i_cropRescale.tif',currT))));

%% Threshold
smoothCor = imgaussfilt3(gCorr,smoothKern);
% smoothCor = gCorr;
intBounds = median(smoothCor(:)) + [-std(smoothCor(:)) std(smoothCor(:))]/2;
logicMat = ~imdilate(~(smoothCor >= intBounds(1) & smoothCor <= intBounds(2)),strelObj);

%% Generate sparse grid
gridNodes = 20;
gridSpace = round(min(size(gCorr))/gridNodes);
[gridX, gridY, gridZ] = ndgrid(1:gridSpace:size(gCorr,1), 1:gridSpace:size(gCorr,2), 1:gridSpace:size(gCorr,3));
gridInds = sub2ind(size(gCorr), gridX, gridY, gridZ);

%% Get grid points in bg regions
subSampMat = consMatLnB(gCorr, logicMat);
gridCorr = double(reshape(subSampMat(gridInds(:)), size(gridX)));
gridOg = double(reshape(currScale(gridInds(:)), size(gridX)));
% gridRatio = gridOg./gridCorr; gridRatio(find(gridCorr==0)) = 0;
[dataX, dataY, dataZ] = ind2sub(size(gridCorr), find(gridCorr ~= 0));
[zeroX, zeroY, zeroZ] = ind2sub(size(gridCorr), find(gridCorr == 0));

%% Generate scattered int object  
test = scatteredInterpolant(dataX,dataY,dataZ,gridOg(gridCorr~=0));
test2 = test(zeroX, zeroY, zeroZ);
test3 = gridOg;
test3(gridCorr == 0) = test2;
scaledUp = imresize3(test3, gridSpace);
totFilt = totFilt + scaledUp(1:size(currScale,1), 1:size(currScale,2), 1:size(currScale,3));

end

%% Weighted average along z pre-interp
dataCounts = sum(double(logical(gridOg)),3);
totInts = sum(gridOg,3);
meanProf = dataCounts./totInts;
meanProf(totInts == 0) = 0;

%% mean of all scaled-down matrices of "background" values
sheetTimes = 30:290;
strelSize = 4;
strelObj = strel('sphere',strelSize);
gridNodes = 30;

gCorr = double(tiffreadVolume(fullfile(gCorrDir,sprintf('t%03i_gCorr.tif',sheetTimes(1)))));
gridSpace = round(min(size(gCorr))/gridNodes);
[gridX, gridY, gridZ] = ndgrid(1:gridSpace:size(gCorr,1), 1:gridSpace:size(gCorr,2), 1:gridSpace:size(gCorr,3));
gridInds = sub2ind(size(gCorr), gridX, gridY, gridZ);
tic
for tInd = 1:numel(sheetTimes)
    currT = sheetTimes(tInd);
    gCorr = double(tiffreadVolume(fullfile(gCorrDir,sprintf('t%03i_gCorr.tif',currT))));
    currScale =  double(tiffreadVolume(fullfile(cropRescDir,sprintf('t%03i_cropRescale.tif',currT))));
    if tInd == 1
        totFilts = zeros(size(gridX));
        totCounts = totFilts;
    end
    
    % Threshold
    smoothCor = imgaussfilt3(gCorr,strelSize);
    intBounds = median(smoothCor(:)) + [-std(smoothCor(:)) std(smoothCor(:))]/2;
    logicMat = ~imdilate(~(smoothCor >= intBounds(1) & smoothCor <= intBounds(2)),strelObj);                

    % Sample indices within median ranges and store
    subSampMat = consMatLnB(currScale, logicMat);
    gridCorr = double(reshape(subSampMat(gridInds(:)), size(gridX))); 
    totFilts(:,:,:,tInd) = gridCorr;
    totCounts = totCounts + double(logical(gridCorr));

end
toc

%% Generate weighted filt matrix
wFilt = sum(totFilts,4)./totCounts; wFilt(totCounts==0) = 0;

%% Scat int
test3 = fillin3D(wFilt);

%% Interpolate for each rz plane, then average results
% Interpolate for each xz plane
outFilt = avgXY2DInterps(wFilt);

%% Hard remove slices and repeat
slice1 = 5:11;
slice2 = 23:27;
noSlices = outFilt;
noSlices(:,:,[slice1 slice2]) = 0;

outFilt2 = avgXY2DInterps(noSlices);

%% Gauss smooth and test

%% Average early times only 
%% mean of all scaled-down matrices of "background" values
sheetTimes = 25:50;
gridNodes = 30;
smallKern = 3;

currScale =  double(tiffreadVolume(fullfile(cropRescDir,sprintf('t%03i_cropRescale.tif',sheetTimes(1)))));
gridSpace = round(min(size(currScale))/gridNodes);
[gridX, gridY, gridZ] = ndgrid(1:gridSpace:size(currScale,1), 1:gridSpace:size(currScale,2), 1:gridSpace:size(currScale,3));
gridInds = sub2ind(size(currScale), gridX, gridY, gridZ);
tic
for tInd = 1:numel(sheetTimes)
    currT = sheetTimes(tInd);
    currScale =  double(tiffreadVolume(fullfile(cropRescDir,sprintf('t%03i_cropRescale.tif',currT))));
    if tInd == 1
        totFilts = zeros(size(gridX));
        totCounts = totFilts;
    end
    
    % Threshold
    smoothImg = imgaussfilt3(currScale,smallKern);
%     intBounds = median(smoothImg(:)) + [-std(smoothImg(:)) std(smoothImg(:))]/2;
%     logicMat = ~imdilate(~(smoothImg >= intBounds(1) & smoothImg <= intBounds(2)),strelObj);                

    % Sample indices within median ranges and store
%     selImg = consMatLnB(smoothImg, logicMat);
    
    gridImg = double(reshape(smoothImg(gridInds(:)), size(gridX))); 
    totFilts(:,:,:,tInd) = gridImg;
    totCounts = totCounts + double(logical(gridImg));
end
toc


%% OLD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load
currT = 285;
gCorr = double(tiffreadVolume(fullfile(gCorrDir,sprintf('t%03i_gCorr.tif',currT))));
currScale =  double(tiffreadVolume(fullfile(cropRescDir,sprintf('t%03i_cropRescale.tif',currT))));

%% Threshold
strelSize = 4;
strelObj = strel('sphere',strelSize);
smoothCor = imgaussfilt3(gCorr,smoothKern);
% smoothCor = gCorr;
intBounds = median(smoothCor(:)) + [-std(smoothCor(:)) std(smoothCor(:))]/2;
logicMat = ~imdilate(~(smoothCor >= intBounds(1) & smoothCor <= intBounds(2)),strelObj);

%% Generate sparse grid
gridNodes = 20;
gridSpace = round(min(size(gCorr))/gridNodes);
[gridX, gridY, gridZ] = ndgrid(1:gridSpace:size(gCorr,1), 1:gridSpace:size(gCorr,2), 1:gridSpace:size(gCorr,3));
gridInds = sub2ind(size(gCorr), gridX, gridY, gridZ);

%% Get grid points in bg regions
subSampMat = consMatLnB(gCorr, logicMat);
gridCorr = double(reshape(subSampMat(gridInds(:)), size(gridX)));
gridOg = double(reshape(currScale(gridInds(:)), size(gridX)));
% gridRatio = gridOg./gridCorr; gridRatio(find(gridCorr==0)) = 0;
[dataX, dataY, dataZ] = ind2sub(size(gridCorr), find(gridCorr ~= 0));
[zeroX, zeroY, zeroZ] = ind2sub(size(gridCorr), find(gridCorr == 0));

%% Generate scattered int object  
test = scatteredInterpolant(dataX,dataY,dataZ,gridOg(gridCorr~=0));
test2 = test(zeroX, zeroY, zeroZ);
test3 = gridOg;
test3(gridCorr == 0) = test2;

%% FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [outSlice] = fillin2D(currSlice)
    [dataX, dataY] = ind2sub(size(currSlice), find(currSlice ~= 0));
    [zeroX, zeroY] = ind2sub(size(currSlice), find(currSlice == 0));
     
    currInt = scatteredInterpolant(dataX,dataY,currSlice(currSlice~=0));
    currIntVals = currInt(zeroX, zeroY);
    outSlice = currSlice;
    outSlice(currSlice == 0) = currIntVals;
end

function [outMat] = fillin3D(currMat)
    [dataX, dataY, dataZ] = ind2sub(size(currMat), find(currMat ~= 0));
    [zeroX, zeroY, zeroZ] = ind2sub(size(currMat), find(currMat == 0));
     
    intObj = scatteredInterpolant(dataX,dataY,dataZ,currMat(currMat~=0));
    intVals = intObj(zeroX, zeroY, zeroZ);
    outMat = currMat;
    outMat(currMat == 0) = intVals;
end

function outInterp = avgXY2DInterps(bgOnly)
    orthFilt = permute(bgOnly, [2 1 3]);
    outFilt1 = zeros(size(bgOnly));
    outFilt2 = zeros(size(orthFilt));

    for rInd = 1:max(size(bgOnly,[1,2]))
            
        if rInd <= size(bgOnly,1)
            currSlice = squeeze(bgOnly(rInd, :,:));
            outFilt1(rInd,:,:) = fillin2D(currSlice);
        end
        if rInd <= size(orthFilt,1)
            currSlice = squeeze(orthFilt(rInd, :,:));
            outFilt2(rInd,:,:) = fillin2D(currSlice);
        end
    end

    outFilt2 = permute(outFilt2, [2 1 3]);
    outInterp = (outFilt1 + outFilt2)/2;
end

