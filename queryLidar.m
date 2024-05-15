function outdata = queryLidar(query_lat, query_lon, query_type, data_source, dem_source, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Elijah Gendron
% 05/15/2024
%
% DESCRIPTION:
%   Query a LiDAR data set at/ around a point.
%
% INPUTS:
%   query_lat ... Latitude of query. -90 to 90 (degrees) [numeric]
%
%   query_lon ... Longitude of query. -180 to 180 (degrees) [numeric]
%
%   query_type ... Determines query algorithm (case sensitive) [char]
%       OPTIONS: 'search' ... Opens a 3D plot of the point cloud reduced locally around the query. 
%                              Can be zoomed to pick a specific point. (recommended)
%                'peak'   ... Assumes highest point in vicinity of query is the point of interest.
%                'point'  ... Returns info for the closest LiDAR point in lat/lon to the query.
%
%   data_source ... Full file path to LiDAR data file (.las/.laz extension) [char]
%
%   dem_source ... Full file path to DEM data file (.tif/.img extension). Needed to parse local -> global coordinate
%                   transformation. [char]
%
% OPTIONAL INPUT PAIRS (varargin)
%
%   1) cleanData ... If true, will run MATLAB built in LiDAR data cleaning algorithms [logical]:
%                    pcdenoise - run with in.filterNumNbr and in.filterThreshold. Removes erronious points (see MATLAB documentation)
%                    pcdownsample - removes duplicate points (see MATLAB documentation)
%       DEFAULT: true
%
%   2) colorScale ... Set colorscale of 'search' 3D Plots [char]
%           OPTIONS: 'jet', 'turbo', 'winter', 'Greyscale', 'BR'
%       DEFAULT: 'jet'
%
%   3) filterGround ... If true, will filter by LiDAR classification = 2 [logical]
%       DEFAULT: false
%
%   4) queryRadius_deg ... Set the initial radius around the query that 'search' mode will downsample to, in deg [numeric]
%       DEFAULT: 0.0008
%
%   5) zoomScale ... Amount by which each sucessive zoom in 'search' mode will reduce the point cloud. [numeric]
%       DEFAULT: 0.5
%
%   6) forceUnit ... Specify the native unit of .las/.laz file if conversion does not work correctly [char]
%           OPTIONS: '', 'N/A', 'ft', 'm'
%       DEFAULT: '' (read from DEM)
%
%   7) filterNumNbr ... Set NumNeighbors input in pcdenoise (see MATLAB documentation) [numeric]
%       DEFAULT: 20
%
%   8) filterThreshold ... Set Threshold input in pcdenoise (see MATLAB documentation) [numeric]
%       DEFAULT: 1
%
%   9) displayLLA ... If true, plots in 'search' mode will have lat/lon on the x/y axes, instead of local coordinates [logical]
%       DEFAULT: true
%
%   10) center ... If true, will pick the center of the LiDAR data set as query point. Will ignore query_lat and 
%                  query_lon inputs. Used primarily for dev testing [logical]
%       DEFAULT: false
%
% OUTPUTS:
%   outdata ... Data structure containing information about queried/ selected point. Contains the following fields:
%       elevation_m ... Elevation of queried points in m [Nx1 numeric]
%       elevation_ft ... Elevation of queried points in ft [Nx1 numeric]
%       location_pos ... Location of queried points in local coordinate system  [Nx2 numeric]
%       location_deg ... Location of queried points in lat/lon [Nx2 numeric]
%       queryType ... Nx1 list of associated query types [Nx1 cellstr]  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set option values
% colorscale options
cso = {'BR', 'Greyscale', 'jet', 'turbo', 'winter'};
% unit options
uo = {'m', 'ft', 'N/A'};

%% Variable Input Arguments
p = inputParser;
%              Parameter            Default     Condition
p.addParameter('cleanData',       true,          @islogical)
p.addParameter('colorscale',      'jet',         @(x)ischar(x)&ismember(x,cso))
p.addParameter('filterGround',    false,         @islogical)
p.addParameter('queryRadius_deg', 0.0008,        @isnumeric)
p.addParameter('zoomScale',       0.5,           @isnumeric)
p.addParameter('forceUnit',       '',            @(x)ischar(x)&ismember(x,uo))
p.addParameter('filterNumNbr',    20,            @isnumeric)
p.addParameter('filterThreshold', 1,             @isnumeric)
p.addParameter('displayLLA',      true,          @islogical)
p.addParameter('center',          false,         @islogical)

p.parse(varargin{:});
in = p.Results;

%% NOTES
% Unfortunately seems impossible/ very difficult to query lidar results from the web
% As such, must input data_source for each query

% Tools required:
%"Lidar Toolbox"                              "2.0"        true         "LP"
%"Mapping Toolbox"                            "5.2"        true         "MG"
% -------------
%% Ensure input
n = length(query_lat);
if ~isnumeric(query_lat) || ~isnumeric(query_lon)
    error('Lat & Lon values must be numeric')
end

if ~all(isfile(data_source))
    error('At least one data source does not point directly to file')
