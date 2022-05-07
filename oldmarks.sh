OOO=`grep -m2 "<oref:ShortName>" WayBill_v3.xml | tail -n1 | awk -F '[<>]' '{print $3}'`
