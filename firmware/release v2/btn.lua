local pressDuration = ...

if pressDuration == nil then
     pressDuration = 1
end

btnTimer = 0;
tempVar = 0;

-- multiply battery voltage by 5.70 to compensate for potential divider
-- 5.70 comes from potential divider of 470K & 100K resistors' ladder
-- i.e. battery voltage at adc pin = vbatt * 100 / (100 + 470)
-- hence actual battery voltage = adc value * (100 + 470) / 100
battV = 5.70 * adc.read(0) / 1000;

function startConfig()
     -- set dummy ssid and password to disconnect from connected wifi
     -- testing for bug
     wifi.sta.config("dummyssid", "dummypass");
     wifi.setmode(wifi.STATIONAP);
     
     -- start ssid server
     dofile("config.lc");
     
     -- start blinking in BLUE
     tmr.alarm(btnTimer, 2000, 1, function()
          blinkLED(BLUE, 1);
     end);
end

function postResponse(nBytes)
     if nBytes > 0 and retVal ~= nil and string.find(retVal, '"success":true') ~= nil then
          -- action successful
          -- blink GREEN 3 times
          blinkLED(GREEN, 3);
          print("1btn success");
     else
		-- action failed
		-- if failure is due to rate-limiting, blink in magenta
		if string.find(retVal, '"code":"1BTN_RATE_LIMITED"') ~= nil then
			-- blink YELLOW 3 times
			blinkLED(MAGENTA, 3);
			print("1btn rate limited");
          else
			-- if failure is due to reconfig request, blink in blue
			if string.find(retVal, '"code":"1BTN_RECONFIG"') ~= nil then
				-- blink BLUE 3 times
				blinkLED(BLUE, 3);
				print("1btn reconfig requested");
			else
				-- blink RED 3 times
				blinkLED(RED, 3);
				print("1btn fail");
			end
		end
     end

     -- check if user has asked 1btn to force reconfig
	if string.find(retVal, '"code":"1BTN_RECONFIG"') ~= nil then
		startConfig();
	else
	-- go back to deep sleep mode - indefinitely
		print("sleeping now");
		node.dsleep(0);
	end
end

function sendEvent()
     setLED(BLUE);
     
     -- send MAC ID as button ID
     btnID = string.upper(wifi.sta.getmac());
     
     -- send AP name as one of the variables
     btnAP = wifi.sta.getconfig();

     retVal = nil;
     postStr = "?"..
               "id="..btnID..
               "&b="..battV..
               "&w="..btnAP..
               "&e=1"..
               "&d="..pressDuration;         

	pcall(assert(loadfile)("httpsend.lc"), "url", "port", postStr, postResponse);
end

-- this is where the main program starts
-- at the outset, check the battery voltage
-- if battery is down, keep blinking RED indefinitely ( hang till death )

print("\nmyMAC = "..string.upper(wifi.sta.getmac()));

if battV < 3.0 then
     print("low battery !");
     
     tmr.alarm(btnTimer, 2000, 1, function()
          blinkLED(RED, 1);
     end);
else
     -- start normal routine
     setLED(BLUE);

     -- 2 seconds delay
     tmr.alarm(btnTimer, 2000, 0, function()
          myIP = wifi.sta.getip();
     
          if myIP ~= nil then
               -- if connected
               print("1btn started ! [ v 1.0 ]");
               sendEvent();
          else
          -- if IP not available
			startConfig();
          end
     end);
end

-- EOF
