%% Display
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 83';
imgName = 't%03i_illBleachCorr16bit_560.tif';
% filDataDir = '<redacted original absolute path>';
filDataDir = 'Session 83';
filDataName = 'Concatenated_2D_Info.mat';
% saveDir ='<redacted original absolute path>';
saveDir ='Session 83';
saveName = 'Time%06i_Qaligns.png';

currSlice = 38;
padLim = 1;
fieldBounds = [6000 21000];
timeRange = 1:50;
% Filament filter parameters
minVol = 8;                 % pixels (allVols)
minLength = 2;              % pixels (majAxes)
minAR = 1.5;                % Ratio major/minor axes (aspectRatio)
% selectSetInd = 1;            % Numbered data set (subIndsVec) (relevant when concatenated filaments over multiple directories)

%% Load
load(fullfile(filDataDir,'FilamentAlignment_AngleDataREDO.mat'))
load(fullfile(filDataDir,filDataName));
generalFilt = filterStruct.filter;
alignsField = tensorAligns;

%% Overlay filaments on segmentation
for tInd = 1:numel(timeRange)
    
    currT = timeRange(tInd);
    newFilt = generalFilt & (objInds == currT);

    if ~exist(saveDir,'dir')
        mkdir(saveDir);
    end
    bgData = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
    currDisp = squeeze(bgData(:,:,currSlice,:));
    
    tempLogic = newFilt & ismember(sliceInds,(-padLim:padLim)+currSlice);
    tempAligns = min(1,max(0,alignsField(tempLogic)));
    imagesc(currDisp);
    clim(fieldBounds)
    colormap(flipud(gray))
    hold on
    plot(backboneXs(:,tempLogic),backboneYs(:,tempLogic),'LineWidth',3,'Color','white');
    plot(backboneXs(:,tempLogic),backboneYs(:,tempLogic),'LineWidth',2);
    colororder(([1; 0; 0].*tempAligns)' + ([0; 0; 1].*(1-tempAligns))');
    hold off
    imwrite(getframe(gcf).cdata,fullfile(saveDir,sprintf(saveName,currT)));

end