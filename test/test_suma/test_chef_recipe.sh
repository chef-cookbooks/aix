#!/bin/ksh93

function show_error_chef
{
	echo "********* TEST FAILURE ********"
	cat $current_dir/aixtest/trace.log
	echo "-------------------------------"
	cat $current_dir/aixtest/chef.log
	echo "*******************************"
}

function check_suma
{
    lpp_source=$1
    expected_action=$2
    expected_origin=$3
    expected_type=$4
    expected_target=$5

    check_action=$(check_value_log 'Action' $lpp_source/suma.log)
    check_origin=$(check_value_log 'FilterML' $lpp_source/suma.log)
    check_type=$(check_value_log 'RqType' $lpp_source/suma.log)
    check_target=$(check_value_log 'RqName' $lpp_source/suma.log)
    if [ "$check_action" != "$expected_action" -o "$check_type" != "$expected_origin" -o "$check_origin" != "$expected_type" -o "$check_target" != "$expected_target" ]
    then
	    echo "********* SUMA FAILURE ********"
        echo "\texpected action = $expected_action"
        echo "\texpected origin = $expected_origin"
        echo "\texpected type = $expected_type"
        echo "\texpected target = $expected_target"
        echo ""
	    cat $lpp_source/suma.log
	    echo "*******************************"
	    let nb_failure+=1
    	return 1
    fi
    return 0
}

function check_nim
{
    lpp_source=$1
    expected_name=$2
    expected_server=$3
    expected_location=$lpp_source
	
	if [ -z "$expected_name" -a -z "$expected_server" ]
	then
		if [ -f "$lpp_source/nim.log" ]
		then
		    echo "********* NIM FAILURE ********"
		    cat $lpp_source/nim.log
		    echo "******************************"
		    let nb_failure+=1
		fi
	else
		if [ -f "$lpp_source/nim.log" ]
		then
		    check_name=$(check_value_log 'name' $lpp_source/nim.log)
		    check_location=$(check_value_log 'location' $lpp_source/nim.log)
		    check_server=$(check_value_log 'server' $lpp_source/nim.log)
		    if [ "$check_name" != "$expected_name" -o "$check_location" != "$expected_location" -o "$check_server" != "$expected_server" ]
		    then
			    echo "********* SUMA FAILURE ********"
		        echo "\texpected name = $expected_name"
		        echo "\texpected location = $expected_location"
		        echo "\texpected server = $expected_server"
		        echo ""
			    cat $lpp_source/nim.log
			    echo "*******************************"
			    let nb_failure+=1
		    fi
		#else
		    #echo "********* NIM FAILURE (no log file '$lpp_source/nim.log') ********"
		    #let nb_failure+=1
		fi
	fi
}


function check_directory
{
	if [ ! -d  "$1" ]
	then
		echo "** lpp_source folder '$1' not created!"
		let nb_failure+=1
		return 1
	else
		return 0
	fi
}

function check_no_directory
{
	if [ -d  "$1" ]
	then
		echo "** lpp_source folder '$1' are created!"
		let nb_failure+=1
		return 1
	else
		return 0
	fi
}

function check_value_log
{
    field=$1
	log_file=$2
    check=$(grep "$field" $log_file | sed "s|$field : ||g")
    echo $check
}

function run_test
{
	ruby_test_name=$1
	nb_test_wanted=$2
	must_be_success=$3
	log_manage=$4
	
    rm -rf $current_dir/aixtest/trace.log
    rm -rf $current_dir/aixtest/chef.log
	echo "{\n\"run_list\": [ \"recipe[aixtest::${ruby_test_name}]\" ]\n}\n" > $current_dir/firstrun.json
    if [ ! -z "$log_manage" ]
    then
    	chef-solo -l info -c $current_dir/solo.rb -j $current_dir/firstrun.json 2>&1
        chefres=$?
    else
    	chef-solo -l info --logfile "$current_dir/aixtest/chef.log" -c $current_dir/solo.rb -j $current_dir/firstrun.json 2>&1 > $current_dir/aixtest/trace.log
        chefres=$?
    fi
	if [ $chefres -ne 0 ] # chef exit with error
	then
		res=1 # return error
		[ $must_be_success -eq 0 ] && res=0 # if not be success => success
	else # chef exit with success
		res=0 # return success
		[ $must_be_success -eq 0 ] && res=1 # if not be success => error
	fi 	
	if [ $res -ne 0 ]
	then
		show_error_chef
		let nb_failure+=nb_test_wanted
	fi
	return $res
}

