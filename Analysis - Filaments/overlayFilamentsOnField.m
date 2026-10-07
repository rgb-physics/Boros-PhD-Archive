% Assumes filament data has been prepared and concatenated in
% prepareFilamentStats_2D.m. Allows the user to filter filament candidates,
% then overlay them over an intensity field of choice.
% segSuperDir = '<redacted original absolute path>';
segSuperDir = 'Session 83';
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 83';
imgName = 'BlobMat_t%03i_illBleachCorr16bit.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 83';
saveName = 'Time%06i_MTsDenseSparseOverlay.png';
% Time and z selection
selTimes = 1:50;        % File indices/frames
currSlice = [39 40 41]; % vector of z slices; will pull filaments from these slices and project onto the z slice = mean of the vector
% Logic/filter parameters
minVol = 8;                 % pixels (allVols)
minLength = 2;              % pixels (majAxes)
minAR = 1.5;                % Ratio major/minor axes (aspectRatio)
selectSetInd = 1;            % Numbered data set (subIndsVec) (relevant when concatenated filaments over multiple directories)
% Display options
fieldBounds = [0 1];
% Save
saveBool = 0;

%% Load
load(fullfile(segSuperDir,'Concatenated_2D_Info.mat'));
aspectRatio = majAxes./minAxes;

%% Define volume filter, aspect ratio filter, orientation filter, slice filter
allVec = ones(size(sliceInds));
sizeFilt = allVols > minLength;         
arFilt = aspectRatio > minAR;       
lengthFilt = majAxes > 2;       
dataSetFilt = ismember(subIndsVec,selectSetInd);  
% sliceFilt = allVec;             % slice index   (sliceInds)
logicVec = sizeFilt & arFilt & lengthFilt & dataSetFilt;

%% View selection of filaments
for tInd = 1:numel(selTimes)
    % Get filaments that satisfy desired constraints
    currT = selTimes(tInd);
    sliceFilt = ismember(sliceInds, currSlice);
    timeFilt = objInds == currT;
    curr2DLogic = sliceFilt & timeFilt;
    currLogic = logicVec & curr2DLogic;
    % Load image
    currTif = tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT)));      % With formatting changes, could selectively load appropriate slices only
    imagesc(currTif(:,:,round(mean(currSlice))));
    colormap('gray')
    clim(fieldBounds)
    hold on
    plot(backboneXs(:,curr2DLogic),backboneYs(:,curr2DLogic),'LineWidth',2,'Color','g');
    plot(backboneXs(:,currLogic),backboneYs(:,currLogic),'LineWidth',1,'Color','r');
    hold off
    % Save, if requested
    if saveBool == 1
        imwrite(getframe(gcf).cdata,fullfile(saveDir,sprintf(saveName,currT)));
    end
end

