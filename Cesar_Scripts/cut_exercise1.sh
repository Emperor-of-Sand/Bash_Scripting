: '
Given  lines of input, print the  character from each line as a new line of output. It is guaranteed that each of the  lines of input will have a  character.

Input Format

A text file containing  lines of ASCII characters.

Constraints

Output Format

For each line of input, print its  character on a new line for a total of  lines of output.

Sample Input

Hello
World
how are you
Sample Output

l
r
w
'

# Code
while read n
do
    echo $n |cut -c 3
done
# Example 2
: '
Display the  and  character from each line of text.

Input Format

A text file with  lines of ASCII text only.

Constraints

Output Format

The output should contain  lines. Each line should contain just two characters at the  and the  position of the corresponding input line.

Sample Input

Hello

World

how are you

Sample Output

e

o

oe
'
while read n
do
    echo $n |cut -c 2,7
done

# Each line should contain the range of characters starting at the  position of a string and ending at the 

while read n
do
    echo $n |cut -c 2-7
done
