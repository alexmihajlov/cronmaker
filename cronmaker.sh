#!/bin/sh

USAGE=" CronMaker\\n
\\n
Usage: cronmaker.sh [-hvg] [-c config_file] [-t tmp_dir]\\n
\\n
"

current_dir=$(cd $(dirname $0); pwd -P)
out_dir=$current_dir/tmp
config_file=$current_dir/cronmaker.ini
remake=0
verbose=0
install_cron=1
mails="ovpstat@bugs.ru"



# check for any argument set
#if [ $# -eq 0 ]; then
#    exit 1
#fi

# parse command line arguments
while getopts hvgc:t: OPT; do
    case "$OPT" in
	h)	echo -e $USAGE
		exit 0
	;;
	v)	verbose=1
	;;
	g)	install_cron=0
		remake=1
	;;
	c)	config_file=$OPTARG
	;;
	t)	out_dir=$OPTARG
	;;
	\?)	# getopts issues an error message
		echo $USAGE >&2
		exit 1
	;;
    esac
done


# 
#shift `expr $OPTIND - 1`
# access additional parameters through $@ or $* as usual or using this loop:
#for PARAM; do
#echo $PARAM
#done



if [ ! -r $config_file ]; then
    echo "Error: Configuration file not found at $config_file" >&2
    exit 1
fi

if [ $verbose -ne 0 ]; then 
    echo "Checking modify time..."
fi

if [ ! -r $out_dir/cronfile ]; then
    if [ $verbose -ne 0 ]; then
	echo "Need rebuild: cronfile missing"
    fi
    remake=1
else
    eval `stat -s $out_dir/cronfile`
    last_mtime=$st_mtime

    eval `stat -s $config_file` 
    
    if [ $st_mtime -gt $last_mtime ]; then
	if [ $verbose -ne 0 ]; then
	    echo "Need rebuild: config changed"
	fi
	remake=1
    else

        for i in `cat $config_file`
	do
	    if [ ! -r $i ]; then
		echo "Error: Cron file not found at $i" >&2
	    else 
		eval `stat -s $i`
	    
		if [ $st_mtime -gt $last_mtime ]; then
		    if [ $verbose -ne 0 ]; then
			echo "Need rebuld: file changed $i"
		    fi
		    remake=1
		fi
	    fi
	done
    fi
fi

if [ $remake -eq 0 ]; then
    if [ $verbose -ne 0 ]; then
	echo "Rebuild not need"
    fi
    exit 0
fi    

if [ $verbose -ne 0 ]; then
    echo "Rebuilding cron file..."
fi

echo "## ******** Cronfile generated by LS CronMaker Utility ($(date)) ******** " > $out_dir/cronfile

for i in `cat $config_file` 
do
    if [ -r $i ]; then
        cat $i >> $out_dir/cronfile
        echo '' >> $out_dir/cronfile
        echo '' >> $out_dir/cronfile
    else 
	echo "Error: cron file not found at $i" >&2
    fi
done

if [ $verbose -ne 0 ]; then
    echo "Rebuild done"
fi

if [ $install_cron -ne 0 ]; then
    crontab $out_dir/cronfile 2>/dev/null
    result=`echo $?`
    if [ $result -ne 0 ]; then
       echo "Cronamker's cron on `hostname` NOT installed" | mail -s "CRONMAKER INSTALL CRON ERROR" $mails;
	rm $out_dir/cronfile 2>/dev/null
    fi

    if [ $verbose -ne 0 ]; then
	echo "Cron install done"
    fi
fi

exit 0
