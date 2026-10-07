%Plot volumes, intensities, etc. from segmentations, then subsample
%intensity data and get average quantities from tifs using segmentations as
%masks.
% Edit dates: 2024-04-29; 2024-12-03
%% Directory info
% tifDirs = {'Session 84',...
%     'Session 84'};
% tifNames = {'t%03i_illBleachCorr16bit_488.tif','t%03i_illBleachCorr16bit_560.tif'};
% blobDir = 'Session 84';
% blobName = 'BlobMat_t%03i_inheritedLabels.tif';
% saveDir = 'Session 84';
% tifDirs = {'<redacted original absolute path>',...
tifDirs = {'Session 81, Exp 3',...
    % '<redacted original absolute path>'};
    'Session 81, Exp 3'};
tifNames = {'t%03i_illBleachCorr16bit_488.tif','t%03i_illBleachCorr16bit_560.tif'};
% blobDir = '<redacted original absolute path>';
blobDir = 'Session 81, Exp 3';
blobName = 'DownscaledSeg_t%03i_illBleachCorr16bit_560.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';

% For multiple sampled tifs (intensities)
bgIntsTag = 'bgInts%i';
blobIntsTag = 'blobInts%i';
meanIntsTag = 'meanInts%i';
medZTag = 'medZInts%i';
tifTag = 'fullDir%i';
pixSizeTag = 'intPixSize%i';

% Parameters
selectTimes = 1:200;
blobPixSize = 2*11/20;        
intPixSizes = {[1 1 1.5/1.1]*blobPixSize,[1 1 1.5/1.1]*blobPixSize};
timeStep = 35;
segRescale = [1 1 1]*blobPixSize;   % Segmentation should have square voxels before volume/area calculations

% Channels to distinguish
chans1 = 2;
chans2 = 3;

% Check if blob files are binary
isLogical = 0;
cutOffVal = 60;

%% Reset storage struct
timeStore = struct();

%% Calculate average quantities
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    if ~isfile(fullfile(blobDir,sprintf(blobName,currT)))
        continue
    end
    % Generate binarized matrix of blob indices, threshold, rescale (square voxels)
    currBlobs = double(tiffreadVolume(fullfile(blobDir, sprintf(blobName,currT))));
    if isLogical == 1
        binaryBlobs = logical(currBlobs);
    else
        binaryBlobs = imbinarize(currBlobs,cutOffVal);
    end
    binaryBlobs = imresize3(binaryBlobs,segRescale.*size(binaryBlobs));
    % Iterate over intensity data directories
    for dirInd = 1:numel(tifNames)
        % Load intensity data
        dataDir = tifDirs{dirInd}; dataName = sprintf(tifNames{dirInd},currT);
        fullDir = fullfile(dataDir,dataName);
        currTif = double(tiffreadVolume(fullDir));
        % Match segmentation and intensity tif sizes
        rescaledBlobs = imresize3(binaryBlobs,size(currTif));
        % Calculate quantities and store
        blobData = consMatLnB(currTif, rescaledBlobs);
        bgData = consMatLnB(currTif, ~rescaledBlobs);
        timeStore(tInd).(sprintf(meanIntsTag,dirInd)) = mean(currTif,'all');
        timeStore(tInd).(sprintf(medZTag,dirInd)) = squeeze(median(currTif, [1,2]));
        timeStore(tInd).(sprintf(bgIntsTag,dirInd)) = sum(bgData(:));
        timeStore(tInd).(sprintf(blobIntsTag,dirInd)) = sum(blobData(:));
        timeStore(tInd).(sprintf(tifTag,dirInd)) = fullDir;
        timeStore(tInd).(sprintf(pixSizeTag,dirInd)) = intPixSizes{dirInd};        
    end
    % Store blob/segmentation info
    timeStore(tInd).blobVols = sum(binaryBlobs,'all');
    surfaceLogic = (bwdist(~binaryBlobs)<=1) & (bwdist(~binaryBlobs)>0);      %%% CHECK THIS
    timeStore(tInd).blobAreas = sum(surfaceLogic(:));
    timeStore(tInd).blobPixRescale = segRescale;
    timeStore(tInd).blobPixSize = segRescale/blobPixSize;
end

% Save info
save(fullfile(saveDir, sprintf('t%03i-%03i_globalIntVolStats.mat',min(selectTimes),max(selectTimes))), 'timeStore');

%% 


load(fullfile(saveDir, sprintf('t%03i-%03i_globalIntVolStats.mat',min(selectTimes),max(selectTimes))), 'timeStore');

%% Global bleach rate 
currField = 'meanInts2';

