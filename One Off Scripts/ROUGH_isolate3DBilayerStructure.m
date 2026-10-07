%% Calculate fraction occupied by network over time
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 30';
dataName = 'Time%06i_raw%s.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 30';
if ~exist(saveDir,'dir')
    mkdir(saveDir)
end
% k4Name = 'a_t%03i_c001.tif';
% zRange = 20:90;
selTimes = 90;
mtChan = '488';
k4Chan = '488';
logicChan = mtChan;
threshVal = 150;
voxSize = [.3667 .3667 1.5];
desVox = [1 1 1];

gaussKern = 4;
dilKern = 4;

saveBool = 1;

%% Repeat but find borders with LOG
% tInd = 1;
volFrac = selTimes;
for tInd = 1:numel(selTimes)
    % tic
    currT = selTimes(tInd);
    currName = fullfile(dataDir,sprintf(dataName,currT,logicChan));
    if ~exist(currName,'file')
        continue
    end
    currTif = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT,logicChan))));
    % selRange = currTif(:,:,zRange);
    selRange = currTif;
    tifRS = imresize3(selRange,round(voxSize.*size(selRange)./desVox));
    procImg = LOG(-tifRS,4);
    % cutOffLogic = abs(procImg) > threshVal;
    cutOffLogic = (procImg) > threshVal;
    % dilLog = double(cutOffLogic);
    % cutOffLogic = tifRS < threshVal;
    dilLog = imdilate(cutOffLogic,strel('sphere',dilKern));
    smoothLog = imgaussfilt3(double(dilLog),gaussKern);

    if saveBool == 1
        outTif = tifRS.*smoothLog;
        save3DTiff(uint16(outTif),fullfile(saveDir,sprintf(['carved_' dataName],currT,mtChan)))
            
        % currTif = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT,mtChan))));
        % currRS = imresize3(currTif,round(voxSize.*size(currTif)./desVox));
        % outTif = currRS.*smoothLog;
        % save3DTiff(uint16(outTif),fullfile(saveDir,sprintf(['carved_' dataName],currT,mtChan)))
        % currTif = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT,k4Chan))));
        % currRS = imresize3(currTif,round(voxSize.*size(currTif)));
        % outTif = currRS.*smoothLog;
        % save3DTiff(uint16(outTif),fullfile(saveDir,sprintf(['carved_' dataName],currT,k4Chan)))
    end    
    volFrac(tInd) = sum(dilLog(:))/numel(dilLog);
    % toc
    % pause(.01)
end

save(fullfile(saveDir,'volumeFraction.mat'),'volFrac','selTimes');

%% Plot
frac2Shift = 140*2;
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 34, Exp 1';
load(fullfile(saveDir,'volumeFraction.mat'),'volFrac','selTimes');
selTimes2 = selTimes + frac2Shift;
volFrac2 = volFrac;
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 2';
load(fullfile(saveDir,'volumeFraction.mat'),'volFrac','selTimes');

figure
plot(selTimes/2,volFrac,'Color',[20 20 20]/255,'LineWidth',2)
hold on
plot(selTimes2/2,volFrac2,'Color',[20 20 50]/255,'LineWidth',2)

% xlim([0 122])
ylim([0.25 0.5])
xlim([80 165])
