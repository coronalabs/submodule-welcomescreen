------------------------------------------------------------------------------
--
-- This file is part of the Corona game engine.
-- For overview and more information on licensing please refer to README.md 
-- Home page: https://github.com/coronalabs/corona
-- Contact: support@coronalabs.com
--
------------------------------------------------------------------------------

local simulator = {}
local json = require("json")

function simulator.analytics()
end
function simulator.getPreference()
end
function simulator.getRecentProjects()
	return json.decode '[{"formattedString":"welcomescreen","fullURLString":"/Users/vlad/Projects/corona/simulator-extensions/welcomescreen"},{"formattedString":"SimpleStore with really really long title","fullURLString":"/Users/vlad/Projects/Builds/SimpleStore/Users/vlad/Projects/Builds/SimpleStore/Users/vlad/Projects/Builds/SimpleStore/Users/vlad/Projects/Builds/SimpleStore/Users/vlad/Projects/Builds/SimpleStore/Users//Users/vlad/Projects/Builds/SimpleStore"},{"formattedString":"ComposerScene","fullURLString":"/Users/vlad/Desktop/ComposerScene"},{"formattedString":"assets2","fullURLString":"/Users/vlad/Projects/mt2/platform/test/assets2"},{"formattedString":"Circles","fullURLString":"/Users/vlad/Projects/Circles"},{"formattedString":"StatusBar","fullURLString":"/Users/vlad/Downloads/StatusBar"},{"formattedString":"UILaunchImageTest","fullURLString":"/Users/vlad/Downloads/UILaunchImageTest"},{"formattedString":"test_newTexture","fullURLString":"/Users/vlad/Downloads/test_newTexture"},{"formattedString":"HttpMethods","fullURLString":"/Users/vlad/Projects/Builds/HttpMethods"}]'
end
function simulator.getSubscription()
end
function simulator.setCursorRect()
end
function simulator.setProjectResourceDirectory()
end
function simulator.show(...)
	print("SIMULATOR SHOW: ", ...)
end
return simulator