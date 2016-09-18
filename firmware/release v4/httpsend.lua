local api, port, data, cbFunction, destFile = ...;

local conn = net.createConnection(net.TCP, 0);
local bytes = 0;
local dataLen = 0;

-- global variable - data holder
retVal = nil;

data = data:gsub("%s+", "%%20");

local function writeToFile(_data, _mode)
     if destFile ~= nil and _data ~= nil and destFile ~= "" then
          file.open(destFile, _mode);
          file.write(_data);
          file.close();
     end
end

conn:on("connection", function(conn, payload)
     print("\nsending http request");
     
     conn:send("GET /"..data.." HTTP/1.1\r\n".. 
     "Host: "..api.."\r\n"..
     "User-Agent: KNEWRON Technologies/smartWIFI/1.0\r\n"..
     "Connection: keep-alive\r\n"..
     "Accept: */*\r\n"..
     "\r\n");
end);

conn:on("receive", function(conn, payload)
     if bytes == nil or bytes == 0 then
          print("http response received");
          
          _begin, _end = string.find(payload, "\r\n\r\n");
          
          local infoLen = payload:match("Length: (%d+)");
          
          if _end == nil then _end = 1 end
          if infoLen == nil then infoLen = -1 end
          
          bytes = infoLen + _begin + 3;

          -- if payload doesn't have content length information, allow 2KB data max
          if bytes == nil then
               bytes = 2048;
          end

          dataLen = bytes;
          
		print("http response start ("..bytes.." bytes)\n");

          -- print all raw data for debug
          -- print(payload);          
          -- string.sub(payload, _end + 1, #payload);

          retVal = payload;
          uart.write(0, payload);

          writeToFile(payload, "w+");
     else
          if payload ~= nil then
			retVal = payload;

               uart.write(0, payload);

               writeToFile(payload, "a+");
          end
     end

     bytes = bytes - #payload;

     if bytes == 0 then
          bytes = nil;
          _begin = nil;
          _end = nil;

          print("\n\nhttp response end");
          
          conn:close();
     end
end);

conn:on("sent", function(conn, payload)
	print("http request sent");
end);

conn:on("disconnection", function(conn, payload)
     print("http disconnected\n");

     writeToFile = nil;
     conn = nil;

     if cbFunction ~= nil then
          cbFunction(dataLen);
     end

     dataLen = nil;
end);

conn:connect(port, api);