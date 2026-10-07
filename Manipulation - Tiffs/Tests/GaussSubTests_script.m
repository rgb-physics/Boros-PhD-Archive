%% data
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 28, Exp 6';
dataNameForm = 'slice35_%04i.tif';
% renormDir = '<redacted original absolute path>';
renormDir = 'Session 28, Exp 6';
renormNameForm = 'renorm_%04i.tif';
selectTimes = 0:290;
gKernel = 15;
firstFileNorm = 1;

mkdir(renormDir);
%% normalize
firstTif = tiffreadVolume(fullfile(dataDir,sprintf(dataNameForm,selectTimes(1))));
save3DTiff(firstTif, fullfile(renormDir,sprintf(renormNameForm,selectTimes(1))));

for tInd = 2:numel(selectTimes)

    currT = selectTimes(tInd);
    currTif = double(tiffreadVolume(fullfile(dataDir,sprintf(dataNameForm,currT))));
    currRenorm = currTif./double(firstTif)*median(currTif(:));
    save3DTiff(uint16(currRenorm), fullfile(renormDir,sprintf(renormNameForm,currT)));

end

%% Plot histograms, shifted by intensity fraction
numBins = 100;
[a,b] = histcounts(firstTif(:),numBins);
for tInd = 2:10:numel(selectTimes)

    currT = selectTimes(tInd);
    currTif = double(tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm,currT))));
    [c,d] = histcounts(currTif(:), numBins);
    subplot(1,2,1)
    scatter(b(2:end)*sum(currTif(:))/sum(firstTif(:)), a, 20, [tInd/numel(selectTimes) 0 (1-tInd/numel(selectTimes))],'filled')
    hold on
    subplot(1,2,2)
    scatter(d(2:end), c, 20, [tInd/numel(selectTimes) 0 (1-tInd/numel(selectTimes))],'filled')
% scatter(tInd,sum(currTif(:))/sum(firstTif(:)),'filled')
    hold on

end

%% Given a rescaled histogram, rescale pixel values in matrix
tInd = 150;
numBins = 100;
[bins,edges,binInds] = histcounts(firstTif(:), numBins);
currTif = double(tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm,currT))));
scaleFact = sum(currTif(:))/sum(firstTif(:));
scaledBins

%% Seungwoo Test
% swDir = '<redacted original absolute path>';
swDir = 'Session 28, Exp 6';
swName = 'Time000020_16bitcropped.tif';
saveName = '_passVal%i.tif';
carveSizes = 1:30;

swTif = double(tiffreadVolume(fullfile(swDir,swName)));

for carveInd = 1:numel(carveSizes)
    
    currCarve = carveSizes(carveInd);
    fftImg = fftshift(fft2(ifftshift(swTif)));
    hpfftImg = fftImg;  lpfftImg = fftImg;
    hpfftImg((floor(end/2)+1-currCarve):(floor(end/2)+1+currCarve),(floor(end/2)+1-currCarve):(floor(end/2)+1+currCarve))=0;
    lpfftImg(logical(abs(hpfftImg))) = 0;
    hpImg = fftshift(ifft2(ifftshift(hpfftImg)));
    lpImg = fftshift(ifft2(ifftshift(lpfftImg)));
    save3DTiff(uint16(hpImg+5000),fullfile(swDir, ['hp_' sprintf(saveName, currCarve)]));
    save3DTiff(uint16(lpImg),fullfile(swDir, ['lp_' sprintf(saveName, currCarve)]));
end

%% chebfun testing
scaleVal = .25;
test = imresize(swTif,scaleVal);
f = chebfun2(test-mean(test(:)),[1 size(test,1) 1 size(test,2)] - 1);
% f = chebfun2(ff);
levels = 1:189;
contour(f,levels), axis([1 size(test,1) 1 size(test,2)] - 1), axis square
title(['rank ' int2str(length(f))],'fontsize',12)

%% Use MATLAB fit
scaleVal = .25;
test = imresize(swTif,scaleVal);
[xmat,ymat] = ndgrid(1:size(test,1), 1:size(test,2));
testfit = fit([xmat(:) ymat(:)],test(:),'poly55');
plot(testfit,[xmat(:) ymat(:)],test(:))

f = fit([T.x, T.y],T.z,'linearinterp');

% p00 + p10*x + p01*y + p20*x^2 + p11*x*y + p02*y^2 + p30*x^3 +
%                      p21*x^2*y + p12*x*y^2 + p03*y^3 + p40*x^4 + p31*x^3*y 
%                     + p22*x^2*y^2 + p13*x*y^3 + p04*y^4 + p50*x^5 + p41*x^4*y 
%                     + p32*x^3*y^2 + p23*x^2*y^3 + p14*x*y^4 + p05*y^5

