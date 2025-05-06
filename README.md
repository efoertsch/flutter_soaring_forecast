# flutter_soaring_forecast
SoaringForecast

Flutter version of Android SoaringForecast (https://github.com/efoertsch/SoaringForecast). Note all development on the Android version has stopped and all current and future development is under this branch.

Display soaring forecast and weather information of interest to glider pilots. Features include:

1. Soaring forecasts displayed from Greater Boston Soaring Club RASP (https://www.soargbsc.net/rasp/  courtesy of Steve Paavola). Currently NewEngland and Mifflin forecasts are always generated. (A short diversion - Steve Paavola's RASP generating code posted in github at https://github.com/s-paavola/multi-rasp )
2. Turnpoints can be downloaded from Worldwide Turnpoint Exchange (http://soaringweb.org/TP/) or you can import your own (in SeeYou .cup format)
3. SUAs can be displayed. (The GeoJson SUA files were created based on SUA files in Tim Newport-Peace format from the Worldwide Turnpoint Exchange and run through a converter at  https://mygeodata.cloud/converter/ to produce the GeoJson files)
4. Google map view of turnpoints display with onTap on turnpoint
5. Forecast graphs and data table generated on longPress on turnpoint, sounding or any location on map
6. Tasks can be defined using the imported turnpoints and overlaid on the RASP forecast.
7. Skew-t soundings can be displayed from selected NE locations (soundings from soarbgsc.net/rasp/ also)
8. METAR and TAF from 1800WxBrief
9. Generate local, route(task) or NOTAM specific 1800WxBrief briefings
10. GOES East current and animated (GIF) images.
11. Customized version of Windy with task overlay.

Airport information to supplement TAF/METARS downloaded from http://ourairports.com/data/. Note that on weekends, the file may be empty (being updated?) for a period of time, but the app should check for that and schedule downloads until what appears to be a full file is available.


