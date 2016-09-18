print("compiling...");

for fName, size in pairs(file.list()) do
	if fName ~= "init.lua" then
		if string.find(fName, ".lu") ~= nil then
			if consoleLog == true then
				uart.write(0, string.format("%s", fName));
			end
			
			node.compile(fName);
			file.remove(fName);

			if consoleLog == true then
				uart.write(0, "...done\n");
			end
		end
	end
end

print("compling complete...");