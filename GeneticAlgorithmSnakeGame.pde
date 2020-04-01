import g4p_controls.*;

/*
 * CONFIGURABLE PROPERTIES
 */
int N = 2000; //population size
int topPercent = 10; //what percentage get to reproduce. Also 50% of the percentage that gets lost each generation.
float mutationChance = 0.1;
//Snakes get points for lasting longer and getting fruit, more heavily weighted towards getting fruit.
float pointsPerTimeStep = 0.1;
float pointsForFinishing = 150;
float pointsForFruit = 150;
//The NN library writes files to a weird place so I don't want this to automatically save.
boolean writeToFileAutomatically = false;

/*
 * NON-CONFIGURABLE PROPERTIES
 */
int timeDelay = 0; // This one is technically configurable but via a user pressing a button on the screen
int DIRECTION_UP = 0;
int DIRECTION_RIGHT = 1; 
int DIRECTION_DOWN = 2; 
int DIRECTION_LEFT = 3; 
int NAlive = N;
int bestGeneration = 0;
double bestGenerationScore = 0;
double currentGenerationScore;
ArrayList<Snake> Snakes = new ArrayList<Snake>();
ArrayList<Snake> prevGeneration = new ArrayList<Snake>();
int currentGeneration = 0;
boolean gameOver = false;
boolean keyHasBeenPressedThisFrame;
ArrayList<int[]> fruitPositions = new ArrayList<int[]>();
int time = 0;
int maxTime = 400;
int piecesOfFruitEaten = 0;

//Drawing helper variables
int margin = 50;
int cellsInWidth = 20;
int cellsInHeight = 20;
int cellWidth = (700 - 2*margin)/cellsInWidth;
int cellHeight = (700 - 2*margin)/cellsInHeight;

GWindow statsWindow;

void setup() {
  statsWindow = GWindow.getWindow(this, "Stats Window", 100, 50, 700, 400, JAVA2D);
  statsWindow.addDrawHandler(this, "windowDraw");
  statsWindow.addData(new StatsWindowData());
  
  ellipseMode(CENTER);
  size(700, 700);
  createInitialSnakes();
}

void draw() {
  time++;
  if (allSnakesAreDead() || time > maxTime) {
    scoreGenerationAndRestartGame();
  }

  //Make the snakes think and decide where to go
  for (int i=0; i<N; i++) {
    Snake snake = Snakes.get(i);
    if (!snake.isDead) {
      snake.think();
      //snake has chosen to go left/right/straight on.
      boolean collisionDetected = snake.willCollideWithSomething();
      if (collisionDetected) {
        snake.isDead = true;
        NAlive--;
      } else {
        //Update the snake's position and give it some points for surviving another time step.
        snake.updatePositions();
        snake.points = snake.points + pointsPerTimeStep;
      }
    }
  }

  //User can configure this time delay with buttons on the screen
  if (timeDelay > 0) {
    delay(timeDelay);
  }

  background(20, 20, 200); //draw everything on top of the background
  drawGameBorder();
  drawSomeOfTheSnakes();
  drawGenerationText();
  drawBestGenerationText();
  drawFruitEatenText();
  drawSnakesAliveText();
  drawSpeedButtons();
}

/**
 * At the end of a generation's playthrough, we score them and restart the game
 */
void scoreGenerationAndRestartGame() {
  if (time > maxTime)
  {
    increaseAllAliveSnakesScores();
  }
  //work out what the generation scored.
  calculateGenerationScore();
  StatsWindowData d = (StatsWindowData)statsWindow.data;
  d.addScore(currentGenerationScore, NAlive, piecesOfFruitEaten);
  //create new snakes implementing all the genetics etc.
  createNewSnakes();
  //reset some game state variables.
  resetStartOfGameState();
}

/**
 * Just reset some variables.
 */
void resetStartOfGameState() {
  N = Snakes.size();
  piecesOfFruitEaten = 0;
  NAlive = N;
  time = 0;
  
  //Let the maximum time the snakes can run for increase over time.
  //Hopefully they'll first learn to grab the fruit, then eventually
  //start surviving slightly better.
  if (currentGeneration > 2000) {
    maxTime = 800; }
  /*} else if (currentGeneration > 1000) {
    maxTime = 500;
  } else if (currentGeneration > 500) {
    maxTime = 400;
  } else if (currentGeneration > 200) {
    maxTime = 300;
  } else if (currentGeneration > 50) {
    maxTime = 200;
  }*/
}


void createInitialSnakes() {
  for (int i=0; i<N; i++) {
    //start all the snakes from the same position
    ArrayList<int[]> positions = createInitialPositionsArray();
    Snakes.add(new Snake(positions));
  }
}

