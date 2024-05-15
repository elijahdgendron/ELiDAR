function deployElidarExe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Elijah Gendron
% 05/15/2024
%
% DESCRIPTION:
%   When deploying the exe GUI, a new readme file will overwrite the existing one.
%
% INPUTS:
%   N/A
%
% OUTPUTS:
%   README_EXE.txt will be updated
%   ELiDAR.exe will be updated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Get existing/ expected paths
lidarToolPath = fileparts(which(mfilename));                    % ELiDAR toolbox
readme_project = fullfile(lidarToolPath, 'README.txt');         % Current README.txt
tmpreadme_project = fullfile(lidarToolPath, 'README.txt_tmp');  % Move README.txt to this
readme_exe = fullfile(lidarToolPath, 'readme.txt');             % Exe deployment readme.txt
tmpreadme_exe = fullfile(lidarToolPath, 'README_EXE.txt');      % Move exe reame here
initAppName = fullfile(lidarToolPath, 'VisualApp.exe');         % App will deploy with this name
finalAppName = fullfile(lidarToolPath, 'ELiDAR.exe');           % Change to this name
otherFilesLocation = fullfile(lidarToolPath, 'Extra_exe_documentation');   % Move extra exe log files here
otherFilesToMove = {fullfile(lidarToolPath, 'unresolvedSymbols.txt'), ...  % Other extra exe log files to move
    fullfile(lidarToolPath, 'mccExcludedFiles.log'), ...
    fullfile(lidarToolPath, 'includedSupportPackages.txt'), ...
    fullfile(lidarToolPath, 'requiredMCRProducts.txt')};

% Move existing readme
movefile(readme_project, tmpreadme_project);

%% Deploy Compiled GUI
mcc -e ELiDAR.mlapp -o VisualApp

% Move exe readme
movefile(readme_exe, tmpreadme_exe);

% Move text file back
movefile(tmpreadme_project, readme_project);

% Rename visual app
movefile(initAppName, finalAppName);

%% Move additional files
for ii = 1:numel(otherFilesToMove)
    try
        movefile(otherFilesToMove{ii}, otherFilesLocation);
    catch ME
        warning(ME.getReport)
    end
end
end