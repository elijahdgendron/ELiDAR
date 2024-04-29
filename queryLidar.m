function outdata = queryLidar(query_lat, query_lon, query_type, data_source, dem_source, varargin)
%% Set option values
% colorscale options
cso = {'BR', 'greyscale', 'jet'};
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

p.parse(varargin{:});
in = p.Results;

%% NOTES
% Unfortunately seems impossible/ very difficult to query lidar results from the web
% As such, must input data_source for each query

% Tools required:
%"Lidar Toolbox"                              "2.0"        true         "LP"
%"Mapping Toolbox"                            "5.2"        true         "MG"
%

% Tools wanted:
%"Symbolic Math Toolbox"                      "9.0"        true         "SM"
%"MATLAB Compiler"                            "8.3"        true         "CO"
%"Curve Fitting Toolbox"                      "3.6"        true         "CF"




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
    % Read in file
    thisFile = data_source{ii};
    lasReader = lasFileReader(thisFile);
    if in.filterGround
        [ptCloud, ptAttributes] = readPointCloud(lasReader,"Attributes","Classification");
        % Classification 2 = ground
        % Often this leaves chunks empty, too many trees

        ptCloud = select(ptCloud, ptAttributes.Classification == 2);
    else
        ptCloud = readPointCloud(lasReader);
    end

    % To view liad data:
    %     assignin('base','ptCloud',ptCloud)
    %     lidarViewer

    % OR

