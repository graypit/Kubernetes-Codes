#!/usr/bin/env bash
#===============================================================================
#
#          FILE:  kube-rbac.sh
#
#         USAGE:  kube-rbac.sh --help
#
#   DESCRIPTION:  Create Role/Rolebinding and K8s Config within certs 
#
#        AUTHOR:  Habib Quliyev (), graypit@gmail.com
#        NUMBER:  +994777415001
#        GITHUB:  https://github.com/graypit 
#      POSITION:  DevOps Engineer
#       VERSION:  1.0
#       CREATED:  12/03/2020 1:25:17 PM +04
#      REVISION:  ---
#===============================================================================
# K8S Global Variables:
CurrentKubeConfig="$HOME/.kube/config"
Version='v1.0'
# K8S Config Yaml Value Names:
CA_Name='certificate-authority'
Cert_Name='client-certificate'
Key_Name='client-key'
# Color Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
function ReadMe() {
    echo -e " ===KUBE-RBAC HELP===
Aviable Flags:
  ${GREEN}create${NC} - Create RBAC Access
  ${GREEN}update${NC} - Update Restriction Level / K8S Role
  ${GREEN}delete${NC} - Delete K8S Role and Role Binding
Aviable Parameters:
  ${GREEN}-u${NC} / ${GREEN}--username${NC} - Set Username for RBAC/Config
  ${GREEN}-n${NC} / ${GREEN}--namespace${NC} - Set K8S Namespace Name for RBAC/Config
  ${GREEN}-r${NC} / ${GREEN}--restriction-level${NC} - Set Restriction Level for RBAC.For details see below
  ${GREEN}-d${NC} / ${GREEN}--deployment${NC} - Set Deployment Name for RBAC/Config
  ${GREEN}-v${NC} / ${GREEN}--version${NC} - Get Script Version
  ${GREEN}-h${NC} / ${GREEN}--help${NC} - Get Script Help
  ${GREEN}--cacert${NC} - Set Path to Kubernetes Admin CA Certificate
  ${GREEN}--cakey${NC} - Set Path to Kubernetes Admin CA Key
Restriction Rules:
  ${GREEN}Restriction Level${NC}: ${RED}0${NC} | Rules: Default Permissions in Namespace
    Explanation: Create Pods/Deployments,List Current Pods/Deployments,Get Logs,Exec Pods
  ${GREEN}Restriction Level${NC}: ${RED}1${NC} | Rules: Only list Deployments and Pods and Get logs from them
Examples:
  Create:
   If you want to access to namespace execute script like below:
   Example: kube-rbac create --username user --namespace my-namespace --restriction-level 0 or 1
   But if you want to access to only namespace's deployment execute script like below:
   Example: kube-rbac create --username user --namespace my-namespace --deployment deploymentname --restriction-level 0 or 1
  Update:
   If you want to update Restriction Level / Role and execute script like below:
   Example: kube-rbac delete --username --namespace my-namespace --restriction-level 1
  Delete:
   If you want to delete Role and Role Binding execute script like below:
   Example: kube-rbac delete --username --namespace my-namespace
Usage:
  ${RED}kube-rbac [flags] [options]${NC}"
    exit 1
}
# Defile Parameters Array:
declare -A Param=(
[Username]="-u|--username"
[Namespace]="-n|--namespace"
[DeploymentName]="-d|--deployment"
[RestrictionLevel]="-r|--restriction-level"
[TaskMode]="create|delete|update"
[Version]="-v|--version"
[Help]="-h|--help"
[Mismatch]="-*|--*"
[CaCert]="--cacert"
[CaKey]="--cakey"
)
# Detect Parameters:
while [[ "$#" -gt 0 ]]
do
    if   [[ "$1" = @(${Param[Username]}) ]];then Username="$2" ; shift 2        
    elif [[ "$1" = @(${Param[Namespace]}) ]];then Namespace="$2" ; shift 2
    elif [[ "$1" = @(${Param[DeploymentName]}) ]];then DeploymentName="$2" ; shift 2        
    elif [[ "$1" = @(${Param[RestrictionLevel]}) ]];then RestrictionLevel="$2" ; shift 2
    elif [[ "$1" = @(${Param[TaskMode]}) ]];then TaskMode="$1" ; shift        
    elif [[ "$1" = @(${Param[Version]}) ]];then echo -e "Version: ${GREEN}$Version${NC}" ; exit
    elif [[ "$1" = @(${Param[CaCert]}) ]];then CaCert="$2" ; shift 2
    elif [[ "$1" = @(${Param[CaKey]}) ]];then CaKey="$2" ; shift 2
    elif [[ "$1" = @(${Param[Help]}) ]];then ReadMe
    elif [[ "$1" = @(${Param[Mismatch]}) ]];then echo -e "${RED}kube-rbac: Unknown flag: $1${NC}" ; exit 1
    else echo -e "${RED}kube-rbac: "\'$1\'" is not a kube-rbac command.\nSee 'kube-rbac --help'${NC}" ; exit 1 ; fi
