 //<>//
import controlP5.*;
import processing.serial.*;
import java.util.concurrent.*;
import java.text.SimpleDateFormat;
import java.util.Date;

ControlP5 cp5;
Serial port;  // The serial port

PGraphics pg;
PVector disc1Center, disc2Center, canvasCenter;
ArrayList<PVector> path = new ArrayList<PVector>();
PVector lastA;//= new PVector(disc1Center.x + radius1, 0);
PVector lastB;//= new PVector(disc2Center.x + radius2, 0);

int exportResolution = 1000;  // Set higher resolution for export
int hOffset = 350, vOffset = 430;
int printStartTime;

String comPort = "COM17";  // Default COM port
boolean isConnected = false;
boolean running = false;
boolean fastForward = false;
boolean fastForwardActivated = false;
boolean isPrinting = false;

float progress = 0;  // For progress bar
float t = 0;
float gearRatio = 1 / 9.375;
float maxSpeed = 2; // Max speed in RPS

//Default Settings
float radius1 = 14, radius2 = 22;  // Define radius1 and radius2
float speed1 = 0.2000, speed2 = 0.4000, canvasSpeed = 0.3;
float acc1 = 0.00, acc2=0.00;
float rodLength1 = 107.5, rodLength2 = 107.5, rodLength3 = 87.5, rodLength4 = 87.5, rodLength5 = 42.431, rodLength6 = 65.899, rodLength7 = 35.670;
boolean direction1 = true, direction2 = true;
boolean canvasDirection = true;  // For canvas rotation direction
float fastForwardTimeout = 120;


void setup() {
  size(1200, 530);
  pixelDensity(1);//displayDensity());
  background(100);  
  smooth();

  cp5 = new ControlP5(this);

  pg = createGraphics(exportResolution, exportResolution);  // Size of the canvas for the pattern)

  setupUI();

  // Set positions for disc centers and canvas center
  disc1Center = new PVector(hOffset + width / 2 - 46.5, vOffset);  // Center of disc 1
  disc2Center = new PVector(hOffset +  width / 2 + 46.5, vOffset);  // Center of disc 2
  canvasCenter = new PVector(hOffset + width / 2, vOffset - 180);  // Center of the canvas

  updatePantograph();
  Connect();
  initLeds();
  delay(100);
  changeLEDState(LEDState.IDLE);
}

void draw() {

  if (fastForward && !fastForwardActivated) {
    fastForwardActivated = true;
    simulateFastForward();
  }

  if (!fastForward || (fastForward && t < fastForwardTimeout)) {
    background(100);  // Set light grey background

    // Draw the canvas
    pushMatrix();
    translate(canvasCenter.x, canvasCenter.y);  // Move to canvas center
    float adjustedCanvasSpeed = canvasSpeed *TWO_PI* gearRatio * (canvasDirection ? -1 : 1);  // Apply gear ratio and reverse direction
    rotate(-t * adjustedCanvasSpeed);  // Rotate canvas
    translate(-canvasCenter.x, -canvasCenter.y);  // Move back
    fill(240);
    ellipse(canvasCenter.x, canvasCenter.y, 350, 350);  // Draw canvas

    // Draw the path on the rotating canvas
    noFill();
    beginShape();
    for (PVector pt : path) {
      vertex(pt.x, pt.y);
    }
    endShape();
    popMatrix();

    // Draw discs (they should rotate independently)
    drawDiscs();

    if (running && t < fastForwardTimeout) {
      // Update the simulation based on current time and user inputs
      updatePantograph();
    }

    if (isPrinting) {
      int elapsed = millis() - printStartTime;
      progress = map(elapsed, 0, fastForwardTimeout * 1000, 0, 100);
      cp5.getController("Progress").setValue(progress);

      if (elapsed >= fastForwardTimeout * 1000) {
        Stop();
        EmergencyStop();
        isPrinting = false;
      }
    }
  }
}

