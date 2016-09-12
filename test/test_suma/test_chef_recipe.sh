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
    if [ "$expected_action" == "error" ]
    then
    	if [ ! -f "$lpp_source/suma.error" ]
    	then
		    echo "********* SUMA FAILURE ********"
	        echo "	no error"
		    echo "*******************************"
		    let nb_failure+=1
	    	return 1
    	fi
    else
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

function check_error_chef_log
{
	excepted_error=$1
	secondary_error=$2
	error_msg=$(grep 'ERROR: aix_suma' $current_dir/aixtest/chef.log | sed 's|.*had an error: ||g')
	if [ "$error_msg" != "$excepted_error" ]
	then
		echo "error '$error_msg'"
		let nb_failure+=1
		return 1
	else
		if [ ! -z "$secondary_error" ]
		then
			error_msg=$(grep "$secondary_error" $current_dir/aixtest/chef.log)
			if [ -z "$error_msg" ]
			then
				let nb_failure+=1
				return 1
			fi
		fi
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
	run_test "test_oslevel" 8 1
	if [ $? -eq 0 ]
	then
		echo '== aix_suma "11. Downloading SP 7100-02-02" =='
		check_directory '/tmp/img.source/7100-02-02-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/7100-02-02-lpp_source "Preview Download" "SP SP" "7100-02 7100-02" "7100-02-02 7100-02-02"
		fi

		echo '== aix_suma "12. Downloading SP 7100-02-03-1316" =='
		check_directory '/tmp/img.source/7100-02-03-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/7100-02-03-lpp_source "Preview Download" "SP SP" "7100-02 7100-02" "7100-02-03 7100-02-03"
		fi

		echo '== aix_suma "13. Downloading TL 7100-03" =='
		check_directory '/tmp/img.source/7100-03-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/7100-03-lpp_source "Preview Download" "TL TL" "7100-02 7100-02" "7100-03 7100-03"
		fi

		echo '== aix_suma "14. Downloading TL 7100-04-00" =='
		check_directory '/tmp/img.source/7100-04-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/7100-04-lpp_source "Preview Download" "TL TL" "7100-02 7100-02" "7100-04 7100-04"
		fi

		echo '== aix_suma "15. Downloading TL 7100-05-00-0000" =='
		check_directory '/tmp/img.source/7100-05-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/7100-05-lpp_source "Preview Download" "TL TL" "7100-02 7100-02" "7100-05 7100-05"
		fi

		echo '== aix_suma "16. Downloading latest SP for highest TL" =='
		check_directory '/tmp/img.source/latest1/7100-02-08-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/latest1/7100-02-08-lpp_source "Preview Download" "Latest Latest" "7100-02 7100-02" ""
		fi

		echo '== aix_suma "17. Default property oslevel (latest)" =='
		check_directory '/tmp/img.source/latest2/7100-02-08-lpp_source'
		if [ $? -eq 0 ]
		then
			check_suma /tmp/img.source/latest2/7100-02-08-lpp_source "Preview Download" "Latest Latest" "7100-02 7100-02" ""
		fi

		echo '== aix_suma "18. Empty property oslevel (latest)" =='
		check_directory '/tmp/img.source/latest3/7100-02-08-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/latest3/7100-02-08-lpp_source "Preview Download" "Latest Latest" "7100-02 7100-02" ""
		fi

		if [ $nb_failure -ne 0 ]
		then
			show_error_chef
		fi
	fi
	
	echo '== aix_suma "19. Unknown property oslevel (ERROR)" =='
	run_test "test_oslevel_error_unknown" 1 0
	if [ $? -eq 0 ]
	then
		check_no_directory '/tmp/img.source/xxx-lpp_source'
		if [ $? -eq 0 ]
		then
			check_error_chef_log "Chef::Resource::AixSuma::InvalidOsLevelProperty: SUMA-SUMA-SUMA oslevel is not recognized!"
			if [ $? -ne 0 ]
			then
				show_error_chef
			fi 
		fi 
	fi
	echo '== aix_suma "19b. latest SP for TL unknown (ERROR metadata 0500-035)" =='
	run_test "test_oslevel_error_metadata" 1 0
	if [ $? -eq 0 ]
	then
		check_no_directory '/tmp/img.source/latest3/7100-02-08-lpp_source'
		if [ $? -eq 0 ]
		then
			check_error_chef_log "Chef::Resource::AixSuma::SumaMetadataError: SUMA-SUMA-SUMA suma metadata returns 1!" 
			if [ $? -ne 0 ]
			then
				show_error_chef
			fi 
		fi 
	fi
fi

if [ ! -z "$(echo $run_option | grep 'B')" ]
then
	echo "---- location tests ----"
	rm -rf /tmp/img.source
	rm -rf /usr/sys/inst.images
	run_test "test_location" 4 1
	if [ $? -eq 0 ]
	then
		old_failure=$nb_failure

		echo '== aix_suma "21. Existing directory (absolute path)" =='
		check_directory '/tmp/img.source/21/7100-02-02-lpp_source'

		echo '== aix_suma "23. Default property location (/usr/sys/inst.images)" =='
		check_directory '/usr/sys/inst.images/7100-02-02-lpp_source'

		echo '== aix_suma "24. Empty property location (/usr/sys/inst.images)" =='
		check_directory '/usr/sys/inst.images/7100-02-03-lpp_source'

		echo '== aix_suma "27. Provide existing lpp source as location" =='
		check_directory '/usr/sys/inst.images/beautifull'

		if [ $nb_failure -ne $old_failure ]
		then
			show_error_chef
		fi
	fi
	echo '== aix_suma "26. Existing lpp source but different location (ERROR)" =='
	run_test "test_location_error_diff_lpp_loc" 1 0
	if [ $? -eq 0 ]
	then
		check_no_directory '/tmp/img.source/26/7100-02-03-lpp_source'
		if [ $? -eq 0 ]
		then
			check_error_chef_log "Chef::Resource::AixSuma::InvalidLocationProperty: SUMA-SUMA-SUMA lpp source location mismatch"
			if [ $? -ne 0 ]
			then
				show_error_chef
			fi 
		fi 
	fi
	echo '== aix_suma "28. Provide unknown lpp source as location (ERROR)" =='
	run_test "test_location_error_unknown_lpp" 1 0
	if [ $? -eq 0 ]
	then
		check_error_chef_log "Chef::Resource::AixSuma::InvalidLocationProperty: SUMA-SUMA-SUMA cannot find lpp_source 'unknown_lpp-source' into Ohai output"
		if [ $? -ne 0 ]
		then
			show_error_chef
		fi 
	fi
fi

if [ ! -z "$(echo $run_option | grep 'C')" ]
then 
	echo "---- targets tests ----"
	rm -rf /tmp/img.source
	run_test "test_targets" 4 1
	if [ $? -eq 0 ]
	then
		old_failure=$nb_failure

		echo '== aix_suma "31. Valid client list with wildcard" =='
		check_directory '/tmp/img.source/31/7100-02-02-lpp_source'

		echo '== aix_suma "32. Mostly valid client list" =='
		check_directory '/tmp/img.source/32/7100-02-02-lpp_source'

		echo '== aix_suma "34. Default property targets (all nim clients)" =='
		check_directory '/tmp/img.source/34/7100-02-02-lpp_source'

		echo '== aix_suma "35. Empty property targets (all nim clients)" =='
		check_directory '/tmp/img.source/35/7100-02-02-lpp_source'

		if [ $nb_failure -ne $old_failure ]
		then
			show_error_chef
		fi
	fi
	echo '== aix_suma "33. Invalid client list (ERROR)" =='
	run_test "test_targets_error_invalid" 1 0
	if [ $? -eq 0 ]
	then
		check_no_directory '/tmp/img.source/33/7100-02-02-lpp_source'
		if [ $? -eq 0 ]
		then
			check_error_chef_log "Chef::Resource::AixSuma::InvalidTargetsProperty: SUMA-SUMA-SUMA cannot reach any clients!"
			if [ $? -ne 0 ]
			then
				show_error_chef
			fi 
		fi 
	fi
fi

if [ ! -z "$(echo $run_option | grep 'D')" ]
then 
	echo "---- suma tests ----"
	rm -rf /tmp/img.source
	mkdir -p /tmp/img.source/46/7100-02-02-lpp_source
	suma -x -a RqName=7100-02-02 -a RqType=SP -a Action=Download -a DLTarget=/tmp/img.source/46/7100-02-02-lpp_source -a FilterML=7100-02 > /dev/null
	rm "/tmp/img.source/46/7100-02-02-lpp_source/suma.log"		
	run_test "test_suma" 5 1
	if [ $? -eq 0 ]
	then
		old_failure=$nb_failure
		
		echo '== aix_suma "45. error no fixes 0500-035 (Preview only)" =='
		check_directory '/tmp/img.source/45/7100-02-02-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/45/7100-02-02-lpp_source "error"
			if [ $? -eq 0 ]
			then
		        check_nim /tmp/img.source/45/7100-02-02-lpp_source "" '' 
			fi 
		fi

		echo '== aix_suma "46. nothing to download (Preview only)" =='
		check_directory '/tmp/img.source/46/7100-02-02-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/46/7100-02-02-lpp_source "Preview" "SP" "7100-02" "7100-02-02"
			if [ $? -eq 0 ]
			then
		        check_nim /tmp/img.source/46/7100-02-02-lpp_source "" '' 
			fi 
		fi

		echo '== aix_suma "47. failed fixes (Preview + Download)" =='
		check_directory '/tmp/img.source/47/7100-02-02-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/47/7100-02-02-lpp_source "Preview Download" "SP SP" "7100-02 7100-02" "7100-02-02 7100-02-02"
			if [ $? -eq 0 ]
			then
		        check_nim /tmp/img.source/47/7100-02-02-lpp_source "" '' 
			fi 
		fi

		echo '== aix_suma "48. lpp source exists (Preview + Download)" =='
		check_directory '/tmp/img.source/48/7100-02-02-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/48/7100-02-02-lpp_source "Preview Download" "SP SP" "7100-02 7100-02" "7100-02-02 7100-02-02"
			if [ $? -eq 0 ]
			then
		        check_nim /tmp/img.source/48/7100-02-02-lpp_source "" '' 
			fi 
		fi

		echo '== aix_suma "49. lpp source absent (Preview + Download + Define)" =='
		check_directory '/tmp/img.source/49/7100-02-02-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/49/7100-02-02-lpp_source "Preview Download" "SP SP" "7100-02 7100-02" "7100-02-02 7100-02-02"
			if [ $? -eq 0 ]
			then
		        check_nim /tmp/img.source/49/7100-02-02-lpp_source "7100-02-02-lpp_source" 'master' 
			fi 
		fi
		
		if [ $nb_failure -ne $old_failure ]
		then
			show_error_chef
		fi
	fi
	echo '== aix_suma "41. error no more space 0500-004 (Download ERROR)" =='
	run_test "test_suma_error_no_space" 1 0
	if [ $? -eq 0 ]
	then
		check_directory '/tmp/img.source/41/7100-02-02-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/41/7100-02-02-lpp_source "Preview" "SP" "7100-02" "7100-02-02"
			if [ $? -eq 0 ]
			then
				check_error_chef_log "Mixlib::ShellOut::ShellCommandFailed: Expected process to exit with [0], but received '1'" "0500-004 no more space."
				if [ $? -ne 0 ]
				then
					show_error_chef
				fi 
			fi 
		fi 
	fi

	echo '== aix_suma "42. error network 0500-013 (Preview ERROR)" =='
	run_test "test_suma_error_network" 1 0
	if [ $? -eq 0 ]
	then
		check_directory '/tmp/img.source/42/7100-02-02-lpp_source'
		if [ $? -eq 0 ]
		then
			check_error_chef_log "Chef::Resource::AixSuma::SumaPreviewError: SUMA-SUMA-SUMA error:" "0500-013 Failed to retrieve list from fix server."
			if [ $? -ne 0 ]
			then
				show_error_chef
			fi 
		fi 
	fi

	echo '== aix_suma "43. error entitlement 0500-059 (Preview ERROR)" =='
	run_test "test_suma_error_entitlement" 1 0
	if [ $? -eq 0 ]
	then
		check_directory '/tmp/img.source/43/7100-02-02-lpp_source'
		if [ $? -eq 0 ]
		then
			check_error_chef_log "Chef::Resource::AixSuma::SumaPreviewError: SUMA-SUMA-SUMA error:" "0500-059 Entitlement is required to download. The system's serial number is not entitled. Please go to the Fix Central website to download fixes."
			if [ $? -ne 0 ]
			then
				show_error_chef
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

