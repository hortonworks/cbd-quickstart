BATS=bats
BATSFLAGS=#--tap
BATSRESULTDIR=results/

define run_test
	@echo ::: $(1) :::
	$(BATS) $(BATSFLAGS) $(1) | tee -a $(BATSRESULTDIR)$(notdir $(basename $(1)))-`date +'%Y%m%d-%H%M%S'`.tap
endef

define run_tests_on 
	$(eval CLUSTER_NAME=$(strip $(basename $(basename $(1)))))
	@echo on cluster:: $(CLUSTER_NAME) :: $(2) ::
	$(call run_test,$(2) )
endef	

define run_tests_on_stack 
	$(eval STACK_NAME=$(strip $(basename $(basename $(1)))))
	@echo on stack:: $(STACK_NAME) :: $(2) ::
	$(call run_test,$(2) )
endef	

EPHEMERALCLUSTERS=eph-datasci26-16.clusterdescriptor.bash eph-datasci26-21.clusterdescriptor.bash eph-analytics26.clusterdescriptor.bash eph-edwetl26-16.clusterdescriptor.bash 

STACKDEPLOYER=cloudformation/deploy.bash
SMARTSENSE_DEPLOYER=helper/smartsense-stack-prep.bash
CLUSTERDEPLOYER=createcluster/create-cluster-uni.bats
GET_CLI_UTIL=util/getcli.bash
CLUSTER_FOR_FUNCTIONAL_TEST=edwetl26-21
STACK_FOR_SS_FUNCTIONAL_TEST=autotesting-cli-$(shell date +%a%H%M%S)
STACK_FOR_FUNCTIONAL_TEST=au-basic
export STACK_NAME
export CLUSTER_NAME

#TESTENVIRONMENTS
%.stackdescriptor.bash: 
	$(eval STACK_NAME=$(strip $(basename $(basename $@))))
	@echo stack : $(STACK_NAME)
	$(STACKDEPLOYER) deploy
	$(GET_CLI_UTIL)

hdc: $(STACK_FOR_FUNCTIONAL_TEST).stackdescriptor.bash
	$(eval STACK_NAME=$(strip $(basename $(basename $<))))
	@echo stack : $(STACK_NAME)
	$(GET_CLI_UTIL)

$(EPHEMERALCLUSTERS): datalake26-a.clusterdescriptor.bash
	@echo ephemeral cluster
	$(eval CLUSTER_NAME=$(strip $(basename $(basename $@))))
	$(eval STACK_NAME=au-advanced)
	@echo cluster : $(CLUSTER_NAME)
	#$(CLUSTERDEPLOYER)
	$(call run_test, $(CLUSTERDEPLOYER))

datalake26-a.clusterdescriptor.bash: au-advanced.stackdescriptor.bash
	$(call run_tests_on_stack,$<,sharedservices/register-ldap-jun.bats)
	$(call run_tests_on_stack,$<,sharedservices/register-metastore-initial.bats)
	$(eval CLUSTER_NAME=$(strip $(basename $(basename $@))))
	$(eval STACK_NAME=$(strip $(basename $(basename $<))))
	@echo cluster : $(CLUSTER_NAME)
	#$(CLUSTERDEPLOYER)
	$(call run_test, $(CLUSTERDEPLOYER))


%.clusterdescriptor.bash: $(STACK_FOR_FUNCTIONAL_TEST).stackdescriptor.bash 
	$(eval CLUSTER_NAME=$(strip $(basename $(basename $@))))
	$(eval STACK_NAME=$(strip $(basename $(basename $<))))
	@echo cluster : $(CLUSTER_NAME)
	#$(CLUSTERDEPLOYER)
	$(call run_test, $(CLUSTERDEPLOYER))

