------------------------------------------------------------------------------
--
-- This file is part of the Corona game engine.
-- For overview and more information on licensing please refer to README.md 
-- Home page: https://github.com/coronalabs/corona
-- Contact: support@coronalabs.com
--
------------------------------------------------------------------------------

local widget = require("widget")
local json = require("json")

Browser = {}
Browser.__index = Browser

function Browser:create(balance)
   local brwsr = {}             -- our new object
   setmetatable(brwsr, Browser)  -- make Browser handle lookup
   brwsr.url = nil      -- initialize our object
   return brwsr
end


function Browser:show(x, y, width, height, url)

	local toolbarWidth = 50
	local iconSize = 40
	local iconAlpha = 1.0
	local mostRecentURL = nil

	if self.browserGroup then
		self.webview.isVisible = true
		self.browserGroup.isVisible = true
	else
		self.browserGroup = display.newGroup()

		self.webview = native.newWebView(x + (toolbarWidth/2), y, width - toolbarWidth, height)
		self.browserGroup:insert(self.webview)

		local background = display.newRect(x, y, width, height)
		background:setFillColor(0.8, 0.8, 0.8)
		self.browserGroup:insert(background)

		local homeButton = widget.newButton
		{
			width = iconSize,
			height = iconSize,
			label = "",
			defaultFile = "assets/browser_home.png",
			overFile = "assets/browser_home.png",
			onRelease = function()
							self.webview:request(url)
						end
		}
		homeButton.x = (x - (width/2)) + (homeButton.width / 2) + 5
		homeButton.y = (y - (height/2)) + (homeButton.height / 2) + 20
		homeButton.alpha = iconAlpha
		self.browserGroup:insert(homeButton)

		local backButton = widget.newButton
		{
			width = iconSize,
			height = iconSize,
			label = "",
			defaultFile = "assets/browser_back.png",
			overFile = "assets/browser_back.png",
			onRelease = function()
							self.webview:back()
						end
		}
		backButton.x = homeButton.x
		backButton.y = homeButton.y + backButton.height
		backButton.alpha = iconAlpha
		self.browserGroup:insert(backButton)

		local forwardButton = widget.newButton
		{
			width = iconSize,
			height = iconSize,
			label = "",
			defaultFile = "assets/browser_forward.png",
			overFile = "assets/browser_forward.png",
			onRelease = function()
							self.webview:forward()
						end
		}
		forwardButton.x = homeButton.x
		forwardButton.y = backButton.y + forwardButton.height
		forwardButton.alpha = iconAlpha
		self.browserGroup:insert(forwardButton)

		local browserButton = widget.newButton
		{
			width = iconSize,
			height = iconSize,
			label = "",
			defaultFile = "assets/browser_external.png",
			overFile = "assets/browser_external.png",
			onRelease = function()
							system.openURL(mostRecentURL or url)
						end
		}
		browserButton.x = homeButton.x
		browserButton.y = forwardButton.y + browserButton.height
		browserButton.alpha = iconAlpha
		self.browserGroup:insert(browserButton)

		local function webListener(event)
			mostRecentURL = event.url
			
			if event.type == "loaded" then
				if self.webview.canGoBack then
					backButton.alpha = 1.0
				else
					backButton.alpha = 0.4
				end
				if self.webview.canGoForward then
					forwardButton.alpha = 1.0
				else
					forwardButton.alpha = 0.4
				end
			end
		end
		self.webview:addEventListener( "urlRequest", webListener )
	end

	if self.url ~= url then
		self.url = url
		self.webview:request(url)
	end
end

function Browser:hide()
	if self.browserGroup then
		self.webview.isVisible = false
		self.browserGroup.isVisible = false
	end
end

return Browser
