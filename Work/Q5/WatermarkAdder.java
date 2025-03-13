import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;


public class WatermarkAdder {
    
    private static final String WATERMARK_TEXT = "Gilad Maman 313154205 and Shlomo Landaho 315689497";
    
    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("Usage: java WatermarkAdder [image_directory]");
            System.exit(1);
        }
        
        String imageDirectory = args[0];
        System.out.println("Adding watermark to images in directory: " + imageDirectory);
        
        File directory = new File(imageDirectory);
        if (!directory.exists() || !directory.isDirectory()) {
            System.out.println("Error: " + imageDirectory + " is not an existing directory");
            System.exit(1);
        }
        
        // Create output directory
        String outputDirectory = imageDirectory + "_watermarked";
        new File(outputDirectory).mkdir();
        
        // Find all image files in the directory
        File[] imageFiles = directory.listFiles((dir, name) -> 
            name.toLowerCase().endsWith(".png") || 
            name.toLowerCase().endsWith(".jpg") || 
            name.toLowerCase().endsWith(".jpeg"));
        
        if (imageFiles == null || imageFiles.length == 0) {
            System.out.println("No image files found in the directory");
            System.exit(1);
        }
        
        System.out.println("Found " + imageFiles.length + " images");
        
        // Add watermark to each image
        Arrays.stream(imageFiles).forEach(file -> addWatermark(file, outputDirectory));
        
        System.out.println("Finished adding watermark to all images. Results saved in: " + outputDirectory);
    }
    
    /**
     * Adds a watermark to a single image file
     * @param imageFile The source image file
     * @param outputDirectory The directory to save the watermarked image
     */
    private static void addWatermark(File imageFile, String outputDirectory) {
        try {
            String outputPath = outputDirectory + File.separator + imageFile.getName();
            System.out.println("Adding watermark to image: " + imageFile.getName());
            
            
            ProcessBuilder pb = new ProcessBuilder(
                "convert", imageFile.getAbsolutePath(),
                "-gravity", "Center",
                "-pointsize", "30",
                "-fill", "rgba(0,0,0,0.5)",  
                "-annotate", "0", WATERMARK_TEXT,
                outputPath
            );
            
            Process process = pb.start();
            int exitCode = process.waitFor();
            
            if (exitCode == 0) {
                System.out.println("  ✓ Successfully completed: " + outputPath);
            } else {
                System.out.println("  ✗ Failed with error code: " + exitCode);
                // Show error output
                String error = new String(process.getErrorStream().readAllBytes());
                System.out.println("  Error: " + error);
            }
        } catch (IOException | InterruptedException e) {
            System.out.println("Error adding watermark to image " + imageFile.getName() + ": " + e.getMessage());
        }
    }
}