%.smartsense_descriptor.bash:
	$(eval STACK_NAME=$(strip $(basename $(basename $@))))
	@echo stack : $(STACK_NAME)
	source ./$(SMARTSENSE_DEPLOYER) && create_ss_controller 'I Have Read and Opt In to SmartSense Telemetry' "A-00000000-C-00000000"
	source ./$(SMARTSENSE_DEPLOYER) && create_stackdescriptor $(STACK_NAME)
	$(GET_CLI_UTIL)

#TESTCASE DEPENDENCIES

sample/sampletest.bats:  $(CLUSTER_FOR_FUNCTIONAL_TEST).clusterdescriptor.bash .FORCE
	$(call run_tests_on,$<,$@)

recovery/%.bats: $(CLUSTER_FOR_FUNCTIONAL_TEST).clusterdescriptor.bash .FORCE
	$(call run_tests_on,$<,$@)

resize/%.bats: $(CLUSTER_FOR_FUNCTIONAL_TEST).clusterdescriptor.bash .FORCE
	$(call run_tests_on,$<,$@)

listclustertypes/%.bats: $(STACK_FOR_FUNCTIONAL_TEST).stackdescriptor.bash .FORCE
	$(call run_tests_on_stack,$<,$@)

controller/%.bats: $(STACK_FOR_FUNCTIONAL_TEST).stackdescriptor.bash .FORCE
	$(call run_tests_on_stack,$<,$@)

cluster-smoke/%.bats: $(CLUSTER_FOR_FUNCTIONAL_TEST).clusterdescriptor.bash .FORCE
	$(call run_tests_on,$<,$@)

terminate_functional: .FORCE
	$(call run_tests_on,$(CLUSTER_FOR_FUNCTIONAL_TEST),terminatecluster/terminate-simple-scenario.bats)

smartsense_functional: .FORCE
	$(call run_test,cloudformation/controller.bats )

flex_functional: $(STACK_FOR_SS_FUNCTIONAL_TEST).smartsense_descriptor.bash .FORCE
	$(call run_tests_on_stack,$<,flex/flex-flow.bats)

flex_less_functional: $(STACK_FOR_FUNCTIONAL_TEST).stackdescriptor.bash .FORCE
	$(call run_tests_on_stack,$<,flex/flex-less-flow.bats)

# makes rule always run
.FORCE:

.PHONY: functional_testset sample_testset recovery_testset imagecatalog_testset clean 

#TESTSETS
smartsense_testset: cloudformation/controller.bats

recovery_testset: recovery/*.bats

resize_testset: resize/*.bats

controller_testset: controller/*.bats

recovery_testset: recovery/*.bats

imagecatalog_testset: imagecatalog/*.bats

blueprints_testset: listclustertypes/*.bats

component_testset: cluster-smoke/*.bats

flex_testset: flex/*.bats

functional_testset: imagecatalog_testset blueprints_testset controller_testset recovery_testset resize_testset component_testset terminate_functional

%_cluster_ts: %.clusterdescriptor.bash
	$(call run_tests_on,$<,cluster-smoke/cluster-component-smoke.bats)
	$(call run_tests_on,$<,terminatecluster/terminate-simple-scenario.bats)

#CLUSTERTYPES ON BASIC CONTROLLER TESTSET
#tries all blueprints
#for parallel running; note - controller must be ready to run par
clustertypes_A_testset: hdc edwetl25-20_cluster_ts edwetl25-16_cluster_ts analytics26_cluster_ts datasci26-16_cluster_ts

clustertypes_B_testset: hdc edwetl26-16_cluster_ts analytics25_cluster_ts datasci25-16_cluster_ts datasci26-21_cluster_ts

ephemeraltypes_testset: eph-edwetl26-16_cluster_ts eph-analytics26_cluster_ts eph-datasci26-16_cluster_ts

clean: terminate_stack delete-cli

terminate_stack: .FORCE
	@echo stack : $(STACK_NAME)
	source ./$(SMARTSENSE_DEPLOYER) && terminate_controller $(STACK_NAME)

delete-cli:
	$(RM) hdc hdc-cli*.tgz

