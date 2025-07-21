-- This script will read digital crop information from the camera's EXIF metadata stored in the image file
-- and apply the corresponding crop in Capture One if necessary.
--
-- Author: Guido H
-- * Version 1.0, November 2024
-- * Version 1.1, July 2025
-- Released under GNU GPL 3.0

tell application "Capture One"
	
	-- Get all selected images
	set imageQueue to (get selected variants)
	
	-- Initialize progress bar
	set progress total units to (the number of items in the imageQueue)
	set progress completed units to 0
	set progress text to "Cropping Selected Images"
	set imgCount to 0
	
	-- Loop through each selected image
	repeat with variantItem in imageQueue
		try
			-- Get parent image and its size
			set parentImage to (get parent image of variantItem)
			set imgSize to (get dimensions of parentImage)
			set imgWidth to (item 1 of imgSize)
			set imgHeight to (item 2 of imgSize)

			-- Get orientation of image
			set imgOrientation to (get orientation of (get adjustments of variantItem))
			
			-- Get path of raw file
			set imagePath to (get path of (get parent image of variantItem))
			
			-- Extract all relevant EXIF data from the raw file (some requested fields will be missing depending on the camera model)
			set commandLine to "eval `/usr/libexec/path_helper -s`; exiftool -X -RAF:RawImageAspectRatio -RAF:RawZoomActive -RAF:RawZoomTopLeft -RAF:RawZoomSize -SubIFD:DefaultUserCrop \"" & imagePath & "\""
			set xmlExif to (do shell script commandLine)
			
			tell application "System Events"
				
				-- Extract the inner XML tags from exiftool's output
				try
					set xmlRDF to make new XML data with properties {name:"xmlData", text:xmlExif}
					set xmlData to XML element "rdf:Description" of XML element "rdf:RDF" of xmlRDF
				on error
					display dialog "Metadata (RDF Structure) missing." buttons {"Ok"} with title "Error"
				end try
				
				set cropFlag to "?"
				
				-- Try to extract generic crop information from DefaultUserCrop field
				-- Tested with Leica SL2-S (APS-C mode)
				try
					set cropXYWH to my theSplit(value of XML element "SubIFD:DefaultUserCrop" of xmlData, " ")
					set cropW to (imgWidth * (item 3 of cropXYWH))
					set cropH to (imgHeight * (item 4 of cropXYWH))
					set cropX to (((imgWidth * (item 1 of cropXYWH)) + cropW) div 2)
					set cropY to (((imgHeight * (item 2 of cropXYWH)) + cropH) div 2)
					set cropFlag to "Yes"
				end try
				
				-- Try to extract aspect ratio information for FujiFilm GFX cameras
				if (cropFlag is "?") then
					try
						-- Aspect ratio in the form "A:B", e.g. "3:2"
						set aspect to my theSplit(value of XML element "RAF:RawImageAspectRatio" of xmlData, ":")
						set oldRatio to imgWidth / imgHeight
						set newRatio to (item 1 of aspect) / (item 2 of aspect)

						-- Rotate crop to match image orientation if necessary by inverting the aspect ratio
						if (imgOrientation is 0) or (imgOrientation is 180) then
							set newRatio to (item 1 of aspect) / (item 2 of aspect)
						else
							set newRatio to (item 2 of aspect) / (item 1 of aspect)
						end if

						-- Initialize cropped width and height
						set cropW to imgWidth
						set cropH to imgHeight

						-- Determine if we need to crop based on width or height
						if oldRatio > newRatio then
						    -- Image is wider than desired aspect ratio, crop width
						    set cropW to round (imgHeight * newRatio)
						else if oldRatio < newRatio then
						    -- Image is taller than desired aspect ratio, crop height
						    set cropH to round (imgWidth / newRatio)
						end if

						-- Center cropped image
						set cropX to (imgWidth div 2)
						set cropY to (imgHeight div 2)
						set cropFlag to "Yes"
					on error
						set cropFlag to "?"
					end try
				end if

				-- Try to extract crop information for FujiFilm X cameras
				-- Tested with FujiFilm X100VI (Digital Teleconverter Modes)
				if (cropFlag is "?") then
					try
						-- cropFlag will be "Yes" or "No"
						set cropFlag to (value of XML element "RAF:RawZoomActive" of xmlData)
						
						-- Each pair of coordinates should be like "1234x768"; split them into an array
						-- Width x height of crop
						set cropWH to my theSplit(value of XML element "RAF:RawZoomSize" of xmlData, "x")
						set cropW to (item 1 of cropWH)
						set cropH to (item 2 of cropWH)
						
						-- Top left x and y of crop
						set cropXY to my theSplit(value of XML element "RAF:RawZoomTopLeft" of xmlData, "x")
						set cropX to ((item 1 of cropXY) + (cropW div 2))
						set cropY to ((item 2 of cropXY) + (cropH div 2))
					on error
						set cropFlag to "?"
					end try
				end if
			end tell
			
			-- Finalize crop
			if (cropFlag is "Yes") then
				try
					set crop of variantItem to {cropX, cropY, cropW, cropH}
				on error
					display dialog "Error while cropping." buttons {"Ok"} with title "Error"
				end try
			end if
		end try
		
		-- Advance progress bar
		set imgCount to (imgCount + 1)
		set progress completed units to imgCount
	end repeat
end tell


-- From: https://erikslab.com/2007/08/31/applescript-how-to-split-a-string/
on theSplit(theString, theDelimiter)
	-- save delimiters to restore old settings
	set oldDelimiters to AppleScript's text item delimiters
	-- set delimiters to delimiter to be used
	set AppleScript's text item delimiters to theDelimiter
	-- create the array
	set theArray to every text item of theString
	-- restore the old setting
	set AppleScript's text item delimiters to oldDelimiters
	-- return the result
	return theArray
end theSplit