boolean allSnakesAreDead() {
  for (int i=0; i<N; i++)
  {
    Snake s = Snakes.get(i);
    if (!s.isDead)
    {
      return false;
    }
  }
  return true;
}

/*
 * Create a new generation of snakes.
 * A - Find the best scoring X% of snakes.
 * B - Remove the worst 2X% of snakes.
 * C - Allow the best scoring snakes to have 2 offspring, breeding with another of the top snakes.
 * D - Give the new snakes a chance to mutate.
 * E - Add the best scoring X% and their offspring to the new generation.
 * F - Add all the snakes that did ok (not in the top X% or the bottom 2X%) to the new generation.
 */
void createNewSnakes() {
  //copy the snakes into prevGeneration
  prevGeneration = null;
  prevGeneration = new ArrayList<Snake>();
  for (int i=0; i<N; i++) {
    prevGeneration.add(Snakes.get(i).copySnake());
  }

  //A - Find the best scoring X% of snakes.
  //B - Remove the worst 2X% of snakes.
  ArrayList<Snake> newGeneration = new ArrayList<Snake>();
  int NBest = topPercent*N/100;
  ArrayList<Snake> bestSnakes = findBestXAndRemoveWorst2XOfSnakes(NBest);

  //C - Allow the best scoring snakes to have 2 offspring, breeding with another of the top snakes.
  for (int i=0; i<NBest; i++) {
    Snake snake = bestSnakes.get(i).copySnake();
    Snake otherSnake = bestSnakes.get(floor(random(1, NBest))).copySnake();
    NeuralNetwork childBrain1 = snake.brain.merge(otherSnake.brain);
    NeuralNetwork childBrain2 = snake.brain.merge(otherSnake.brain);
    //D - Give the new snakes a chance to mutate.
    Snake childSnake1 = createNewGenSnake(childBrain1);
    Snake childSnake2 = createNewGenSnake(childBrain2);
    Snake snakeCopy = snake.copySnake();
    snakeCopy.positions = createInitialPositionsArray();
    //E - Add the best scoring X% and their offspring to the new generation.
    newGeneration.add(snakeCopy);
    newGeneration.add(childSnake1);
    newGeneration.add(childSnake2);
  }
  //F - Add all the snakes that did ok (not in the top X% or the bottom 2X%) to the new generation.
  for (int i=0; i<Snakes.size(); i++) {
    Snake s = Snakes.get(i);
    Snake sCopy = s.copySnake();
    sCopy.positions = createInitialPositionsArray();
    newGeneration.add(sCopy);
  }
  Snakes = newGeneration;
  currentGeneration++;

  if (currentGeneration % 5 == 0) {
    System.gc();
  }
  
  bestSnakes = null;
  newGeneration = null;
}

ArrayList<Snake> findBestXAndRemoveWorst2XOfSnakes(int NBest) {
  ArrayList<Snake> bestSnakes = new ArrayList<Snake>();
  int NWorst = 2*NBest;
  for (int i=0; i<NBest; i++) { //get twice the amount of worst snakes as best snakes. Remove the worst snakes
    float highestScore = 0;
    Snake bestSnake = new Snake(createInitialPositionsArray());
    for (int j=0; j<Snakes.size(); j++)
    {
      Snake s = Snakes.get(j);
      float score = s.points;
      if (i < NBest && score > highestScore)
      {
        //we've found the best snake so far
        highestScore = s.points;
        bestSnake = s;
      }
    }
    Snakes.remove(bestSnake);
    bestSnakes.add(bestSnake);
  }

  for (int i=0; i<NWorst; i++) {
    float lowestScore = 99999999;
    Snake worstSnake = new Snake(createInitialPositionsArray());
    for (int j=0; j<Snakes.size(); j++)
    {
      Snake s = Snakes.get(j);
      float score = s.points;
    
      if (score < lowestScore) {
        //we've found the worst snake so far
        lowestScore = s.points;
        worstSnake = s;
      }
    }
    Snakes.remove(worstSnake);
  }
  return bestSnakes;
}

Snake createNewGenSnake(NeuralNetwork brain) {
  ArrayList<int[]> positions = createInitialPositionsArray();
  return new Snake(positions, brain);
}

ArrayList<int[]> createInitialPositionsArray() {
  ArrayList<int[]> positions = new ArrayList<int[]> (); // [ [Head], [Tail1], [Tail2], .. , [TailEnd] ]

  positions.add(new int[] {floor(cellsInWidth/2), floor(cellsInHeight/2)});
  positions.add(new int[] {floor(cellsInWidth/2)-1, floor(cellsInHeight/2)});
  positions.add(new int[] {floor(cellsInWidth/2)-2, floor(cellsInHeight/2)});
  positions.add(new int[] {floor(cellsInWidth/2)-3, floor(cellsInHeight/2)});
  positions.add(new int[] {floor(cellsInWidth/2)-4, floor(cellsInHeight/2)});

  return positions;
}

