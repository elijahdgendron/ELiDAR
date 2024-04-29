%%%%%%%%%%%%%%%%%%%%%%%%%%%
ELiDAR GUI Project
Elijah Gendron
04/29/2024
%%%%%%%%%%%%%%%%%%%%%%%%%%%

Purpose:
This is a small toolbox to assist me in LiDAR analysis of peak and saddle elevations of Colorado (or other) mountains based off publicly available government data.
Source for CO: https://coloradohazardmapping.com/lidarDownload

Disclaimer:
This is my first attempt doing anything with LiDAR data, and I am not a software engineer. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%
HOW TO USE ELiDAR GUI:

Step 0) Identify a feature of interest, obtain an initial guess for lat/lon location
	This can come from www.listsofjohn.com (LoJ), Google Maps, www.peakbagger.com, etc.

Step 1) Download LiDAR and DEM data
	For CO data, use the "Go To Source" Button. Otherwise, find reliable LiDAR and DEM source data
	The DEM is required because the local->global coordinate transformation info is being parsed from it.
	On the website, click the region of interest, and then show tiles.
	Select the tile containing the point of interest. If point borders or nearly borders multiple tiles, download all and see "Combine data" additional feature.

Step 2) Untar in folder with descriptive name
	If analyzing the saddle of Columbia Point for example, name the folder Columbia_Saddle or the like.
	Make sure both the LiDAR (.laz/.las) and DEM (.tif/.img) are in this folder!
	I recommend not renaming the files. Absolutely DO NOT add a prefix of "LLA_", as this will trick my tool into thinking the file is in a global coordinate system.

Step 3) Use Folder button to direct GUI to this folder, select it at the directory level.

Step 4) Enter the initial Lat/Lon guess, configure options, and press the Analyze button

Step 5) Click on a point in the figure and "Zoom" in the question box to zoom in / reduce the point cloud. 
	Repeat this until you have the exact desired point selected. Enter anything into the prompt and select "Done"
	Reference other data, such as google maps or pictures to help select the best point

Step 6) Record the result however you want

%%%%%%%%%%%%%%%%%%%%%%%%%%%
Additional Features:

Screenshots) Save screenshots of the figure as desired using the "Take Snapshot" button

Combine data)   Place LiDAR and DEM files to combine in a folder (ie. Peak_9123) if a peak borders multiple tiles.
		Use the "Combine Data" tab, direct the GUI to the folder, then press "Combine"
		After this is done, you can direct the primary data path to the new location produced (Combine_Peak_9123)
		Note: The laz file saved is not in a standard format. It saves in LLA (deg deg alt (ft)), as such the x-y and z axes have different units and this cannot be displayed by standard LiDAR tools, but it can be used in the ELiDAR GUI.
		This is done because the source data might be in multiple different projections, so I simply keep the data in its inversely projected state.
		NOTE: This will run the pcdenoise function on each data set before combining, the filter is currently non-configurable with the default inputs seen in the GUI.

Take Notes) In the "Scratch" Tab, notes can be taken and saved as .txt file to the Data Path.
	    If notes are taken, the GUI will prompt a warning before resetting.

Calculate Prominence) Use the "Prominence" Tab to calculate on-the-fly prominence values for general info.

Close Figs) This button will close all MATLAB figures open.

RESET) This button will close and re-open the GUI in its initial state.

Re-enable) This button will re-enable the Analyze and Take Snapshot buttons, which may be stuck disabled in the case of errors.

Default Folder Path) If desired, can have a default data location by changing the Default button callback in MATLAB App Editor.

%%%%%%%%%%%%%%%%%%%%%%%%%%%
Query Type:

Search) Almost always use this. Will make figure appear to select exact point desired. MUST use this when searching for saddles, or in terrain with mixed ground/ trees/ rocks.

Peak) Assumes the nearby local maximum is the desired elevation. Only works for above treeline peaks, and may include undesired features such as man-made cairns.

Point) Return the LiDAR data closest to the query lat/lon. Just there because.

%%%%%%%%%%%%%%%%%%%%%%%%%%%
Options:

Clean Data) Will use MATLAB's built in LiDAR data filtering algorithm to reduce noise and remove duplicates. Uses the following advanced options:
	Filter n Nbr & Filter Thresh) See MATLAB documetation on pcdenoise for details

Ground Only) Will filter to only Classification = 2

Plot LLA) If checked, will convert all intermediate plots to use Lat/Lon instead of local projection

Zoom Scale) Each successive zoom in will reduce by this percent

Color Scale) Changes the color scale of search plots

Force Unit) Specify only if the tool is misreading the local coordinate system unit

Search Radius) The radius (in degrees) around the initial guess to display. We do not want to use the entire LiDAR data set since it would be very slow

%%%%%%%%%%%%%%%%%%%%%%%%%%%

