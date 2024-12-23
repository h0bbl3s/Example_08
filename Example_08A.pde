// Example 08A: wifi networked lamp
// parts of the code are inspired
// by a blog post by Tod E. Kurt (todbot.com)
//
// This code has been reworked by hobbles (h0bbl3s@yahoo.com)
// to work with more recent versions of Processing
// the feed had to be changed as well, feel free to change it
//
// Copy and paste this example into an empty Processing sketch

import processing.serial.*;
import java.net.*;
import java.io.InputStreamReader;
import java.util.*;

String feed = "https://hackaday.com/blog/feed/"; // this seemed an appropriate replacement for makezine, feel free to change

int interval = 10;  // retrieve feed every 60 seconds;
int lastTime;       // the last time we fetched the content

int power    = 0; // I tried to choose terms that would come up frequently but not too much
int exploit   = 0;
int wifi = 0;

int light = 0;  // light level measured by the lamp

Serial port;
color c;
String cs;

String buffer = ""; // Accumulates characters coming from wifi

PFont font;

void setup() {
  size(640,480);
  frameRate(10);    // we don't need fast updates

  font = loadFont("HelveticaNeue-Bold-28.vlw");  
  fill(255);  
  textFont(font, 28);
  // IMPORTANT NOTE:
  // The first serial port retrieved by Serial.list()
  // should be your wifi. If not, uncomment the next
  // line by deleting the // before it, and re-run the
  // sketch to see a list of serial ports. Then, change
  // the 0 in between [ and ] to the number of the port
  // that your wifi is connected to.
  //println(Serial.list());
  String wifiPort = Serial.list()[0];
  port = new Serial(this, wifiPort, 9600); // connect to wifi

  lastTime = 0;
  fetchData();
}

void draw() {
  background( c );
  int n = (interval - ((millis()-lastTime)/1000));

  // Build a colour based on the 3 values
  c = color(exploit, power, wifi);
  cs = "#" + hex(c,6); // Prepare a string to be sent to wifi

  text("wifi Networked Lamp", 10,40);
  text("Reading feed:", 10, 100);
  text(feed, 10, 140);

  text("Next update in "+ n + " seconds",10,450);
  text("exploit" ,10,200); 
  text(" " + exploit, 130, 200);
  rect(200,172, exploit, 28);

  text("power ",10,240);
  text(" " + power, 130, 240);
  rect(200,212, power, 28);

  text("wifi ",10,280);
  text(" " + wifi, 130, 280);
  rect(200,252, wifi, 28);

  // write the colour string to the screen
  text("sending", 10, 340);
  text(cs, 200,340);

  text("light level", 10, 380);
  rect(200, 352,light/10.23,28); // this turns 1023 into 100

  if (n <= 0) {
    fetchData();
    lastTime = millis();
  }

  port.write(cs); // send data to wifi

  if (port.available() > 0) { // check if there is data waiting
    int inByte = port.read(); // read one byte
    if (inByte != 10) { // if byte is not newline
      buffer = buffer + char(inByte); // just add it to the buffer
    }
    else {

      // newline reached, let's process the data
      if (buffer.length() > 1) { // make sure there is enough data

        // chop off the last character, it's a carriage return
        // (a carriage return is the character at the end of a
        // line of text)
        buffer = buffer.substring(0,buffer.length() -1);
 
        // turn the buffer from string into an integer number
        light = int(buffer);

        // clean the buffer for the next read cycle
        buffer = "";

        // We're likely falling behind in taking readings
        // from wifi. So let's clear the backlog of
        // incoming sensor readings so the next reading is
        // up-to-date.
        port.clear(); 
      }
    } 
  }

}

void fetchData() {
  // we use these strings to parse the feed
  String data; 
  String chunk;

  // zero the counters
  power    = 0;
  exploit   = 0;
  wifi = 0;
  try {
    URL url = new URL(feed);  // An object to represent the URL
    // prepare a connection   
    URLConnection conn = url.openConnection(); 
    conn.connect(); // now connect to the Website

    // this is a bit of virtual plumbing as we connect
    // the data coming from the connection to a buffered
    // reader that reads the data one line at a time.
    BufferedReader in = new
      BufferedReader(new InputStreamReader(conn.getInputStream()));

    // read each line from the feed
    while ((data = in.readLine()) != null) {

      StringTokenizer st =
        new StringTokenizer(data,"\"<>,.()[] ");// break it down
      while (st.hasMoreTokens()) {
        // each chunk of data is made lowercase
        chunk= st.nextToken().toLowerCase() ;

        if (chunk.indexOf("power") >= 0 ) // found "power"?
          power++;    // increment power by 1
        if (chunk.indexOf("exploit") >= 0)   // found "exploit"?
          exploit++;   // increment exploit by 1
        if (chunk.indexOf("wifi") >= 0) // found "wifi"?
          wifi++; // increment wifi by 1
      }
    }

    // Set 64 to be the maximum number of references we care about.
    if (exploit > 64)   exploit = 64;
    if (power > 64)    power = 64;
    if (wifi > 64) wifi = 64;

    exploit = exploit * 4;     // multiply by 4 so that the max is 255,
    power = power * 4;       // which comes in handy when building a
    wifi = wifi * 4; // colour that is made of 4 bytes (ARGB)
  } 
  catch (Exception ex) { // If there was an error, stop the sketch
    ex.printStackTrace();
    System.out.println("ERROR: "+ex.getMessage());
  }

}
