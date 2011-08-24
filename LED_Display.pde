import processing.serial.*;
int message_no = 0;
String message;
int state = 0;
boolean ready = true;
Serial display;
Twitter twitter;
int num_messages;

void setup() {
  display = new Serial(this, Serial.list()[0]);
  twitter = new Twitter("username", "password");
}

void draw() {

  if (state == 0) {

    try {
      java.util.List statuses = twitter.getPublicTimeline(); 

      Status status = (Status)statuses.get(message_no);
      message = status.getText();

      num_messages = statuses.size();
    }

    catch (TwitterException e) { 
      println(e.getStatusCode());
    }

    if (message.length() > 239) {
      message_no++;
    }
  }

  updateDisplay();
}

String outputMessage() {
  String theseChars = "<BE>05<E><ID01><L1><PA><FE><MA><WC><FE>" + message + "<E><ID01><BF>06";
  char check = 0;
  for (int c = 0; c < theseChars.length(); c++) {
    check = char(check ^ theseChars.charAt(c));
  }
  return "<ID01><L1><PA><FE><MA><WC><FE>" + message + hex(check, 2) + "<E>";
}

void updateDisplay() {

  if (display.available() > 2) {  

    String serialData = display.readString();

    if (serialData.equals("ACK")) {
      state++;
      ready = true;
    } 
    else {
      state = 0;
      ready = true;
      println("  I broke a bit, hold on a second...");
      delay(1000);
    }

    println("    " + serialData);
  }

  if (ready) {
    if (state == 0) {
      display.write("<ID01><BE>05<E>");
      ready = false;
    } 
    else if (state == 1) {
      display.write(outputMessage());
      ready = false;
    } 
    else if (state == 2) {
      display.write("<ID01><BF>06<E>");
      ready = false;
    } 
    else if (state == 3) {
      println(message_no + ": " + message + " - display updated!");
      delay(1325 + (message.length() * 90));
      message_no++;
      state = 0;
      ready = true;
      if (message_no >= num_messages) {  
        try {
          java.util.List statuses = twitter.getPublicTimeline(); 
          message_no = 0;
          Status status = (Status)statuses.get(message_no);
          message = status.getText();
          num_messages = statuses.size();
        }

        catch (TwitterException e) { 
          println(e.getStatusCode());
        }
      }
    }
  }
}

