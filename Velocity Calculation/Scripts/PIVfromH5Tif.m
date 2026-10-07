%% Run 3D PIV - ignore queries centered on regions without segmentation
% 10/2/2023 - Rémi Boros, implemented from Sebastian Streichan

% NOTE: I use parfor. The code also expects images to have cubic voxels.
% Masks are rescaled to image size in the loop

% Raw intensity data to query
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 56, Exp 1';
imgName = 'Time%06i_raw647.tif';
% Segmentation data for masking
% segDir = '<redacted original absolute path>';    % For masking
segDir = 'Session 56, Exp 1';    % For masking
segName = 'PassOne_t%03i_16bitSubSamp_Probabilities Stage 2.h5';
% Save directory info
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 56, Exp 1';
saveName = 't%04i-t%04i_pivOUT.mat';

% Selected time range
selectTimes = 1:100;
consecBool = 1;         % Calculate only for consecutive frame pairs?

% PIV interrogation spacing and window size
spacing = 8;
window = 16;
% Sub-pixel correction method; options: 'none' 'gaussian' 'centroid'
% Implemented from QuickPIV: Efficient 3D particle image velocimetry
% software applied to quantifying cellular migration during embryogenesis
method = 'gaussian';

% If desired, can dilate masks using a spherical strel object
maskBool = 1;
dilRadius = 3;
% h5 info for pulling mask from .h5
segChannelOrder = [2 1 3];
h5Chans = [2 3];
segThresh = 0.33;

%% Iterate through time
dilBool = (dilRadius > 0);
for tInd = 1:(numel(selectTimes) - 1)

    % Define current times to be probed
    currT = selectTimes(tInd);  nextT = selectTimes(tInd + 1);
    if (consecBool == 1 && ~(abs(currT - nextT) == 1))
        continue
    end

    % Load images and segmentations for masking
    if tInd == 1
        % Load mask and image for time point 1
        img1 = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
        if maskBool == 1
            currH5 = h5read(fullfile(segDir,sprintf(segName,currT)),'/exported_data');
            mask1 = imbinarize(permute(squeeze(sum(currH5(h5Chans,:,:,:),1)),segChannelOrder),segThresh);
        elseif maskBool == 0
            mask1 = ones(size(img1));
        end
        %Define strel object for dilation and dilate mask, if requested
        if dilBool && maskBool
            strelObj = strel('sphere',dilRadius);
            mask1 = imdilate(mask1,strelObj);
        end
    else
        % Shift matrices defined at time i to time i+1
        img1 = img2;
        mask1 = mask2;
    end

    % Load mask and image for next time point
    img2 = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,nextT))));
    if maskBool == 1
        currH5 = h5read(fullfile(segDir,sprintf(segName,currT)),'/exported_data');
        mask2 = imbinarize(permute(squeeze(sum(currH5(h5Chans,:,:,:),1)),segChannelOrder),segThresh);
    elseif maskBool == 0
        mask2 = ones(size(img1));
    end
    %Dilate mask, if requested
    if dilBool && maskBool
        mask2 = imdilate(mask2,strelObj);
    end

    % Calculate 3D PIV
    tic
    [allShifts, cenCoords, shifts, validCenCoords, queryDims] = calc3DPIV_Sparse(img1, img2, mask1, mask2, spacing, window, method);
    save(fullfile(saveDir,sprintf(saveName,currT,nextT)),'allShifts','cenCoords','shifts','validCenCoords','queryDims');
    toc

end

%% Display 2D quiver on 2D image slices
% Cut dim = 1 means fixed x/column val; cut dim = 2 means fixed y/row val
% i.e. cut dim is given in coordinate space, not image space
cutDim = 3; dimInd = 6;
dimVals = unique(cenCoords(:,cutDim));
queryImg1 = double(img1); queryImg2 = double(img2);
% queryImg1 = double(mask1); queryImg2 = double(mask2);

% Define dimension in matrix space (x -> col, y -> row)
if cutDim ~=3
    refDim = mod1b(cutDim + 1, 2);
else
    refDim = cutDim;
end

% Get image slices (matrix space)
rowDim = mod1b(refDim + 1, 3); colDim = mod1b(refDim + 2, 3);
tempImg = permute(queryImg1, [refDim rowDim colDim]);
tempSlice1 = squeeze(tempImg(dimVals(dimInd),:,:));
tempImg = permute(queryImg2, [refDim rowDim colDim]);
tempSlice2 = squeeze(tempImg(dimVals(dimInd),:,:));
dispSlice = double(tempSlice2) - double(tempSlice1)*2 + double(tempSlice2 + tempSlice1);

% Get points in slice (coordinate space)
dim1 = mod1b(cutDim + 1, 3); dim2 = mod1b(cutDim + 2, 3);
velCoords = cenCoords(:,cutDim) == dimVals(dimInd);
sparseCoords = validCenCoords(:,cutDim) == dimVals(dimInd);

% Display
imagesc(dispSlice);
hold on
quiver(cenCoords(velCoords,dim1), cenCoords(velCoords,dim2), allShifts(velCoords,dim1), allShifts(velCoords,dim2),2,'r');
