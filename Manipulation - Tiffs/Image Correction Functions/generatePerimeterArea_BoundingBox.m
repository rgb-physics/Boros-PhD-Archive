function [perimeterMat, areaMat] = generatePerimeterArea_BoundingBox(holeBox,imgSize,perWidth)
%GENERATEPERIMETER_BOUNDINGBOX Takes in a vector HOLEBOX of bounding box
%information structured as [xmin ymin xwidth ywidth], a vector IMGSIZE
%with the dimensions of the the object is located, and a scalar PERWIDTH
%indicating the desired width of the perimeter surrounding the bounding box.
%The function returns a logic matrix with 1s stored along a perimeter
%outlining the bounding box stored in HOLEBOX with a width (in
%indices/pixels) corresponding to PERWIDTH. It does so taking the 
%difference of two rectangular regions, one corresponding to the area
%contained WITHIN the bounding box and the second PERWIDTH pixels larger.
%It also returns the matrix indicating the locations of pixels WITHIN the
%corresponding bounding box

% Generate first area matrix
areaMat = generateArea_BoundingBox(holeBox,imgSize);

% Generate second area matrix
matExtension = [-perWidth -perWidth 2*perWidth 2*perWidth];
extArea = generateArea_BoundingBox(holeBox + matExtension, imgSize);

% Generate perimeter
perimeterMat = xor(extArea, areaMat);

end

