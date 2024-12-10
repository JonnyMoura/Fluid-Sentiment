




ArrayList<Particle> particles; 
String[] sentiments; 
HashMap<String, Particle> originalState = new HashMap<>();
HashMap<String, Particle> currentState = new HashMap<>();

int maxParticlesToAddPerCycle = 10; 
int regenerationInterval = 125;
int lastRegeneration = 0;


PGraphics paintLayer; 
int[] paintPixels; 
int[] permanentPixels;



void setup() { 
    size(1080, 1080, P2D); 
    colorMode(HSB, 360, 100, 100);

    paintPixels = new int[width * height]; 
    permanentPixels = new int[width * height];

    for (int i = 0; i < permanentPixels.length; i++) { 
        permanentPixels[i] = color(0, 0, 0); 
    }

    paintLayer = createGraphics(width, height); 
    paintLayer.beginDraw(); 
    paintLayer.endDraw();

    particles = new ArrayList<Particle>();
    sentiments = loadStrings("sentiments.txt");

    // Initialize particles based on sentiments 
    for (String sentiment : sentiments) {
        String id = generateUniqueID();
        String[] data = split(sentiment, ',');

        Particle p = new Particle(id, random(width), random(height), data[0].trim(),int(data[1].trim()),int(data[2].trim()),float(data[3].trim())); 
        particles.add(p);
        originalState.put(id, p);
         
    } 
}

void draw() { 
    updatePaintLayer(); 
    paintLayer.loadPixels(); 
    paintLayer.pixels = paintPixels.clone(); 
    paintLayer.updatePixels();

    // Draw the painting layer 
    image(paintLayer, 0, 0);

    updateCurrentState(); 
    if (frameCount - lastRegeneration > regenerationInterval) { 
        regenerateParticles(); 
        lastRegeneration = frameCount; 
    } 

    for (int i = particles.size() - 1; i >= 0; i--) { 
        Particle p = particles.get(i); 
        p.applyRandomEscapeForce();
        p.update();
        p.show(); 
        p.reproducePositive();

        for (int j = particles.size() - 1; j >= 0; j--) {
            if (i != j) {
                Particle other = particles.get(j);
                p.interact(other);
            }
        }
        
    }
}



void updatePaintLayer() { 
    System.arraycopy(permanentPixels, 0, paintPixels, 0, permanentPixels.length);

    // Overlay new particle trails with some transparency 
    for (Particle p : particles) { 
        p.paintTrail(paintLayer.pixels); 
    } 
}

int countPositiveParticles() { 
    int count = 0; 
    for (Particle p : particles) { 
        if (p.isPositive()) { 
            count++; 
        } 
    } 
    return count; 
}

void updateCurrentState() { 
    currentState.clear(); 
    for (Particle p : particles) { 
        currentState.put(p.id,p ); 
    } 
}



void regenerateParticles() {
    int regeneratedCount = 0;
    int originalCount = originalState.size();
    int currentCount = currentState.size();
    
    if (currentCount < 0.8* originalCount) {
      for (String id : originalState.keySet()) {
          if (!currentState.containsKey(id) && regeneratedCount < maxParticlesToAddPerCycle ) {
            
              Particle originalParticle = originalState.get(id);
              
              Particle regeneratedParticle = new Particle(id,random(width), random(height), 
                                                           originalParticle.sentiment, 
                                                           originalParticle.verbCount, 
                                                           originalParticle.adjCount, 
                                                           originalParticle.punctuationDensity);
              println(regeneratedParticle.id);
              particles.add(regeneratedParticle);
              currentState.put(id, regeneratedParticle);
              regeneratedCount++;
          }
      }
}}

void keyPressed() {
    if (key == 'E' || key == 'e') {
        // Salvar a pintura como imagem
        paintLayer.beginDraw();
        paintLayer.background(0); 
        paintLayer.image(paintLayer, 0, 0); 
        paintLayer.endDraw();
        String timestamp = nf(year(), 4) + "_" + nf(month(), 2) + "_" + nf(day(), 2) + "_" + 
                       nf(hour(), 2) + "_" + nf(minute(), 2) ;
                       
                       
        String sketchFolder = sketchPath();
        File parentFolder = new File(sketchFolder).getParentFile();
        
        File targetFolder = new File(parentFolder, "Experiences");
        String filename = "painting_" + timestamp + ".png";
        paintLayer.save(targetFolder.getAbsolutePath() + "/" + filename);
        println("Pintura salva");
    }

    if (key == 'Q' || key == 'q') {
        // Encerrar a simulação
        println("Encerrando a simulação.");
        exit();
    }
}

String generateUniqueID() {
    return str(millis()) + "_" + str(random(1000));
}
