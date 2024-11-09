// enum for LED states
enum LEDState {
  IDLE(0),
    WAITING_FOR_CONNECTION(1),
    CONNECTED(2),
    COMPLETE(3),
    WORKING_S(4),
    WORKING_M(5),
    WORKING_F(6);

  private final int value;

  LEDState(int value) {
    this.value = value;
  }

  public int getValue() {
    return value;
  }
}

void changeLEDState(LEDState state) {
  if (isConnected) {
    int stateValue = state.getValue();

    // Extract the binary values for the three pins
    int pin1Value = 1 - (stateValue >> 2) & 1;  // Extract bit 2
    int pin2Value = 1 - (stateValue >> 1) & 1;  // Extract bit 1
    int pin3Value = 1 - stateValue & 1;         // Extract bit 0

    // Send IO commands to set each of the three output pins on the TMCM-3110
    sendIOCommand(0, pin1Value, 200);  // Set output pin 1
    sendIOCommand(1, pin2Value, 200);  // Set output pin 2
    sendIOCommand(2, pin3Value, 200);  // Set output pin 3

    logMessage("LED state changed to " + state.name() +
      " (PIN_1=" + pin1Value +
      ", PIN_2=" + pin2Value +
      ", PIN_3=" + pin3Value + ")");
  } else {
    logMessage("Not connected to any COM port.");
  }
}


boolean sendIOCommand(int pin, int value, int timeout) {
  int command = 14;
  byte[] commandPacket = AssembleCommandPacket(1, command, pin, 2, value);
  timeout = 1000;
  // Convert commandPacket to hex string
  StringBuilder hexCommand = new StringBuilder();
  for (byte b : commandPacket) {
    hexCommand.append(String.format("%02X ", b));
  }

  // Use an ExecutorService to manage the timeout
  ExecutorService executor = Executors.newSingleThreadExecutor();
  Future<Boolean> future = executor.submit(new Callable<Boolean>() {
    public Boolean call() throws Exception {
      if (port != null) {
        port.write(commandPacket);
        logMessage("Command Sent: " + hexCommand.toString().trim());
        return true;  // Indicate success
      } else {
        throw new Exception("Port is null");
      }
    }
  }
  );

  try {
    return future.get(timeout, TimeUnit.MILLISECONDS);
  }
  catch (TimeoutException e) {
    logMessage("Error: Command sending timed out.");
    return false;  // Indicate failure due to timeout
  }
  catch (Exception e) {
    logMessage("Error: " + e.getMessage());
    return false;  // Indicate failure due to other errors
  }
  finally {
    executor.shutdown();
  }
}


void initLeds() {
  sendIOCommand(3, 0, 200);
  if (isConnected) {
    changeLEDState(LEDState.CONNECTED);
  }
}
