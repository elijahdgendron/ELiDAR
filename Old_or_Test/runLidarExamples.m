% Test queryLidar function
% Run lidar examples

% dem_souce = 'C:\Users\e416680\Documents\Lidar\DEM\LiDAR_2024-04-22T17_26_17.083Z\usgs_opr_co_sanluisjuanmiguel_2020_d20_dem_13s_cc_9342.tif'
% %% Antora peak
% outdata = queryLidar(38.32496, -106.21840, 'peak', ...
% 'C:\Users\e416680\Documents\Lidar\LiDAR_2024-04-20T19_10_05.384Z\usgs_lpc_co_sanluisjuanmiguel_2020_d20_13s_cc_9342.laz', ...
% dem_source);
% 
% %% Sheep mountain
% outdata = queryLidar(38.33355, -106.21413, 'peak', 'C:\Users\e416680\Documents\Lidar\LiDAR_2024-04-20T19_10_05.384Z\usgs_lpc_co_sanluisjuanmiguel_2020_d20_13s_cc_9343.laz', dem_source);
% 
% %% Antora/ sheep saddle
% outdata = queryLidar(38.33107, -106.21720, 'saddle', 'C:\Users\e416680\Documents\Lidar\LiDAR_2024-04-20T19_10_05.384Z\usgs_lpc_co_sanluisjuanmiguel_2020_d20_13s_cc_9343.laz', dem_source);
% 
% % sheep_prominence =
% % 
% %   288.1175
% %   


% To find the prominence of a peak, find the existing estimated peak and saddle , run tool on both.
% Peak 8something
% TODO: filter by category for tree summits
outdata = queryLidar(38.82773,-104.90565,'search', ...
    'C:\Users\e416680\Documents\Lidar\Peak8123\LD31681362.las', ...
    'C:\Users\e416680\Documents\Lidar\Peak8123\dem_LD31681362.tif');
peak_elev = outdata.search_elevation_ft; % I believe to be 8122.6

% search_elevation_m: 2.4783e+03
%     search_elevation_ft: 8.1308e+03
%     search_location_pos: [3.1693e+06 1.3627e+06]
%     search_location_deg: [38.8278 -104.9056]

outdata2 = queryLidar(38.82484, -104.90930,'saddle', ...
    'C:\Users\e416680\Documents\Lidar\Saddle8123\LD31681359.las', ...
    'C:\Users\e416680\Documents\Lidar\Saddle8123\dem_LD31681359.tif');
saddle_elev = outdata2.saddle_elevation_ft; % I believe to be 7822.166

prominence = peak_elev - saddle_elev;

disp(['Prominence: ', num2str(prominence)])

% Check north sub-summit elevation
outdata3 = queryLidar(38.82855,-104.90577,'search', ...
    'C:\Users\e416680\Documents\Lidar\Peak8123\LD31681362.las', ...
    'C:\Users\e416680\Documents\Lidar\Peak8123\dem_LD31681362.tif');

% Second (North) sub-summit is 8120.7378, roughly 10 feet shorter

%% Peak 9136
outdata = queryLidar(38.92108, -104.94671, 'search', ...
    'C:\Users\e416680\Documents\Lidar\Peak9163\LD31561395.las', ...
    'C:\Users\e416680\Documents\Lidar\Peak9163\dem_LD31561395.tif');
peak_elev =outdata.peak_elevation_ft; % I believe to be 9613.1

outdata2 = queryLidar(38.91971, -104.95930, 'saddle', ...
    'C:\Users\e416680\Documents\Lidar\Saddle9163\LD31531395.las', ...
    'C:\Users\e416680\Documents\Lidar\Saddle9163\dem_LD31531395.tif');
saddle_elev = outdata2.saddle_elevation_ft; % I believe to be 

prominence = peak_elev - saddle_elev;
disp(['Prominence: ', num2str(prominence)])

% Pretty much exactly 300


%% Columbia Point
outdata = queryLidar(37.97903, -105.59816, 'peak', ...
    'C:\Users\e416680\Documents\Lidar\ColumbiaPoint\CWCB_PARK_00156.las', ...
    'C:\Users\e416680\Documents\Lidar\ColumbiaPoint\CWCB_PARK_00156.img');
peak_elev =outdata.peak_elevation_ft; % I believe to be 13985.7287

outdata2 = queryLidar(37.97930, -105.59951, 'saddle', ...
    'C:\Users\e416680\Documents\Lidar\ColumbiaPoint\CWCB_PARK_00156.las', ...
    'C:\Users\e416680\Documents\Lidar\ColumbiaPoint\CWCB_PARK_00156.img');
saddle_elev = outdata2.saddle_elevation_ft; % I believe to be 13685.3668

prominence = peak_elev - saddle_elev;

disp(['Prominence: ', num2str(prominence)])
% Prominence = xl

% Ranked determination still within error bounds
% Error is 0.091 m, or 0.2986 ft per measurement, meaning prominence has variance 2x this
