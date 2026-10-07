% dataDir = '<redacted original absolute path>';
dataDir = 'Session 28, Exp 6';
stackName = 'scaledDown2x_z%02i.tif';
saveDir = dataDir;
saveName = ['IntScaled_' stackName];
selectZ = 25:5:35;

%% load
firstStack = (tiffreadVolume(fullfile(dataDir,sprintf(stackName,selectZ(1)))));

%% Get total intensities for each layer
totInts = zeros(size(firstStack,3),numel(selectZ));
for currLayer = 1:numel(selectZ)

    layNum = selectZ(currLayer);
    currTif = double(tiffreadVolume(fullfile(dataDir, sprintf(stackName, layNum))));
    totInts(:,currLayer) = sum(double(tiffreadVolume(fullfile(dataDir, sprintf(stackName, layNum)))), [1 2]);
    IntScale = permute(repmat(totInts(:,currLayer),[1, size(firstStack,2), size(firstStack,1)]), [3,2,1]);
    save3DTiff(uint16(currTif./IntScale*IntScale(1)), fullfile(saveDir,sprintf(saveName,layNum)));

end