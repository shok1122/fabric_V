#!/bin/bash

. assets/orgs.info

ORDERER=$FABRIC_CORE_PEER_ADDRESS_ORDERER
CAFILE=$FABRIC_CORE_PEER_TLS_ROOTCERT_FILE_ORDERER
CHANNEL_NAME=$FABRIC_CHANNEL_NAME
ORG_NUM_LIST=$FABRIC_ORG_NUM
PEER_NUM_LIST=$FABRIC_PEER_NUM

help()
{
    echo "This is helps."
}

log()
{
    echo "*** $1"
    echo "*** - $CORE_PEER_LOCALMSPID"
    echo "*** - $CORE_PEER_TLS_ROOTCERT_FILE"
    echo "*** - $CORE_PEER_MSPCONFIGPATH"
    echo "*** - $CORE_PEER_ADDRESS"
}

set_globals()
{
    local peer="PEER$1"
    local org="ORG$2"

    tmp="FABRIC_CORE_PEER_LOCALMSPID_${org}";        eval CORE_PEER_LOCALMSPID='$'$tmp
    tmp="FABRIC_CORE_PEER_TLS_ROOTCERT_FILE_${org}"; eval CORE_PEER_TLS_ROOTCERT_FILE='$'$tmp
    tmp="FABRIC_CORE_PEER_MSPCONFIGPATH_${org}";     eval CORE_PEER_MSPCONFIGPATH='$'$tmp
    tmp="FABRIC_CORE_PEER_ADDRESS_${peer}_${org}";   eval CORE_PEER_ADDRESS='$'$tmp
}

print_globals()
{
    local prefix=$1
}

# Create channel
create_channel()
{
    peer channel create -o $ORDERER -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls true --cafile $CAFILE
}

# Join a peer to the channel
join_channel()
{
    local peer="$1"; local org="$2"
    set_globals $peer $org

    log "peer channel join"
    peer channel join -b $CHANNEL_NAME.block
}

# Join all peers to the channel
join_channel_all()
{
    for org in ${ORG_NUM_LIST//,/ }; do
        for peer in ${PEER_NUM_LIST//,/ }; do
            echo $peer $org
            join_channel $peer $org
        done
    done
}

update_anchor()
{
    local peer="$1"; local org="$2"
    set_globals $peer $org

    log "peer channel update"

    peer channel update -o $ORDERER -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls true --cafile $CAFILE
}

update_anchor_all()
{
    for org in ${ORG_NUM_LIST//,/ }; do
        update_anchor 0 $org
    done
}

# Run channel command
channel()
{
    local cmd="$1"
    shift

    case $cmd in
        create)
            create_channel
            ;;
        join)
            join_channel $@
            ;;
        join-all)
            join_channel_all
            ;;
        update-anchor)
            update_anchor $@
            ;;
        update-anchor-all)
            update_anchor_all
            ;;
        *)
            help
            ;;
    esac
}

install_chaincode()
{
    local peer="$1"; local org="$2"
    set_globals $peer $org

    local path_cc="$3"
    local name_cc="$4"

    log "peer install chaincode"

    peer chaincode install -n $name_cc -v 1.0 -p $path_cc -l golang
}

install_chaincode_all()
{
    local path_cc="$1"
    local name_cc="$2"

    for org in ${ORG_NUM_LIST//,/ }; do
        for peer in ${PEER_NUM_LIST//,/ }; do
            echo $peer $org
            install_chaincode $peer $org $path_cc $name_cc
        done
    done
}

instantiate_chaincode()
{
    local name_cc="$1"
    local version_cc="$2"

    local args_cc="{\"Args\":[]}"
    local policy_cc="OR('Org000MSP.member','Org001MSP.member')"

    set_globals 0 000

    log "peer instantiate chaincode"

    peer chaincode instantiate \
        -o $ORDERER \
        --tls \
        --cafile $CAFILE \
        -n $name_cc \
        -C $CHANNEL_NAME \
        -v $version_cc \
        -c $args_cc \
        -P $policy_cc
}

chaincode()
{
    local cmd="$1"
    shift

    case $cmd in
        install)
            install_chaincode $@
            ;;
        install-all)
            install_chaincode_all $@
            ;;
        instantiate)
            instantiate_chaincode $@
            ;;
        *)
            help
            ;;
    esac
}

invoke()
{
    local name_cc=$1
    local func_cc=$2
    local args_cc=$3

    set_globals 0 000

    log "peer chaincode invoke"

    peer chaincode invoke \
        -o $ORDERER \
        --tls true \
        --cafile $CAFILE \
        -C $CHANNEL_NAME \
        -n $name_cc \
        --waitForEvent \
        --peerAddresses $FABRIC_CORE_PEER_ADDRESS_PEER0_ORG000 \
        --tlsRootCertFiles $FABRIC_CORE_PEER_TLS_ROOTCERT_FILE_ORG000 \
        -c "{\"Args\":[\"$func_cc\",$args_cc]}"
}

query()
{
    local name_cc=$1
    local func_cc=$2
    local args_cc=$3

    set_globals 0 000

    log "peer chaincode query"

    peer chaincode query \
        -C $CHANNEL_NAME \
        -n $name_cc \
        -c "{\"Args\":[\"$func_cc\",$args_cc]}"
}

app()
{
    local name_cc="$1"
    local cmd="$2"


    case $cmd in
        set)
            invoke $name_cc 'set' "\"${3}\",\"${4}\""
            ;;
        get)
            query $name_cc 'get' "\"${3}\""
            ;;
    esac
}

playing()
{
    channel create
    channel join-all
    channel update-anchor-all
    chaincode install-all fabric-playing/arithmetic-operation arithmetic
    chaincode instantiate arithmetic 1.0
}

CMD="$1"
shift

case $CMD in
    channel)
        channel $@
        ;;
    chaincode)
        chaincode $@
        ;;
    app)
        app $@
        ;;
    playing)
        playing
        ;;
    *)
        help
        ;;
esac

