#!/bin/ksh93

function show_error_chef
{
	echo "********* TEST FAILURE ********"
	cat $current_dir/aixtest/trace.log
	echo "-------------------------------"
	cat $current_dir/aixtest/chef.log
	echo "*******************************"
}

function check_nim
{
    expected_lpp_source=$1
    expected_name=$2
	
	if [ -z "$expected_name" -a -z "$expected_server" ]
	then
		if [ -f "/tmp/img.source/nim.log" ]
		then
		    echo "********* NIM FAILURE ********"
		    cat /tmp/img.source/nim.log
		    echo "******************************"
		    let nb_failure+=1
		fi
	else
		if [ -f "/tmp/img.source/nim.log" ]
		then
		    check_name=$(check_value_log 'name' /tmp/img.source/nim.log)
		    check_lpp_source=$(check_value_log 'lpp_source' /tmp/img.source/nim.log)
		    if [ "$check_name" != "$expected_name" -o "$check_lpp_source" != "$expected_lpp_source" ]
		    then
			    echo "********* NIM FAILURE ********"
		        echo "\texpected lpp_source = '$expected_lpp_source'"
		        echo "\texpected name = '$expected_name'"
		        echo ""
		        echo "\tcheck lpp_source = '$check_lpp_source'"
		        echo "\tcheck name = '$check_name'"
		        echo ""
			    cat /tmp/img.source/nim.log
			    echo "*******************************"
			    let nb_failure+=1
		    fi
		else
		    echo "********* NIM FAILURE (no log file '$lpp_source_dir/nim.log') ********"
		    let nb_failure+=1
		fi
	fi
}

function check_directory
{
	if [ ! -d  "$1" ]
	then
		echo "** lpp_source folder '$1' not created!"
		show_error_chef
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
[ -z "$run_option" ] && run_option="A123"

current_dir=$PWD
if [ ! -d "$current_dir/aix/test/test_suma/recipes" ]
then
    echo "*** tests suma for cookbook aix not found! ***"
    exit 1
fi

export PATH=$current_dir/aix/test/aix_fake:$PATH:/opt/chef/bin
cd $current_dir

[ -z "$(nim -h 2>&1 | grep '++ Nim fake for tests ++')" ] && echo "*** No Fake nim ***" && exit 1

echo "--------- Prepare tests cookbook ---------"
rm -rf $current_dir/aixtest
mkdir -p $current_dir/aixtest
cp -r $current_dir/aix/test/test_nim/recipes $current_dir/aixtest/recipes
echo "name             'aixtest'\ndepends   'aix'\nsupports 'aix', '>= 6.1'\n" > $current_dir/aixtest/metadata.rb
echo "cookbook_path \"$current_dir\"" > $current_dir/solo.rb
echo "ohai.plugin_path << '$current_dir/nim/ohai/plugins/'" >> $current_dir/solo.rb

echo "--------- Run tests recipes ---------"

nb_failure=0
if [ ! -z "$(echo $run_option | grep 'A')" ]
then 
	echo "---- Nominal tests ----"
	rm -rf /tmp/img.source
	mkdir -p /tmp/img.source/7100-09-04-lpp_source
	suma -x -a RqName=7100-09-04 -a RqType=SP -a Action=Download -a DLTarget=/tmp/img.source/7100-09-04-lpp_source -a FilterML=7100-09 > /dev/null
	run_test "test_simple" 2 1
	if [ $? -eq 0 ]
	then
		echo '== aix_nim "Updating 2 clients => SP 7100-09-04" =='
		echo '== aix_nim "no updating (lpp not exist) => TL 7100-11" =='
	    check_nim "7100-09-04-lpp_source" 'client1 client2'
		nbfixes=$(grep -c 'Install fixes...' "${current_dir}/aixtest/chef.log")
		if [ $nbfixes -ne 1 ]
		then
			echo "** not correct fixes number $nbfixes<>1 "
			show_error_chef
			let nb_failure+=1
		fi
	fi
fi

echo "---- Error and exception tests ----"
rm -rf /tmp/img.source
mkdir -p /tmp/img.source/7100-09-04-lpp_source
suma -x -a RqName=7100-09-04 -a RqType=SP -a Action=Download -a DLTarget=/tmp/img.source/7100-09-04-lpp_source -a FilterML=7100-09 > /dev/null
if [ ! -z "$(echo $run_option | grep '1')" ]
then 
	echo '== aix_nim "Updating client unknown" =='
	run_test "test_error_1" 1 0
	if [ $? -eq 0 ]
	then
		if [ -f '/tmp/img.source/nim.log' ]
		then
			show_error_chef
			check_nim
		else
			error_msg=$(grep 'ERROR: aix_nim' $current_dir/aixtest/chef.log | sed 's|.*had an error: ||g')
			if [ "$error_msg" != "RuntimeError: NIM-NIM-NIM no client targets specified!" ]
			then
				show_error_chef
				echo "error '$error_msg'"
				let nb_failure+=1
			fi
		fi 
	fi
fi
if [ ! -z "$(echo $run_option | grep '2')" ]
then 
	echo '== aix_nim "Updating but failure" =='
	run_test "test_error_2" 1 0
	if [ $? -eq 0 ]
	then
		if [ -f '/tmp/img.source/nim.log' ]
		then
			show_error_chef
			check_nim
		else
			error_msg=$(grep 'ERROR: aix_nim' $current_dir/aixtest/chef.log | sed 's|.*had an error: ||g')
			if [ "$error_msg" != "Mixlib::ShellOut::ShellCommandFailed: Expected process to exit with [0], but received '1'" ]
			then
				show_error_chef
				echo "error '$error_msg'"
				let nb_failure+=1
			fi
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

