import g4p_controls.*;

/*
 * CONFIGURABLE PROPERTIES
 */
int N = 10000; //population size
float mutationChance = 0.2;
float pointsForFinishing = 5; //Snakes get points for reaching the end of the allowed time.

//The NN library writes files to a weird place so I don't want this to automatically save.
boolean writeToFileAutomatically = false;

/*
 * NON-CONFIGURABLE PROPERTIES
 */
int timeDelay = 0; // This one is technically configurable but via a user pressing a button on the screen

int NAlive = N;
int bestGeneration = 0;
float bestGenerationScore = 0;
float currentGenerationScore;
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
      
      //snake has now chosen to go left/right/straight on.
      boolean collisionDetected = snake.willCollideWithSomething();
      
      if (collisionDetected) {
        snake.isDead = true;
        NAlive--;
      } else {
        //Update the snake's position and give it some points for surviving another time step.
        snake.updatePositions();
        //snake.points = snake.points + pointsPerTimeStep;
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
  
  //Pass this generation's stats into the stats window.
  StatsWindowData d = (StatsWindowData)statsWindow.data;
  d.addScore(currentGenerationScore, NAlive, piecesOfFruitEaten);
  
  //create new snakes implementing all the genetics etc.
  createNewSnakes_Mk2();
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
  
  if (currentGeneration > 1000) {
    mutationChance = 0.001;
  } else if (currentGeneration > 500) {
    mutationChance = 0.01;
  } else if (currentGeneration > 300) {
    mutationChance = 0.025;
  } else if (currentGeneration > 200) {
    mutationChance = 0.05;
  } else if (currentGeneration > 100) {
    mutationChance = 0.1;
  }
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

/**
 * createNewSnakes_Mk2. Better version. Calculate a random number between 0 and the sum of all snakes' points.
 * Then go through the population adding their score and select the snake if the cumulative
 * score is above the random number. This means snakes with a higher score are more likely
 * to be chosen.
 */
void createNewSnakes_Mk2() {
  //Copy the snakes into prevGeneration so if I want to save it I can.
  prevGeneration = null;
  prevGeneration = new ArrayList<Snake>();
  for (int i=0; i<N; i++) {
    prevGeneration.add(Snakes.get(i));
  }
  
  ArrayList<Snake> newGeneration = new ArrayList<Snake>();
  
  newGeneration = addBestSnake(newGeneration);
  
  for (int i=0; i<N-1; i++) {
    //Select two parents
    Snake parent1 = selectParentSnake();
    Snake parent2 = selectParentSnake();
    
    //Create a child snake
    NeuralNetwork childBrain = parent1.brain.merge(parent2.brain);
    Snake childSnake = createNewGenSnake(childBrain);
    
    //Add the child to the next generation
    newGeneration.add(childSnake);
  }
  Snakes = newGeneration;
  currentGeneration++;
}

Snake selectParentSnake() {
  float randomNumber = random(currentGenerationScore);
  float cumulativeScore = 0.01; //smallest possible score so that we always return a snake.
  for (int i=0; i<N; i++) {
    Snake s = Snakes.get(i); 
    cumulativeScore += s.points;
    if (cumulativeScore > randomNumber) {
      return s;
    }
  }
  
  return null;
}

ArrayList<Snake> addBestSnake(ArrayList<Snake> newGen) {
  Snake bestSnake = null;
  float bestScore = 0;
  for (int i=0; i<N; i++) {
    Snake s = Snakes.get(i);
    if (s.points > bestScore) {
      bestSnake = s;
    }
  }
  newGen.add(bestSnake.copySnake());
  return newGen;
}

Snake createNewGenSnake(NeuralNetwork brain) {
  ArrayList<int[]> positions = createInitialPositionsArray();
  return new Snake(positions, brain, mutationChance);
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

void keyPressed() {
  switch (key) {
    case '/':
      mutationChance = 0.5;
      break;
    case '.':
      mutationChance = 0.3;
      break;
    case ',':
      mutationChance = 0.2;
      break;
    case 'm':
      mutationChance = 0.1;
      break;
    case 'n':
      mutationChance = 0.075;
      break;
    case 'b':
      mutationChance = 0.05;
      break;
    case 'v':
      mutationChance = 0.025;
      break;
    case 'c':
      mutationChance = 0.01;
      break;
  }
  println("Mutation Chance selected: " + mutationChance);
}

/**
 * Get the best scoring snake for either this or the last generation. Write this to file.
 */
void findBestSnakeAndWriteToFile(boolean currentGeneration) {
  float bestScore = 0;
  Snake bestSnake = null;
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
  currentGenerationScore = 0; //smallest possible increment
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
 * Snakes can get points if they are alive at the end of the game.
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
 * Draw at most 10 snakes. You can get some idea of what the population
 * is doing, and it runs about as fast as not drawing any.
 */
void drawSomeOfTheSnakes() {
  //if less that 10 are alive, just draw all the alive ones.
  if (NAlive < 10) { 
    for (int i=0; i<N; i++) {
      Snake snake = Snakes.get(i);
      if (!snake.isDead)
      {
        snake.drawSnake();
        snake.drawFruit();
      }
    }
  } else {
    //draw only 10 snakes
    int drawn = 0;
    int i = 0;
    while (drawn < 10) {
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
