-- start with standard + ap mode
wifi.setmode(wifi.STATIONAP);

-- create access-point
apCfg = {};
apCfg.ssid = "my1btn";
--apCfg.ssid = "myBtn_"..string.sub(string.upper(string.gsub(wifi.sta.getmac(), ":", "")), -6);
apCfg.pwd = "12345678";
wifi.ap.config(apCfg);

-- configure access-point
ipcfg = {};
ipcfg.ip = "192.168.1.1";
ipcfg.netmask = "255.255.255.0";
ipcfg.gateway = "192.168.1.1";
wifi.ap.setip(ipcfg);

-- start listening to the webserver
srv = net.createServer(net.TCP);

print("config started "..wifi.ap.getip());
print(apCfg.ssid.." [ "..apCfg.pwd.." ]");

function strSplit(inputstr, sep)
     local t = {};

     i = 1;

     for str in string.gmatch(inputstr, '([^'..sep..']+)') do
          t[i] = str;
          i = i + 1;
     end
     
     return t;
end

function readFile(fName)
	file.open(fName, "r");
	
	htmlText = file.read();
	
	htmlText = string.gsub(htmlText, "{{MAC}}", "MAC: "..string.upper(wifi.sta.getmac()));
	
	local ip = wifi.sta.getip();
	if ip ~= nil then
		htmlText = string.gsub(htmlText, "{{MYIP}}", "MY IP: "..string.upper(ip));
	end

	file.close(fName);
	
	return htmlText;
end

function sendResponse(conn, color, content, response)
	setLED(color);
	
	if content == 'F' then
		response = readFile(response);
	end
	
	conn:send("HTTP/1.1 200 OK\r\nContent-type:text/html\r\n\r\n"..response);
	conn:close();

	print(response);
	setLED(0);
end

-- now listen
srv:listen(80, function(conn)
     conn:on("receive", function(conn, payload)
          if payload ~= nil then
               data = string.sub(payload, string.find(payload, "GET /") + 5, string.find(payload, "HTTP/") - 1);
               
               if string.find(payload, "favicon.ico") == nil then
                    -- perform URL decoding
                    data = string.gsub(data, "+", " ");
                    data = string.gsub(data, "%%(%x%x)", function(h)
                              return string.char(tonumber(h, 16));
                         end);
                    data = string.gsub (data, "\r\n", "\n");

                    -- print every data received
				print(#data.." "..data);
				
                    str1 = {nil, nil};
				
				if #data > 10 then
					str1 = strSplit(data, '/');
				end
				
				if str1[1] ~= nil then
					_, ssid_start = string.find(str1[1], "ssid=");
					ssid_end, pass_start = string.find(str1[1], "pass=");
					pass_end, _ = string.find(str1[1], "action=");

					ssid = string.sub(str1[1], ssid_start + 1, ssid_end - 2);
					pass = string.sub(str1[1], pass_start + 1, pass_end - 2);

					-- print(ssid, pass);
					wifi.setmode(wifi.STATIONAP);
					wifi.sta.config(ssid, pass, 1);
					
					local attempt = 0;
					
					tmr.alarm(1, 250, tmr.ALARM_AUTO, function()
						-- 30 attempts = 15 sec timeout
						if attempt > 30 then
							-- stop timer
							tmr.stop(1);
							
							-- send failure status
							sendResponse(conn, MAGENTA, 'F', "login.html");
						else
							if wifi.sta.getip() ~= nil then 
								-- stop timer
								tmr.stop(1);

								-- send success status with assigned ip
								local ip = wifi.sta.getip();
								
								sendResponse(conn, BLUE, 'T', "Connected to "..ip..", restarting in 5 seconds ! You can close the browser now.");
								-- sendResponse(conn, BLUE, 'F', "showmacnip.html");

								tmr.alarm(1, 5000, tmr.ALARM_AUTO, function()
									node.restart();
								end);
							else
								attempt = attempt + 1;
							end
						end
					end);
				else
					sendResponse(conn, MAGENTA, 'F', "login.html");
				end
			end
		end
		
          -- clean-up
          collectgarbage();
     end)
end);