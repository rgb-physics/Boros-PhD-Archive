function [meanCorrs, vanHove] = radialAutoCorr(fieldData,ringBin, subWin)
%RADIALAUTOCORR Takes in a field and number of bins to average over
%and returns the auto-correlation of said field radially averaged over its
%dimensions. Subwin is an option parameter that describes a window over
%which the correlation should be queried. Said window must not be larger 
%than the size of the input field. Input field should be 2D or 3D. If input
%data is 3D, radial averaging is over concentric spheres

%Store field dimensions
fieldDims = size(fieldData);

%Define subWin if not passed
if nargin == 2
    subWin = min(size(fieldData));
else
    subWin = min(subWin, min(fieldDims/2));
end

%Sub-window indices
queryRange = -subWin:subWin;

%Pad data for fft
currPadded = padarray(fieldData, ceil(size(fieldData)/2), 0); %pad array for proper fftn
%Get autocorrelation/van Hove of padded data
vanHove = generateVanHove(currPadded);

%Get inner field
if numel(fieldDims) == 2
    subvanHove = vanHove(fieldDims(1) + queryRange, fieldDims(2) + queryRange);
else
    subvanHove = vanHove(fieldDims(1) + queryRange, fieldDims(2) + queryRange, fieldDims(3) + queryRange);
end

%Radially average and store in vector
radialMat = generateRadialMatrix(size(subvanHove),ringBin);
meanCorrs = zeros(ringBin,1);
for currBin = 1:ringBin
    meanCorrs(currBin) = mean(subvanHove( radialMat == currBin ), 'all');
end
meanCorrs = meanCorrs/max(meanCorrs(:));

end

