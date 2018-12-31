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

local widget = require "widget"
local simErr, simulator = pcall(require, "simulator")
if not simErr then
	simulator = require "simulator_stub"
end
local json = require "json"
local lfs = require "lfs"

-- Reference locals
local stage = display.getCurrentStage()
local screenW, screenH = display.contentWidth, display.contentHeight
local halfW, halfH = screenW*.5, screenH*.5
local platform = system.getInfo( "platformName" )
local userHome = nil
if platform == "Mac OS X" then
	userHome = os.getenv("HOME")
end

local uiFont = "HelveticaNeue"
local dirSeparator = "/"
if platform == "Win" then
	uiFont = "Arial"
	dirSeparator = "\\"
end


-- Colors and fonts
local windowBackgroundColor = { 29/255 , 29/255 , 29/255, 1 }
local topBlockBackgroundColor = { 37/255, 37/255, 37/255, 1 }
local linesColor = { 1, 1, 1, 10/100}
local hintsBGColor = { 37/255, 37/255, 37/255, 1 }

local tabColorSelected = {238/255, 238/255, 238/255, 1}
local tabColorHidden = {159/255, 159/255, 159/255, 1}

local textColorNormal = tabColorSelected
local textColorSelected = { 249/255, 111/255, 41/255, 1 }

local textColorLinks = {177/255,177/255,177/255,1}

local textColorCopyright = { 115/255, 115/255, 115/255 }

local textColorHits = { 165/255, 165/255, 165/255 }

local fontSizeTabBar = 17.5
local fontSizeProjectButtons = 17.5
local fontSizeSections = 17.5
local fontSizeLinkAndNews = 12.5
local fontSizeTooltip = 11
local fontSizeCopyright = 10
local fontSizeRecetProjectName = 15
local fontSizeRecetProjectPath = 12.5

local fontRegular = native.newFont("Exo2-Regular", 35)
local fontBold = native.newFont("Exo2-Bold", 35)


-- Local module vars/groups/etc
local uiTouchesDisabled = false
local isRetinaEnabled = (platform == "Mac OS X")

-- Log analytics when opening URLs
local function OpenURL(url, tag)
	local tag = tag or url
	system.openURL(url)
	simulator.analytics("welcome", "link", tag)
end

-- Creating Pointer Location variable to hold all the pointer location data
-- Need this inorder to disable and enable the mouse pointers
local g_pointerLocations = {}
g_pointerLocations.button = {}
g_pointerLocations.button.text = {}
g_pointerLocations.button.image = {}
g_pointerLocations.project = {}
g_pointerLocations.quickLink = {}
g_pointerLocations.feeds = {}
g_pointerLocations.chrome = {}

-- Limit the length of displayed strings to some number of pixels
local function limitDisplayLength(len, str, font, fontSize, isPath)
	local process
	local origStr = str
	local txtObj = nil
	repeat
		txtObj = display.newText( str, 0, 0, font, fontSize )
		width = txtObj.width
		txtObj:removeSelf( )
		if width > len and str:len() > 3 then
			str = str:gsub('...$', '') -- reduce length of string by 3 characters
			-- str = str .. "…" -- this messes things up because … is a UTF-8 character
		end
	until width <= len

    -- return the possibly trimmed string and add an elipsis if it was trimmed
	return str .. (str ~= origStr and "…" or "")
end


-- Functions to enable and remove pointers

local function setPointers(element, cursor) --Will set pointer for all elements in array
	if element then
		for k, v in pairs(element) do
			local location = v
			location.cursor = cursor
			simulator.setCursorRect(location)
		end
	end
end

local function setPointer(element, cursor) --Will set pointer to single element
	element.cursor = cursor
	simulator.setCursorRect(element)
end

local function removeAllPointers()
	-- Method to remove simulator pointing arrow
	local cursor = "none"

	setPointers(g_pointerLocations.button.text,cursor)
	setPointers(g_pointerLocations.button.image,cursor)
	setPointers(g_pointerLocations.project,cursor)
	setPointers(g_pointerLocations.link,cursor)
	setPointers(g_pointerLocations.feeds,cursor)
	setPointers(g_pointerLocations.chrome,cursor)
end

local function restoreAllPointers()
	-- Method to remove simulator pointing arrow
	local cursor = "pointingHand"

	setPointers(g_pointerLocations.button.text,cursor)
	setPointers(g_pointerLocations.button.image,cursor)
	setPointers(g_pointerLocations.project,cursor)
	setPointers(g_pointerLocations.link,cursor)
	setPointers(g_pointerLocations.feeds,cursor)
	setPointers(g_pointerLocations.chrome,cursor)
end


-----------------------------------------------------------------------------------------


local hovered = {}
local hoveredListeners = {}
local function howerListener(event)
	if event.target == nil then
		for k, v in pairs(hoveredListeners) do
			if (not hovered[k]) == (not hovered[k]) and v.state == (not hovered[k]) then
				v.state = not (not hovered[k])
				for i=1,#v.listeners do
					v.listeners[i](v.state)
				end
			end
		end
		hovered = {}
	else
		hovered[event.target] = true
	end
end