void drawDiscs() {
  // Draw the discs
  ellipse(disc1Center.x, disc1Center.y, radius1 * 2, radius1 * 2);  // Disc 1
  ellipse(disc2Center.x, disc2Center.y, radius2 * 2, radius2 * 2);  // Disc 2

  textAlign(LEFT, CENTER); // Align text to the left and center vertically

  // Label for Disc 1
  text("Disc 1", disc1Center.x + radius1 + 1, disc1Center.y+10);

  // Label for Disc 2
  text("Disc 2", disc2Center.x + radius2 + 1, disc2Center.y+10);
}

void updatePantograph() {

  // Calculate angular velocities based on speeds and direction
  float v1 = speed1 + acc1*t;
  float v2 = speed2 + acc2*t;
  float x1 = speed1 * t + 0.5*acc1*(t*t);
  float x2 = speed2 * t + 0.5*acc2*(t*t);

  if (v1 > maxSpeed) {
    v1 = 2.0;
    x1 = 2.0 *t;
  }
  if (v2 > maxSpeed) {
    v2 = 2.0;
    x2 = 2.0 *t;
  }

  float x1_rad = x1 * 2 * PI* (direction1 ? -1 : 1);
  float x2_rad = x2 * 2 * PI* (direction2 ? -1 : 1);

  // Update positions of points on the rods based on time and angular velocities
  t += 1.0 / frameRate;

  PVector A = new PVector(disc1Center.x + radius1 * cos(x1_rad), disc1Center.y + radius1 * sin(x1_rad));
  PVector B = new PVector(disc2Center.x + radius2 * cos(x2_rad), disc2Center.y + radius2 * sin(x2_rad));
  PVector H = findIntersection(A, rodLength1, B, rodLength2, 0);
  PVector C = PVector.add(H, PVector.mult(PVector.sub(H, A), rodLength3 / rodLength1));
  PVector D = PVector.add(H, PVector.mult(PVector.sub(H, B), rodLength4 / rodLength2));
  PVector E = findIntersection(C, rodLength5, D, rodLength6, 1);
  PVector P = PVector.add(E, PVector.mult(PVector.sub(E, C), rodLength7 / rodLength5));

  // Rotate the point to simulate the canvas rotation
  PVector rotatedP = P.copy();
  rotatedP.sub(canvasCenter);
  rotatedP.rotate((canvasDirection ? -1 : 1)* t * canvasSpeed* TWO_PI * gearRatio); // Apply gear ratio and reverse rotation direction
  rotatedP.add(canvasCenter);
  path.add(rotatedP);

  if (isPrinting) {
    StartMotor(0, v1);
    StartMotor(1, v2);
  }


  if (!fastForward ) {
    stroke(0);
    line(A.x, A.y, C.x, C.y); // Rod from A to C
    line(B.x, B.y, D.x, D.y); // Rod from B to D
    line(H.x, H.y, C.x, C.y); // Rod from H to C
    line(H.x, H.y, D.x, D.y); // Rod from H to D
    line(C.x, C.y, P.x, P.y); // Rod from C to P
    line(D.x, D.y, E.x, E.y); // Rod from D to E
  }
}


PVector findIntersection(PVector P1, float L1, PVector P2, float L2, int direction) {
  // Intersection calculation similar to your Grasshopper method
  float d = P1.dist(P2);
  float a = (L1 * L1 - L2 * L2 + d * d) / (2 * d);
  float h = sqrt(L1 * L1 - a * a);
  PVector P3 = P1.copy().add(PVector.sub(P2, P1).mult(a / d));
  float offsetX = h * (P2.y - P1.y) / d;
  float offsetY = h * (P2.x - P1.x) / d;
  if (direction == 0) {
    return new PVector(P3.x + offsetX, P3.y - offsetY);
  } else {
    return new PVector(P3.x - offsetX, P3.y + offsetY);
  }
}

void simulateFastForward() {
  path.clear();
  t = 0.0;
  // Simulate the pattern drawing by running the update method quickly
  int steps = (int)(fastForwardTimeout * frameRate);
  for (int i = 0; i < steps; i++) {
    updatePantograph();
  }
}

