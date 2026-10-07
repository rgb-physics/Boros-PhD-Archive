%% Analysis of 3D data; returns power spectra and structure factor
% 2023/10/30

%% Data info
% Directory info
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 56, Exp 2';
% segDir = '<redacted original absolute path>';
segDir = 'Session 56, Exp 2';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 45, Exp 3';
imgName = 't%03i_illBleachCorr16bit.tif';
segName = 'inOnPerim_t%03i.tif';
timeRange = 1:32;
% Segmentation info
selChans = [2 3];
probThresh = 0.33;
% Bin info for statistics
intRange = 0:3:255; %For intensity histogram bins
ringBin = 30;       %For radial averaging of correlation function
% Scaling info
pixelSize = .37;      % Units of length/pixel
% Rescale info
rsVec = [1 1 4]/2;
% Image pixel size, used to store conversions
ogPixSize = [1 1 4]*11*2/60;

%% iterate through time
for tInd = 1:numel(timeRange)
    %% Load data
    currT = timeRange(tInd);
    % Raw image
    imgData = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
    % Ilastik segmentation
    currSegName = fullfile(segDir,sprintf(segName,currT));
    currSeg = tiffreadVolume(currSegName);
    % scaledVals = unique(currSeg);
    scaledVals = [85 170 255];
    currSeg = ismember(currSeg, scaledVals(selChans));  
    currSeg = imresize3(currSeg,size(imgData));

    %% Get masked object properties
    scaledSeg = imresize3(currSeg,size(currSeg).*rsVec);
    maskData = imresize3(double(consMatLnB(imgData, currSeg)),size(scaledSeg));
    bwObjs = bwconncomp(scaledSeg);
    newPixSize = size(scaledSeg)./size(imgData).*ogPixSize;
    propStructBW = regionprops3(bwObjs,maskData,'Centroid','SurfaceArea','WeightedCentroid','Volume','MaxIntensity');
    save(fullfile(saveDir,sprintf('blobInfo_t%03i.mat',currT)),'propStructBW','ogPixSize','newPixSize');

    %% Spatial correlation function from 
    for fieldInd = 1:2
        if fieldInd == 1
            currField = imresize3(double(imgData),size(imgData).*rsVec);
        elseif fieldInd == 2
            currField = maskData;
        end
        shiftedField = currField - mean(currField,'all');
        
        % Pad field before generating van Hove
        subWin = 2*ceil(min(size(shiftedField)/2));
        currPadded = padarray(shiftedField, ceil(size(shiftedField)/2), 0); %pad array for proper fftn
        vanHoveFull = generateVanHove(currPadded);
        % Store
        if tInd == 1 && fieldInd == 1
            xyCenters = zeros(2*subWin+1,2*subWin+1,numel(timeRange));
            xyBlobCenters = xyCenters;
        end    
        if fieldInd == 1
            xyCenters(:,:,tInd) = vanHoveFull(size(shiftedField,1) + (-subWin:subWin), ...
                    size(shiftedField,2) + (-subWin:subWin),round(size(vanHoveFull,3)/2));
        elseif fieldInd == 2
            xyBlobCenters(:,:,tInd) = vanHoveFull(size(shiftedField,1) + (-subWin:subWin), ...
                    size(shiftedField,2) + (-subWin:subWin),round(size(vanHoveFull,3)/2));
        end
    end

    %% Store correlation info
    % Radially average over set number of bins
    if tInd == 1
        xyCorrs = zeros(ringBin, numel(timeRange));
        xyBlobCorrs = xyCorrs;
        % Generate a matrix for radial averaging
        radialMat = generateRadialMatrix(size(xyCenters,[1 2]),ringBin);
    end 
    for currBin = 1:ringBin
        currField1 = xyCenters(:,:,tInd);   currField2 = xyBlobCenters(:,:,tInd);
        xyCorrs(currBin,tInd) = mean(currField1( radialMat == currBin ), 'all');
        xyBlobCorrs(currBin,tInd) = mean(currField2( radialMat == currBin ), 'all');
    end

end
radialEdges = (1:(numel(unique(radialMat))-1)).*newPixSize'*subWin/ringBin;
save(fullfile(saveDir,'xyCorrs.mat'),'xyBlobCorrs','xyCorrs','radialEdges','ringBin','subWin');
save3DTiff(uint16(xyCenters/max(xyCenters(:))*(2^16-1)), fullfile(saveDir,'xyCentersMat.tif'));
save3DTiff(uint16(xyBlobCenters/max(xyBlobCenters(:))*(2^16-1)), fullfile(saveDir,'xyBlobCentersMat.tif'));

