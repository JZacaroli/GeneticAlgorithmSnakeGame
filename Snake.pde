int DIRECTION_UP = 0;
int DIRECTION_RIGHT = 1; 
int DIRECTION_DOWN = 2; 
int DIRECTION_LEFT = 3;
float pointsPerTimeStep = 0.01;
float pointsForFruit = 25;

class Snake {
  ArrayList<int[]> positions = new ArrayList<int[]>();
  int direction = floor(random(3)); //start snakes going right/up/down randomly.
  float points = 0;
  NeuralNetwork brain;
  boolean isDead = false;
  int[] fruitPosition = new int[] {};

  //This constructor is used when initialising the first generation of snakes
  Snake(ArrayList<int[]> _positions) {
    positions = _positions;
    brain = new NeuralNetwork(9, 6, 3); //brain = new NeuralNetwork(400, 20, 3);
    brain.setActivationFunction(ActivationFunction.TANH);
    createFruit();
  }
  //This constructor is used when creating a new generation of snakes.
  Snake(ArrayList<int[]> _positions, NeuralNetwork _brain, float _mutationChance) {
    positions = _positions;
    brain = _brain;
    brain.setActivationFunction(ActivationFunction.TANH);
    brain.mutate(_mutationChance);
    createFruit();
  }
  //returns a copy of this snake with the same brain and points!!
  Snake copySnake() {
    return createNewGenSnake(brain.copy());
  }

  void createFruit() {
    int[] randomPos = findWhereToPlaceFruit();
    int randomX = randomPos[0];
    int randomY = randomPos[1];
    fruitPosition = append(fruitPosition, randomX);
    fruitPosition = append(fruitPosition, randomY);
  }
  int[] findWhereToPlaceFruit() {
    int[][] possiblePositionsForFruit = new int[cellsInWidth*cellsInHeight][2];
    int numberAdded = 0;
    for (int row=1; row<=cellsInHeight; row++) {
      for (int col=1; col<=cellsInWidth; col++) {
        //if this column and row is in the snake's positions vector, then don't add
        boolean shouldAdd = true;
        for (int i=0; i<positions.size(); i++) {
          int[] pos = positions.get(i);
          int x = pos[0]; 
          int y = pos[1];
          if (x == col && y == row) {
            shouldAdd = false;
          }
        }
        if (shouldAdd) {
          int[] pos = new int[] {col, row};
          possiblePositionsForFruit[numberAdded] = pos;
          numberAdded++;
        }
      }
    }
    int randomIndex = floor(random(0, numberAdded));
    return possiblePositionsForFruit[randomIndex];
  }

  /*
   * 'Thinking' requires
   * A - computing the inputs of the neural network
   * B - Computing the output of the neural network given the inputs.
   * C - Deciding what the output means. (i.e. turn left, straight on, turn right)
   */
  void think() {
    //A - computing the inputs of the neural network
    double distanceToLeftWall = positions.get(0)[0]/cellsInWidth; //distance to right wall is just 1-this.
    double distanceToCeiling = positions.get(0)[1]/cellsInHeight; //distance to floor is just 1-this.
    double xDistanceToFruit = fruitPosition[0] - positions.get(0)[0];
    double yDistanceToFruit = fruitPosition[1] - positions.get(0)[1];
    //TODO: Distance to self!
    double xDir = 0;
    double yDir = 0;
    double snakeLength = positions.size()/(cellsInWidth + cellsInHeight);
    if (direction == DIRECTION_RIGHT)
    {
      xDir = 1;
    } else if (direction == DIRECTION_LEFT)
    {
      xDir = -1;
    } else if (direction == DIRECTION_UP)
    {
      yDir = 1;
    } else if (direction == DIRECTION_DOWN)
    {
      yDir = -1;
    }
    double[] inputs = new double[] {distanceToLeftWall, 1-distanceToLeftWall, distanceToCeiling, 1-distanceToCeiling, xDistanceToFruit/cellsInWidth, yDistanceToFruit/cellsInHeight, xDir, yDir, snakeLength};
    //B - Computing the output of the neural network given the inputs.
    double[] output = brain.guess(inputs);

    //C - Deciding what the output means. (i.e. turn left, straight on, turn right)
    //work out which output is highest.
    double highestOutput = 0;
    int highestI = 0;
    for (int i=0; i<3; i++) {
      double nextOutput = output[i];
      if (nextOutput > highestOutput)
      {
        highestI = i;
        highestOutput = nextOutput;
      }
    }
    //Which output is highest tells us which direction we should try to go in!
    if (highestI == 0) { //turn left
      direction = (direction + 3) % 4;
    } else if (highestI == 2) { //turn right
      direction = (direction + 1) % 4;
    }
    //else highestI = 1, which means go straight on! (don't change direction)
  }

