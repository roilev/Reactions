class Ripple {

  float smallestDistance = cols*rows;
  int smallestX = 0;
  int smallestY = 0;

  float mouseLocX;
  float mouseLocY;

  int count;
  float decay = 1;
  int x;
  int y;
  float z;

  Ripple(float posX, float posY) {
    ///////////////////////////////////////////////////////////
    //mouseLocX = map(posX, 0, width, width, 0); /////mapping
    //mouseLocY = map(posY, 0, height, height, 0);///to 3D terrain
    mouseLocX = map(posX, 300, 870, 0, w / scl);
    mouseLocY = map(posY, 300, 660, 0, h/ scl);
    ///////////////////////////////////////////////////////////
  }

  void update() {
    for (int i=0; i<0.1; i++) {
      z = sin( radians(count+dist(x, y, cols, rows)));
      depth[smallestX][smallestY] = depth[smallestX][smallestY] - z;
      count++;
      decay+=0.05;
    }
  }

  void display() {
    for (int x = 0; x < terrain.length; x++) {
      for (int y = 0; y < terrain[x].length; y++) {
        float currentDistance = (dist(x, y, mouseLocX, mouseLocY));
        depth[x][y]= (50*sin( 10*radians(count+currentDistance)))/decay;
      }
    }
  }
}