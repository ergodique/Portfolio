import java.util.Arrays;

public class Main {
    public static int[] findSumPair(int[] numbers,int k){
        int[] result={0,0};
        boolean found=false;
        for (int i=0;i< numbers.length;i++){
            for (int j=i+1;j< numbers.length;j++){
                if(numbers[i]+numbers[j]==k){
                    result[0]=i;
                    result[1]=j;
                    found=true;
                    break;
                }
            }
            if (found){
                break;
            }
        }
        return result;
    }
    public static void main(String[] args) {
        int[] numbers={1,1,2,9,4,13,0};
        int k=13;
        System.out.println(Arrays.toString(findSumPair(numbers,k)));
    }
}