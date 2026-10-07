%% Load epi foam data, extract features

% dataDir = '<redacted original absolute path>';
dataDir = '';
dataName = 't%i.tif';

selTimes = [8 54 220];
logKern = 3;

%%
tInd = 3;
currT = selTimes(tInd);
currTif = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT))));

%% 
selZ = 2;
kerns = 1:2:10;
storeMat = zeros(size(currTif,1),size(currTif,2),numel(kerns));
for index = 1:numel(kerns)
    storeMat(:,:,index) = LOG(currTif(:,:,selZ),kerns(index));
    % figure
    % imagesc(abs(test));
end