local function addHoverObject(object, onHover)
	if hoveredListeners[object] then
		hoveredListeners[object].listeners[#hoveredListeners[object].listeners + 1] = onHover
	else
		object:addEventListener( "mouse", howerListener )
		hoveredListeners[object] = {
			state = false,
			listeners = {onHover,},
		}
	end
end

Runtime:addEventListener("mouse", howerListener)



-----------------------------------------------------------------------------------------

-- Functions to enable/disable uiTouches (used as an onComplete listeners for some transitions)
local enableTouches = function()
	uiTouchesDisabled = false
end

local disableTouches = function()
	uiTouchesDisabled = true
end

local function unescape(str)
  str = string.gsub( str, '&lt;', '<' )
  str = string.gsub( str, '&gt;', '>' )
  str = string.gsub( str, '&quot;', '"' )
  str = string.gsub( str, '&apos;', "'" )
  str = string.gsub( str, '&mdash;', "-" )
  str = string.gsub( str, '&ndash;', "-" )
  str = string.gsub( str, '&#(%d+);', function(n) return (tonumber(n) > 255 and "" or string.char(n)) end )
  str = string.gsub( str, '&amp;', '&' ) -- and finally ...
  return str
end


-----------------------------------------------------------------------------------------

local function jsonFile( filename, base )
	base = base or system.ResourceDirectory
	local path = system.pathForFile( filename, base )
	local contents
	local file = io.open( path, "r" )
	if file then
		contents = file:read( "*a" )
		io.close( file ) -- close the file after using it
	end
	return contents
end


-----------------------------------------------------------------------------------------
-- Utility Functions
local function scaleForRetina( text )
	if isRetinaEnabled then
		text.xScale = 0.5
		text.yScale = 0.5
	end
end


local function newRetinaText( text, x, y, size, bold )
	local obj
	if isRetinaEnabled then
		obj = display.newText( text, x, y, bold and fontBold or fontRegular, size*2 )
		obj.xScale = 0.5
		obj.yScale = 0.5
	else
		obj = display.newText( text, x, y, bold and fontBold or fontRegular, size )
	end
	return obj
end
-----------------------------------------------------------------------------------------


-- Background rectangles and lines

-- background

display.setDefault('background', unpack(windowBackgroundColor))

local bgRect = display.newRect(halfW, halfH, screenW, screenH )
bgRect:setFillColor(unpack(windowBackgroundColor))

-- Lines

local vertLine = display.newLine( 634, 0, 634, display.contentHeight )
vertLine:setStrokeColor( unpack(linesColor) )
vertLine.strokeWidth = 1

local footerLine = display.newLine( 34, 649.75, 633.5, 649.75 )
footerLine:setStrokeColor( unpack(linesColor) )
footerLine.strokeWidth = 1

local latestNewsLine = display.newLine( 301.5, 488.5, 301.5, 627.5 )
latestNewsLine:setStrokeColor( unpack(linesColor) )
latestNewsLine.strokeWidth = 1

-- header rect

local bgTop = display.newRect(halfW, 40, screenW, 80 )
bgTop:setFillColor(unpack(topBlockBackgroundColor))

-- Corona Logo

local g_coronaLogo = display.newImageRect( "assets/CoronaLogo.png", 144.5, 45.5)
g_coronaLogo.x = 927 + g_coronaLogo.contentWidth*0.5
g_coronaLogo.y = 15 + g_coronaLogo.contentHeight*0.5

g_pointerLocations.chrome['coronaLogo'] =
{
	cursor = "pointingHand",
	x = g_coronaLogo.x - g_coronaLogo.contentWidth*0.5,
	y = g_coronaLogo.y - g_coronaLogo.contentHeight*0.5,
	width = g_coronaLogo.contentWidth,
	height = g_coronaLogo.contentHeight,
}
simulator.setCursorRect(g_pointerLocations.chrome['coronaLogo'])
g_coronaLogo:addEventListener("tap", function () OpenURL("https://coronalabs.com", "homepage") end)


-- Display the Corona version text (build number)

local buildNum = system.getInfo( "build" )
local version = newRetinaText(buildNum, 0, 0, 15)
version:setFillColor(1, 1, 1, 50/255)
version.anchorX = 1
version.x = 1071.5
version.y = 60

g_pointerLocations.chrome['version'] =
{
	cursor = "pointingHand",
	x = version.x - version.contentWidth,
	y = version.y - version.contentHeight*0.5,
	width = version.contentWidth,
	height = version.contentHeight,
}
simulator.setCursorRect(g_pointerLocations.chrome['version'])
version:addEventListener("tap", function () OpenURL("https://developer.coronalabs.com/downloads/daily-builds", "daily-builds") end)

-- Create tab bar


local g_tabBarBase = 80
local g_currentTab = "tab1"
local g_browser = {}
local g_browserFactory = require("browser")


local function handleTabBarEvent( newTab )

	local url = ""
	if newTab == "tab2" then
		url = "https://docs.coronalabs.com/api"
	elseif newTab == "tab3" then
		url = "https://marketplace.coronalabs.com"
	elseif newTab == "tab4" then
		url = "https://forums.coronalabs.com"
	end

	if newTab == "tab1" and g_currentTab ~= "tab1" then
		if g_browser[g_currentTab] then
			g_browser[g_currentTab]:hide()
		end
		restoreAllPointers()
	elseif newTab ~= "tab1" then
		-- It's a browser tab
		if g_browser[g_currentTab] then
			g_browser[g_currentTab]:hide()
		end
		if not g_browser[newTab] then
			g_browser[newTab] = g_browserFactory.create()
		end
		removeAllPointers()
		g_browser[newTab]:show(halfW, halfH + g_tabBarBase/2, display.contentWidth - 8, (display.contentHeight - g_tabBarBase) - 10, url)
	end

	g_currentTab = newTab
end
 
local function makeTabBar( listener )
	
	local tabLabels = {"Projects", "Documentation", "Marketplace", "Forums"}
	local tabXs = {66, 230, 410, 551}

	local tabButtons = {}

	local function highlightTabs(selected)
		for i = 1, #tabButtons do
			tabButtons[i].highlight(selected == i)
		end
	end


	for i = 1, #tabLabels do
		local tab = {}
		local title = newRetinaText(tabLabels[i], tabXs[i], 45, fontSizeTabBar)

		local highlight = display.newGroup()
		local h = display.newImageRect(highlight, "assets/selectedTab.png", title.contentWidth, 24)
		h.x = tabXs[i]
		h.y = 78

		local l = display.newImageRect(highlight, "assets/selectedTabL.png", 10, 24)
		l.x = h.x - h.contentWidth*0.5 - l.contentWidth*0.5
		l.y = 78

		local r = display.newImageRect(highlight, "assets/selectedTabR.png", 10, 24)
		r.x = h.x + h.contentWidth*0.5 + r.contentWidth*0.5
		r.y = 78

		local tabName = "tab" .. i

		function tab.highlight( enable )
			title:setFillColor( unpack(enable and tabColorSelected or tabColorHidden) )
			highlight.isVisible = enable
		end

		local rc = display.newRect( tabXs[i], 56, highlight.contentWidth+10, 48 )
		rc.alpha = 0
		rc.isHitTestable = true
		rc:addEventListener( "touch", function ( event )
			if event.phase == "ended" then
				handleTabBarEvent(tabName)
				highlightTabs(i)
			end
		end )

		tabButtons[#tabButtons+1] = tab
	end
	highlightTabs(1)
end

makeTabBar(handleTabBarEvent)


-----------------------------------------------------------------------------------------
-- QUICK LINKS
-----------------------------------------------------------------------------------------

local quickLinks = display.newImageRect("assets/groupLinks.png", 17, 17)
quickLinks.x = 44
quickLinks.y = 500

local quickLinksTitle = newRetinaText("Quick Links", quickLinks.x+quickLinks.contentWidth*0.5+5, quickLinks.y, fontSizeSections)
quickLinksTitle.anchorX = 0
quickLinksTitle:setFillColor(unpack(textColorNormal))





local function setupQuickLinks()

	local quickLinksData = {
		{
			x = 34,
			y = 548,
			title="Getting Started",
			link="https://docs.coronalabs.com/guide/programming/index.html?utm_source=simulator", -- Getting Started
		},
		{
			x = 34,
			y = 585,
			title="Developer Guides",
			link="https://docs.coronalabs.com/guide/index.html?utm_source=simulator",    -- Learn
		},
		{
			x = 34,
			y = 622,
			title="Samples",
			link="https://coronalabs.com/resources/tutorials/sample-code/?utm_source=simulator",  -- samples
			simShow = "sampleCode",
		},
		{
			x = 162,
			y = 548,
			title="Demos",
			link="https://docs.coronalabs.com/guide/programming/index.html?utm_source=simulator#demo-projects", -- Demos
		},
		{
			x = 162,
			y = 585,
			title="Ads / Monetization",
			link="https://docs.coronalabs.com/guide/monetization/monetization/?utm_source=simulator", -- Corona Ads
		},
		{
			x = 162,
			y = 622,
			title="Request a Feature",
			link="http://feedback.coronalabs.com/?utm_source=simulator", -- Request a Feature
		},
	}

	-- onRelease Event Listeners for Links
	local function onQuickLink(link)
		if not uiTouchesDisabled then
			disableTouches()
			if link.simShow then
				simulator.show( link.simShow )
				simulator.analytics("welcome", "link", link.title)
			else
				OpenURL( link.link, link.title )
			end
			timer.performWithDelay( 500, enableTouches )
		end
		return true
	end

	for i = 1, #quickLinksData do

		local link = quickLinksData[i]

		local quickLinkBtn = newRetinaText(link.title, link.x, link.y, fontSizeLinkAndNews)
		quickLinkBtn:setFillColor( unpack(textColorLinks) )
		quickLinkBtn.anchorX = 0

		local function onHover( hover )
			quickLinkBtn:setFillColor( unpack(hover and textColorSelected or textColorLinks) )
		end		

		addHoverObject(quickLinkBtn, onHover)

		quickLinkBtn:addEventListener( "touch", function( event )
			if event.phase == 'ended' then
				onQuickLink(link)
			end
		end )


		g_pointerLocations.quickLink[i] =
		{
			cursor = "pointingHand",
			x = quickLinkBtn.x - (quickLinkBtn.anchorX * quickLinkBtn.contentWidth),
			y = quickLinkBtn.y - (quickLinkBtn.anchorY * quickLinkBtn.contentHeight),
			width = quickLinkBtn.contentWidth,
			height = quickLinkBtn.contentHeight,
		}
		simulator.setCursorRect(g_pointerLocations.quickLink[i])

	end
end

setupQuickLinks()

-- -----------------------------------------------------------------------------------------
-- -- RECENT NEWS
-- -----------------------------------------------------------------------------------------

local latestGroup = display.newGroup( )

local latestNews = display.newImageRect(latestGroup, "assets/groupNews.png", 17, 17)
latestNews.x = 351
latestNews.y = 500

local latestNewsTitle = newRetinaText( "Latest News", latestNews.x+latestNews.contentWidth*0.5+5, quickLinks.y, fontSizeSections)
latestGroup:insert(latestNewsTitle)
latestNewsTitle.anchorX = 0
latestNewsTitle:setFillColor(unpack(textColorNormal))


latestGroup:insert( latestNewsLine )

latestGroup.isVisible = false

local function newTooltip(object, text )
	local x = object.x + object.contentWidth*(0.5-object.anchorX)
	local y = object.y - object.contentHeight*object.anchorY

	local border = 2
	local triangle = display.newImageRect( "assets/tooltip.png", 15, 8 )
	triangle.anchorY = 1
	triangle.x = x
	triangle.y = y

	local label = newRetinaText(text, x, y - border - triangle.contentHeight , fontSizeTooltip)
	label:translate(0, -label.contentHeight*0.5)
	label:setFillColor( unpack(textColorHits) )

	if label.x + label.contentWidth*0.5 + border + 10 > display.contentWidth then
		label:translate(display.contentWidth-(label.x + label.contentWidth*0.5 + border + 10), 0)
	end

	local bgRc = display.newRect( label.x, label.y, label.contentWidth+border*2, label.contentHeight+border*2 )
	bgRc:setFillColor( unpack(hintsBGColor) )

	local tooltip = display.newGroup( )
	tooltip.alpha = 0
	tooltip:insert( triangle )
	tooltip:insert( bgRc )
	tooltip:insert( label )

	local tooltipFadein = nil
	local function tooltipObjectHover( hover )
		if hover then
			if not tooltipFadein then
				tooltipFadein = transition.fadeIn( tooltip,  { time=200 } )	
			end
		else
			tooltip.alpha = 0
			if tooltipFadein then
				transition.cancel( tooltipFadein )
				tooltipFadein = nil
			end
		end
	end

	addHoverObject(object, tooltipObjectHover)

	return tooltip
end

local function loadFeedPanel(feedModificationDate, blogFeed)
	if not (feedScroll == nil) then
		feedScroll:removeSelf()
		feedScroll = nil
	end

	if feedModificationDate then
		-- If more than a month has passed since the news feed was updated, hide the "Latest News" panel
		local numSecondsInAMonth = (60*60*24*30)
		if (os.time() - feedModificationDate) > numSecondsInAMonth then
			return
		end
	else
		return
	end

	if not blogFeed or #blogFeed == 0 then
		return
	end

	latestGroup.isVisible = true

	local feedYs = {548, 585, 622}

	for i = 1, #feedYs do
		if blogFeed[i] then
			local text = unescape(blogFeed[i].title)
			local url = blogFeed[i].url:gsub('&#(%d+);', function(n) return string.char(n) end) -- fix broken URL encoding
			if url:find('%?') then
				url = url .. "&ref=homescreen"
			else
				url = url .. "?ref=homescreen"
			end
			
			-- text = text .. ' ' .. text

			local availableWidth = 280
			local shortedText = limitDisplayLength(availableWidth, text, fontRegular, fontSizeLinkAndNews)

			local newsItem = newRetinaText(shortedText, 344, feedYs[i], fontSizeLinkAndNews)
			newsItem:setFillColor( unpack(textColorLinks) )
			newsItem.anchorX = 0

			if text ~= shortedText then
				newTooltip(newsItem, text)
			end

			local function onHover( hover )
				newsItem:setFillColor( unpack(hover and textColorSelected or textColorLinks) )
			end		

			addHoverObject(newsItem, onHover)

			newsItem:addEventListener( "touch", function( e )
				if e.phase == "ended" then
					OpenURL( url, "newsfeed-item" )
				end
			end )
			

			g_pointerLocations.feeds[i] =
			{
				cursor = "pointingHand",
				x = newsItem.x - (newsItem.anchorX * newsItem.contentWidth),
				y = newsItem.y - (newsItem.anchorY * newsItem.contentHeight),
				width = newsItem.contentWidth,
				height = newsItem.contentHeight,
			}
			if g_currentTab == "tab1" then
				simulator.setCursorRect(g_pointerLocations.feeds[i])
			end

		end
	end

end


-- Parse a HTTP header date and return the number of seconds since the epoch
local function parseHTTPDateFormat(dateStr)

	if dateStr == nil then
		-- print("parseHTTPDateFormat: missing date")
		return nil
	end

	local datePattern = '(%d+) (%a+) (%d+)'
	local dayMatch, monthMatch, yearMatch = dateStr:match(datePattern)
	local year = 0
	local day = 0
	local month = 0

	if dayMatch and monthMatch and yearMatch then

		local months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}

		for k,v in ipairs(months) do
			if monthMatch == v then
				month = k
				break
			end
		end

		day = dayMatch
		year = yearMatch
	end

	if month == 0 then
		-- print("parseHTTPDateFormat: unrecognized date format: "..tostring(dateStr))
		return nil
	end

	return os.time{year=year, month=month, day=day, hour=0}
end

local function downloadFeeds()

	-- DOWNLOAD BLOG FEED DATA AND DISPLAY IF SUCCESSFUL
	local function networkListener( event )
		local blogFeed
		local feedModificationDate = 0
		if not event.isError and event.status < 400 then
			feedModificationDate = parseHTTPDateFormat(event.responseHeaders['Last-Modified'])
			-- get from temporary directory (downloaded version) if no network error
			local decodeJSON = function() blogFeed = json.decode( jsonFile( "feed.json", system.TemporaryDirectory ) ); end
			pcall( decodeJSON )
		end
		loadFeedPanel(feedModificationDate, blogFeed)
	end

	network.download( "https://coronalabs.com/links/homescreen/feed.json?t="..tostring(os.time()), "GET", networkListener, "feed.json", system.TemporaryDirectory )
end

-- wrap initial call in 1ms timer so network requests don't delay app launch as much
timer.performWithDelay( 1, downloadFeeds )



-- BUTTONS

local function onNewProject()
	if not uiTouchesDisabled then
		disableTouches()
		simulator.show( "new" )
		simulator.analytics("welcome", "button", "New Project")
		timer.performWithDelay( 500, enableTouches )
	end
	return true
end


local function onOpenProject()
	if not uiTouchesDisabled then
		disableTouches()
		-- Launch the actual simulator (open project)

		simulator.show( "open" )
		simulator.analytics("welcome", "button", "Open Project")
		timer.performWithDelay( 500, enableTouches )
	end
	return true
end

local function onRelaunchProject()
	if not uiTouchesDisabled then
		simulator.show( "relaunchProject" )
	end
	return true
end

local bigButtons = {
	{
		title = "New Project",
		x = 125,
		y = 265,
		y2 = 341,
		w = 89,
		h = 73.5,
		image = "assets/projectNew.png",
		hover = "assets/projectNewHover.png",
		handler = onNewProject,
	},
	{
		title = "Open Project",
		x = 305,
		y = 265,
		y2 = 341,
		w = 89,
		h = 73.5,
		image = "assets/projectOpen.png",
		hover = "assets/projectOpenHover.png",
		handler = onOpenProject,
	},
	{
		title = "Relaunch Project",
		x = 485,
		y = 265,
		y2 = 341,
		w = 89,
		h = 73.5,
		image = "assets/projectRelaunch.png",
		hover = "assets/projectRelaunchHover.png",
		handler = onRelaunchProject,
	}
}


function addProjectButtons()
	for i = 1, #bigButtons do
		local info = bigButtons[i]


		local btn = display.newImageRect(info.image, info.w, info.h )
		btn.x = info.x
		btn.y = info.y

		local btnHover = display.newImageRect(info.hover, info.w, info.h )
		btnHover.isVisible = false
		btnHover.x = info.x
		btnHover.y = info.y

		local btnName = newRetinaText(info.title, info.x, info.y2, fontSizeProjectButtons, true)
		btnName:setFillColor( unpack(textColorNormal) )

		local function onHover( hover )
			btn.isVisible = not hover
			btnHover.isVisible = hover
			btnName:setFillColor( unpack(hover and textColorSelected or textColorNormal) )
		end
		
		local h = info.y2-info.y+btnName.contentHeight*0.5+info.h*0.5
		local clickRect = display.newRect(info.x, info.y-info.h*0.5 + h*0.5, math.max(info.w, btnName.contentWidth), h )
		clickRect.isVisible = false
		clickRect.isHitTestable = true

		addHoverObject(clickRect, onHover)

		clickRect:addEventListener( "touch", function( e )
			if e.phase == "ended" then
				info.handler()
			end
		end )

		g_pointerLocations.button.image[i] =
		{
			cursor = "pointingHand",
			x = clickRect.x - (clickRect.anchorX * clickRect.contentWidth),
			y = clickRect.y - (clickRect.anchorY * clickRect.contentHeight),
			width = clickRect.contentWidth,
			height = clickRect.contentHeight,
		}
		simulator.setCursorRect(g_pointerLocations.button.image[i])

	end
end

addProjectButtons()

-------------------
-- Copyright Notice
-------------------


local copyright1 = newRetinaText("© 2018 Corona Labs Inc. ", 34, 675, fontSizeCopyright)
copyright1:translate( copyright1.contentWidth*0.5, 0 )
copyright1:setFillColor( unpack(textColorCopyright) )

local copyright2 = newRetinaText("Term of service", copyright1.x + copyright1.contentWidth*0.5, copyright1.y, fontSizeCopyright)
copyright2:setFillColor( unpack(textColorCopyright) )
copyright2:translate(copyright2.contentWidth*0.5, 0)

local unlderlineY = copyright2.y+copyright2.contentHeight*0.5 - 1.5
local underline = display.newLine(copyright2.x - copyright2.contentWidth*0.5, unlderlineY, copyright2.x + copyright2.contentWidth*0.5, unlderlineY)
underline:setStrokeColor( unpack(textColorCopyright) )

local function onHover( hover )
	underline:setStrokeColor( unpack(hover and textColorSelected or textColorCopyright) )
	copyright2:setFillColor( unpack(hover and textColorSelected or textColorCopyright) )
end		

addHoverObject(copyright2, onHover)

copyright2:addEventListener( "touch", function( event )
	if event.phase == "ended" then
		OpenURL("https://coronalabs.com/terms-and-conditions/?utm_source=simulator", "Term of service")
	end
end )

g_pointerLocations.quickLink[#g_pointerLocations.quickLink+1] =
{
	cursor = "pointingHand",
	x = copyright2.x - (copyright2.anchorX * copyright2.contentWidth),
	y = copyright2.y - (copyright2.anchorY * copyright2.contentHeight),
	width = copyright2.contentWidth,
	height = copyright2.contentHeight,
}
simulator.setCursorRect(g_pointerLocations.quickLink[#g_pointerLocations.quickLink])


local copyright3 = newRetinaText(" & ", 34, 675, fontSizeCopyright)
copyright3.x = copyright2.x + copyright2.contentWidth*0.5 + copyright3.contentWidth*0.5
copyright3:setFillColor( unpack(textColorCopyright) )



local copyright4 = newRetinaText("Privacy Policy.", copyright3.x + copyright3.contentWidth*0.5, copyright3.y, fontSizeCopyright)
copyright4:setFillColor( unpack(textColorCopyright) )
copyright4:translate(copyright4.contentWidth*0.5, 0)

local unlderlineY = copyright4.y+copyright4.contentHeight*0.5 - 1.5
local underline = display.newLine(copyright4.x - copyright4.contentWidth*0.5, unlderlineY, copyright4.x + copyright4.contentWidth*0.5, unlderlineY)
underline:setStrokeColor( unpack(textColorCopyright) )

local function onHover( hover )
	underline:setStrokeColor( unpack(hover and textColorSelected or textColorCopyright) )
	copyright4:setFillColor( unpack(hover and textColorSelected or textColorCopyright) )
end		

addHoverObject(copyright4, onHover)

copyright4:addEventListener( "touch", function( event )
	if event.phase == "ended" then
		OpenURL("https://coronalabs.com/privacy-policy/?utm_source=simulator", "Privacy Policy")
	end
end )

g_pointerLocations.quickLink[#g_pointerLocations.quickLink+1] =
{
	cursor = "pointingHand",
	x = copyright4.x - (copyright4.anchorX * copyright4.contentWidth),
	y = copyright4.y - (copyright4.anchorY * copyright4.contentHeight),
	width = copyright4.contentWidth,
	height = copyright4.contentHeight,
}
simulator.setCursorRect(g_pointerLocations.quickLink[#g_pointerLocations.quickLink])


-------------------
--- RECENT PROJECTS
-------------------

local recentProjects = display.newImageRect("assets/groupRecent.png", 17, 17)
recentProjects.x = 694
recentProjects.y = 151

local recentProjectsTitle = newRetinaText("Recent Projects", recentProjects.x+recentProjects.contentWidth*0.5+5, recentProjects.y, fontSizeSections)
recentProjectsTitle.anchorX = 0
recentProjectsTitle:setFillColor(unpack(textColorNormal))


local recentsGroup = display.newGroup( )

local projectsButtonWidth = 325



local function createProjectActions(x, y, projectURL)

	local group = display.newGroup()
	local activeGroup = display.newGroup()

	group:insert( activeGroup )

	local mini = display.newImageRect( group, "assets/miniMenu.png", 17,17 )
	mini:translate(x,y)

	local miniActive = display.newImageRect( activeGroup, "assets/miniMenuHover.png", 17,17 )
	miniActive:translate(x,y)

	local function createActiveButton(x, img, hover, tooltipText, func)
		local btn = display.newImageRect( activeGroup, img, 17,17 )
		btn.x = x
		btn.y = y
		
		local btnHover = display.newImageRect( activeGroup, hover, 17,17 )
		btnHover.x = x
		btnHover.y = y
		btnHover.isVisible = false
		btnHover.isHitTestable = true

		local tooltip = newTooltip(btnHover, tooltipText)
		activeGroup:insert( tooltip )

		addHoverObject(btnHover, function( hover )
			btnHover.isVisible = hover
			btn.isVisible = not hover
		end)

		btnHover:addEventListener( "touch", function( event )
			if event.phase == "ended" then 
				-- howerListener{}
				func()
				return true
			end
		end )
	end
	
	x = x-32

	createActiveButton(x, "assets/miniSandbox.png", "assets/miniSandboxHover.png", "Show Project Sandbox", function()
		if not uiTouchesDisabled then
			disableTouches()
			simulator.show( "showSandbox", projectURL)
			timer.performWithDelay( 500, enableTouches )
		end
	end)


	x = x-32

	createActiveButton(x, "assets/miniBrowse.png", "assets/miniBrowseHover.png", "Show Project Files", function()
		if not uiTouchesDisabled then
			disableTouches()
			simulator.show( "showFiles", projectURL)
			timer.performWithDelay( 500, enableTouches )
		end
	end)

	x = x-32

	createActiveButton(x, "assets/miniEdit.png", "assets/miniEditHover.png", "Open in Editor", function()
		if not uiTouchesDisabled then
			disableTouches()
			simulator.show( "editProject", projectURL)
			timer.performWithDelay( 500, enableTouches )
		end
	end)

	x = x-32

	createActiveButton(x, "assets/miniOpen.png", "assets/miniOpenHover.png", "Open", function()
		if not uiTouchesDisabled then
			disableTouches()
			simulator.show( "open", projectURL)
			timer.performWithDelay( 500, enableTouches )
		end
	end)

	activeGroup.isVisible = false

	local function toggle(on)
		activeGroup.isVisible = on
		mini.isVisible = not on
	end

	return group, toggle
end

-- function hsvToRgb(h, s, v)
--   local r, g, b
--   local i = math.floor(h * 6);
--   local f = h * 6 - i;
--   local p = v * (1 - s);
--   local q = v * (1 - f * s);
--   local t = v * (1 - (1 - f) * s);
--   i = i % 6
--   if i == 0 then r, g, b = v, t, p
--   elseif i == 1 then r, g, b = q, v, p
--   elseif i == 2 then r, g, b = p, v, t
--   elseif i == 3 then r, g, b = p, q, v
--   elseif i == 4 then r, g, b = t, p, v
--   elseif i == 5 then r, g, b = v, p, q
--   end
--   return r, g, b
-- end



function showRecents()
	-- Clear the previous recents list
	recentsGroup:removeSelf( )
	recentsGroup = display.newGroup( )

	setPointers(g_pointerLocations.project, "none")

	local projects = simulator.getRecentProjects()
	local projectsItemHeight = 65


	if #projects <= 0 then
		--Project count is zero - No Projects - so show place to create one
		

		local btn = display.newImageRect("assets/projectNew.png", 89, 73.5 )
		btn.x = 867
		btn.y = 318

		local btnHover = display.newImageRect("assets/projectNewHover.png", 89, 73.5 )
		btnHover.isVisible = false
		btnHover.x = btn.x
		btnHover.y = btn.y

		local btnName = newRetinaText("Create your first Project", 867, btn.y + 76, fontSizeProjectButtons, true)
		btnName:setFillColor( unpack(textColorNormal) )

		local function onHover( hover )
			btn.isVisible = not hover
			btnHover.isVisible = hover
			btnName:setFillColor( unpack(hover and textColorSelected or textColorNormal) )
		end
		
		local h = btnName.y-btnHover.y+btnName.contentHeight*0.5+btn.contentHeight*0.5
		local clickRect = display.newRect(867, btnHover.y-btn.contentHeight*0.5 + h*0.5, math.max(btn.contentWidth, btnName.contentWidth), h )
		clickRect.isVisible = false
		clickRect.isHitTestable = true

		addHoverObject(clickRect, onHover)

		clickRect:addEventListener( "touch", function( e )
			if e.phase == "ended" then
				onNewProject()
			end
		end )


		g_pointerLocations.project[1] =
		{
			cursor = "pointingHand",
			x = (clickRect.x - (clickRect.contentWidth / 2)),
			y = (clickRect.y - (clickRect.contentHeight / 2)),
			width = clickRect.contentWidth,
			height = clickRect.contentHeight,
		}
		simulator.setCursorRect(g_pointerLocations.project[1])

		recentsGroup:insert( clickRect )
		recentsGroup:insert( btn )
		recentsGroup:insert( btnHover )
	else
		--At least 1 recent project was found. List them.
		-- recentProjectsTitle.isVisible = true

		-- Enabling and disabling the recent project scrolling and setting numbers. if <=5, scroll will be disabled.
		local numProjectsShown = 7
		if numProjectsShown > #projects then
			numProjectsShown = #projects
		end

		for i = 1,numProjectsShown do

			-- On Windows we sometimes get nil entries in the recents array
			-- so we avoid them here
			if projects[i] then
				local projectgroup = display.newGroup()

				local projectName = projects[i].formattedString
				local projectDir = projects[i].fullURLString

				if platform == "Win" then
					projectDir = projectDir .. "\\..\\."
				end
				local icon = nil

				if projectName == nil or projectName == "" then
					-- This used to happen on Windows if there aren't enough recent items
					break
				end

				local fullURLString = projects[i].fullURLString
				local function projectOpen()
					simulator.show( "open", fullURLString)
					simulator.analytics("welcome", "recents", "open-project-"..tostring(i))
				end

				-- PROJECT ICONS
				if not icon then 
					local projectIconFile = simulator.getPreference("welcomeScreenIconFile") or "Icon.png"
					local projectIcon = projectDir ..dirSeparator.. projectIconFile
					if lfs.attributes(projectIcon) ~= nil then
						simulator.setProjectResourceDirectory(projectDir)
						icon = display.newImageRect(projectIconFile, system.ProjectResourceDirectory, 32, 32)
					end
				end

				if not icon then 
					local projectIconFile = "Icon-xhdpi.png"
					local projectIcon = projectDir ..dirSeparator.. projectIconFile
					if lfs.attributes(projectIcon) ~= nil then
						simulator.setProjectResourceDirectory(projectDir)
						icon = display.newImageRect(projectIconFile, system.ProjectResourceDirectory, 32, 32)
					end
				end

				if not icon then 
					local projectIconFile = "Icon-hdpi.png"
					local projectIcon = projectDir ..dirSeparator.. projectIconFile
					if lfs.attributes(projectIcon) ~= nil then
						simulator.setProjectResourceDirectory(projectDir)
						icon = display.newImageRect(projectIconFile, system.ProjectResourceDirectory, 32, 32)
					end
				end

				if not icon then 
					local projectIconFile = "Icon-120.png"
					local iconDir = projectDir ..dirSeparator.. "Images.xcassets" ..dirSeparator.. "AppIcon.appiconset"
					local projectIcon = iconDir .. dirSeparator .. projectIconFile
					if lfs.attributes(projectIcon) ~= nil then
						simulator.setProjectResourceDirectory(iconDir)
						icon = display.newImageRect(projectIconFile, system.ProjectResourceDirectory, 32, 32)
					end
				end

				if not icon then
					-- project lacks an "Icon.png" file (or whatever pref value they set), use a default
					icon = display.newImageRect("assets/DefaultAppIcon.png", system.ResourceDirectory, 32, 32)
				end

				projectgroup:insert(icon)
				icon.anchorX = 0
				icon.anchorY = 0
				icon.x = 687
				icon.y = 214 + projectsItemHeight * (i - 1)

				local x = icon.x + icon.contentWidth + 17.5
				local y = icon.y

				-- PROJECT NAME & PATH
				local shortProjectName = limitDisplayLength(projectsButtonWidth*0.55, projectName, fontRegular, fontSizeRecetProjectName)

				local projectNameLabel = newRetinaText(shortProjectName, x, y - 6, fontSizeRecetProjectName)
				projectNameLabel:setFillColor( unpack(textColorNormal) )
				projectNameLabel.anchorX = 0
				projectNameLabel.anchorY = 0


				if shortProjectName ~= projectName then
					newTooltip(projectNameLabel, projectName)
				end

				local function onHover( hover )
					projectNameLabel:setFillColor( unpack(hover and textColorSelected or textColorNormal) )
				end
				addHoverObject(projectNameLabel, onHover)



				local prPath = projects[i].fullURLString
				if userHome then
					prPath = projects[i].fullURLString:gsub("^"..userHome, "~")
				end
				if userHome and prPath:find(userHome, 0, true) == 1 then
					prPath = "~"..projects[i].fullURLString:sub(#userHome+1)
				end
				
				local shortProjectPath = limitDisplayLength(projectsButtonWidth, prPath, fontRegular, fontSizeRecetProjectPath, true)

				local projectPathLabel = newRetinaText(shortProjectPath, x, y + icon.contentHeight + 2, fontSizeRecetProjectPath)
				projectPathLabel:setFillColor( unpack(textColorLinks))
				projectPathLabel.anchorX = 0
				projectPathLabel.anchorY = 1

				if shortProjectPath ~= prPath then
					newTooltip(projectPathLabel, prPath)
				end

				local function onHover( hover )
					projectPathLabel:setFillColor( unpack(hover and textColorSelected or textColorLinks) )
				end
				addHoverObject(projectPathLabel, onHover)

				projectgroup:insert(projectNameLabel)
				projectgroup:insert(projectPathLabel)

				recentsGroup:insert(projectgroup)

				--Making a box so to take the cursor event anywhere in the box
				local cell = display.newRect(icon.x, icon.y - 10, icon.contentWidth + 17.5 + projectsButtonWidth+10, icon.height + 18)
				cell:translate( cell.contentWidth*0.5, cell.contentHeight*0.5 )
				cell:setFillColor(0.5,0.5,0.5,0.5)
				cell.isHitTestable = true
				cell.isVisible = false
				projectgroup:insert(cell)

				local projectActionsGroup, toggleFunction = createProjectActions(x + projectsButtonWidth, projectNameLabel.y + projectNameLabel.contentHeight*0.5, projects[i].fullURLString)
				projectgroup:insert(projectActionsGroup)

				addHoverObject(cell, function( hover )
					toggleFunction(hover)
				end)

				local cellContentX, cellContentY = projectgroup:localToContent(cell.x, cell.y)
				g_pointerLocations.project[i] =
				{
					cursor = "pointingHand",
					x = cellContentX - (cell.width / 2),
					y = cellContentY - (cell.height / 2),
					width = cell.width,
					height = cell.height
				}
				simulator.setCursorRect(g_pointerLocations.project[i])

				cell:addEventListener( "touch", cell )

				function cell:touch( event )
					if event.phase == "ended" then
						projectOpen()
					end
				end
			end
		end
	end
end



showRecents()
Runtime:addEventListener( "_projectLoaded", showRecents )


-----------------------------------------------------------------------------------------

-- Hide status bar, if it exists...
-- Do this at the end. TODO - why?
if type( display.setStatusBar ) == "function" then
	display.setStatusBar( display.HiddenStatusBar )
end
