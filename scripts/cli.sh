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
        if [ "$org" != "000" ]; then
            update_anchor 0 $org
        fi
    done
}

# Run channel command
channel()
{
    cmd="$1"
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

CMD="$1"
shift

case $CMD in
    channel)
        channel $@
        ;;
    help|*)
        help
        ;;
esac