figure
subplot(1,2,1)
plot(selectTimes*timeStep, vertcat(timeStore(:).(currField)));
xlabel('Time (s)')
ylabel('Mean Global Int.')
set(gca,'FontSize',15)
title('Mean global intensity over time')

subplot(1,2,2)
plot(selectTimes(2:end)*timeStep, diff(vertcat(timeStore(:).(currField)))./timeStep)
xlabel('Time (s)')
ylabel('\Delta Global Int. Change')
set(gca,'FontSize',15)
title('Rate of global intensity change over time')

figure
loglog(selectTimes*timeStep, vertcat(timeStore(:).(currField)))

%% Vol fracs and mass fracs objs
fieldName1 = 'blobVols';
fieldName2 = 'blobInts2';

field1 = vertcat(timeStore.(fieldName1));
field2 = vertcat(timeStore.(fieldName2));
times = selectTimes*timeStep;



%% Vol fracs over time
bgIntsKif = vertcat(timeStore.('bgInts1'));
blobIntsKif = vertcat(timeStore.('blobInts1'));
bgIntsMTs = vertcat(timeStore.('bgInts2'));
blobIntsMTs = vertcat(timeStore.('blobInts2'));
blobVols = vertcat(timeStore.blobVols);
blobAreas = vertcat(timeStore.blobAreas);
times = selectTimes*timeStep;

objIntPerVox = blobInts./blobVols;
bgIntPerVox = bgInts./(numel(currBlobs) - blobVols);

%% Intensity fractions over time in diff regions
figure
hold on
scatter(selectTimes*timeStep, blobIntsMTs./(bgIntsMTs+blobIntsMTs), 'r','filled')
scatter(selectTimes*timeStep, bgIntsMTs./(bgIntsMTs+blobIntsMTs), 'b','filled')
scatter(selectTimes*timeStep, blobIntsKif./(blobIntsKif+bgIntsKif), 16, [.8 .3 0],'d')
scatter(selectTimes*timeStep, bgIntsKif./(blobIntsKif+bgIntsKif), 16, [0 .3 .8],'d')
legend('Object MT Ints (sum)', 'Background MT Ints (sum)','Object Kif4 Ints (sum)', 'Background Kif4 Ints (sum)')
xlabel('Time (s)')
ylabel('Intensity fraction (normalized)')
set(gca,'FontSize',15)
title('Global intensity fraction per time')
%% volume fraction
figure
hold on
scatter(times, blobVols./vertcat(timeStore(:).segMatVol), 'filled')
xlabel('Time (s)')
ylabel('Total object vol fraction')
set(gca,'FontSize',15)
title('Global volume fraction per time')
%% vol to area fraction
figure
hold on
scatter(times, blobAreas./blobVols, 'filled')
xlabel('Time (s)')
ylabel('Total object vol fraction')
set(gca,'FontSize',15)
title('Mean area/volume over time')

%% ints per voxel
figure
hold on
scatter(times, objIntPerVox, 'r', 'filled')
scatter(times, bgIntPerVox, 'b', 'filled')
xlabel('Time (s)')
ylabel('Mean intensity per voxel')
set(gca,'FontSize',15)
title('Averaged intensities per voxel type')
legend('Object Intensities (mean)', 'Background Intensities (mean)')

%% ints per voxel corrected for bleaching
figure
hold on
scatter(times, objIntPerVox./vertcat(timeStore(:).meanInt), 'r', 'filled')
scatter(times, bgIntPerVox./vertcat(timeStore(:).meanInt), 'b', 'filled')
xlabel('Time (s)')
ylabel('Mean intensity per voxel')
set(gca,'FontSize',15)
title('Averaged intensities per voxel type (bleach corr.)')
legend('Object Intensities (mean)', 'Background Intensities (mean)')

%% vol scaled ints over time
figure
hold on
scatter(times, blobInts./(blobInts+bgInts)./(blobVols/numel(currBlobs)), 'filled')

%%
figure
hold on
scatter(selectTimes*timeStep, blobInts./(blobInts+bgInts), 'r')
scatter(selectTimes*timeStep, bgInts./(blobInts+bgInts), 'b')
legend('Object Intensities (sum)', 'Background Intensities (sum)')
xlabel('Time (s)')
ylabel('Intensity fraction (normalized)')
set(gca,'FontSize',15)
title('Global intensity fraction per time')
%%
figure
hold on
scatter(selectTimes*timeStep, blobInts./(blobInts+bgInts), 'r')
scatter(selectTimes*timeStep, bgInts./(blobInts+bgInts), 'b')
legend('Object Intensities (sum)', 'Background Intensities (sum)')
xlabel('Time (s)')
ylabel('Intensity fraction (normalized)')
set(gca,'FontSize',15)
title('Global intensity fraction per time')
