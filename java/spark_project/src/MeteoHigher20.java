import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaPairRDD;   
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;
import scala.Tuple2;
import scala.Tuple21;
import java.util.Arrays;

@SuppressWarnings("unused")
public class MeteoHigher20 {
    @SuppressWarnings("resource")
    public static void main(String[] args) {
    String inputFile = "meteosample.txt";
    String outputFile = "result";

    SparkConf conf = new SparkConf().setAppName("MeteoHigher20");
    JavaSparkContext sc = new JavaSparkContext(conf);

    long t1 = System.currentTimeMillis();

    JavaRDD<String> data = sc.textFile(inputFile);
    JavaPairRDD<String, Integer> pairs = data.mapToPair(w -> { 
        String[] parts = w.split(" : ");
        String key = parts[1]+" : "+parts[2];
        int value = Integer.parseInt(parts[3]);
        return new Tuple2<>(key, value);
    }).filter(t -> t._2>20);

    JavaRDD<String> months = pairs.keys().distinct();

    long nbmonths = months.count();
    JavaRDD<String> nbMonthsRDD = sc.parallelize(Arrays.asList(String.valueOf(nbmonths)));
    JavaRDD<String> nbMonthsRDD2 = sc.parallelize(java.util.Collections.singletonList(
        "Number of uniques months with temperature hihger than 20ºC"+nbmonths));

    nbMonthsRDD.saveAsTextFile(outputFile);

    long t2 = System.currentTimeMillis();
    System.out.println("======================");
    System.out.println("time in ms :"+(t2-t1));
    System.out.println("======================");
    }
}