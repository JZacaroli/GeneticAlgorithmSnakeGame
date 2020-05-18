# GeneticAlgorithmSnakeGame

 Teaching your computer to play snake through a genetic algorithm in Processing (Java).

 Inspired by @CodingTrain 's video on playing flappy bird with a genetic algorithm. The snakes' brains are simple Neural networks implemented by @kim-marcel [here](https://github.com/kim-marcel/basic_neural_network). To run, make sure you install the G4P add-on libraries, and you're ready to go.
 
 
 # Something I've learned about Genetic Algorithms:
 
 They're <b>very</b> sensitive to how you choose the next generation. The ideal way to implement it would be probabalistically (i.e. each snake has a chance of reproducing which is informed by its previous score), which I didn't do. In my method, I allow the top 15% scoring snakes of each generation to reproduce with the top 70% and then got rid of the bottom 30% (which is effectively a probability distribution, just a very quantized one). I initially tried letting the top 15% reproduce only with themselves, but that created a completely homogeneous set of snakes and is very bad at wiggling out of local maxima, even with mutation. It's therefore important to keep a level of noise in the system to help deal with this.


# TODO:
- Train for a while.
- Create sketch to watch a single well-trained snake.