done
function CheckAndDefineTask() { 
    if [ "$#" -lt 2 ]
    then
        echo 'See kube-rbac --help';exit 1
    elif [ "$#" -eq 3 ]
    then 
        if [[ ! "$RestrictionLevel" = @(0|1) ]];then echo -e "${RED}See kube-rbac --help${NC}";exit 1;fi
    elif [ "$#" -eq 4 ]
    then
        if   [ -z "$DeploymentName" ]; then echo -e "${RED}See kube-rbac --help${NC}";exit 1;fi
    elif [ "$#" -gt 4 ]
    then
        if   [ -z "$CaCert" ]; then echo -e "${RED}See kube-rbac --help${NC}";exit 1;fi
        if   [ -z "$CaKey" ]; then echo -e "${RED}See kube-rbac --help${NC}";exit 1;fi
    fi 
}

function CheckDepends() {
   if [ ! `which kubectl 2>/dev/null` ];then echo -e "${RED}There is no 'kubectl' command found...${NC}" ; exit 1;fi
   if [ ! `which openssl 2>/dev/null` ];then echo -e "${RED}Please install 'openssl' on your system${NC}" ; exit 1;fi
}

function CheckExists () {
    if [ "$(ls ./$Username-Certs 2>/dev/null)" ]
    then 
        echo -e "${RED}User Certs directory is already exist:${NC} ./$Username-Certs"
        if [ "$(ls ./$Username-config 2>/dev/null)" ]
        then 
            echo -e "${RED}K8S User Config file is already exist:${NC} ./$Username-Certs" ; exit 1
        else
            exit 1
        fi
    fi
    if [ ! "$(ls $CaCert 2>/dev/null)" ]
    then
        echo -e "${RED}K8S CA Certificate not found${NC}: $CaCert"
        if [ ! "$(ls $CaKey 2>/dev/null)" ]
        then
            echo -e "${RED}K8S CA Key not found${NC}: $CaCert"
        fi
        exit 1
    fi

}

function CheckTaskMode() {
    if [ "$TaskMode" == 'create' ]
    then 
        CheckExists
        echo -e "Start to $TaskMode RBAC Configuration...\nGenerate K8S Config file for user: $Username"
    elif [ "$TaskMode" == 'delete' ]
    then
        DeleteTask
    elif [ "$TaskMode" == 'update' ]
    then
        UpdateTask        
    fi
    if [ ! -z "$RestrictionLevel" ]; then echo -e "Restriction Level : $RestrictionLevel\nNamespace: $Namespace";fi
    if [ ! -z "$DeploymentName" ]; then echo "On Deployment : $DeploymentName";fi
}

