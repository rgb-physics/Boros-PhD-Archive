%% Takes in isolated drop, returns intensity profile through center over time
% info stored in segmented regions
% Rémi Boros - 2024-06-19

% Directory info
% blobDir = '<redacted original absolute path>';
blobDir = 'Session 85';
% tifDir = '<redacted original absolute path>';
tifDir = 'Session 85';
blobName = 't%03i_trajectory278.tif';       % Binary image
tifName = 't%03i_illBleachCorr16bit_560.tif';

selectTimes = 45:65;
imgScale = [1 1 4];
slopeStart = [490 110 165]';
slopeEnd = [350 330 195]';
lineCenter = [440 220 180]';

mergeTime = 53;


%% Calculate principle component at merge time
% Load and rescale
currT = mergeTime;  
currBlob = tiffreadVolume(fullfile(blobDir,sprintf(blobName,currT)));               
currTif = tiffreadVolume(fullfile(tifDir,sprintf(tifName,currT))); 
tifSize = size(currTif);
rescBlob = imresize3(currBlob,tifSize.*imgScale,'nearest');
objProps = regionprops3(rescBlob,'PrincipalAxisLength');
slopeVec = (slopeStart - slopeEnd)/sqrt(sum((slopeStart-slopeEnd).^2));
lineLen = objProps.PrincipalAxisLength;
slopeLine = repmat(-lineLen/2:.1:lineLen/2,3,1)*1.5;
princAxis = round(slopeVec.*slopeLine + lineCenter);
indices = sub2ind(size(rescBlob),princAxis(2,:),princAxis(1,:),princAxis(3,:));

% Construct vectorof unique indices/corresponding order
noRepeats = find(diff([indices 0])~=0);
uniqueInds = indices(noRepeats);
dispLen = 1:numel(uniqueInds);          % This is approx.

%% Sample ints along selected cross section
crossSecInts = zeros(numel(uniqueInds),numel(selectTimes));
totalMass = zeros(numel(selectTimes),1);
totalVol = zeros(numel(selectTimes),1);

for tInd = 1:numel(selectTimes)
    % Load and rescale
    currT = selectTimes(tInd);  
    currBlob = tiffreadVolume(fullfile(blobDir,sprintf(blobName,currT)));               
    currTif = tiffreadVolume(fullfile(tifDir,sprintf(tifName,currT))); 
    blobSize = size(currBlob);  tifSize = size(currTif);
    rescBlob = logical(imresize3(currBlob,tifSize.*imgScale,'nearest'));
    rescTif = imresize3(currTif,tifSize.*imgScale);
    crossSecInts(:,tInd) = rescTif(uniqueInds);
    totalMass(tInd) = sum(rescTif(rescBlob));
    totalVol(tInd) = sum(rescBlob(:));
end


%% Plot
subTimes = 5:16;
shiftVal = 5000;
bgShift = 9000;
rollAvgWin = 1;

[a,b] = meshgrid(selectTimes(subTimes)*30,1:size(crossSecInts,1));
% surf(a,b,movmean(crossSecInts(:,subTimes),10)','EdgeColor','none')

shiftVec = shiftVal*((1:numel(subTimes))-1);
plot(movmean(crossSecInts(:,subTimes),rollAvgWin) + shiftVec - bgShift,'LineWidth',3);
hold on

timeColorVec = [0 183 235; 255 120 0]/255;
% timeColorStamps = [1 25 50 75 100];
timeColorStamps = [1 numel(subTimes)];     % Session 35 exp 2
% timeColorStamps = [1 12 25 60 100];     % Session 35 exp 1
timeColorArray = stitchGradients(timeColorVec,timeColorStamps);
colororder(timeColorArray);

plot(repmat([1 size(crossSecInts,1)],numel(subTimes),1)',repmat(shiftVec',1,2)','Color','black','LineWidth',1,'LineStyle', '--')

ylim([0 63000])
set(gca,'FontSize',15)
ylabel('Intensity Sampled Along Cross Section')
xlabel('\Deltar')

%% Sample ints in selected chans

strelObj = strel('sphere',2);

tInd = 1;

% Load and rescale
currT = selectTimes(tInd);  
currBlob = tiffreadVolume(fullfile(blobDir,sprintf(blobName,currT)));               
currTif = tiffreadVolume(fullfile(tifDir,sprintf(tifName,currT))); 
blobSize = size(currBlob);      tifSize = size(currTif);
rescBlob = imresize3(currBlob,tifSize.*imgScale,'nearest');
rescTif = imresize3(currTif,tifSize.*imgScale);
% Calculate signed distance transform from perimeter
currPerim = rescBlob - imerode(rescBlob,strelObj);
regionFlip = ~rescBlob - logical(rescBlob);  
distMat = bwdist(currPerim).*regionFlip;

%% TEMP EMERGENCY
% Images without perimeters
selTimes = [300 540 1110 1470 2190]/30;
selZ = 45;
% newSaveDir = '<redacted original absolute path>';
newSaveDir = 'Session 85';

for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);  
    currBlob = tiffreadVolume(fullfile(blobDir,sprintf(blobName,currT)));               
    currTif = tiffreadVolume(fullfile(tifDir,sprintf(tifName,currT))); 
    blobSize = size(currBlob);  tifSize = size(currTif);
    rescBlob = logical(imresize3(currBlob,tifSize.*imgScale,'nearest'));
    rescTif = imresize3(currTif,tifSize.*imgScale);
    % Calculate signed distance transform from perimeter
    currPerim = rescBlob - imerode(rescBlob,strelObj);
    noPerim = double(consMatLnB(rescTif,~logical(currPerim)));
    selPerimSlice = currPerim(:,:,selZ*imgScale(3))*((2^16)-1);
    selNoPerimSlice = noPerim(:,:,selZ*imgScale(3)) + selPerimSlice;

    save3DTiff(uint16(selNoPerimSlice),fullfile(newSaveDir,sprintf('NoPerimSubsampled_560_t%03i.tif',currT)));
    save3DTiff(uint16(selPerimSlice),fullfile(newSaveDir,sprintf('OnlyPerimSubsampled_560_t%03i.tif',currT)));
    
end