%% Plot radially averaged structure and correlation
figure
subplot(1,2,1)
plot(((1:numel(xyCorr))-1)*pixelSize,xyCorr/max(xyCorr(:)))
hold on
scatter(((1:numel(xyCorr))-1)*pixelSize, xyCorr/max(xyCorr(:)), 'r', 'filled')
title('Avg. Correlation Function (Real Space)')
xlabel('\Deltar'); ylabel('Correlation')

subplot(1,2,2)
loglog(xyBlobCorrs)
title('Log-log Avg. Structure Factor')
xlabel('q (inverse pixels)'); 


%% Display structure factor and correlation function
figure
imagesc(xyCenter)
title('Spatial Correlation Function (Real Space)')
xlabel('\Deltax'); ylabel('\Deltay')

%% Plot distributions of radii and peak maxima
figure
subplot(1,2,1)
histogram(sqrt([propStructBW.Area])/pi*pixelSize)
title('Distribution of object radii')
subplot(1,2,2)
histogram([propStructBW.MaxIntensity],intRange)
title('Distribution of max intensities')

%% Plot weighted centroids over image
% This highlights that the analysis works well for single peaked objects.
% NOTE: Some objects "touch" so have multiple peaks. These are not detected
cens = vertcat(propStructBW.Centroid);
figure
imagesc(imgData)
hold on
scatter(cens(:,1),cens(:,2),'r','filled')

%% END OF EASY STUFF %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Attempt to get locations from multi-peaked objects
% Don't let perfection be the enemy of the good: if 95% of your objects are
% correctly detected, it might not be worth it find the rest of your
% objects. If you have too many multi-peaked blobs, though, the following
% might be some ideas you can use as a jumping off point

%% Look for locations of "average" blob in image
% We'll be approximating the "average" object profile by summing all
% objects that fall within the desired parameter range (in our case below a
% cut off radius)
% Find all small objects by defining a cutoff
cutOffRad = 1.5;
% Find all objects with radii smaller than cutoff
allRads = sqrt(vertcat(propStructBW.Area))/pi*pixelSize;
validInds = allRads < cutOffRad;

% Get pixel IDs of valid objects
validObjs = bwObjs;
validObjs.PixelIdxList = bwObjs.PixelIdxList(validInds);
validObjs.NumObjects = numel(bwObjs.PixelIdxList(validInds));

% Get bounding boxes of each object
validProps = regionprops(validObjs,"BoundingBox");

% Do some algebra to shift image contents to within bounding box
boxDims = vertcat(validProps.BoundingBox);
boxDimMax = max(boxDims(:,3:4));
% Define boundaries of box in image where object is
imageQuerySub = round([boxDims(:,1:2), boxDims(:,1)+boxDims(:,3)-1, boxDims(:,2)+boxDims(:,4)-1]);
% Define boundaries of average box where object will be projected
shiftBoxSub = round([(boxDimMax - boxDims(:,3:4))/2 + 1, (boxDimMax - boxDims(:,3:4))/2 + boxDims(:,3:4)]);

% A smarter person than me would vectorize this
avgObj = zeros(boxDimMax([2 1]));
for oInd = 1:validObjs.NumObjects
    currImgSub = imageQuerySub(oInd,:);  currBoxSub = shiftBoxSub(oInd,:);
    newMat = zeros(size(avgObj));
%     currQueryInds = sub2ind(size(imgData), currImgSub(1):currImgSub(3), currImgSub(2):currImgSub(4));
%     currBoxInds = sub2ind(boxDimMax, currBoxSub(1):currBoxSub(3), currBoxSub(2):currBoxSub(4));
    
    currObj = maskData(currImgSub(2):currImgSub(4),currImgSub(1):currImgSub(3));
    newMat(currBoxSub(2):currBoxSub(4), currBoxSub(1):currBoxSub(3)) = currObj;  
    avgObj = avgObj + newMat;  
end
avgObj = avgObj/validObjs.NumObjects;

% Now look for objects that "look" like mean object
objCorrs = xcorr2(maskData,avgObj);

figure
subplot(1,2,2)
imagesc(objCorrs)
title('Correlation of masked image with "average" object')
subplot(1,2,1)
imagesc(avgObj)
title('Average Object Under Cutoff')

%% Look at gradients?
figure
[xGrad, yGrad] = gradient(maskData);
subplot(1,2,1)
imagesc(-sqrt(xGrad.^2 + yGrad.^2));
title('Magnitude of gradient of masked data')
subplot(1,2,2)
imagesc(maskData)
hold on
scatter(cens(:,1),cens(:,2),6,'r','filled')
title('Masked Data with Centers')