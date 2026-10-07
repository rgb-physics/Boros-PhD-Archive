%% Various scripts to write .csvs

%% .csv of power spectra of fft analysis
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
dataName = '600bin_powerSpectra_variables.mat';
load(fullfile(dataDir,dataName));
% Write table of scaled wavelengths
temp = table(scaledK');
temp.Properties.VariableNames = {'scaledKValues'};
writetable(temp,fullfile(dataDir,'scaledKValues.csv'));
% Write table of times
temp = table(selectTimes');
temp.Properties.VariableNames = {'scaledTimes'};
writetable(temp,fullfile(dataDir,'scaledTimes.csv'));
% Write .csvs for each powerspectra
for index = 1:size(storeMat,2)
    temp = table(squeeze(storeMat(:,index,:)));
    writetable(temp,fullfile(dataDir,sprintf('SpectraFromZ%02i.csv',selZ(index))));
end

%% .csv of r_min data from various data sets
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
dataName= 'sortedTraj_IntsVolsMinRs_Eroded.mat';
load(fullfile(dataDir,dataName));
temp = table(sortedMat(:,1),sortedMat(:,2),sortedMat(:,3),sortedMat(:,4),sortedMat(:,5));
temp.Properties.VariableNames = {'ObjID','Frame','ObjVol','ObjMass','ObjRmin'};
% writetable(temp,fullfile('<redacted original absolute path>','20x_Phi0_Rmin.csv'));
writetable(temp,fullfile('','20x_Phi0_Rmin.csv'));


% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
dataName= 'sortedTraj_IntsVolsMinRs_Eroded.mat';
load(fullfile(dataDir,dataName));
temp = table(sortedMat(:,1),sortedMat(:,2),sortedMat(:,3),sortedMat(:,4),sortedMat(:,5));
temp.Properties.VariableNames = {'ObjID','Frame','ObjVol','ObjMass','ObjRmin'};
% writetable(temp,fullfile('<redacted original absolute path>','20x_Phi100_Rmin.csv'));
writetable(temp,fullfile('','20x_Phi100_Rmin.csv'));


% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 3';
dataName= 'sortedTraj_IntsVolsMinRs_Eroded.mat';
load(fullfile(dataDir,dataName));
temp = table(sortedMat(:,1),sortedMat(:,2),sortedMat(:,3),sortedMat(:,4),sortedMat(:,5));
temp.Properties.VariableNames = {'ObjID','Frame','ObjVol','ObjMass','ObjRmin'};
% writetable(temp,fullfile('<redacted original absolute path>','60x_Phi100_Rmin.csv'));
writetable(temp,fullfile('','60x_Phi100_Rmin.csv'));

%% .csv of 3D power spectra
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
dataName = 'BleachCorr_500bin_powerSpectra_variables.mat';
load(fullfile(dataDir,dataName));
% Write table of scaled wavelengths
temp = table(scaledK');
temp.Properties.VariableNames = {'scaledKValues'};
writetable(temp,fullfile(dataDir,'scaledKValues.csv'));
% Write table of times
temp = table(selectTimes');
temp.Properties.VariableNames = {'scaledTimes'};
writetable(temp,fullfile(dataDir,'scaledTimes.csv'));
% Write .csvs for each powerspectra
    temp = table(storeMat);
    writetable(temp,fullfile(dataDir,'SpectraFrom3D.csv'));

%% .csv of rmin statistics S88 e1-5
% dataDirs = {'<redacted original absolute path>',...
dataDirs = {'Session 88, Exp 1',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 2',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 3',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 5',...
    % '<redacted original absolute path>'};
    'Session 88, Exp 4'};

saveNames = {'S88_E1_RStats.csv',...
    'S88_E2_RStats.csv',...
    'S88_E3_RStats.csv',...
    'S88_E5_RStats.csv',...
    'S88_E4_RStats.csv'};

for dirInd = 1:numel(dataDirs)   

    dataDir = dataDirs{dirInd};
% dataName = 'sorted_RMinStatistics.mat';

% load(fullfile(dataDir,dataName));
% storeMat = sparse(1,1);
% 
% for index = 1:numel(rMinStats)
% 
%     currVec = rMinStats(index).MinAxStats';
%     if index == 1
%         writematrix(currVec,fullfile(dataDir,'rminStats.csv'));
%     else
%         writematrix(currVec,fullfile(dataDir,'rminStats.csv'),'WriteMode','append');
%     end
%     % storeMat(1:numel(currVec),index) = currVec;
% 
% end

dataName= 'sortedTraj_IntsVolsMinRs_ErodedScaled2.mat';
load(fullfile(dataDir,dataName));
temp = table(sortedMat(:,1),sortedMat(:,2),sortedMat(:,3),sortedMat(:,4),sortedMat(:,5));
temp.Properties.VariableNames = {'ObjID','Frame','ObjVol','ObjMass','ObjRmin'};
writetable(temp,fullfile(dataDir,saveNames{dirInd}));

end
