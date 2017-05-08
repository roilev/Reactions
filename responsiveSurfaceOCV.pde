
import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;
import codeanticode.syphon.*;
import processing.sound.*;

//general
boolean isShow;
boolean isCallib;

int cycleDur = 10;
int delayTimer;

//video
Capture video;
OpenCV opencv;
PImage src;
ArrayList<Contour> contours;

// <1> Set the range of Hue values for our filter
//ArrayList<Integer> colors;
int maxColors = 4;
int[] hues;
int[] colors;
int rangeWidth = 10;

PImage[] outputs;

int colorToChange = 1;

//grid
int cols, rows;
int scl = 20;
int w = 2000;
int h = 1600;
float flying = 0;

//arrays
float[][] terrain;
float[][] depth;
ArrayList ripples = new ArrayList();

//sound
TriOsc triOsc;
Env env;
float mouseLocSound;
float attackTime = 2;
float sustainTime = 0.4;
float sustainLevel = 0.5;
float releaseTime = 0.9;

//syphon
SyphonServer server;

void settings() {
  size(1280, 720, P3D);
  PJOGL.profile=1;
}

void setup() {

  //syphon
  server = new SyphonServer(this, "Processing to Syphon");

  String[] cameras = Capture.list();
  //printArray(cameras);
  video = new Capture(this, width, height, cameras[0]);

  //video = new Capture(this, width, height);
  opencv = new OpenCV(this, video.width, video.height);
  contours = new ArrayList<Contour>();

  // Array for detection colors
  colors = new int[maxColors];
  hues = new int[maxColors];
  outputs = new PImage[maxColors];

  //sound
  triOsc = new TriOsc(this);
  env  = new Env(this);

  //grid
  cols = w / scl;
  rows = h/ scl;
  terrain = new float[cols][rows];
  depth = new float[cols][rows];

  //general
  isCallib = true;
  isShow = false;

  video.start();
}

void draw() {
  background(0);

  delayTimer++;

  if (video.available()) {
    video.read();
  }

  // <2> Load the new frame of our movie in to OpenCV
  opencv.loadImage(video);

  // Tell OpenCV to use color information
  opencv.useColor();
  src = opencv.getSnapshot();

  // <3> Tell OpenCV to work in HSV color space.
  opencv.useColor(HSB);

  detectColors();
  reaction();

  if (isCallib) {
    // Show images
    image(src, 0, 0);
  } else if (isShow) {

    //grid
    flying -= 0.001;
    float yoff = flying;
    for (int y = 0; y < rows; y++) {
      float xoff = 0;
      for (int x = 0; x < cols; x++) {
        terrain[x][y] = map(noise(xoff, yoff), 0, 1, -10, 10);
        xoff += 0.2;
      }
      yoff += 0.2;
    }

    //ripple
    for (int i=0; i<ripples.size(); i++) {
      Ripple ripple = (Ripple) ripples.get(i);
      ripple.update();
      ripple.display();
    }

    //show
    background(0);
    stroke(255);
    fill(0);

    translate(width/2, height/2+50);
    rotateX(PI/8); //3D look (PI/3)
    translate(-w/2, -h/2);

    for (int y = 0; y < rows-1; y++) {
      beginShape(TRIANGLE_STRIP);
      for (int x = 0; x < cols; x++) {
        vertex(x*scl, y*scl, terrain[x][y]+depth[x][y]);
        vertex(x*scl, (y+1)*scl, terrain[x][y+1]+depth[x][y+1]);
      }
      endShape();
    }
  }
  server.sendScreen();
  //println(mouseX + " , " + mouseY);
}

//////////////////////
// Detect Functions
//////////////////////

void detectColors() {
  for (int i=0; i<hues.length; i++) {
    if (hues[i] <= 0) continue;
    opencv.loadImage(src);
    opencv.useColor(HSB);
    opencv.setGray(opencv.getH().clone());
    int hueToDetect = hues[i];
    //println("index " + i + " - hue to detect: " + hueToDetect);

    // <5> Filter the image based on the range of 
    //     hue values that match the object we want to track.
    opencv.inRange(hueToDetect-rangeWidth/2, hueToDetect+rangeWidth/2);

    //opencv.dilate();
    opencv.erode();
    outputs[i] = opencv.getSnapshot();
  }

  if (outputs[0] != null) {
    opencv.loadImage(outputs[0]);
    contours = opencv.findContours(true, true);
  }
}

void reaction() {

  for (int i=0; i<contours.size(); i++) {
    Contour contour = contours.get(i);
    Rectangle r = contour.getBoundingBox();
    //////////////////////////////////////////////////////////////////////////
    if (r.width < 25 || r.height < 25) //change on location size of object
      /////////////////////////////////////////////////////////////////////////
      continue;
      //////////////////////////////////////////////////////////////////////////
    if (r.x < 870 && r.x > 300 && r.y > 300 && r.y < 660) {//change on location location of screen
      /////////////////////////////////////////////////////////////////////////
      stroke(255, 0, 0);
      fill(255, 0, 0, 150);
      strokeWeight(2);
      rect(r.x, r.y, r.width, r.height);

      if (delayTimer % cycleDur == 0) {
        delayTimer = 0;

        ripples.add(new Ripple(r.x, r.y));

        //sound
        mouseLocSound = map(r.y, height, 0, 150, 250);
        triOsc.freq(mouseLocSound);
        triOsc.play();
        env.play(triOsc, attackTime, sustainTime, sustainLevel, releaseTime);
      }
    }
  }
}

void mousePressed() {

  color c = get(mouseX, mouseY);
  println("r: " + red(c) + " g: " + green(c) + " b: " + blue(c));
  int hue = int(map(hue(c), 0, 255, 0, 180));
  colors[colorToChange-1] = c;
  hues[colorToChange-1] = hue;
  println("color index " + (colorToChange-1) + ", value: " + hue);
}

void keyPressed() {
  if (key == ' ') { 
    ripples.clear();
  } else if (key == '`') {
    if (isCallib) {
      isCallib = false;
      isShow = true;
    } else {
      isCallib = true;
      isShow = false;
    }
  }
}