%         labels = label2rgb(ptAttributes.Classification,'spring');
%         l = unique(ptAttributes.Classification);
%         labelDecoder = label2rgb(l, 'spring');
%         colorData = reshape(labels,[],3);
%         %colorData(:,1) = 255-colorData(:,3);
%         figure
%         pcshow(ptCloud.Location,colorData)

    % De-project
    x = ptCloud.Location(:,1);
    y = ptCloud.Location(:,2);
    if project
        [lat, lon] = projinv(proj, x, y);
    else
        lat = x;
        lon = y;
    end
    %alt = ptCloud.Location(:,3);

    % Get points within queryRadius_deg of query point
    d_query = sqrt((lat-query_lat).^2+(lon-query_lon).^2);
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

    % Create sub-set of pointCloud
    ptCloud = select(ptCloud, ixQuery);

    % De-noise
    if in.cleanData && project
        ptCloud = pcdenoise(ptCloud, 'NumNeighbors',in.filterNumNbr, 'Threshold', in.filterThreshold);

        % Remove duplicates
        ptCloud = pcdownsample(ptCloud,'gridAverage',0.01);
    end

    % Define query type
    switch query_type{ii}
        case 'peak'
            %% PEAK
            % Find local max in region surrounding peak coords
            [m, ix] = max(ptCloud.Location(:,3));
            if project
                [lat_m, lon_m] = projinv(proj, ptCloud.Location(ix,1), ptCloud.Location(ix,2));
            else
                lat_m = ptCloud.Location(ix,1);
                lon_m = ptCloud.Location(ix,2);
            end

            if unitFoot
                outdata.peak_elevation_m = double(m)/m2ft;
                outdata.peak_elevation_ft = double(m);
            else
                outdata.peak_elevation_m = double(m);
                outdata.peak_elevation_ft = double(m)*m2ft;
            end
            outdata.peak_location_m = double([ptCloud.Location(ix,1), ptCloud.Location(ix,2)]);
            outdata.peak_location_deg = double([lat_m, lon_m]);

        case {'saddle','search'}
            %% SEARCH / SADDLE
            global x_cursor y_cursor
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
            while redo
                % Fit curve to nearby points
                x = double(ptCloud.Location(:,1));
                y = double(ptCloud.Location(:,2));
                z = double(ptCloud.Location(:,3));

                colorScale = (z-min(z))/(max(z)-min(z));
                if strcmp(in.colorscale, 'greyscale')
                    c = repmat(colorScale, 1, 3);
                elseif strcmp(in.colorscale, 'BR')
                    c = [colorScale, zeros(size(colorScale)), 1-colorScale];
                elseif strcmp(in.colorscale, 'jet')
                    c = colormap(jet(length(colorScale)));
                else
                    error('Unimplemented color mapping');
                end

                % Select point from plot, ask for user entry
                figure
                if in.displayLLA
                    if project
                        [xlat, ylon] = projinv(proj, x, y);
                    else
                        xlat = x;
                        ylon = y;
                    end
                    scatter3(xlat, ylon, z, [], c);
                    figH = gcf;
                    xlabel('Lat (deg)')
                    ylabel('Lon (deg)')
                else
                    scatter3(x, y, z, [], c);
                    figH = gcf;
                    xlabel('x (increases East)')
                    ylabel('y (increases North)')
                end
                if unitFoot
                    zlabel('Altitude (ft)')
                else
                    zlabel('Altitude (m)')
                end
                dcm = datacursormode(figH);
                dcm.Enable='on';
                dcm.UpdateFcn = @threeRows;

                opts = [];
                opts.WindowStyle = 'normal';
                opts.Resize = 'on';
                % saddleInfo = inputdlg({'Select a Point, Click Done To Zoom, Enter Anything To Complete'}, 'Query Location', [1], ...
                %     {''}, opts);
                saddleInfo = MFquestdlg([0.1, 0.5],'Select a Point, Click Done To Zoom, Enter Anything To Complete','Query Location', ...
                    'Zoom','Done','Cancel','Zoom');
                if isempty(saddleInfo) || strcmp(saddleInfo, 'Cancel')
                    clear x_cursor y_cursor
                    return
                end
                sx = x_cursor;
                sy = y_cursor;

                if in.displayLLA && project
                    [sx, sy] = projfwd(proj, sx, sy);
                end

                %redo = isempty(saddleInfo{1});
                redo = strcmp(saddleInfo, 'Zoom');

                % Reduce figure size to(defined in zoomScale) and recolor
                queryRadiusTmp = queryRadiusTmp*in.zoomScale;

                % Get points within queryRadius_deg of query point
                d_query = sqrt((x-sx).^2+(y-sy).^2);
                ixQuery = d_query <= queryRadiusTmp;

                ptCloud = select(ptCloud, ixQuery);

                close(figH);
                
            end
            clear x_cursor y_cursor

            % When done, get user selected point
            ix = ismembertol(x, sx, 0.000000000001) & ismembertol(y, sy, 0.000000000001);
            if project
                [lat_m, lon_m] = projinv(proj, x(ix), y(ix));
            else
                lat_m = x(ix);
                lon_m = y(ix);
            end

            if unitFoot
                outdata.([query_type{ii}, '_elevation_m']) = z(ix)/m2ft;
                outdata.([query_type{ii}, '_elevation_ft']) = z(ix);
            else
                outdata.([query_type{ii}, '_elevation_m']) = z(ix);
                outdata.([query_type{ii}, '_elevation_ft']) = z(ix)*m2ft;
            end
            outdata.([query_type{ii}, '_location_pos']) = [x(ix), y(ix)];
            outdata.([query_type{ii}, '_location_deg']) = [lat_m, lon_m];
            
        case 'point'
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

            if unitFoot
                outdata.point_elevation_m = double(z(ixMatch));
                outdata.point_elevation_ft = double(z(ixMatch)*m2ft);
            else
                outdata.point_elevation_m = double(z(ixMatch))/m2ft;
                outdata.point_elevation_ft = double(z(ixMatch));
            end
            
            outdata.point_location_pos = double([x(ixMatch), y(ixMatch)]);
            outdata.point_location_deg = double([lat_m, lon_m]);
    end
end
end

function txt = threeRows(~, info)
global x_cursor y_cursor
x_cursor = info.Position(1);
y_cursor = info.Position(2);
txt = '';%[{num2str(x_cursor);num2str(y_cursor);num2str(x_cursor^2+y_cursor^2)}];
end