function DetectKubeConfigFile() {
    if [ ! -z "${KUBECONFIG}" ]
    then
        CurrentKubeConfig=${KUBECONFIG}
        CheckExportedConfig='true'
    else
        if [ ! "$(ls $CurrentKubeConfig 2>/dev/null)" ]
        then
            echo -e "${RED}There is no Kubernetes Config file was found${NC}"
            echo -e "${RED}Prepare your Config file and run it again${NC}"
            exit 1
        fi
    fi
    kubeApiUrl=$(kubectl config view|sed 's/<br\ *\/>/\n/g'|grep server|awk '{ print $2 }'|tr -d '\n')
    kubeClusterName=$(cat $CurrentKubeConfig|grep name|head -n1|awk '{ print $2 }')
    echo -e "K8S System Config file: ${GREEN}$CurrentKubeConfig${NC}"
    echo -e "K8S Cluster Name: ${GREEN}$kubeClusterName${NC}"
}

function DetectSslPath() {
    KubeApiServerPod=$(kubectl -n kube-system get po |grep kube-apiserver|awk {'print $1'})
    if [[ -z $CaCert || -z $CaKey ]]
    then
        KubePkiPath=$(kubectl -n kube-system describe po $KubeApiServerPod|grep k8s-certs|head -n1|awk '{ print $1 }')
        if [ ! "$#" -eq 0 ];then echo 'Oops..We did not find Kubernetes CA Certificates Path' && exit 1;fi
    fi
    if [ "$(ls $KubePkiPath 2>/dev/null)" ]
    then
        echo -e "K8S SSL Path: ${GREEN}$KubePkiPath${NC}"
    else
        echo -e "${RED}I could not find K8S SSL Path on your system${NC}"
        exit 1
    fi
}

function PrepareTempArea() {
    TemporaryDir=$(mktemp -d -t rbac-XXXXXXXXXX --tmpdir=`pwd`)
    K8S_CertsDir="$TemporaryDir/K8S-Certs"
    mkdir $K8S_CertsDir $TemporaryDir/$Username-Certs
    if [[ -z $CaCert || -z $CaKey ]]
    then
        cp $KubePkiPath/ca* $K8S_CertsDir/
    else
        cp $CaCert $K8S_CertsDir/ca.crt && cp $CaKey $K8S_CertsDir/ca.key
    fi
    cd $TemporaryDir/$Username-Certs
}

function GenerateRoleAndRoleBinding(){
    ScriptPath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
    echo "Start to Generate and Apply Role And RoleBinding manifest files to K8S"
    if [ -z "$DeploymentName" ]
    then
        cat $ScriptPath/templates/Level_$RestrictionLevel/role.yaml|sed "s#setusername#$Username#g;s#setns#$Namespace#g" |kubectl apply -f -
        cat $ScriptPath/templates/Level_$RestrictionLevel/role-binding.yaml|sed "s#setusername#$Username#g;s#setns#$Namespace#g" |kubectl apply -f -
    else
        cat $ScriptPath/templates/Level_$RestrictionLevel/role.yaml|sed "s#setusername#$Username#g;s#setns#$Namespace#g;s!#resourceNames!resourceNames!g;s#setdeploy#$DeploymentName#g" |kubectl apply -f -
        cat $ScriptPath/templates/Level_$RestrictionLevel/role-binding.yaml|sed "s#setusername#$Username#g;s#setns#$Namespace#g;s!#resourceNames!resourceNames!g;s#setdeploy#$DeploymentName#g" |kubectl apply -f -
    fi
}

function DeleteTask () {
    kubectl -n $Namespace delete role $Username-role
    kubectl -n $Namespace delete rolebinding $Username-rolebinding
    exit
}