void mousePressed() {
  //Work out if one of the buttons was pressed.
  if (mouseX > 0 && mouseX < margin) {
    if (mouseY > margin && mouseY < 2*margin) {
      timeDelay = 100;
    } else if (mouseY > 2*margin && mouseY < 3*margin) {
      timeDelay = 20;
    } else if (mouseY > 3*margin && mouseY < 4*margin) {
      timeDelay = 0;
    } else if (mouseY > 4*margin && mouseY < 6*margin) {
      //find the best performing snake, write it to file.
      findBestSnakeAndWriteToFile(false);
    }
  }
}

/**
 * Get the best scoring snake for either this or the last generation. Write this to file.
 */
void findBestSnakeAndWriteToFile(boolean currentGeneration) {
  float bestScore = 0;
  Snake bestSnake = new Snake(createInitialPositionsArray());
  Snake s;
  for (int i=0; i<N; i++) {
    if (currentGeneration) {
      s = Snakes.get(i);
    } else {
      s = prevGeneration.get(i);
    }
    float score = s.points;
    if (score > bestScore) {
      bestScore = score;
      bestSnake = s;
    }
  }
  println("Writing to file...");
  bestSnake.brain.writeToFile();
}

/**
 * Sum the scores of all the snakes.
 */
void calculateGenerationScore() {
  currentGenerationScore = 0;
  for (int i=0; i<N; i++) {
    currentGenerationScore += Snakes.get(i).points;
  }
  if (currentGenerationScore > bestGenerationScore) {
    bestGeneration = currentGeneration;
    bestGenerationScore = currentGenerationScore;
    if (writeToFileAutomatically) {
      findBestSnakeAndWriteToFile(true);
    }
    println("New best generation! Gen: " + currentGeneration +
    ". " + NAlive +" survived. " + piecesOfFruitEaten +
    " pieces of fruit were eaten. Total Score: " + currentGenerationScore);
  }
}

/**
 * Snakes get points if they are alive at the end of the game.
 */
void increaseAllAliveSnakesScores() {
  for (int i=0; i<Snakes.size(); i++)
  {
    Snake s = Snakes.get(i);
    if (!s.isDead) {
      s.points += pointsForFinishing;
    }
  }
}

/**********************************************************************
************************DRAWING METHODS********************************
**********************************************************************/

void drawSpeedButtons() {
  rectMode(CORNER);
  fill(255, 0, 0);
  rect(0, margin, margin, margin);
  fill(0, 0, 0);
  textSize(15);
  text("SLOW", 5, margin+30);

  fill(125, 125, 0);
  rect(0, 2*margin, margin, margin);
  fill(0, 0, 0);
  textSize(15);
  text("MED", 5, 2*margin+30);

  fill(0, 255, 0);
  rect(0, 3*margin, margin, margin);
  fill(0, 0, 0);
  textSize(15);
  text("FAST", 5, 3*margin+30);

  fill(0);
  rect(0, 4*margin, margin, 2*margin);
  fill(255);
  textSize(12);
  text("SAVE", 10, 5*margin);
}

/**
 * Draw at most 50 snakes. You can get a good idea of what the population
 * as a whole is doing, and it runs about as fast as not drawing any.
 */
void drawSomeOfTheSnakes() {
  //if less that 50 are alive, just draw all the alive ones.
  if (NAlive < 50) { 
    for (int i=0; i<N; i++) {
      Snake snake = Snakes.get(i);
      if (!snake.isDead)
      {
        snake.drawSnake();
        snake.drawFruit();
      }
    }
  } else {
    //draw only 50 snakes
    int drawn = 0;
    int i = 0;
    while (drawn < 50) {
      Snake snake = Snakes.get((i));
      if (!snake.isDead)
      {
        snake.drawSnake();
        snake.drawFruit();
        drawn++;
      }
      i++;
    }
  }
}

void drawGenerationText() {
  fill(0, 250, 0);
  textSize(32);
  text("Generation: " + currentGeneration, 10, 30);
}

void drawBestGenerationText() {
  textSize(32);
  text("Best Generation: " + bestGeneration, width/2, margin-20);
}

void drawFruitEatenText() {
  textSize(22);
  text("Fruit Eaten: " + piecesOfFruitEaten, 10, height-margin/2);
}

void drawSnakesAliveText() {
  textSize(22);
  text("Snakes Alive: " + NAlive, width/2, height-margin/2);
}

void drawGameBorder() {
  fill(50, 204, 255);
  strokeWeight(2);
  stroke(0);
  rect(margin, margin, width-2*margin, height - 2*margin);
}
