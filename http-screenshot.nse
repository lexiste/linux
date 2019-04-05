--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 dated June, 1991 or at your option
-- any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- A copy of the GNU General Public License is available in the source tree;
-- if not, write to the Free Software Foundation, Inc.,
-- 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
--

description = [[
Take a screen shot of a web page from a host.
]]

author = "Todd Fencl <tfencl at radial.com>"

license = "GPLv2"

categories = {"discovery", "safe"}

local shortport = require "shortport"
local stdnse = require "stdnse"
portrule = shortport.http

action = function(host, port)
	-- check to see if secure is enabled and set to "ssl" even if the response is tls
	local ssl = port.version.service_tunnel

	-- by default, start with http://
	local prefix = "http"

	-- screenshot file name template
	local fname = "cutycapt-nmap-" .. host.ip .. "-" .. port.number .. ".png"

	-- if port is flagged as secure, change the prefix to https://
	if ssl == "ssl" then
		prefix = "https"
	end

	-- execute the command to cutycapt passing our params
	-- this requires graphic libraries, wkhtmlto can perform without graphics but having problems getting a stable version running
	local cmd = "/usr/bin/cutycapt --insecure --url=" .. prefix .. "://" .. host.ip .. ":" .. port.number .. " --out=" .. fname

	local ret = os.execute(cmd)

	-- based on the response, let the user know how we did ...
	local result = "Could not verify ... failed somewhere in " .. cmd

	if ret then
		result = "Successfully saved to " .. fname .. " [ " .. port.version.service_tunnel .. " ]"
	end

	-- now return the result
	return stdnse.format_output(true, result)

end