end

[~,~,ext]=fileparts(data_source);
if ~all(contains(ext, 'laz') | contains(ext, 'las'))
    error('data sources must be laz or las files')
end

% Set input
if ischar(query_type)
    query_type = {query_type};
end
if ischar(data_source)
    data_source = {data_source};
end

if size(query_lat, 2) ~= 1 || size(query_lon, 2) ~= 1 || size(query_type, 2) ~= 1 || size(data_source, 2) ~= 1
    error('Inputs must be Nx1')
end

if ~iscellstr(query_type)
    error('Query type must be cellstr unless n=1, which must be char array or cellstr')
end

%% Init
outdata = [];
m2ft = 3.2808399;

%webPath = 'https://coloradohazardmapping.com/lidarDownload';
%basePath = 'C:\Users\e416680\Documents\Lidar\LiDAR_2024-04-20T19_10_05.384Z';

%% Init
[~, data_sourceName] = fileparts(data_source); 

project = true;
if startsWith(data_sourceName, 'LLA')
    % Assume this is from combineLAS tool, no georaster needed
    project = false;
    unitFoot = false;
end

%% Get Projection Info
if project
    [~,R] = readgeoraster(dem_source);
    proj = R.ProjectedCRS;
    unitFoot = [];
    if ~isempty(in.forceUnit)
        if contains(in.forceUnit, 'ft')
            unitFoot = true;
        elseif contains(in.forceUnit, 'm')
            unitFoot = false;
        end
    end

    if isempty(unitFoot)
        unitFoot = contains(proj.LengthUnit, 'foot','IgnoreCase',true);
    end
end

