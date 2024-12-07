import edu.stanford.nlp.pipeline.*;
import edu.stanford.nlp.ling.*;
import edu.stanford.nlp.sentiment.SentimentCoreAnnotations;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.*;

public class Main {
    public static void main(String[] args) {
        // Define the path to the input text file
        String inputPath = "C:/Users/joanm/Documents/Processing/LDC_Repo/data/input.txt"; // Change this to your input file path
        StringBuilder textBuilder = new StringBuilder();

        // Read the text from the file
        try (BufferedReader reader = new BufferedReader(new FileReader(inputPath))) {
            String line;
            while ((line = reader.readLine()) != null) {
                textBuilder.append(line).append("\n");
            }
        } catch (IOException e) {
            System.err.println("Error reading from file: " + e.getMessage());
            return; // Exit if there's an error reading the file
        }

        String text = textBuilder.toString(); // Convert StringBuilder to String

        // Set up pipeline properties
        Properties props = new Properties();
        props.setProperty("annotators", "tokenize, ssplit, pos, parse, sentiment");

        // Build Stanford CoreNLP pipeline
        StanfordCoreNLP pipeline = new StanfordCoreNLP(props);

        // Create a CoreDocument
        CoreDocument document = new CoreDocument(text);

        // Annotate the document
        pipeline.annotate(document);

        // Define the paths for the output files
        String sentimentOutputPath = "C:/Users/joanm/Documents/Processing/LDC_Repo/data/sentiments.txt";
        

        try (BufferedWriter sentimentWriter = new BufferedWriter(new FileWriter(sentimentOutputPath))) {

            for (CoreSentence sentence : document.sentences()) {
                // Get the sentiment for each sentence
                String sentiment = sentence.sentiment();


                // Get tokens and analyze parts of speech
                List<CoreLabel> tokens = sentence.tokens();
                int  verbCount = 0, adjectiveCount = 0, punctuationCount = 0;

                for (CoreLabel token : tokens) {
                    String pos = token.get(CoreAnnotations.PartOfSpeechAnnotation.class);


                     if (pos.startsWith("VB")) { // Verbs
                        verbCount++;
                    } else if (pos.startsWith("JJ")) { // Adjectives
                        adjectiveCount++;
                    } else if (pos.matches("\\p{Punct}")) { // Punctuation
                        punctuationCount++;
                    }
                }

                // Calculate punctuation density
                int tokenCount = tokens.size();
                float punctuationDensity = (tokenCount > 0) ? (float) punctuationCount / tokenCount : 0;

                // Write the counts and density to the counts file
                sentimentWriter.write( sentiment + "," + verbCount + "," + adjectiveCount + "," + punctuationDensity);
                sentimentWriter.newLine();
            }

            System.out.println("Sentiments and counts have been written to their respective files.");
        } catch (IOException e) {
            System.err.println("Error writing to file: " + e.getMessage());
        }
    }
}
