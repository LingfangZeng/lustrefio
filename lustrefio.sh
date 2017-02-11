#initialization
function auto_mkdir()
{
        #$1 dirname $2 option
        if [ $# -lt 1 ];then
                return
        fi
        if [ $# -eq 1 -o "$2"x == "weak"x ];then
                if [ ! -d $1 ];then
                        mkdir -p $1
                        return
                fi
        fi
        if [ $# -eq 2 -a "$2"x == "force"x ];then
                if [ -d $1 ];then
                        rm -rf $1
                fi
                auto_mkdir $1 "weak"
        fi
}

function print_message()
{
    local message_type=$1
    shift
    case ${message_type} in
        TEST_INFO|TEST_ERROR|TEST_WARN)
            echo "${message_type}:$@"
            ;;
        MULTEXU_ECHO)
            echo "$@"
           ;;
                MULTEXU_ECHOX)
                        local cmd=$1
                        shift
                        $cmd echo "$@"
    esac
}

#result directory
result_dir="/home/raid10/fio"

#test parameters
blocksize=1 #the blocksize

declare -a raid_array
raid=
raid_array=("shm" "sdb" "sdc" "sda" "sda" "sda")
direct=0
iodepth=1
allow_mounted_write=1
ioengine="psync"

#random io special parameters
special_cmd="-rwmixread=70"
size="10M"
numjobs=2
runtime=100
sleeptime=20
limit=10
name="raid10_test"

blocksize_start=1
blocksize_end=2048
blocksize_multi_step=2
#check test completion time
checktime_init=600
checktime_lower_limit=60

#IO pattern

declare -a rw_array 
#fio read or write mode
rw_array=("randrw" "readwrite" "write" "randwrite" "read" "randread")
#
#fio installation
#
#print_message "TEST_INFO" "now start to check fio tool in client nodes..."
#git clone git://git.kernel.dk/fio.git
#cd fio
#./configure --enable-gfio
#make fio
#make gfio

#
#detete preview test directory or file
#
#rm -rf "${directory}"
rm -rf "${result_dir}"
#sleep ${sleeptime}s
##create test directory
#mkdir "${directory}/"
mkdir "${result_dir}"

#
#start testing
#
print_message "TEST_INFO" "now start the test processes..."
for raid in ${raid_array[*]}
do
#test directory
directory="/dev/$raid"
    for rw_pattern in ${rw_array[*]}
    do
        #directory where test results store
		dirname="${result_dir}/${rw_pattern}"
		auto_mkdir "${dirname}" "weak"
		
		print_message "TEST_ECHO" "	rw_array:${rw_pattern}"
        for ((blocksize=${blocksize_start} ;blocksize <= ${blocksize_end}; blocksize*=${blocksize_multi_step}))
        do
		print_message "TEST_ECHO" "		start a test..."   
			
            special_cmd_io_choice=
			
            if [[ ${rw_pattern} == "readwrite" ]] || [[ ${rw_pattern} == "randrw" ]];then
                special_cmd_io_choice=${special_cmd}
            fi

            cmdvar="/home/fio/fio -directory=${directory} -direct=${direct} -iodepth ${iodepth} -thread -rw=${rw_pattern} ${special_cmd_io_choice} -allow_mounted_write=${allow_mounted_write} -ioengine=${ioengine} -bs=${blocksize}k -size=${size} -numjobs=${numjobs} -runtime=${runtime} -group_reporting -name=${name} "
            print_message "TEST_ECHO" "		test command:${cmdvar}"
            #delte test file
            rm -f "${directory}/*"
	sleep ${sleeptime}s
            #Name of test result:readwritemode-raid-blocksize-k.txt
            filename="${rw_pattern}-${raid}-${blocksize}-k.txt"
            touch "${dirname}/${filename}"
            `${PAUSE_CMD}`    
            echo "${cmdvar}" > ${dirname}/${filename}
            #write tets result into file
            #
            ${cmdvar} >> ${dirname}/${filename}
      
            print_message "TEST_ECHO" "		finish this test..."

        done #blocksize
    done #rw_pattern
done #raid