void Start() {
  if (fastForward) {
    fastForward = false;
    fastForwardActivated = false;
    path.clear();
    cp5.get(Toggle.class, "fastForward").setState(false);  // Deactivate the toggle button
  }
  running = true;
  t = 0;
  path.clear();
  fastForwardActivated = false;

  float maxSpeed = max(speed1, speed2);
  if (maxSpeed<0.2) {
    changeLEDState(LEDState.WORKING_S);
  } else if (maxSpeed>=0.2 && maxSpeed<1) {
    changeLEDState(LEDState.WORKING_M);
  } else if (maxSpeed>1) {
    changeLEDState(LEDState.WORKING_F);
  }
}

void Stop() {
  running = false;
  if (isConnected) {
    for (int i = 0; i < 3; i++) {
      StopMotor(i);
    }
    isPrinting = false;
    //cp5.getController("Progress").setValue(0);
    logMessage("All motors stopped.");
    changeLEDState(LEDState.COMPLETE);
  }
}

void ExportPNG() {
  String timestamp = str(year()) + "-" + nf(month(), 2) + "-" + nf(day(), 2) + "_" + nf(hour(), 2) + "-" + nf(minute(), 2) + "-" + nf(second(), 2);
  String filename = "pattern_" + timestamp + ".png";

  // Draw the polyline onto the PGraphics object at higher resolution
  pg.beginDraw();
  pg.background(255);  // White background for the export
  pg.translate(pg.width, pg.height);  // Center the pattern
  pg.scale(-(float)exportResolution / 350);  // Scale to higher resolution
  pg.noFill();
  pg.stroke(0);  // Set stroke color for the polyline
  pg.strokeWeight(0.3);  // Set stroke weight (thickness) for the polyline

  for (int i = 1; i < path.size(); i++) {
    PVector pt1 = path.get(i - 1);
    PVector pt2 = path.get(i);
    pg.line(pt1.x - (canvasCenter.x - 175), pt1.y - (canvasCenter.y - 175),
      pt2.x - (canvasCenter.x - 175), pt2.y - (canvasCenter.y - 175));  // Draw line segments
  }

  // Reset transformations for the text
  pg.resetMatrix();
  pg.scale(2); // Adjust this scale factor if needed to match your desired text size in the high-resolution output

  pg.fill(0);
  pg.textAlign(LEFT, TOP);
  pg.textSize(9);
  pg.text("Disc 1 Speed: " + nf(speed1, 1, 2) + " RPS " + (direction1 ? "CW" : "CCW"), 10, 10);
  pg.text("Disc 2 Speed: " + nf(speed2, 1, 2) + " RPS " + (direction2 ? "CW" : "CCW"), 10, 25);
  pg.text("Canvas Speed: " + nf(canvasSpeed, 1, 2) + " RPS " + (canvasDirection ? "CW" : "CCW"), 10, 40);
  pg.text("Timeout: " + nf(fastForwardTimeout, 1, 2) + " s", 10, 55);

  // End drawing and save the PGraphics object as a PNG
  pg.endDraw();
  pg.save(filename);

  println("Pattern saved as " + filename + " at resolution " + exportResolution + "x" + exportResolution);
}


void Reset() {
  if (fastForward) {
    fastForward = false;
    fastForwardActivated = false;
    path.clear();
    cp5.get(Toggle.class, "fastForward").setState(false);  // Deactivate the toggle button
  }
  running = false;
  isPrinting = false;
  Stop();
  t = 0;
  lastA = new PVector(disc1Center.x + radius1, 0);
  lastB = new PVector(disc2Center.x + radius2, 0);
  path.clear();
}

void Connect() {
  comPort = cp5.get(Textfield.class, "COM Port").getText();
  //comPort = "COM3";
  try {
    port = new Serial(this, comPort, 9600);
    isConnected = true;
    logMessage("Connected to " + comPort);
    changeLEDState(LEDState.CONNECTED);
  }
  catch (Exception e) {
    logMessage("Failed to connect to " + comPort);
    isConnected = false;
  }
}

void Disconnect() {
  if (isConnected) {
    port.stop();
    isConnected = false;
    logMessage("Disconnected from " + comPort);
  }
}

void StartMotor0() {
  StartMotor(0, speed1);
}
void StartMotor1() {
  StartMotor(1, speed2);
}
void StartMotor2() {
  StartMotor(2, canvasSpeed);
}

