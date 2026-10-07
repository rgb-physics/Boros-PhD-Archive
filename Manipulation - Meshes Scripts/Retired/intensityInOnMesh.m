% This script iterates through a series of mesh objects and calculates the
% mean intensity inside each mesh and on the surface of each mesh.

%% Define mesh directory
% meshDir = '<redacted original absolute path>';
meshDir = 'Session 12, Exp 4';
meshNameForm = 'T%0.2i.ply';
% tifDir = '<redacted original absolute path>';
tifDir = 'Session 12, Exp 4';
tifNameForm = 'Time%0.6i.tif';
timeRangeTifs = 0:26; timeRangeMeshes = 1:27; flipNorms = 0;
pixSize = 0.55;     %um/pix
bgMean = 17500;       %Mean background intensity in ORIGINAL TIFs (16 or 8bit)

%% Iterate through each mesh and get info
intVolDensity = zeros(size(timeRangeMeshes));
intSurfDensity = intVolDensity;
meshVols = intVolDensity; meshSurfs = intVolDensity;
meanVolInts = intVolDensity; meanSurfInts = intVolDensity;
scaledBGs = intVolDensity;

for currMesh = 1:numel(timeRangeMeshes)
    
    %Load tif
    currTif = tiffreadVolume(fullfile(tifDir, sprintf(tifNameForm, timeRangeTifs(currMesh))));
    maxVal = double(max(currTif, [], [1 2 3])); minVal = double(min(currTif, [], [1 2 3]));
    currTif = im2double(currTif);
    scaledBGs(currMesh) = (bgMean - minVal)/(maxVal - minVal); 
    
    %Load mesh and get bounds
    meshObj = read_ply_mod(fullfile(meshDir, sprintf(meshNameForm, timeRangeMeshes(currMesh)))) ;
    [xmin] = min(meshObj.v);
    [xmax] = max(meshObj.v);
    %Generate coordinate matrices
    [rowMat, colMat, zMat] = meshgrid(xmin(1):xmax(1), xmin(2):xmax(2), xmin(3):xmax(3));
    XYZ = [rowMat(:) colMat(:) zMat(:)];
    
   %Get indices bounded by object surface perimeter
    meshObj.vertices = meshObj.v; meshObj.faces = meshObj.f;
    contentVec = inpolyhedron(meshObj, XYZ, 'flipNormals',flipNorms);
    contentMat = reshape(contentVec, size(rowMat));
    
    %Get surface area and volume
    [objInfo] = regionprops3( bwconncomp(contentMat),'SurfaceArea','Volume','Centroid');
    objInfo.SurfaceArea = objInfo.SurfaceArea*pixSize^2;
    objInfo.Volume      = objInfo.Volume*pixSize^3;
    
    %Get mean intensity/volume
    intVolDensity(currMesh) = sum(currTif(logical(contentMat)), [1 2 3])/( objInfo.Volume );
    meshVols(currMesh) = objInfo.Volume;
    
    %Define barycenter coordinates of each face
    bcs = barycenter(meshObj.v, meshObj.f) ;
    
    %Get intensity values on surface face barycenters
    [xmin] = [1 1 1];
    [xmax] = size(currTif);
    [rowMat, colMat, depthMat] = ndgrid(xmin(1):xmax(1), xmin(2):xmax(2), xmin(3):xmax(3));
    ginterpInt = griddedInterpolant(rowMat, colMat, depthMat, (currTif));
    ints_faces = ginterpInt(bcs(:,1), bcs(:,2), bcs(:,3));
    
    %Get mean intesnity/surface area
    intSurfDensity(currMesh) = sum(ints_faces)/( objInfo.SurfaceArea );
    meshSurfs(currMesh) = objInfo.SurfaceArea;
    
    %Store mean intensity
    meanSurfInts(currMesh) = mean((currTif), [1 2 3])/(xmax(1)*xmax(2)*xmax(3)*pixSize^2);
    meanVolInts(currMesh) = mean((currTif), [1 2 3])/(xmax(1)*xmax(2)*xmax(3)*pixSize^3);
end

%% Normalize densities
normSurfDensity = (intSurfDensity-min(intSurfDensity))/(max(intSurfDensity)-min(intSurfDensity));
normVolDensity = (intVolDensity-min(intVolDensity))/(max(intVolDensity)-min(intVolDensity));

%%
close all
figure
plot([1:27]*20, meshVols,'Color',[55 6 101]/255,'LineWidth',5)
hold on
plot([1:27]*20, meshSurfs*pixSize,'Color',[241 74 22]/255,'LineWidth',5)
scatter((1:27)*20, meshVols, 30,([53 88 154])/255, 'filled')
scatter((1:27)*20, meshSurfs*pixSize,30, ([252 153 24])/255,'filled')
xlabel('Time (sec)')
ylabel('Volume (\mum^3)')
title('Cell Size Over Time')
% legend('Volume','Bounding Surface Volume')
set(gca, 'FontSize', 15)

figure
plot((1:27)*20, normVolDensity, 'Color', [55 6 101]/255, 'LineWidth', 5)
hold on
plot((1:27)*20,  normSurfDensity, 'Color', [241 74 22]/255, 'LineWidth', 5)
scatter((1:27)*20, normVolDensity, 30, ([53 88 154])/255,'filled')
scatter((1:27)*20, normSurfDensity, 30, ([252 153 24])/255,'filled')
xlabel('Time (sec)')
ylabel('Normalized Intensity Density')
title('Normalized Intensity Density Over Time')
% legend('Volume','Bounding Surface Volume')
set(gca, 'FontSize', 15)
ylim([-.05 1.2])



