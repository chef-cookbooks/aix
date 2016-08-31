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
		else
		    echo "********* NIM FAILURE (no log file '$lpp_source/nim.log') ********"
		    let nb_failure+=1
		fi
	fi
}


function check_directory
{
	if [ ! -d  "$1" ]
	then
		echo "** lpp_source folder '$1' not created!"
		#show_error_chef
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
[ -z "$run_option" ] && run_option="ABC1234567"

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
	echo "---- Nominal tests ----"
	rm -rf /tmp/img.source
	run_test "test_simple" 4 1
	if [ $? -eq 0 ]
	then
		echo '== aix_suma "Downloading SP 7100-09 >> 7100-09-02" =='
		check_directory '/tmp/img.source/7100-09-02-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/7100-09-02-lpp_source "Preview Download" "SP SP" "7100-09 7100-09" "7100-09-02 7100-09-02"
			if [ $? -eq 0 ]
			then
		        check_nim /tmp/img.source/7100-09-02-lpp_source "7100-09-02-lpp_source" 'master' 
			fi 
		fi 
	
		echo '== aix_suma "Downloading TL+SP 7100-09 >> 7100-10-02" =='
		check_directory '/tmp/img.source/7100-10-02-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/7100-10-02-lpp_source "Preview Download" "SP SP" "7100-09 7100-09" "7100-10-02 7100-10-02"
			if [ $? -eq 0 ]
			then
		        check_nim /tmp/img.source/7100-10-02-lpp_source "7100-10-02-lpp_source" 'master' 
			fi 
		fi 
	
		echo '== aix_suma "nothing 7100-10 >> 7100-09-03" =='
		check_directory '/tmp/img.source/7100-09-03-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/7100-09-03-lpp_source "Preview" "SP" "7100-10" "7100-09-03"
			if [ $? -eq 0 ]
			then
		        check_nim /tmp/img.source/7100-09-03-lpp_source "" '' 
			fi 
		fi 
	
		echo '== aix_suma "Downloading multi-clients TL+SP 7100-08 >> 7100-10-04" =='
		check_directory '/tmp/img.source/7100-10-04-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/7100-10-04-lpp_source "Preview Download" "SP SP" "7100-08 7100-08" "7100-10-04 7100-10-04"
			if [ $? -eq 0 ]
			then
		        check_nim /tmp/img.source/7100-10-04-lpp_source "7100-10-04-lpp_source" 'master' 
			fi 
		fi 
	fi
fi

if [ ! -z "$(echo $run_option | grep 'B')" ]
then 
	echo "---- Complex tests ----"
	rm -rf /tmp/img.source
	rm -rf /usr/sys/inst.images
	mkdir -p /tmp/img.source/7100-09-05-lpp_source
	suma -x -a RqName=7100-09-05 -a RqType=SP -a Action=Download -a DLTarget=/tmp/img.source/7100-09-05-lpp_source -a FilterML=7100-09 > /dev/null
	rm -f /tmp/img.source/7100-09-05-lpp_source/suma.*
	run_test "test_complex" 6 1
	if [ $? -eq 0 ]
	then
		echo '== aix_suma "Want to download but up-to-date" =='
		check_directory '/tmp/img.source/7100-09-02-lpp_source'
		if [ $? -eq 0 ]
		then
	        if [ -f '/tmp/img.source/7100-09-02-lpp_source/suma.error' ]
	        then
	            val=$(grep '0500-' /tmp/img.source/7100-09-02-lpp_source/suma.error)
	            if [ "$val" != "0500-035 No fixes match your query." ]
	            then
		            echo "********* BAD SUMA ERROR ********"
		            cat /tmp/img.source/7100-09-02-lpp_source/suma.error
		            echo "*********************************"
		            echo "$val"
		            echo "*********************************"
		            let nb_failure+=1
	            fi
	        else
		        echo "********* SUMA FAILURE ********"
		        cat /tmp/img.source/7100-09-02-lpp_source/suma.log
		        echo "*******************************"
		        let nb_failure+=1
	        fi
		fi
		
		echo '== aix_suma "Downloading TL 7100-09 >> 7100-10" =='
		check_directory '/usr/sys/inst.images/7100-10-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /usr/sys/inst.images/7100-10-lpp_source "Preview Download" "TL TL" "7100-09 7100-09" "7100-10 7100-10"
			if [ $? -eq 0 ]
			then
		        check_nim /usr/sys/inst.images/7100-10-lpp_source "7100-10-lpp_source" 'master' 
			fi 
		fi
	
		echo '== aix_suma "Downloading TL 7100-09 >> 7100-11" =='
		check_directory '/tmp/img.source/7100-11-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/7100-11-lpp_source "Preview Download" "TL TL" "7100-09 7100-09" "7100-11 7100-11"
			if [ $? -eq 0 ]
			then
		        check_nim /tmp/img.source/7100-11-lpp_source "7100-11-lpp_source" 'master' 
			fi 
		fi
	
		echo '== aix_suma "Downloading Latest 7100-09" =='
		check_directory '/tmp/img.source/9999-99-99-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/9999-99-99-lpp_source "Preview Download" "Latest Latest" "7100-09 7100-09" ""
			if [ $? -eq 0 ]
			then
		        check_nim /tmp/img.source/9999-99-99-lpp_source "9999-99-99-lpp_source" 'master' 
			fi 
		fi
	
		echo '== aix_suma "Only preview (already download) 7100-09 >> 7100-09-05" =='
		check_directory '/tmp/img.source/7100-09-05-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/7100-09-05-lpp_source "Preview" "SP" "7100-09" "7100-09-05"
			if [ $? -eq 0 ]
			then
		        check_nim /tmp/img.source/7100-09-05-lpp_source "" '' 
			fi 
		fi

		echo '== aix_suma "Downloading SP 7100-09 >> 7100-09-03 with failure" =='
		check_directory '/tmp/img.source/7100-09-03-lpp_source'
		if [ $? -eq 0 ]
		then
	        check_suma /tmp/img.source/7100-09-03-lpp_source "Preview Download" "SP SP" "7100-09 7100-09" "7100-09-03 7100-09-03"
			if [ $? -eq 0 ]
			then
		        check_nim /tmp/img.source/7100-09-03-lpp_source "" '' 
			fi 
		fi
		 
	fi
fi

if [ ! -z "$(echo $run_option | grep 'C')" ]
then 
	echo "---- Error and exception tests ----"
	rm -rf /tmp/img.source
	if [ ! -z "$(echo $run_option | grep '1')" ]
	then 
		echo '== aix_suma "error network (BSO) for test" =='
		run_test "test_error_1" 1 0
		if [ $? -eq 0 ]
		then
			check_directory '/tmp/img.source/7100-09-02-lpp_source'
			if [ $? -eq 0 ]
			then
				error_msg1=$(grep 'ERROR: aix_suma' $current_dir/aixtest/chef.log | sed 's|.*had an error: ||g')
				error_msg2=$(grep 'CWPKI0022E' $current_dir/aixtest/chef.log | sed 's| A signer with SubjectDN.*||g')
				error_msg3=$(grep 'CWPKI0040I' $current_dir/aixtest/chef.log | sed "s| The server's SSL.*||g")
				error_msg4=$(grep '0500-013' $current_dir/aixtest/chef.log)
				if [ "$error_msg1" != "RuntimeError: Suma error:" -o "$error_msg2" != "CWPKI0022E: SSL HANDSHAKE FAILURE:" -o "$error_msg3" != "CWPKI0040I: An SSL handshake failure occurred from a secure client." -o "$error_msg4" != "0500-013 Failed to retrieve list from fix server." ]
				then
					show_error_chef
					echo "error1 '$error_msg1'"
					echo "error2 '$error_msg2'"
					echo "error3 '$error_msg3'"
					echo "error4 '$error_msg4'"
					let nb_failure+=1
				fi
				# suma return "
				#			   CWPKI0022E: SSL HANDSHAKE FAILURE:  A signer with SubjectDN "CN=ASA Temporary Self Signed Certificate" was sent from target host:port "esupport.ibm.com:443".  The signer may need to be added to local trust store  "/var/ecc/data/TrustList.jks" located in SSL configuration alias "null" loaded from SSL configuration file "null".  The extended error message from the SSL handshake exception is: "PKIX path building failed: java.security.cert.CertPathBuilderException: unable to find valid certification path to requested target".
				#
				#			   CWPKI0040I: An SSL handshake failure occurred from a secure client.  The server's SSL signer has to be added to the client's trust store.  A retrieveSigners utility is provided to download signers from the server but requires administrative permission.  Check with your administrator to have this utility run to setup the secure environment before running the client.  Alternatively, the com.ibm.ssl.enableSignerExchangePrompt can be enabled in ssl.client.props for "DefaultSSLSettings" in order to allow acceptance of the signer during the connection attempt.
				#			   0500-013 Failed to retrieve list from fix server.
				#			  "
			fi 
		fi
	fi
	if [ ! -z "$(echo $run_option | grep '2')" ]
	then 
		echo '== aix_suma "error network for test" =='
		run_test "test_error_2" 1 0
		if [ $? -eq 0 ]
		then
			check_directory '/tmp/img.source/7100-09-01-lpp_source'
			if [ $? -eq 0 ]
			then
				error_msg=$(grep '0500-013' $current_dir/aixtest/chef.log)
				if [ "$error_msg" != "0500-013 Failed to retrieve list from fix server." ]
				then
					show_error_chef
					echo "error '$error_msg'"
					let nb_failure+=1
				fi
				# suma return "0500-013 Failed to retrieve list from fix server."
			fi 
		fi
	fi
	if [ ! -z "$(echo $run_option | grep '3')" ]
	then 
		echo '== aix_suma "Suma configuration: not entitled" =='
		run_test "test_error_3" 1 0
		if [ $? -eq 0 ]
		then
			check_directory '/tmp/img.source/7100-09-05-lpp_source'
			if [ $? -eq 0 ]
			then
				error_msg=$(grep '0500-059' $current_dir/aixtest/chef.log)
				if [ "$error_msg" != "0500-059 Entitlement is required to download. The system's serial number is not entitled. Please go to the Fix Central website to download fixes." ]
				then
					show_error_chef
					echo "error '$error_msg'"
					let nb_failure+=1
				fi
				# suma return "0500-059 Entitlement is required to download.
				#			   The system's serial number is not entitled.
				#			   Please go to the Fix Central website to download fixes."
			fi 
		fi
	fi	
	if [ ! -z "$(echo $run_option | grep '4')" ]
	then 
		echo '== aix_suma "Suma with client unknown" =='
		run_test "test_error_4" 1 0
		if [ $? -eq 0 ]
		then
			if [ -d '/tmp/img.source/7100-09-03-lpp_source' ]
			then
				echo "** lpp_source folder '/tmp/img.source/7100-09-03-lpp_source' are created!"
				show_error_chef
				let nb_failure+=1
			else
				error_msg=$(grep 'ERROR: aix_suma' $current_dir/aixtest/chef.log | sed 's|.*had an error: ||g')
				if [ "$error_msg" != "RuntimeError: SUMA-SUMA-SUMA no client targets specified or cannot reach them!" ]
				then
					show_error_chef
					echo "error '$error_msg'"
					let nb_failure+=1
				fi
			fi 
		fi
	fi
	if [ ! -z "$(echo $run_option | grep '5')" ]
	then 
		echo '== aix_suma "Suma with oslevel wrong" =='
		run_test "test_error_5" 1 0
		if [ $? -eq 0 ]
		then
			if [ -d '/tmp/img.source/7100-09-03-lpp_source' ]
			then
				echo "** lpp_source folder '/tmp/img.source/7100-09-03-lpp_source' are created!"
				show_error_chef
				let nb_failure+=1
			else
				error_msg=$(grep 'ERROR: aix_suma' $current_dir/aixtest/chef.log | sed 's|.*had an error: ||g')
				if [ "$error_msg" != "RuntimeError: SUMA-SUMA-SUMA oslevel is not recognized!" ]
				then
					show_error_chef
					echo "error '$error_msg'"
					let nb_failure+=1
				fi
			fi 
		fi
	fi
	if [ ! -z "$(echo $run_option | grep '6')" ]
	then 
		echo '== aix_suma "Suma with target empty" do" =='
		run_test "test_error_6" 1 0
		if [ $? -eq 0 ]
		then
			if [ -d '/tmp/img.source/7100-10-00-lpp_source' ]
			then
				echo "** lpp_source folder '/tmp/img.source/7100-10-00-lpp_source' are created!"
				show_error_chef
				let nb_failure+=1
			else
				error_msg=$(grep 'ERROR: aix_suma' $current_dir/aixtest/chef.log | sed 's|.*had an error: ||g')
				if [ "$error_msg" != "RuntimeError: SUMA-SUMA-SUMA no client targets specified or cannot reach them!" ]
				then
					show_error_chef
					echo "error '$error_msg'"
					let nb_failure+=1
				fi
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

