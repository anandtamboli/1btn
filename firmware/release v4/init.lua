-- setup uart at 9600bps by default with echo
uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1);

rawcode, reason = node.bootreason();
-- to get to this mode hold the RESET button, then turn power off,
-- then release RESET and lastly turn power on
if rawcode == 2 and reason == 6 then
	print("\nWaiting 2.5 seconds before sleep...");
	tmr.alarm(0, 2500, tmr.ALARM_SINGLE, function()
		node.dsleep(0);
	end);
else
	local fName = "setup.lc";

	if file.open(fName) ~= nil then
		file.close(fName);
		dofile(fName);
	else
		print(fName.." does not exist !");
	end
end
