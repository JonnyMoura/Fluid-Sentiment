class Particle {
  PVector position;
  PVector velocity;
  PVector acceleration;  
  String sentiment;
  int colour;
  float speed;
  int size = 10;
  int killCount = 0;
  int survivalTime = 0;
  int initializationFrames = 30;
  color baseColor;
  color currentColour;
  color[] colorPalette;
  float newBrightness;
  int verbCount;
  int adjCount;
  float punctuationDensity;
  String id;
  
  float attractionForceMagnitude = 0;
  float repulsionForceMagnitude = 0;
  ArrayList <Particle> flockmates ;
  int flockmateCounter = 0;
  
  
  boolean escaping = false;
  float escapeForceMagnitude = 0;
  int escapeDuration = 0;
  
  

  Particle(String id, float x, float y, String sentiment, int verbCount, int adjCount, float punctuationDensity) {
    position = new PVector(x, y);
    this.id = id;
    this.sentiment = sentiment;
    this.verbCount = verbCount;
    this.adjCount = adjCount;
    this.punctuationDensity = punctuationDensity;
    velocity = PVector.random2D();
    acceleration = new PVector(0, 0);
    flockmates = new ArrayList<>();
    
    
    

    switch (sentiment) {
    case "Very Negative":
        baseColor =  color(0, 60, 80);// Warm dark red
        speed = 10;
        break;
    case "Negative":
        baseColor = color(25, 100, 85); // Bright orange
        speed = 5;
        break;
    case "Neutral":
        baseColor = color(240, 10, 80); // Soft lavender-grey
        speed = 2;
        break;
    case "Positive":
        baseColor =  color(130, 60, 50); // Softer green
        speed = 5;
        break;
    case "Very positive":
        baseColor = color(170, 80, 90); // Cyan-teal
        speed = 10;
        break;
}

    int maxVerbCount = 1;
    int maxAdjCount = 1;
    
    for (Particle p : particles) {
        if (p.verbCount > maxVerbCount) maxVerbCount = p.verbCount;
        if (p.adjCount > maxAdjCount) maxAdjCount = p.adjCount;
    }
    
    
    float hueVariation = map(verbCount, 0, maxVerbCount, -5, 5);
    float saturationVariation = map(adjCount, 0, maxAdjCount, -50, 50);

    
    float brightnessVariation = map(punctuationDensity, 0, 1, 10, 100);
    

    float newHue = constrain(hue(baseColor) + hueVariation, 0, 360);
    float newSaturation = constrain(saturation(baseColor) + saturationVariation, 0, 100);
    float newBrightness = constrain(brightness(baseColor) +brightnessVariation,0,100);
    currentColour = color(newHue, newSaturation, newBrightness);
  }

  void update() {
    
    velocity.add(acceleration);
    
     if (escaping) {
            PVector escapeForce = PVector.random2D().mult(escapeForceMagnitude);
            velocity.add(escapeForce);
            escapeDuration--;

            // Stop escaping after a duration
            if (escapeDuration <= 0) {
                escaping = false;
                escapeForceMagnitude = 0;
            }
        }
    
    velocity.limit(speed);
    
    
    position.add(velocity);
    
    if (initializationFrames > 0) {
      initializationFrames--;
    }
    
    position.x = (position.x + width) % width;
    position.y = (position.y + height) % height;
    
 
    survivalTime++;
    acceleration.mult(0);
    
   
  }
  

  void show() {
    fill(currentColour);
    stroke(0,0,0);
    ellipse(position.x, position.y, size, size);
  }

  void interact(Particle other) {
    float distance = toroidalDistance(position, other.position);
    flockmates.clear();
    

    // Identify flockmates
    if (sameType(other) && distance < 50) {
        flockmates.add(other);
    }

    // Adjust velocity for flockmates
    if (!flockmates.isEmpty()) {
      acceleration.add(cohesion(flockmates));
      acceleration.add(alignment(flockmates));
      
    }

    
    
    if (sameType(other)) {
      
        if (distance < 50) {
            PVector attraction = PVector.sub(other.position, position).normalize().mult(0.5);
            acceleration.add(attraction);
            attractionForceMagnitude += attraction.mag();
            
            
        }
        if (distance < 30) { 
            PVector separation = PVector.sub(position, other.position)
                                        .normalize()
                                        .mult(map(distance, 0, 30, 15, 1)); 
            acceleration.add(separation);
            repulsionForceMagnitude += separation.mag();
            
        }
    } else {
        // Other interactions between different types
        if (isNegative() && other.isPositive()) {
            if (distance < 100) {
                PVector chase = PVector.sub(other.position, position).normalize().mult(0.2);
                acceleration.add(chase);
                attractionForceMagnitude += chase.mag();
            }
        } else if ((isPositive() && (other.isNegative() || other.isNeutral())) || 
                   (isNegative() && (other.isPositive() || other.isNeutral())) || 
                   (isNeutral() && (other.isPositive() || other.isNegative()))) {
            if (distance < 50) {
                PVector repulsion = PVector.sub(position, other.position).normalize().mult(0.7);
                acceleration.add(repulsion);
                repulsionForceMagnitude += repulsion.mag();
            }
        }
    }

    if (!(isNeutral() || other.isNeutral())) {
        if (distance < 15 && !sameType(other)) {
            if (this.countSameTypeNeighbors() > other.countSameTypeNeighbors()) {
                particles.remove(other);
                killCount++;
                if (killCount >= 2) {
                    addParticleSafely(position.x, position.y, sentiment,verbCount,adjCount,punctuationDensity);
                    killCount = 0;
                }
            }
        }
    }

    velocity.limit(speed);
    
  }

    
    

    
   
  boolean sameType(Particle other) {
    return this.sentiment.equals(other.sentiment);
  }

  int countSameTypeNeighbors() {
    int count = 0;
    for (Particle p : particles) {
      if (sameType(p) && toroidalDistance(position, p.position) < 50) {
        count++;
      }
    }
    return count;
  }

  boolean isNegative() {
    return sentiment.equals("Negative") || sentiment.equals("Very Negative");
  }

  boolean isPositive() {
    return sentiment.equals("Positive") || sentiment.equals("Very positive");
  }

  boolean isNeutral() {
    return sentiment.equals("Neutral");
  }
  
  boolean isInitialized() {
    return initializationFrames <= 0;
  }

  PVector cohesion(ArrayList<Particle> neighbors) {
    PVector center = new PVector();
    for (Particle neighbor : neighbors) {
      center.add(neighbor.position);
    }
    center.div(neighbors.size());
    return PVector.sub(center, position).normalize().mult(0.5);
  }

  PVector alignment(ArrayList<Particle> neighbors) {
    PVector averageVelocity = new PVector();
    for (Particle neighbor : neighbors) {
      averageVelocity.add(neighbor.velocity);
    }
    averageVelocity.div(neighbors.size());
    return averageVelocity.normalize().mult(0.6);
  }

  float toroidalDistance(PVector p1, PVector p2) {
    float dx = abs(p1.x - p2.x);
    float dy = abs(p1.y - p2.y);

    if (dx > width / 2) {
      dx = width - dx;
    }
    if (dy > height / 2) {
      dy = height - dy;
    }

    return sqrt(dx * dx + dy * dy);
  }
  
  void reproducePositive() {
    if (isPositive()) {
        int positiveCount = countPositiveParticles();
        float reproductionThreshold = 75 * pow(1.1,positiveCount); 
        

        if (survivalTime > reproductionThreshold) {
            addParticleSafely(position.x, position.y, sentiment,verbCount,adjCount,punctuationDensity);
            survivalTime = 0; 
        }
    }
}

  void addParticleSafely(float x, float y, String sentiment,int verbCount, int adjCount, float punctuationDensity) {
    boolean safe = true;
    for (Particle p : particles) {
        float distance = toroidalDistance(new PVector(x, y), p.position);
        if (distance < 20) { 
            safe = false;
            break;
        }
    }

    if (safe) {
        String id = generateUniqueID();
        particles.add(new Particle(id,x, y, sentiment,verbCount,adjCount,punctuationDensity));
        id = generateUniqueID();
        particles.add(new Particle(id,x, y, sentiment,verbCount,adjCount,punctuationDensity));
        
    }
}
 void paintTrail(int[] paintLayerPixels) {
    int x = int(position.x);
    int y = int(position.y);

    // Garantir que x e y estejam dentro do intervalo com espaço toroidal
    x = (x + width) % width;
    y = (y + height) % height;

    float velocityMagnitude = velocity.mag();
    int trailRadius = int(map(velocityMagnitude, 0, 10, 10, 100));
    int paintIntensity = int(map(velocityMagnitude, 0, 10, 3, 10));
    int trailRadiusSq = trailRadius * trailRadius;

   
    for (int cyOffset = -trailRadius; cyOffset <= trailRadius; cyOffset++) {
        for (int cxOffset = -trailRadius; cxOffset <= trailRadius; cxOffset++) {
            int dx = cxOffset;
            int dy = cyOffset;
            int distSq = dx * dx + dy * dy;

            if (distSq <= trailRadiusSq) {
                // Coordenadas toroidais
                int cx = (x + cxOffset + width) % width;
                int cy = (y + cyOffset + height) % height;
                int pixelIndex = cx + cy * width;

                float distance = sqrt(distSq);
                float falloffFactor = 1.0 - (distance / trailRadius);
                int falloffIntensity = int(paintIntensity * pow(falloffFactor, 0.5));

                int falloffTrailColor = color(currentColour, falloffIntensity);

                
                int existingPermanentColor = permanentPixels[pixelIndex];
                if (existingPermanentColor == color(0, 0, 100, 255)) {
                    permanentPixels[pixelIndex] = falloffTrailColor;
                    paintLayerPixels[pixelIndex] = falloffTrailColor;
                } else {
                    int blendedColor = blendColors(existingPermanentColor, falloffTrailColor);
                    permanentPixels[pixelIndex] = blendedColor;
                    paintLayerPixels[pixelIndex] = blendedColor;
                }
            }
        }
    }
}


int blendColors(int c1, int c2) {
float a1 = alpha(c1) / 255.0;
float a2 = alpha(c2) / 255.0;

// Weighted average for alpha
float newAlpha = a1 + (1 - a1) * a2;


float blendedHue = (hue(c1) * a1 + hue(c2) * a2) / (a1 + a2);
float blendedSaturation = (saturation(c1) * a1 + saturation(c2) * a2) / (a1 + a2);
float blendedBrightness = (brightness(c1) * a1 + brightness(c2) * a2) / (a1 + a2);

// Return blended color
return color(blendedHue, blendedSaturation, blendedBrightness, newAlpha * 255);
}

 void applyRandomEscapeForce() {
        if (!escaping && random(1) < 0.01) { 
            escaping = true;
            escapeForceMagnitude = random(0.5, 0.9); 
            escapeDuration = int(random(30, 50)); 
        }
    }


}
