#!/bin/bash
trap "my_exit" 2 3 9 15
HOLD1=/tmp/HOLD1.$$
HOLD2=/tmp/HOLD2.$$
my_exit ()
{
echo "receive......exit?"
echo "1:Yes"
echo "2:No"
echo "please choose 1 or 2 :"
read ANS
case $ANS in
1|y|Y) 
echo "<CTRL_c> detected .. now cleaning up..wait"
rm /tmp/*.$$ 2>/dev/null
exit 1
;;
2|n|N) echo "choose 2"
 ;;
esac
 
}
echo "processing......"
while :
do
 df >>$HOLD1
 ps xa>>$HOLD2
done
 
