if [ "$1" = "1" ]
then
	make synthesis;make implementation;make bitfile;make upload
else
	make implementation;make bitfile;make upload
fi
