function deployElidarExe
% Rename README.txt
lidarPath = fileparts(which(mfilename));
readme = fullfile(lidarPath, 'README.txt');
newReadme = fullfile(lidarPath, 'README.txt_tmp');
readmeE = fullfile(lidarPath, 'readme.txt');
exeReadme = fullfile(lidarPath, 'README_EXE.txt');
appName = fullfile(lidarPath, 'VisualApp.exe');
appName2 = fullfile(lidarPath, 'ELiDAR.exe');
movefile(readme, newReadme);

% Deploy GUI
mcc -e ELiDAR.mlapp -o VisualApp

% Move exe readme
movefile(readmeE, exeReadme);

% Move text file back
movefile(newReadme, readme);

% Rename visual app
movefile(appName, appName2);
end