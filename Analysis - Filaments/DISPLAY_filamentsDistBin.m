%% Display filaments on data using distance to color (for binning)
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 83';
imgName = 't%03i_illBleachCorr16bit_560.tif';
% filDataDir = '<redacted original absolute path>';
filDataDir = 'Session 83';
filDataName = 'Concatenated_2D_Info.mat';
% distDir = '<redacted original absolute path>';
distDir = 'Session 83';
distName = 'distBins_T%03i.tif';
% saveDir ='<redacted original absolute path>';
saveDir ='Session 83';
saveName = 'Time%06i_Qaligns.png';

currSlice = 38;
padLim = 1;
fieldBounds = [6000 21000];
timeRange = 2:40;
% Filament filter parameters
minVol = 8;                 % pixels (allVols)
minLength = 2;              % pixels (majAxes)
minAR = 1.5;                % Ratio major/minor axes (aspectRatio)
% selectSetInd = 1;            % Numbered data set (subIndsVec) (relevant when concatenated filaments over multiple directories)
selColors = [47 173 120; 35 235 180; 190 25 150; 145 30 90];

%% Load
load(fullfile(filDataDir,'FilamentAlignment_AngleDataREDO.mat'))
load(fullfile(filDataDir,filDataName));
load(fullfile(distDir,'metadata.mat'));     % unscaledEdges should have bin edges in um
generalFilt = filterStruct.filter;
alignsField = tensorAligns;

%% Overlay filaments on segmentation
for tInd = 1:numel(timeRange)
    
    % Prepare variables
    currT = timeRange(tInd);
    newFilt = generalFilt & (objInds == currT);     % Update filter for current time

    if ~exist(saveDir,'dir')
        mkdir(saveDir);
    end
    % Load data
    bgData = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
    currDisp = squeeze(bgData(:,:,currSlice,:));
    distData = double(tiffreadVolume(fullfile(distDir,sprintf(distName,currT))));
    scDists = imresize3(distData,size(bgData),'nearest');
    scDists = min(255,max(0, scDists));
    currDists = scDists(:,:,currSlice);
    
    % Define logic for filaments at this time and z
    tempLogic = newFilt & ismember(sliceInds,(-padLim:padLim)+currSlice);
    % Iterate through each bin, display filaments within bin; bin1 = 0
    for binInd = 2:numel(binTifVals)
        
        currBin = binTifVals(binInd);
        % Search CoMs, rounded
        currDistInds = find(currDists == currBin);
        
    end

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