%% Global quantity averages at each time in, on, and outside of segmented drops
% 2025-02-14 - Rémi Boros

% segDir = '<redacted original absolute path>';
segDir = 'Session 81, Exp 3';
segName = 'DownscaledSeg_t%03i_illBleachCorr16bit.tif';
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 3';
dataName = 't%03i_illBleachCorr16bit_560.tif';
% dataDir = 'Session 81, Exp 3';
% dataName = 'Time%06i_raw560.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';
saveName = 'inOnOut_volMassRho.mat';
selTimes = 60;
deltaT = 30/60;
pixSize = [.36 .36 1.5];

outInOn = [1 3 2];      % in order of intensity

storeSlice = 25;

cropBool = 0;
cropCorner = [1 15 1];
winSize = [785 770 69];

%% Iterate over time, load data, histcounts, sample and store
totVols = zeros(numel(selTimes),numel(outInOn));
totInts = totVols;      totRhos = totVols;
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    currInts = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT))));
    currSegs = double(tiffreadVolume(fullfile(segDir,sprintf(segName,currT))));

    if cropBool == 1
        [currInts] = cropTiffSave(currInts,cropCorner,winSize,0,'');
    end
    % Ensure sizes of segmentations and image match
    if tInd == 1
        sizeBool = sum( size(currInts) == size(currSegs) );
        checkIntsMat = zeros(size(currInts,1),size(currInts,2),numel(selTimes),3);
    end
    if sizeBool > 0
        currSegs = imresize3(currSegs,size(currInts));
    end
    % Bin segmentations to clean
    [globalVols,~,channelInds] = histcounts(currSegs,numel(outInOn));

    % Store total volumes
    totVols(tInd,outInOn)  = globalVols;
    % Store total intensities
    for chanInd = 1:numel(outInOn)
        currChan = outInOn(chanInd);
        tempIntsSample = consMatLnB(currInts,channelInds == currChan);
        totInts(tInd,chanInd) = sum(tempIntsSample(:));
        checkIntsMat(:,:,tInd,currChan) = tempIntsSample(:,:,storeSlice);
    end

end

%% Save
save(fullfile(saveDir,saveName),'totVols','totInts','totRhos','selTimes','deltaT');

%% Distribution of intensities for each region
figure
binVals = 10:50:4000;
for chanInd = 1:numel(outInOn)
    currChan = outInOn(chanInd);
    tempIntsSample = consMatLnB(currInts,channelInds == currChan);
    histogram(tempIntsSample,binVals);
    hold on
end
legend('out','in','on')
%% plot densities over time
figure
% plot(selTimes*deltaT,totInts)
% plot(selTimes*deltaT,totVols)
% loglog(selTimes*deltaT,sum(totInts(:,2:3),2)./sum(totVols(:,2:3),2));
plot((selTimes*deltaT),(totInts./totVols))
% loglog(selTimes*deltaT,sum(totInts(:,2:3),2))
legend('out','in','on')
box on
xlabel('Time (m)')
ylabel('Densities')
set(gca,'FontSize',15)

%% Estimate radii - plot values against radii


%% Plot density ratios over time
rhos = totInts./totVols;
figure
hold on
plot(selTimes*deltaT,rhos(:,2)./rhos(:,1));
plot(selTimes*deltaT,rhos(:,3)./rhos(:,1));
plot(selTimes*deltaT,rhos(:,1)./rhos(1,1));
legend('in/out','on/out','out/out_{T1}')
box on
xlabel('Time (m)')
ylabel('Density Ratios')
set(gca,'FontSize',15)

%% Plot [MT] concentration
figure
plot(selTimes*deltaT,(totInts./totVols)*(sum(totVols(1,:))./sum(totInts(1,:)))*42)
legend('out','in','on')
box on
xlabel('Time (m)')
ylabel('Densities')
set(gca,'FontSize',15)