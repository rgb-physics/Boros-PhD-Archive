% Permute xyz to xzy
% 2025-07-14 - Rémi Boros

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 3';
dataName = 'T240_carved_%s.tif';
saveDir = dataDir;
saveName = ['permute_' dataName];

dataStrs = {'488','560'};

%%
for index = 1:numel(dataStrs)

    currStr = dataStrs{index};
    currImg = tiffreadVolume(fullfile(dataDir,sprintf(dataName,currStr)));
    outImg = permute(currImg,[ 3 2 1]);

    save3DTiff(uint16(outImg),fullfile(saveDir,sprintf(saveName,currStr)));


end