%% Loop over query points
for ii = 1:n
    %% Read in file
    thisFile = data_source{ii};
    lasReader = lasFileReader(thisFile);

    %% Filter by ground data
    if in.filterGround
        % Need to parse attirbutes if filtering
        [ptCloud, ptAttributes] = readPointCloud(lasReader,"Attributes","Classification");

        ptCloud = select(ptCloud, ptAttributes.Classification == 2);
    else
        ptCloud = readPointCloud(lasReader);
    end

    %% De-project data
    x = ptCloud.Location(:,1);
    y = ptCloud.Location(:,2);
    if project
        [lat, lon] = projinv(proj, x, y);
    else
        lat = x;
        lon = y;
    end

    % Center if dev test
    if in.center
        query_lat(ii) = mean(lat);
        query_lon(ii) = mean(lon);
    end

    %% Downsample point cloud
    % Get points within queryRadius_deg of query point
    d_query = sqrt((lat-query_lat(ii)).^2+(lon-query_lon(ii)).^2);
    ixQuery = d_query <= in.queryRadius_deg;

    % Save off closest lidar point to query
    [~, ixMin] = min(d_query);
    x_min = x(ixMin);
    y_min = y(ixMin);

    % Check if query point is in data
    if ~any(ixQuery)
        warning(['Query Point ', num2str(ii), ' is not in associated source data, continuing']);
        continue
    end

    % Downsample
    ptCloud = select(ptCloud, ixQuery);

    %% Clean data
    if in.cleanData && project
        % If project is false, data is already clean (from combining files)
        % Remove noise
        ptCloud = pcdenoise(ptCloud, 'NumNeighbors',in.filterNumNbr, 'Threshold', in.filterThreshold);

        % Remove duplicates
        ptCloud = pcdownsample(ptCloud,'gridAverage',0.01);
    end

    %% Complete Query
    switch query_type{ii}
        case 'peak'
            %%%%%%%%%%%%%%%%%%
            %% PEAK
            % Find local max in region surrounding peak coords

            [m, ix] = max(ptCloud.Location(:,3));
            if project
                [lat_m, lon_m] = projinv(proj, ptCloud.Location(ix,1), ptCloud.Location(ix,2));
            else
                lat_m = ptCloud.Location(ix,1);
                lon_m = ptCloud.Location(ix,2);
            end

            % Set outdata
            if unitFoot
                outdata.elevation_m = double(m)/m2ft;
                outdata.elevation_ft = double(m);
            else
                outdata.elevation_m = double(m);
                outdata.elevation_ft = double(m)*m2ft;
            end
            outdata.location_pos = double([ptCloud.Location(ix,1), ptCloud.Location(ix,2)]);
            outdata.location_deg = double([lat_m, lon_m]);

        case 'search'
            %%%%%%%%%%%%%%%%%%
            %% SEARCH
            % Open 3D plot for user selection

            % Init global variables that are set in cursor function
            global x_cursor y_cursor

            % Init
            redo = true;
            if ~project
                queryRadiusTmp = in.queryRadius_deg/2;
            elseif unitFoot
                queryRadiusTmp = 100*m2ft;
            else
                queryRadiusTmp = 100;
            end
            sx = [];
            sy = [];

            % Redo as user specifies
            while redo
                % Fit curve to nearby points
                x = double(ptCloud.Location(:,1));
                y = double(ptCloud.Location(:,2));
                z = double(ptCloud.Location(:,3));

                % Color mapping
                colorScale = (z-min(z))/(max(z)-min(z));
                if strcmp(in.colorscale, 'Greyscale')
                    c = repmat(colorScale, 1, 3);
                elseif strcmp(in.colorscale, 'BR')
                    c = [colorScale, zeros(size(colorScale)), 1-colorScale];
                elseif strcmp(in.colorscale, 'jet') || strcmp(in.colorscale, 'winter') || strcmp(in.colorscale, 'turbo')
                    c = z;
                else
                    error('Unimplemented color mapping');
                end

                % Select point from plot, ask for user entry
                f = figure;
                if in.displayLLA
                    if project
                        [xlat, ylon] = projinv(proj, x, y);
                    else
                        xlat = x;
                        ylon = y;
                    end
                    scatter3(xlat, ylon, z, [], z);
                    figH = gcf;
                    xlabel('Lat (deg)')
                    ylabel('Lon (deg)')
                    set(gca, 'YDir', 'reverse');
                else
                    scatter3(x, y, z, [], c);
                    figH = gcf;
                    xlabel('x (increases East)')
                    ylabel('y (increases North)')
                end

                % Color in some cases
                if strcmp(in.colorscale, 'jet')
                    colormap jet
                elseif strcmp(in.colorscale, 'winter')
                    colormap winter
                elseif strcmp(in.colorscale, 'turbo')
                    colormap turbo
                end

                % Apply labels
                if unitFoot
                    zlabel('Altitude (ft)')
                else
                    zlabel('Altitude (m)')
                end
                dcm = datacursormode(figH);
                dcm.Enable='on';
                dcm.UpdateFcn = @threeRows;

                % Prompt user input
                opts = [];
                opts.WindowStyle = 'normal';
                opts.Resize = 'on';
                queryInfo = MFquestdlg([0.1, 0.5],'Select a Point, Click Done To Zoom, Enter Anything To Complete','Query Location', ...
                    'Zoom','Done','Cancel','Zoom');

                if isempty(queryInfo) || strcmp(queryInfo, 'Cancel')
                    % Clear global variables if cancelled
                    clear x_cursor y_cursor
                    close(f)
                    return
                end

                % Read global variables
                sx = x_cursor;
                sy = y_cursor;

                if in.displayLLA && project
                    [sx, sy] = projfwd(proj, sx, sy);
                end

                %redo = isempty(saddleInfo{1});
                redo = strcmp(queryInfo, 'Zoom');

                % Reduce figure size to(defined in zoomScale) and recolor
                queryRadiusTmp = queryRadiusTmp*in.zoomScale;

                % Get points within queryRadius_deg of query point
                d_query = sqrt((x-sx).^2+(y-sy).^2);
                ixQuery = d_query <= queryRadiusTmp;

                ptCloud = select(ptCloud, ixQuery);

                close(figH);
            end

            % Clear global variables
            clear x_cursor y_cursor

            % When done, get user selected point
            % Needs a very small tolerance to work
            ix = ismembertol(x, sx, 0.000000000001) & ismembertol(y, sy, 0.000000000001);
            if project
                [lat_m, lon_m] = projinv(proj, x(ix), y(ix));
            else
                lat_m = x(ix);
                lon_m = y(ix);
            end

            % Set output data
            if unitFoot
                outdata.elevation_m = z(ix)/m2ft;
                outdata.elevation_ft = z(ix);
            else
                outdata.elevation_m = z(ix);
                outdata.elevation_ft = z(ix)*m2ft;
            end
            outdata.location_pos = [x(ix), y(ix)];
            outdata.location_deg = [lat_m, lon_m];
            
        case 'point'
            %%%%%%%%%%%%%%%%%%
            %% POINT
            % Get data on closest lidar return to query

            x = ptCloud.Location(:,1);
            y = ptCloud.Location(:,2);
            z = ptCloud.Location(:,3);

            ixMatch = x == x_min;
            if project
                [lat_m, lon_m] = projinv(proj, x(ix), y(ix));
            else
                lat_m = x(ix);
                lon_m = y(ix);
            end

            % Set outdata fields
            if unitFoot
                outdata.elevation_m = double(z(ixMatch));
                outdata.elevation_ft = double(z(ixMatch)*m2ft);
            else
                outdata.elevation_m = double(z(ixMatch))/m2ft;
                outdata.elevation_ft = double(z(ixMatch));
            end
            
            outdata.location_pos = double([x(ixMatch), y(ixMatch)]);
            outdata.location_deg = double([lat_m, lon_m]);
    end

    % Set outdata Query Type
    outdata.queryType = query_type{ii};
end
end %% End Main Function

%%%%%%%%%%%%%%%%%%%%%%%
%% Helper functions
%%%%%%%%%%%%%%%%%%%%%%%

function txt = threeRows(~, info)
% Controls data pointer output in 'search' plots
global x_cursor y_cursor
x_cursor = info.Position(1);
y_cursor = info.Position(2);
txt = '';%[{num2str(x_cursor);num2str(y_cursor);num2str(x_cursor^2+y_cursor^2)}];
end