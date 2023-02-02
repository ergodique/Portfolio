import java.util.Arrays;

public class Main {
    public static int[] countFrequencies(String[] words){

        //System.out.println("Hello world!");
        Arrays.sort(words);
        System.out.println("Sorted array is: " +Arrays.toString(words));
        int[] counts = new int[words.length];
        counts[0] = 0;
        for (int i = 0, j = 0; i < words.length; i++) {
            if (words[j].equals(words[i])) {
                counts[j]++;
            } else {
                j++;
                words[j] = words[i];
                counts[j] = 1;
            }
        }
        System.out.println("Words array is: " +Arrays.toString(words));
        System.out.println("Counts array is: " +Arrays.toString(counts));

        //remove zero entries from counts
        System.out.println("Removing zeros from counts array");
        int zeroCount=0;
        for(int i=0;i< counts.length;i++){
            if(counts[i]==0)
                zeroCount++;
        }
        int[] newCounts = new int[counts.length-zeroCount];
        for(int i=0;i<counts.length;i++){
            if(counts[i]!=0)
                newCounts[i]=counts[i];
        }
        return newCounts;
    }
    public static void main(String[] args) {
        String[] words={"bone","the","dog","got","the","bone","the"};

        System.out.println(Arrays.toString(countFrequencies(words)));
    }
}