  /*
   * Is this snake about to collide with something.
   */
  boolean willCollideWithSomething() {
    int nextPos[] = workOutNextPos();
    //if the next position is outside the allowable limit, collision with the wall has occurred.
    int nextX = nextPos[0]; 
    int nextY = nextPos[1];
    if (nextX < 1 || nextX > cellsInWidth || nextY < 1 || nextY > cellsInHeight)
    {
      return true;
    }
    //if the next position is already in the positions array, then collision with itself has occurred.
    for (int i=0; i<positions.size()-1; i++) {
      int snakeX = positions.get(i)[0];
      if (snakeX == nextX) {
        int snakeY = positions.get(i)[1];
        if (snakeY == nextY) {
          return true;
        }
      }
    }

    return false;
  }

  /*
   * Work out the next position that the snake's head is going to be in.
   */
  int[] workOutNextPos() {
    int retval[] = new int[2];
    int newHeadXPos = -1;
    int newHeadYPos = -1;
    if (direction == DIRECTION_RIGHT || direction == DIRECTION_LEFT) {
      newHeadYPos = positions.get(0)[1];
      if (direction == DIRECTION_RIGHT) {
        newHeadXPos = positions.get(0)[0] + 1;
      } else {
        newHeadXPos = positions.get(0)[0] - 1;
      }
    } else if (direction == DIRECTION_UP || direction == DIRECTION_DOWN) {
      newHeadXPos = positions.get(0)[0];
      if (direction == DIRECTION_UP) {
        newHeadYPos = positions.get(0)[1] - 1;
      } else {
        newHeadYPos = positions.get(0)[1] + 1;
      }
    }
    retval[0] = newHeadXPos;
    retval[1] = newHeadYPos;
    return retval;
  }

  /*
   * Move this snake.
   */
  void updatePositions() {
    int newPos[] = workOutNextPos();
    int newHeadXPos = newPos[0];
    int newHeadYPos = newPos[1];
    ArrayList<int[]> newPositions = new ArrayList<int[]>();

    //first add the new head position
    newPositions.add(new int[] {newHeadXPos, newHeadYPos});

    /* The number of positions to copy to the new set is dependant on whether a piece of fruit has been eaten.
     If a piece of fruit has been eaten, copy all of them, otherwise copy (all of them-1)
     Checking the fruit position length here is just a sanity check.*/
    int numberOfPositionsToCopy = -1;
    if (fruitPosition.length > 0 && fruitPosition[0] == newHeadXPos && fruitPosition[1] == newHeadYPos)
    {
      //player has eaten fruit!! Copy the old array including the very last point.
      numberOfPositionsToCopy = positions.size();

      //remove the fruit's position and give the snake some points
      fruitPosition = new int[] {};
      points += pointsForFruit;
      createFruit();
      piecesOfFruitEaten++;
    } else {
      //not eaten fruit. Copy the old array minus the very last point. We already have the head.
      numberOfPositionsToCopy = positions.size() - 1;
    }

    //go and add the old positions to the new array
    for (int i=0; i<numberOfPositionsToCopy; i++) {
      newPositions.add(positions.get(i));
    }
    positions = newPositions;
    
    points += pointsPerTimeStep;
  }

  /*
   * Draw this snake.
   */
  void drawSnake() {
    //draw the tail first, in reverse, so that the body parts are placed on top further forward. Looks better when they slightly overlap.
    fill(40, 60, 200, 50); //include alpha to display a bunch of them on screen at the same time.
    stroke(1);
    if (gameOver) {
      fill(175, 0, 0);
    }
    for (int i=positions.size()-1; i>0; i--) {
      int xPos = positions.get(i)[0];
      int yPos = positions.get(i)[1];
      ellipse(margin+((xPos-0.5)*cellWidth), margin+((yPos-0.5)*cellHeight), cellWidth*90/(100+i), cellHeight*90/(100+i));
    }

    //draw the head in a different colour
    fill(20, 20, 20, 50);
    if (gameOver) {
      fill(140, 0, 0);
    }
    int headXPos = positions.get(0)[0];
    int headYPos = positions.get(0)[1];
    ellipse(margin+((headXPos-0.5)*cellWidth), margin+((headYPos-0.5)*cellHeight), cellWidth/0.8, cellHeight/0.8);
  }
  /*
   * Draw the fruit associated with this snake
   */
  void drawFruit() {
    fill(200, 25, 25);
    ellipse(margin+((fruitPosition[0]-0.5)*cellWidth), margin+((fruitPosition[1]-0.5)*cellHeight), cellWidth/2, cellHeight/2);
  }
}
