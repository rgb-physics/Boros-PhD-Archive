%% Look at supplemental figure 3 from 2013 RS paper

% dataDir = '<redacted original absolute path>';
dataDir = '';
% dataName1 = 'StaticGFP-PRC1_2013SupF3B.tif';
dataName = 'StaticGFP-PRC1_2013SupF3D.tif';
xScale = 2.5;       % um
yScale = 20;        % seconds
onChan = 1;
offChan = 2;    

%%
% tif1 = tiffreadVolume(fullfile(dataDir,dataName1));
tif = tiffreadVolume(fullfile(dataDir,dataName));

%% Set scale
figure
imagesc(squeeze(tif));
xCoords = ginput(2);
yCoords = ginput(2);
% Get length of scale bars using ginput
xLen = abs(diff(xCoords(:,1)));
yLen = abs(diff(yCoords(:,2)));

% Rescale lengths
pixSize = [xScale/xLen yScale/yLen];        % [um/pix s/pix]

%% Measure slopes for on velocities (v_lattice)
sampNum = 5;

imagesc(squeeze(tif(:,:,:,onChan)));
onSlopes = ginput(2*sampNum);

%% Calculate slopes
slopeDiffs = abs(diff(onSlopes));
validSlopes = slopeDiffs(1:2:end,1)./slopeDiffs(1:2:end,2)*pixSize(1)/pixSize(2);

%% autocorr
cropImg = squeeze(tif(5:220,10:120,:,onChan));
shiftImg = cropImg - mean(cropImg(:));
aCorr = xcorr2(shiftImg,shiftImg);        

%% Get velocity for off velocities (v_endtag)
timeRange = 2:4:150;
tagRange = 150:203;
smthKern = 5;
cutOffInt = 50;

offImg = squeeze(tif(timeRange,tagRange,:,offChan));
smoothImg = movmean(offImg',smthKern)';
threshImg = smoothImg > cutOffInt;
cumSumImg = cumsum(threshImg,2);
widths = max(cumSumImg,[],2);

masses = sum(smoothImg,2);
% figure
% imagesc(offImg)
% figure
% plot(movmean(offImg',10))
% test
% colororder(test(1:10:end,:))

figure
scatter(timeRange*pixSize(2),widths*pixSize(1),20,'black','filled')
box on
xlabel('time (sec)')
ylabel('width (um)')