run_option="$1"
[ -z "$run_option" ] && run_option="ABCD"

current_dir=$PWD
if [ ! -d "$current_dir/aix/test/test_suma/recipes" ]
then
    echo "*** tests suma for cookbook aix not found! ***"
    exit 1
fi

export PATH=$current_dir/aix/test/aix_fake:$PATH:/opt/chef/bin
cd $current_dir

[ -z "$(suma -h 2>&1 | grep '++ Suma fake for tests ++')" ] && echo "*** No Fake suma ***" && exit 1

echo "--------- Prepare tests cookbook ---------"
rm -rf $current_dir/aixtest
mkdir -p $current_dir/aixtest
cp -r $current_dir/aix/test/test_suma/recipes $current_dir/aixtest/recipes
echo "name             'aixtest'\ndepends   'aix'\nsupports 'aix', '>= 6.1'\n" > $current_dir/aixtest/metadata.rb
echo "cookbook_path \"$current_dir\"" > $current_dir/solo.rb
echo "ohai.plugin_path << '$current_dir/nim/ohai/plugins/'" >> $current_dir/solo.rb

echo "--------- Run tests recipes ---------"

nb_failure=0
if [ ! -z "$(echo $run_option | grep 'A')" ]
then 
	echo "---- oslevel tests ----"
	rm -rf /tmp/img.source
	run_test "test_oslevel" 9 1
	if [ $? -eq 0 ]
	then
		echo '== aix_suma "11. Downloading SP 7100-02-02" =='
		check_directory '/tmp/img.source/7100-02-02-lpp_source'

		echo '== aix_suma "12. Downloading SP 7100-02-03-1316" =='
		check_directory '/tmp/img.source/7100-02-03-lpp_source'

		echo '== aix_suma "13. Downloading TL 7100-03" =='
		check_directory '/tmp/img.source/7100-03-00-lpp_source'

		echo '== aix_suma "14. Downloading TL 7100-04-00" =='
		check_directory '/tmp/img.source/7100-04-00-lpp_source'

		echo '== aix_suma "15. Downloading TL 7100-05-00-0000" =='
		check_directory '/tmp/img.source/7100-05-00-lpp_source'

		echo '== aix_suma "16. Downloading latest SP for highest TL" =='
		check_directory '/tmp/img.source/latest1/9999-99-99-lpp_source'

		echo '== aix_suma "17. Default property oslevel (latest)" =='
		check_directory '/tmp/img.source/latest2/9999-99-99-lpp_source'

		echo '== aix_suma "18. Empty property oslevel (latest)" =='
		check_directory '/tmp/img.source/latest3/9999-99-99-lpp_source'

#		echo '== aix_suma "19. Unknown property oslevel (ERROR)" =='
#		check_no_directory '/tmp/img.source/xxx-lpp_source'
#		if [ $? -eq 0 ]
#		then
#			error_msg=$(grep 'ERROR: aix_suma' $current_dir/aixtest/chef.log | sed 's|.*had an error: ||g')
#			if [ "$error_msg" != "Chef::Resource::AixSuma::InvalidOsLevelProperty: SUMA-SUMA-SUMA oslevel is not recognized!" ]
#			then
#				show_error_chef
#				echo "error '$error_msg'"
#				let nb_failure+=1
#			fi
#		fi
 
		if [ $nb_failure -ne 0 ]
		then
			show_error_chef
		fi
	fi
fi


echo "--------- Result tests ---------"
if [ $nb_failure -eq 0 ] 
then
	echo "====== SUCCESS ====== "
else
	echo "***** $nb_failure tests in failure *****"
fi

