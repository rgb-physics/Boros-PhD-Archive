% Shift all blob IDs to increase difference in values for 3D rendering
% 2026-09-14 - Rémi Boros


% ogDir = '<redacted original absolute path>';
ogDir = 'Session 81, Exp 2';
ogName = 'T%03i_trajIDs.tif';
newDir = fullfile(ogDir,'Zero Shifted Trajs');
newName = ogName;

selTimes = 1:60;
shiftVal = 40;

if ~exist(newDir,'dir')
    mkdir(newDir);
end

%% Iterate over time, shift non-zero index values, save new .tifs

for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    currImg = tiffreadVolume(fullfile(ogDir,sprintf(ogName,currT)));
    % Binarize mask
    imgMask = currImg>0;
    % Preliminary shift
    shftImg = currImg + shiftVal;
    % subsample shift with mask
    outImg = consMatLnB(shftImg,imgMask);

    % save
    save3DTiff(uint16(outImg),fullfile(newDir,sprintf(newName,currT)));
end