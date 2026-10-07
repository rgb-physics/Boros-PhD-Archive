%% Calculate fraction occupied by network over time
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
dataName = 't%03i_illBleachCorr16bit_%s.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';
% k4Name = 'a_t%03i_c001.tif';
selTimes = 1:220;
selChan = '560';
intConv = 50/17000;  %uM/intensity
threshVal = 35;

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end
%% 
% volFrac = selTimes;
% totInts = selTimes;
% % tInd = 1;
% for tInd = 1:numel(selTimes)
% currT = selTimes(tInd);
% currTif = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT,selChan))));
% cutOffLogic = currTif*intConv > threshVal;
% volFrac(tInd) = sum(cutOffLogic(:))/numel(cutOffLogic);
% totInts(tInd) = sum(currTif(:));
% end

%% Repeat but find borders with LOG
volFrac = selTimes;
totInts = selTimes;
% tInd = 1;
for tInd = 1:numel(selTimes)
currT = selTimes(tInd);
currTif = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT,selChan))));
procImg = LOG(currTif,4);
cutOffLogic = ~(procImg>5);
% cutOffLogic = currTif*intConv > threshVal;
volFrac(tInd) = sum(cutOffLogic(:))/numel(cutOffLogic);
totInts(tInd) = sum(currTif(:));
end
save(fullfile(saveDir,'volumeFractionData_MT.mat'),'totInts',"volFrac","threshVal","selChan");

