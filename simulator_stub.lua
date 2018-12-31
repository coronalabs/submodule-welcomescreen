------------------------------------------------------------------------------
--
-- Copyright (C) 2018 Corona Labs Inc.
-- Contact: support@coronalabs.com
--
-- This file is part of the Corona game engine.
--
-- Commercial License Usage
-- Licensees holding valid commercial Corona licenses may use this file in
-- accordance with the commercial license agreement between you and 
-- Corona Labs Inc. For licensing terms and conditions please contact
-- support@coronalabs.com or visit https://coronalabs.com/com-license
--
-- GNU General Public License Usage
-- Alternatively, this file may be used under the terms of the GNU General
-- Public license version 3. The license is as published by the Free Software
-- Foundation and appearing in the file LICENSE.GPL3 included in the packaging
-- of this file. Please review the following information to ensure the GNU 
-- General Public License requirements will
-- be met: https://www.gnu.org/licenses/gpl-3.0.html
--
-- For overview and more information on licensing please refer to README.md
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