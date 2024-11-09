PFont font;
int ySpacing = 55;
int xSpacing = 15;
int controlSpacing = 65; 


void setupUI() {
  font = createFont("Arial", 14, true);  // Use "Arial", size 16
  cp5.setFont(font);

  int yPosition = 40;

  cp5.addSlider("speed1")
    .setPosition(20, yPosition)
    .setSize(300, 40).setRange(0, maxSpeed)
    .setValue(speed1)
    .setDecimalPrecision(3)
    .setScrollSensitivity(0.01)
    .setLabel("Disc 1 Speed (RPS)")
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE)
    .setFont(font);

  cp5.addTextfield("speed1Input")
    .setPosition(300+2*xSpacing, yPosition)
    .setSize(70, 40)
    .setFont(font)
    .setAutoClear(false)
    .setValue(nf(speed1, 1, 3))
    .getCaptionLabel().setVisible(false);

  cp5.addSlider("acc1")
    .setPosition(370+3*xSpacing, yPosition)
    .setSize(130, 40)
    .setRange(0, 0.1)
    .setDecimalPrecision(3)
    .setFont(font)
    .setLabel("Acceleratrion 1")
    .setValue(acc1)
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE);

  cp5.addToggle("direction1")
    .setPosition(500+4*xSpacing, yPosition)
    .setSize(100, 40)
    .setLabel("CW/CCW")
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    .setFont(font);

  yPosition += controlSpacing;

  cp5.addSlider("speed2")
    .setPosition(20, yPosition)
    .setSize(300, 40).setRange(0, maxSpeed)
    .setValue(speed2)
    .setDecimalPrecision(3)
    .setScrollSensitivity(0.01)
    .setLabel("Disc 2 Speed (RPS)")
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE)
    .setFont(font);

  cp5.addTextfield("speed2Input")
    .setPosition(300+2*xSpacing, yPosition)
    .setSize(70, 40)
    .setFont(font)
    .setAutoClear(false)
    .setValue(nf(speed2, 1, 3))
    .getCaptionLabel().setVisible(false);

  cp5.addSlider("acc2")
    .setPosition(370+3*xSpacing, yPosition)
    .setSize(130, 40)
    .setRange(0, 0.1)
    .setValue(acc2)
    .setDecimalPrecision(3)
    .setFont(font)
    .setLabel("Acceleratrion 2")
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE);

  cp5.addToggle("direction2")
    .setPosition(500+4*xSpacing, yPosition)
    .setSize(100, 40)
    .setLabel("CW/CCW")
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    .setFont(font);

  yPosition += controlSpacing;

  cp5.addSlider("canvasSpeed")
    .setPosition(20, yPosition)
    .setSize(300, 40)
    .setRange(0, maxSpeed)
    .setValue(canvasSpeed)
    .setDecimalPrecision(3)
    .setScrollSensitivity(0.01)
    .setLabel("Canvas Speed (RPS)")
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE)
    .setFont(font);

  cp5.addTextfield("canvasSpeedInput")
    .setPosition(300+2*xSpacing, yPosition)
    .setSize(215, 40)
    .setFont(font)
    .setAutoClear(false)
    .setValue(nf(canvasSpeed, 1, 3));
    
  cp5.addToggle("canvasDirection")
    .setPosition(500+4*xSpacing, yPosition)
    .setSize(100, 40)
    .setLabel("CW/CCW")
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    .setFont(font);

  yPosition += controlSpacing + 20;  // Extra spacing for fast forward controls

  // Fast Forward control
  cp5.addToggle("fastForward")
    .setPosition(20, yPosition)
    .setSize(300, 40)
    .setLabel("Fast Forward")
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    .setFont(font);

  cp5.addSlider("fastForwardTimeout")
    .setPosition(330, yPosition)
    .setSize(330, 40)
    .setRange(0, 500)
    .setValue(fastForwardTimeout)
    .setLabel("Timeout (s)")
    .getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE)
    .setFont(font);

  yPosition += controlSpacing + 20;

  // Buttons to start, stop, and reset the simulation with labels
  cp5.addButton("Start")
    .setPosition(20, yPosition)
    .setSize(145, 40)
    .setLabel("Start")
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    .setFont(font);

  cp5.addButton("Stop")
    .setPosition(175, yPosition)
    .setSize(145, 40)
    .setLabel("Stop")
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    .setFont(font);

  cp5.addButton("Reset")
    .setPosition(330, yPosition)
    .setSize(160, 40)
    .setLabel("Reset")
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    .setFont(font);

  cp5.addButton("ExportPNG")
    .setPosition(500, yPosition)
    .setSize(160, 40)
    .setLabel("Export PNG")
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    .setFont(font);

  yPosition+=ySpacing;

  cp5.addButton("PrintPattern")
    .setPosition(20, yPosition)
    .setSize(300, 40)
    .setLabel("Print Pattern");

  // Add a progress bar for the print pattern
  cp5.addSlider("Progress")
    .setPosition(330, yPosition)
    .setSize(330, 40)
    .setRange(0, 100)
    .setValue(0)
    .setLabelVisible(false)
    .setCaptionLabel(" ")
    .lock()
    .setColorForeground(color(0, 150, 0))
    .setColorBackground(color(250));

  yPosition += 60;
  
  cp5.addButton("EmergencyStop")
    .setPosition(20, yPosition)
    .setSize(640, 40)
    .setLabel("Emergency Stop")
    .setColorBackground(color(200, 0, 0));

