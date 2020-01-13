#--------------------------------#
#----------run_iNode.sh----------#
#---execute this file to start---#
#---receving and sending data----#
#--------------------------------#
#--------$./run_iNode.sh---------#
#--------------------------------#
#./iNode.sh  > /dev/null 2>&1 &

cd /opt/iNode/
#nohup bash /opt/iNode/iNode.sh &
bash /opt/iNode/iNode.sh >> iNode.log &
