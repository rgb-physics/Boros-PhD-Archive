% The bug: lines stop plotting as requested on certain iterations
% MATLAB Version R2023a
% Variable to change: Try 2, 3, 5, 8
iterationNum = 8;

% Less important variable: used for displaying
spacerVal = 10;
alphaVal = 0.2;
xData = 0:25;
testMeans1 = spacerVal/2*rand(size(xData));
testSTDs1 = spacerVal/2*rand(size(xData));
testMeans2 = spacerVal/2*rand(size(xData));
testSTDs2 = spacerVal/2*rand(size(xData));
% Display lines for shifting
shiftBases = ((1:iterationNum)-1)*spacerVal;
[xBG,yBG] = ndgrid([xData(1) xData(end)],shiftBases);
figure
plot(xBG,yBG,'black');
hold on

% Loop over iterations and plot; use breakpoints or ginput() if you want to
% pause
for index = 1:iterationNum
    currColor = [index/iterationNum 0 (1-index/iterationNum)];
    yyaxis 'left'
    plotMeanStdPoly(testMeans1+shiftBases(index),testSTDs1,xData,currColor,alphaVal);
    yyaxis 'right'
    plotMeanStdPoly(testMeans2+shiftBases(index),testSTDs2,xData,currColor,alphaVal);
end

function [] = plotMeanStdPoly(meanVals,stdVals,xVals,currColor,alphaVal)
%PLOTMEANSTDPOLY Sloppy bundle function to plot meanVals with a bounding
%polygon of +/- stdVals.

% Generate a polynomial for background standard deviation
[stdPolyX,stdPolyY] = getPolyCoords(meanVals,stdVals,xVals);
nonanLogic = ~isnan(stdPolyY);
currPoly = polyshape(stdPolyX(nonanLogic),stdPolyY(nonanLogic));

% Plot
polyPlot = plot(currPoly);
hold on
polyPlot.FaceAlpha = alphaVal;
polyPlot.EdgeColor = 'none';
polyPlot.FaceColor = currColor;
% plot(xVals,meanVals,'Color',currColor,'LineWidth',2,'LineStyle','-')
plot(xVals,meanVals,'Color',currColor,'LineWidth',2,'LineStyle','--','Marker','none')

end

function [outXs,outYs] = getPolyCoords(yCoords,yHeights,xCoords)
%GETPOLYCOORDS Takes in a set of y-coordinates, y-heights, and optional 
% x-coordinates. Returns a set of coordinates that coorespond to a
% polynomial whose vertices are y-coordinates +/- y-heights at each
% corresponding x-coordinate. Used for plotting standard deviations over
% means.

% Define xCoords, if not passed
if nargin == 2
    xCoords = 1:numel(yCoords);
end

% Generate x-coordinates by reflecting
outXs = [xCoords(:); flipud(xCoords(:))]';

% y-coordinates go +height one way and -height the other way
outYsPlus = yCoords + yHeights;
outYsMinus = yCoords - yHeights;
outYs = [outYsPlus, fliplr(outYsMinus)];

end
