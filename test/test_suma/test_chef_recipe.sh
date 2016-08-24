#!/bin/sh

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

    check_action=$(check_value_log 'Action' $lpp_source)
    check_origin=$(check_value_log 'FilterML' $lpp_source)
    check_type=$(check_value_log 'RqType' $lpp_source)
    check_target=$(check_value_log 'RqName' $lpp_source)
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
    lpp_source=$2
    check=$(grep "$field" $lpp_source/suma.log | sed "s|$field : ||g")
    echo $check
}

function run_test
{
	ruby_test_name=$1
	nb_test_wanted=$2
	must_be_success=$3
	log_manage=$4
	
	rm -rf /tmp/img.source
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
	if [ $chefres -ne 0 ]
	then
		res=1
		[ $must_be_success -eq 1 ] && res=0
	else
		res=0
		[ $must_be_success -eq 0 ] && res=1
	fi 	
	if [ $res -ne 0 ]
	then
		show_error_chef
		let nb_failure+=nb_test_wanted
	fi
	return $res
}

run_option="$1"

current_dir=$PWD
if [ ! -d "$current_dir/aix/test/test_suma/recipes" ]
then
    echo "*** tests suma for cookbook aix not found! ***"
    exit 1
fi

export PATH=$current_dir/aix/test/test_suma:$PATH:/opt/chef/bin
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

echo "---- Nominal tests ----"

run_test "test_simple" 4 1
if [ $? -eq 0 ]
then
	echo '== aix_suma "Downloading TL 7100-09-00 >> 7100-09-02" =='
	check_directory '/tmp/img.source/7100-09-02-lpp_source'
	if [ $? -eq 0 ]
	then
        check_suma /tmp/img.source/7100-09-02-lpp_source "Preview Download" "SP SP" "7100-09-00 7100-09-00" "7100-09-02 7100-09-02"
	fi 

	echo '== aix_suma "Downloading SP 7100-09-00 >> 7100-10-00" =='
	check_directory '/tmp/img.source/7100-10-00-lpp_source'
	if [ $? -eq 0 ]
	then
        check_suma /tmp/img.source/7100-10-00-lpp_source "Preview Download" "SP SP" "7100-09-00 7100-09-00" "7100-10-00 7100-10-00"
	fi 

	echo '== aix_suma "nothing 7100-10-05 >> 7100-09-03" =='
	check_directory '/tmp/img.source/7100-09-03-lpp_source'
	if [ $? -eq 0 ]
	then
        check_suma /tmp/img.source/7100-09-03-lpp_source "Preview" "SP" "7100-10-05" "7100-09-03"
	fi 

	echo '== aix_suma "Downloading LT/SP 7100-08-04 >> 7100-10-04" =='
	check_directory '/tmp/img.source/7100-10-04-lpp_source'
	if [ $? -eq 0 ]
	then
        check_suma /tmp/img.source/7100-10-04-lpp_source "Preview Download" "SP SP" "7100-08-04 7100-08-04" "7100-10-04 7100-10-04"
	fi 
fi

run_test "test_complex" 4 1
if [ $? -eq 0 ]
then
	echo '== aix_suma "Want to download but up-to-date" =='
	check_directory '/tmp/img.source/7100-09-02-lpp_source'
	if [ $? -eq 0 ]
	then
        if [ -f '/tmp/img.source/7100-09-02-lpp_source/suma.error' ]
        then
            val=$(cat /tmp/img.source/7100-09-02-lpp_source/suma.error)
            if [ "$val" != "0500-035 No fixes match your query." ]
            then
	            echo "********* BAD SUMA ERROR ********"
	            cat $lpp_source/suma.error
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
fi

echo "---- Error and exception tests ----"

run_test "test_error_1" 1 0
if [ $? -eq 0 ]
then
	echo '== aix_suma "error network (BSO) for test" =='
	check_directory '/tmp/img.source/7100-09-02-lpp_source'
	if [ $? -eq 0 ]
	then
		# suma return "
		#			   CWPKI0022E: SSL HANDSHAKE FAILURE:  A signer with SubjectDN "CN=ASA Temporary Self Signed Certificate" was sent from target host:port "esupport.ibm.com:443".  The signer may need to be added to local trust store  "/var/ecc/data/TrustList.jks" located in SSL configuration alias "null" loaded from SSL configuration file "null".  The extended error message from the SSL handshake exception is: "PKIX path building failed: java.security.cert.CertPathBuilderException: unable to find valid certification path to requested target".
		#
		#			   CWPKI0040I: An SSL handshake failure occurred from a secure client.  The server's SSL signer has to be added to the client's trust store.  A retrieveSigners utility is provided to download signers from the server but requires administrative permission.  Check with your administrator to have this utility run to setup the secure environment before running the client.  Alternatively, the com.ibm.ssl.enableSignerExchangePrompt can be enabled in ssl.client.props for "DefaultSSLSettings" in order to allow acceptance of the signer during the connection attempt.
		#			   0500-013 Failed to retrieve list from fix server.
		#			  "
		echo ""
	fi 
fi

run_test "test_error_2" 1 0
if [ $? -eq 0 ]
then
	echo '== aix_suma "error network for test" =='
	check_directory '/tmp/img.source/7100-09-02-lpp_source'
	if [ $? -eq 0 ]
	then
		# suma return "0500-013 Failed to retrieve list from fix server."
		echo ""
	fi 
fi

run_test "test_error_3" 1 0
if [ $? -eq 0 ]
then
	echo '== aix_suma "Suma configuration: not entitled" =='
	check_directory '/tmp/img.source/7100-09-02-lpp_source'
	if [ $? -eq 0 ]
	then
		echo ""
	fi 
fi

echo "--------- Result tests ---------"
if [ $nb_failure -eq 0 ] 
then
	echo "====== SUCCESS ====== "
else
	echo "***** $nb_failure tests in failure *****"
fi

