
rgbWeights = [.299 .587 .114];

% Watermelon
colorMat1 = min(255,[[100,0,100];  [242, 134, 144];  [0 180 100] ]); % watermelon
% Get bw weighting
wCMat = colorMat1.*rgbWeights;
bwVals1 = sum(wCMat,2);

% minty night
colorMat2 = min(255,[[10,0,105]; [150, 100, 170]; [150 220 190] ]); % minty night
% Get bw weighting
wCMat = colorMat2.*rgbWeights;
bwVals2 = sum(wCMat,2);

% match fractions
bwFrac = bwVals1./bwVals2;
bwDiff = bwVals1 - bwVals2;
colorMatNew = colorMat2.*(1 + bwDiff./bwVals2)

colorMatNew = colorMat2.*bwFrac

