   mdone=0
   pcdone=0
   oldpc=0
   
   numfiles=(/Users/Benjamin/metas/*.meta)
   numfiles=${#numfiles[@]}
   
   for b in /Users/Benjamin/metas/*.meta
   do
   
   logfile="/Users/Benjamin/Desktop/metainfo.csv"
   
   Time=$(sed '1q;d' $b)
   CIP=$(sed '10q;d' $b)
   CH=$(sed '11q;d' $b)
   Data=$(sed '15q;d' $b)
   
   Time=${Time:11}
   CIP=${CIP:19}
   CH=${CH:17}
   Data=${Data:14}
   
   Time="$Time,"
   CIP="$CIP,"
   CH="$CH,"
   Data="$Data"
   
   echo $Time$CIP$CH$Data>>$logfile
   
   mdone=$((mdone + 1))
   pcdone=$((mdone*100/numfiles))
   
   if [ $pcdone -ne $oldpc ]
   then
   echo "$pcdone%"
   fi
   
   oldpc=$pcdone;

   done