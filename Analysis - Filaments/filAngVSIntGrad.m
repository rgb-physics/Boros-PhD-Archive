%% Compare filament angle to angle associated with intensity gradients
% Takes in data calculated in COMBINED_getFilamentStats2D and 16bit
% corrected dense phase intensity data
% Edited - 2024-08-28
% Rémi Boros

% imgDir = '<redacted original absolute path>';
imgDir = 'Session 56, Exp 1';
imgNameForm = 't%03i_illBleachCorr16bit.tif';
% statDir = '<redacted original absolute path>';
statDir = 'Session 56, Exp 1';
filStatName = 'Concatenated_2D_Info.mat';
angDataName = 'FilamentAlignment_AngleData.mat';

timeRange = 1:100;
scaleVec = [1 1 4]/2;
pixSize = 11*2/60;

%% Pick a time: calculate intensity gradients, then smooth with gaussian
gKern = 2;
tInd = 40;
currT = timeRange(tInd);
currTif = tiffreadVolume(fullfile(imgDir,sprintf(imgNameForm,currT)));
[gradx,grady,gradz] = imgradientxyz(currTif);
allGrads(:,:,:,1) = imgaussfilt3(gradx*scaleVec(1),gKern);  
allGrads(:,:,:,2) = -imgaussfilt3(grady*scaleVec(2),gKern);  
allGrads(:,:,:,3) = imgaussfilt3(gradz*scaleVec(3),gKern);  

%% Compare to distMat from segmentation
% segDir = '<redacted original absolute path>';
segDir = 'Session 56, Exp 1';
segName = 'PassOne_t%03i_16bitSubSamp_Probabilities Stage 2.h5';
h5chans = [1 2 3];
outInOnChans = [1 2 3];
h5thresh = 0.33;
imgScaling = [1 1 4]/2;
[bwGrads,bwMat] = getDistGrads(fullfile(segDir,sprintf(segName,currT)),h5chans,outInOnChans,h5thresh,size(currTif),imgScaling,0);

figure
orthosliceViewer(allGrads);
figure
orthosliceViewer(imresize3_4mat(bwGrads,size(currTif)));

%% save a few snaps to compare
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 56, Exp 1';
saveName = 'Time %03i Slice %03i.tif';
selTimes = 1:5:100;
zInd = 38;
for tInd = 1:numel(selTimes)
    
    currT = selTimes(tInd);
    currTif = tiffreadVolume(fullfile(imgDir,sprintf(imgNameForm,currT)));
    [gradx,grady,gradz] = imgradientxyz(currTif);
    allGrads(:,:,:,1) = imgaussfilt3(gradx*scaleVec(1),gKern);  
    allGrads(:,:,:,2) = -imgaussfilt3(grady*scaleVec(2),gKern);  
    allGrads(:,:,:,3) = imgaussfilt3(gradz*scaleVec(3),gKern);  
    [bwGrads,bwMat] = getDistGrads(fullfile(segDir,sprintf(segName,currT)),h5chans,outInOnChans,h5thresh,size(currTif),imgScaling,0);

    figure
    subplot(1,2,1)
    imagesc(squeeze(allGrads(:,:,zInd,:)))
    title(sprintf('Intensity gradients at Time %03i',currT));
    clim([0 10^3])
    subplot(1,2,2)
    imagesc(imresize3(squeeze(bwGrads(:,:,zInd,:)),[size(allGrads,1) size(allGrads,2) 3]));
    clim([-1 1])
    title(sprintf('Distance transform gradients at Time %03i',currT));
    set(gcf,'Position',[100 100 1800 800])
    exportgraphics(gcf,fullfile(saveDir,sprintf(saveName,currT,zInd)));
    close();

end