void StopMotor0() {
  StopMotor(0);
}
void StopMotor1() {
  StopMotor(1);
}
void StopMotor2() {
  StopMotor(2);
}


void StartMotor(int motorIndex, float speed) {
  if (isConnected) {
    // Send start command for the specified motor
    int direction = 1;  // Example direction (CW)
    int timeout = 1000;
    //float speed = 1.0;  // Example speed in RPS
    if (sendMotorCommand(motorIndex, direction, speed, timeout)) {
      logMessage("Started Motor " + (motorIndex + 1));
    }
  } else {
    logMessage("Not connected to any COM port.");
  }
}

void StopMotor(int motorIndex) {
  if (isConnected) {
    // Send stop command for the specified motor
    int timeout = 1000;
    sendMotorCommand(motorIndex, 3, 0, timeout);  // Stop command
    logMessage("Stopped Motor " + (motorIndex));
  } else {
    logMessage("Not connected to any COM port.");
  }
}

void PrintPattern() {
  if (isConnected) {
    if (fastForward) {
      fastForward = false;
      fastForwardActivated = false;
      path.clear();
      cp5.get(Toggle.class, "fastForward").setState(false);  // Deactivate the toggle button
      logMessage("Fast forward mode deactivated before printing pattern.");
    }

    // Start all motors and begin the print pattern
    StartMotor(0, speed1);
    StartMotor(1, speed2);
    StartMotor(2, canvasSpeed);

    printStartTime = millis();
    isPrinting = true;

    Start();

    logMessage("Printing pattern...");
  } else {
    logMessage("Not connected to any COM port.");
  }
}


void EmergencyStop() {
  for (int i = 0; i < 3; i++) {
    StopMotor(i);
  }
  isPrinting = false;
  //cp5.getController("Progress").setValue(0);
  logMessage("All motors stopped.");
}

boolean sendMotorCommand(int motor, int direction, float rps, int timeout) {
  int command = direction;  // Command logic
  int velocity = ConvertRpsToVint(rps, 200 * 256, 1);
  byte[] commandPacket = AssembleCommandPacket(1, command, 0, motor, velocity);
  timeout = 1000;
  // Convert commandPacket to a human-readable hex string
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
    // Wait for the command to be sent within the timeout period
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



int ConvertRpsToVint(float rps, int stepsPerRevolution, int pulseDiv) {
  double pps = rps * stepsPerRevolution;
  int vint = (int) ((pps * Math.pow(2, pulseDiv) * 2048 * 32) / (16 * Math.pow(10, 6)));
  return vint;
}

byte[] AssembleCommandPacket(int address, int command, int type, int motor, int value) {
  byte[] commandPacket = new byte[9];
  commandPacket[0] = (byte) address;
  commandPacket[1] = (byte) command;
  commandPacket[2] = (byte) type;
  commandPacket[3] = (byte) motor;
  commandPacket[4] = (byte) ((value >> 24) & 0xFF);
  commandPacket[5] = (byte) ((value >> 16) & 0xFF);
  commandPacket[6] = (byte) ((value >> 8) & 0xFF);
  commandPacket[7] = (byte) (value & 0xFF);
  commandPacket[8] = CalculateChecksum(commandPacket);
  return commandPacket;
}

byte CalculateChecksum(byte[] command) {
  int sum = 0;
  for (int i = 0; i < command.length - 1; i++) {
    sum += command[i];
  }
  return (byte) (sum % 256);
}

void logMessage(String message) {
  Textarea logArea = cp5.get(Textarea.class, "Log");
  if (logArea != null) {
    // Get the current date and time
    String currentTime = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());

    // Get the current text in the log area
    String currentText = logArea.getText();

    // Set the new text with the current time and message
    logArea.setText(currentText + currentTime + " | " + message + "\n");

    // Scroll to the bottom of the text area
    logArea.scroll(1);
  } else {
    println("Error: Log area not found.");
  }
}


void controlEvent(ControlEvent theEvent) {
  if (theEvent.isController()) {
    String name = theEvent.getController().getName();

    if ((fastForward) && !name.equals("Reset")) {
      fastForwardActivated = true;
      simulateFastForward();
      fastForwardActivated=false;
    }
  }
}
