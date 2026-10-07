%% Takes in obj .mat files, returns tifs of objects
% An overview for lableing objects by color as well
% 2024-06-04 - Rémi Boros

%% Data directories
% ccDir = '<redacted original absolute path>';
ccDir = 'Session 84';
ccName = 'objIDs_T%06i.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';
saveName = 'sizeLabeled_T%06i.tif';

selectTimes = 1:200;

%% Iterate over time
for tInd = 1:numel(selectTimes)
    %Instantiate
    if tInd == 1 && ~exist(saveDir,'dir')
        mkdir(saveDir);
    end
    % Load
    currT = selectTimes(tInd);
    currdir = fullfile(ccDir,sprintf(ccName,currT));
    if isfile(currdir)
        load(currdir);
    else
        continue
    end
    % Extract indices and generate weights
    currInds = currCC.PixelIdxList';
    objVols = cellIndSizes(currInds);
    scalingVec = genericLenVec(objVols);
    
    % Generate the tif, scale to 16-bit
    currTif = zeros(currCC.ImageSize);
    currTif(vertcat(currInds{:})) = scalingVec/numel(currTif)*(2^8-1)*(2^7);
    
    % Save
    save3DTiff(uint16(currTif),fullfile(saveDir,sprintf(saveName,currT)));

end