//////////////////////////////////////////////////////  ADVANCED CONTROLS //////////////////////////////////////////////////////

  cp5.addTab("Advanced Controls")
    .setPosition(20, 20)
    .setColorBackground(color(150))
    .setColorLabel(color(255))
    .activateEvent(true)
    .setLabel("Advanced Controls");

  yPosition = 250;

  // Create a panel for motor controls and communication
  cp5.addTextfield("COM Port")
    .setPosition(20, yPosition)
    .setSize(120, 40)
    .setFont(font)
    .setAutoClear(false)
    .setValue(comPort)
    .moveTo("Advanced Controls")
    .getCaptionLabel().setVisible(false);

  cp5.addButton("Connect")
    .setPosition(160, yPosition)
    .setSize(120, 40)
    .setLabel("Connect")
    .moveTo("Advanced Controls");

  cp5.addButton("Disconnect")
    .setPosition(300, yPosition)
    .setSize(120, 40)
    .setLabel("Disconnect")
    .moveTo("Advanced Controls");
    
  yPosition = 300;

  cp5.addTextarea("Log")
    .setPosition(20, yPosition)
    .setSize(500, 150)
    .setFont(createFont("arial", 10))
    .setLineHeight(14)
    .setColor(color(128))
    .setColorBackground(color(255, 100))
    .setColorForeground(color(255, 100))
    .setColor(color(255))
    .moveTo("Advanced Controls");

  yPosition = 50;
  int xPosition = 400;

  cp5.addButton("StartMotor0").setPosition(xPosition+20, yPosition).setSize(120, 40).setLabel("Start Motor 0").moveTo("Advanced Controls");
  cp5.addButton("StopMotor0").setPosition(xPosition+160, yPosition).setSize(120, 40).setLabel("Stop Motor 0").moveTo("Advanced Controls");
  yPosition += ySpacing;

  cp5.addButton("StartMotor1").setPosition(xPosition+20, yPosition).setSize(120, 40).setLabel("Start Motor 1").moveTo("Advanced Controls");
  cp5.addButton("StopMotor1").setPosition(xPosition+160, yPosition).setSize(120, 40).setLabel("Stop Motor 1").moveTo("Advanced Controls");
  yPosition +=ySpacing;

  cp5.addButton("StartMotor2").setPosition(xPosition+20, yPosition).setSize(120, 40).setLabel("Start Motor 2").moveTo("Advanced Controls");
  cp5.addButton("StopMotor2").setPosition(xPosition+160, yPosition).setSize(120, 40).setLabel("Stop Motor 2").moveTo("Advanced Controls");
  yPosition += ySpacing;

  int advancedY = 50;

  // Adding Rod Length Numeric Inputs to the Advanced Controls tab
  cp5.addTextfield("rodLength1")
    .setPosition(20, advancedY)
    .setSize(100, 30)
    .setFont(font)
    .setAutoClear(false)
    .setLabel("Rod 1 Length")
    .setValue(str(rodLength1))
    .moveTo("Advanced Controls");

  advancedY += ySpacing;
  cp5.addTextfield("rodLength2")
    .setPosition(20, advancedY)
    .setSize(100, 30)
    .setFont(font)
    .setAutoClear(false)
    .setLabel("Rod 2 Length")
    .setValue(str(rodLength2))
    .moveTo("Advanced Controls");

  advancedY += ySpacing;
  cp5.addTextfield("rodLength3")
    .setPosition(20, advancedY)
    .setSize(100, 30)
    .setFont(font)
    .setAutoClear(false)
    .setLabel("Rod 3 Length")
    .setValue(str(rodLength3))
    .moveTo("Advanced Controls");

  advancedY = 50;

  cp5.addTextfield("rodLength4")
    .setPosition(140, advancedY)
    .setSize(100, 30)
    .setFont(font)
    .setAutoClear(false)
    .setLabel("Rod 4 Length")
    .setValue(str(rodLength4))
    .moveTo("Advanced Controls");

  advancedY += ySpacing;

  cp5.addTextfield("rodLength5")
    .setPosition(140, advancedY)
    .setSize(100, 30)
    .setFont(font)
    .setAutoClear(false)
    .setLabel("Rod 5 Length")
    .setValue(str(rodLength5))
    .moveTo("Advanced Controls");

  advancedY += ySpacing;
  cp5.addTextfield("rodLength6")
    .setPosition(140, advancedY)
    .setSize(100, 30)
    .setFont(font)
    .setAutoClear(false)
    .setLabel("Rod 6 Length")
    .setValue(str(rodLength6))
    .moveTo("Advanced Controls");

  advancedY = 50;
  cp5.addTextfield("rodLength7")
    .setPosition(260, advancedY)
    .setSize(100, 30)
    .setFont(font)
    .setAutoClear(false)
    .setLabel("Rod 7 Length")
    .setValue(str(rodLength7))
    .moveTo("Advanced Controls");


  // Add listeners for textfields to update sliders
  cp5.get(Textfield.class, "speed1Input").addCallback(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      if (theEvent.getAction() == ControlP5.ACTION_BROADCAST) {
        float val = float(((Textfield)theEvent.getController()).getText());
        cp5.get(Slider.class, "speed1").setValue(val);
      }
      if (theEvent.getAction() == ControlP5.ACTION_CLICK) {
        ((Textfield)theEvent.getController()).setFocus(true).setValue("");
      }
    }
  }
  );


  cp5.get(Textfield.class, "canvasSpeedInput").addCallback(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      if (theEvent.getAction() == ControlP5.ACTION_BROADCAST) {
        float val = float(((Textfield)theEvent.getController()).getText());
        cp5.get(Slider.class, "canvasSpeed").setValue(val);
      }
      if (theEvent.getAction() == ControlP5.ACTION_CLICK) {
        ((Textfield)theEvent.getController()).setFocus(true).setValue("");
      }
    }
  }
  );

  cp5.get(Textfield.class, "speed2Input").addCallback(new CallbackListener() {
    public void controlEvent(CallbackEvent theEvent) {
      if (theEvent.getAction() == ControlP5.ACTION_BROADCAST) {
        float val = float(((Textfield)theEvent.getController()).getText());
        cp5.get(Slider.class, "speed2").setValue(val);
      }
      if (theEvent.getAction() == ControlP5.ACTION_CLICK) {
        ((Textfield)theEvent.getController()).setFocus(true).setValue("");
      }
    }
  }
  );
}
