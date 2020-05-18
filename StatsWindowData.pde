import java.util.*;
import java.lang.Double;

public class StatsWindowData extends GWinData {

    float maxScore = 0;
    public List<Float> scores = new ArrayList<Float>();
    int maxSurvivors = 0;
    public List<Integer> survivors = new ArrayList<Integer>();
    int maxFruitEaten = 0;
    public List<Integer> fruitEaten = new ArrayList<Integer>();
    public int numberOfGens = 0;
    
    
    public void addScore(float score, int numOfSurvivors, int numOfFruitEaten) {
      numberOfGens++;
      if (score > maxScore) {
        maxScore = score;
      }
      if (numOfFruitEaten > maxFruitEaten) {
        maxFruitEaten = numOfFruitEaten;
      }
      if (numOfSurvivors > maxSurvivors) {
        maxSurvivors = numOfSurvivors;
      }
      scores.add(score);
      survivors.add(numOfSurvivors);
      fruitEaten.add(numOfFruitEaten);
    }
}

public void windowDraw(PApplet app, GWinData data) {
  StatsWindowData statsData = (StatsWindowData)data;
  //Get out all the data.
  List<Float> scores_ = statsData.scores;
  List<Integer> fruitEaten = statsData.fruitEaten;
  List<Integer> survivors = statsData.survivors;
  float maxSurvivors = (float)statsData.maxSurvivors;
  float maxFruitEaten = (float)statsData.maxFruitEaten;
  int numberOfGens = statsData.numberOfGens;
  float maxScore = statsData.maxScore;
  
  app.background(255);
  
  app.textSize(22);
  app.fill(30);
  app.text("Max Score = " + maxScore, 0, 22);
  app.fill(100, 255, 100);
  app.text("Max Survivors = " + maxSurvivors, 0, 44);
  app.fill(0, 0, 255);
  app.text("Max Fruit Eaten = " + maxFruitEaten, 0, 66);
  
  
  //Draw a graph of the score over the generations in the top half.
  app.strokeWeight(1);
  //For each pair of data points, draw a line between them!
  for (int i=0; i<numberOfGens-1; i++) {
    float score0 = (scores_.get(i)/maxScore);
    float score1 = (scores_.get(i+1)/maxScore);
    float yPos0 = app.height - (score0*(app.height));
    float xPos0 = i * app.width/numberOfGens;
    float yPos1 = app.height - (score1*(app.height));
    float xPos1 = (i+1) * app.width/numberOfGens;
    app.stroke(30);
    app.line(xPos0, yPos0, xPos1, yPos1);
    
    float fruit0Score = (float)fruitEaten.get(i)/maxFruitEaten;
    float fruit1Score = (float)fruitEaten.get(i+1)/maxFruitEaten;
    yPos0 = app.height - (fruit0Score*(app.height));
    yPos1 = app.height - (fruit1Score*(app.height));
    app.stroke(0, 0, 255);
    app.line(xPos0, yPos0, xPos1, yPos1);
    
    float survivor0Score = (float)survivors.get(i)/maxSurvivors;
    float survivor1Score = (float)survivors.get(i+1)/maxSurvivors;
    yPos0 = app.height - (survivor0Score*(app.height));
    yPos1 = app.height - (survivor1Score*(app.height));
    app.stroke(100, 255, 100);
    app.line(xPos0, yPos0, xPos1, yPos1);
  }
  
  
}

public void windowMouse(PApplet app, GWinData data, MouseEvent event) {

}
