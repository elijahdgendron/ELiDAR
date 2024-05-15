function newPath = combineLAS(basePath)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Elijah Gendron
% 05/15/2024
%
% DESCRIPTION:
%   Combine multiple .las/.laz files into one .laz file. Will save in lat/lon/alt (deg/deg/m) regardless of input
%   local coordinates. This is unusual for laz files, but queryLidar will read this in properly. Adds LLA_ to beginning of
%   file name, which is how tool determines that the file is in this format. Helpful if query point is on the border of 
%   multiple tiles
%
% INPUTS:
%   basePath ... Full file path to a folder containing multiple LiDAR data files and their associated DEM files. Will
%                 assume everything in this should be combined
%
% OUTPUTS:
%   newPath ... Full file path to a newly created folder containing combined file data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Init
m2ft = 3.2808399;

%% Combine all las/laz files (with associated dem) in a folder
% Get folder info
[stripPath, folderName] = fileparts(basePath);
newPath = fullfile(stripPath, ['Combined_', folderName]);

% Get needed files
d = dir(basePath);
lasFiles = {};
demFiles = {};
for ii = 1:length(d)
    if contains(d(ii).name, '.laz') || contains(d(ii).name, '.las')
        lasFiles{end+1,1} = fullfile(basePath, d(ii).name);
    elseif contains(d(ii).name, '.tif') || contains(d(ii).name, '.img')
        demFiles{end+1,1} = fullfile(basePath, d(ii).name);
    end
end

% Match las to tif
[~, fileName] = fileparts(lasFiles);
ixMatch = zeros(size(lasFiles));
for ii = 1:length(lasFiles)
    ixMatch(ii) = find(contains(demFiles, fileName{ii}));
end
demFiles = demFiles(ixMatch);

% Set variables to store
lat = [];
lon = [];
z = [];
intensity = [];
classification = [];

%% Read in files
for ii = 1:length(lasFiles)
    disp(['---Reading LAS/LAZ File ',num2str(ii),'/',num2str(length(lasFiles))])
    thisLAS = lasFiles{ii};
    thisDEM = demFiles{ii};
    [~,R] = readgeoraster(thisDEM);
    proj = R.ProjectedCRS;
    lasReader = lasFileReader(thisLAS);
    [ptCloud, ptAttributes] = readPointCloud(lasReader,"Attributes","Classification");
    unitFoot = contains(proj.LengthUnit, 'foot','IgnoreCase',true);

    %% Clean data
    [ptCloud, ix1] = pcdenoise(ptCloud, 'NumNeighbors',20, 'Threshold', 1);
    tmpClassification = ptAttributes.Classification(ix1);

    % Convert to common coordinate system (LLA)
    x = ptCloud.Location(:,1);
    y = ptCloud.Location(:,2);
    n = numel(x);

    % Info will always be stored in meters
    if unitFoot
        z(end+1:end+n,1) = ptCloud.Location(:,3)/m2ft;
    else
        z(end+1:end+n,1) = ptCloud.Location(:,3);
    end
    
    % Set output data
    [lat(end+1:end+n,1), lon(end+1:end+n,1)] = projinv(proj, x, y);
    intensity(end+1:end+n,1) = ptCloud.Intensity;
    classification(end+1:end+n,1) = tmpClassification;
end

%% Combine data
% Create new point cloud
disp('Writing Combined LAZ File')
newPtCloud = pointCloud([lat, lon, z], 'Intensity', intensity);
newPtAttr  = lidarPointAttributes('Classification', classification);
lasWriter = lasFileWriter(fullfile(newPath,'LLA_Custom.laz'));

% Make new directory
if isfolder(newPath)
    rmdir(newPath, 's');
end
mkdir(newPath);

% Write new point cloud to location
writePointCloud(lasWriter, newPtCloud, newPtAttr);
disp('INFO:: LAZ Combination done')
end