function UpdateTask () {
    ScriptPath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
    if [ -z "$DeploymentName" ]
    then
        cat $ScriptPath/templates/Level_$RestrictionLevel/role.yaml|sed "s#setusername#$Username#g;s#setns#$Namespace#g" |kubectl apply -f -
        cat $ScriptPath/templates/Level_$RestrictionLevel/role-binding.yaml|sed "s#setusername#$Username#g;s#setns#$Namespace#g" |kubectl apply -f -
    else
        cat $ScriptPath/templates/Level_$RestrictionLevel/role.yaml|sed "s#setusername#$Username#g;s#setns#$Namespace#g;s!#resourceNames!resourceNames!g;s#setdeploy#$DeploymentName#g" |kubectl apply -f -
        cat $ScriptPath/templates/Level_$RestrictionLevel/role-binding.yaml|sed "s#setusername#$Username#g;s#setns#$Namespace#g;s!#resourceNames!resourceNames!g;s#setdeploy#$DeploymentName#g" |kubectl apply -f -
    fi
    exit
}

function PrepareCertsAndConfigFile() {
    openssl genrsa -out $Username.key 2048 >/dev/null 2>&1
    openssl req -new -key $Username.key -out $Username.csr -subj "/CN=$Username/O=$Username" >/dev/null 2>&1
    openssl x509 -req -in $Username.csr -CA $K8S_CertsDir/ca.crt -CAkey $K8S_CertsDir/ca.key -CAcreateserial -out $Username.crt -days 3650 >/dev/null 2>&1
    if [ ! "$?" -lt 1 ];then echo -e "${RED}Oops..We've some problems with generating certificates${NC}"  && exit 1;fi
    UserConfig="$(pwd)/$Username-config"
    touch $UserConfig && export KUBECONFIG="$UserConfig"
    kubectl config set-context $Username --user $Username --cluster $kubeClusterName  >/dev/null
    kubectl config use-context $Username  >/dev/null
    kubectl config set-credentials $Username --$Cert_Name=$TemporaryDir/$Username-Certs/$Username.crt --$Key_Name=$TemporaryDir/$Username-Certs/$Username.key  >/dev/null
    kubectl config set-cluster $kubeClusterName --$CA_Name=$K8S_CertsDir/ca.crt >/dev/null 2>&1
    kubectl config set-cluster $kubeClusterName --server="tmp-ip"  >/dev/null
    if [ ! "$?" -lt 1 ];then echo -e "${RED}Oops..We've some problems with preparation config file${NC}"  && exit 1;fi
    sed -i "s!tmp-ip!$kubeApiUrl!g" $UserConfig
    unset KUBECONFIG && if [ -z "$CheckExportedConfig" ];then export KUBECONFIG=$CurrentKubeConfig;fi
}

function InjectCertsIntoConfig() {
    ConfigCA=`cat $UserConfig|grep -Po "$CA_Name: \K.*"`
    ConfigCert=`cat $UserConfig|grep -Po "$Cert_Name: \K.*"`
    ConfigCertKey=`cat $UserConfig|grep -Po "$Key_Name: \K.*"`
    sed -i "s!$CA_Name!$CA_Name-data!g" $UserConfig
    sed -i "s!$Cert_Name!$Cert_Name-data!g" $UserConfig
    sed -i "s!$Key_Name!$Key_Name-data!g" $UserConfig
    sed -i "s!$ConfigCA!`cat $K8S_CertsDir/ca.crt|base64|tr -d '\n'`!g" $UserConfig
    sed -i "s!$ConfigCert!`cat $ConfigCert|base64|tr -d '\n'`!g" $UserConfig
    sed -i "s!$ConfigCertKey!`cat $ConfigCertKey|base64|tr -d '\n'`!g" $UserConfig
    cd ../.. && mv $UserConfig . && mv $TemporaryDir/$Username-Certs . && rm -rf $TemporaryDir
    echo -e "Generated Certs files directory: ${GREEN}./$Username-Certs${NC}"
    echo -e "Generated Kubernetes Config file: ${GREEN}./$Username-config${NC}"
    GenerateRoleAndRoleBinding $Username $Namespace $RestrictionLevel $DeploymentName
}

CheckDepends
CheckAndDefineTask $Username $Namespace $RestrictionLevel $DeploymentName $CaCert $CaKey
CheckTaskMode
DetectKubeConfigFile
DetectSslPath
PrepareTempArea
PrepareCertsAndConfigFile
InjectCertsIntoConfig
