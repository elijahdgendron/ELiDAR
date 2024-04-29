%%%%%%%%%%%%%%%%%%%%%%%%%%%
HOW TO USE ELiDAR GUI:

Step 1) Download LiDAR and DEM data
	For CO data, use the "Go To Source" Button.

Step 2) Untar in folder with descriptive name
	If analyzing the saddle of Columbia Point for example, name the folder Columbia_Saddle or the like.
	Make sure both the LiDAR (.laz/.las) and DEM (.tif/.img) are in this folder!

Step 3) Use Folder button to direct GUI to this folder, select it

Step 4) Enter an initial Lat/Lon guess, configure options, and press the Analyze button

Step 5) Click on a point in the figure and "Zoom" in the dialogue box to zoom in / reduce the point cloud. 
	Repeat this until you have the exact desired point selected. Enter anything into the prompt and select "Done"
	Reference other data, such as google maps or pictures to help select the best point

Step 6) Record the result however you want

%%%%%%%%%%%%%%%%%%%%%%%%%%%
Additional Features:

Screenshots) Save screenshots of the figure as desired using the "Take Snapshot" button

Combine data) Place LiDAR and DEM files to combine in a folder (ie. Peak_9123) if a peak borders multiple tiles.
		Use the "Combine Data" tab, direct the GUI to the folder, then press "Combine"
		After this is done, you can direct the primary data path to the new location produced (Combine_Peak_9123)

Take Notes) In the "Scratch" Tab, notes can be taken and saved as .txt file to the Data Path.

Calculate Prominence) Use the "Prominence" Tab to calculate on-the-fly prominence values for general info.

Close Figs) This button will close all MATLAB figures open

RESET) This button will reset the GUI

Re-enable) This button will re-enable the Analyze and Take Snapshot buttons, which may be stuck disabled in the case of errors

Default Folder Path) If desired, can have a default data location by changing the Default button callback in MATLAB App Editor

%%%%%%%%%%%%%%%%%%%%%%%%%%%
Query Type:

Search) Almost always use this. Will make figure appear to select exact point desired

Peak) Assumes the nearby local maximum is the desired elevation. Only works for above treeline peaks

Point) Return the LiDAR data closest to the query lat/lon.

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

