# dzRequestSolarInfo
dzVents script for Domoticz to request optimizer data from the SolarEdge website

## Status
2020-05-18 : Initial commit, only happy flow and hard configurations, one evening work...

## Usage
1. Create an new dzVents script in Domoticz
2. Copy content of dzRequestSolarInfo.lua into script
3. Modify username, password and siteID on lines 81, 82 and 83
4. If you use a "1,234.00" number format on the SolarEdge website, change line 3 to :  
  "isDecimalComma = false" on line 3
5. Add dummy devices for eacht optimizer and inverter type "Electric (instant+Counter)" Name is the name of optimizer or inverter  
  (Temporary uncomment lines 143 and 155 to figure the names)
  
## Known Isuues
 - It needs domoticz V4.11543
 - Energy Usage is not updated correctly after 1 day.
  
## Notes
Code is free for use, but no guarantees
