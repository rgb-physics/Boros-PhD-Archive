%% Take in mask and data, get values
% dataDir = '<redacted original absolute path>';
dataDir = '';
dataName = '20241127_kif4-gfp-afterCleavag-FINAL.tif';
maskName = '20241127_kif4-gfp-afterCleavag-FINAL_Object Predictions.tiff';       
maskVal = 1;

%% Subsample data using mask
dataIn = tiffreadVolume(fullfile(dataDir,dataName));
maskIn = tiffreadVolume(fullfile(dataDir,maskName));

dataFlip = abs(double(dataIn) - 255);
prodMat = consMatLnB(dataFlip,maskIn == maskVal);
imwrite(uint8(prodMat),fullfile(dataDir,'maskedBSAData.tif'));

%% Get total intensities of each object
objInds = bwconncomp(maskIn == maskVal);
objProps = regionprops(objInds,prodMat,'Area','Centroid','MeanIntensity');

%% Convert to concentrations
bsaConc = 2;                % in mg/ml, pre-dilution
bsa2protRatio = 1;          % not 1 if BSA and protein were diluted differently with SDS
bsaVols = [1, 2, 4];        % in uL
kifVols = [2.5 7.5];        % in uL
meanBGInt = 30;             % No idea why it's so high...
% meanBGInt = 255-204;

bsaObjInds = 1:3;  kifObjInds = 4:5;

% Shift background signal from mean intensities, then scale by object areas
bsaMassSig = ([objProps(bsaObjInds).MeanIntensity]- meanBGInt).*[objProps(bsaObjInds).Area];
% test = ([objProps(bsaObjInds).MeanIntensity]).*[objProps(bsaObjInds).Area];
% Two ways to get slope in intensity/uL
massSlopes = diff(bsaMassSig)./diff(bsaVols);
p = polyfit(bsaVols,bsaMassSig,1);
pSlope = p(1);

% Get mean prot masses
protMassSig = ([objProps(kifObjInds).MeanIntensity]- meanBGInt).*[objProps(kifObjInds).Area];

bsaMassSig./bsaMassSig(1)
protMassSig./protMassSig(1)

%%
x1 = linspace(0,6);
y1 = polyval(p,x1);

scatter((bsaVols),bsaMassSig)
hold on
plot(x1,y1)
% xlim([0 5])
% ylim([0 1])

%% By hand
bsaInds = 1:3;  protInds = 4:5;
bsaVols = [1 2 4];
protVols = [2.5 7.5];

areas = [600 1113 1824 196 500];
rawMeanInts = [119 112 103 148 127];
meanInts = abs(rawMeanInts - 255);

meanIntBG = abs(210 - 255);

meanMasses = areas.*(meanInts - meanIntBG);

massSlopes = diff(meanMasses(bsaInds))./diff(bsaVols);
p = polyfit(bsaVols,bsaMassSig,1);
pSlope = p(1);


