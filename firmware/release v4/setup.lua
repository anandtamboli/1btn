-- gpio pin mapping
RED = 1;
GREEN = 2;
YELLOW = 3;
BLUE = 4;
MAGENTA = 5;
CYAN = 6
WHITE = 7;

redLED = 7;
greenLED = 6;
blueLED = 5;

node.setcpufreq(node.CPU160MHZ);

-- set LED pins as output
gpio.mode(redLED, gpio.OUTPUT);
gpio.mode(greenLED, gpio.OUTPUT);
gpio.mode(blueLED, gpio.OUTPUT);

function setLED(ledColor)
     if bit.isset(ledColor, 0) then
          gpio.write(redLED, gpio.HIGH);
     else
          gpio.write(redLED, gpio.LOW);
     end

     if bit.isset(ledColor, 1) then
          gpio.write(greenLED, gpio.HIGH);
     else
          gpio.write(greenLED, gpio.LOW);
     end

     if bit.isset(ledColor, 2) then
          gpio.write(blueLED, gpio.HIGH);
     else
          gpio.write(blueLED, gpio.LOW);
     end
end

function blinkLED(ledColor, blinkTimes)
     for j = 1, blinkTimes do
          setLED(ledColor);
          tmr.delay(250000);
          setLED(0);
          tmr.delay(250000);
     end
end

-- configure wifi
wifi.setmode(wifi.STATIONAP);

setLED(0);

dofile('btn.lc');

-- clean up
collectgarbage("collect");
