require 'fileutils'
require 'erb'
require 'yaml'

require './utils'

# ----------------------------------------
# for container command
# ----------------------------------------
ERB_DOCKER_COMPOSE_BASE = 'template/docker-compose-base.yaml.erb'
ERB_DOCKER_COMPOSE_CLI = 'template/docker-compose-cli.yaml.erb'
ERB_CRYPTO_CONFIG = 'template/crypto-config.yaml.erb'
ERB_CONFIGTX = 'template/configtx.yaml.erb'
PATH_PEER_ORGS = '/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations'
PATH_ORDERER_ORGS = '/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations'

DOMAIN = ARGV[0]
ORG_NUM = ARGV[1].to_i
ENDORSER_NUM = ARGV[2].to_i
CHANNEL_NAME = ARGV[3]

def setup_fabric(_org_num_total)
    org_num_total = _org_num_total
    File.open(ERB_DOCKER_COMPOSE_BASE) do |f|
        parsed_text = ERB.new(f.read, nil, '%-').result(binding)
        path_yaml = 'base/docker-compose-base-1.yaml'
        File.write(path_yaml, parsed_text)
    end
    File.open(ERB_DOCKER_COMPOSE_CLI) do |f|
        parsed_text = ERB.new(f.read, nil, '%-').result(binding)
        path_yaml = './docker-compose-cli.yaml'
        File.write(path_yaml, parsed_text)
    end
    File.open(ERB_CRYPTO_CONFIG) do |f|
        parsed_text = ERB.new(f.read, nil, '%-').result(binding)
        path_yaml = './crypto-config.yaml'
        File.write(path_yaml, parsed_text)
    end
    File.open(ERB_CONFIGTX) do |f|
        parsed_text = ERB.new(f.read, nil, '%-').result(binding)
        path_yaml = './configtx.yaml'
        File.write(path_yaml, parsed_text)
    end
end

def access_container_env(_key1, _key2)
    yaml = YAML.load_file("base/docker-compose-base-1.yaml")
    tmp = yaml["services"][_key1]["environment"].select { |x| x.start_with?("#{_key2}=") }
    return tmp[0]
end

def generate(_org_num_total, _endorser_num)
    File.open('assets/orgs.info', 'w') do |f|
        f.puts("# ------------------------------")
        f.puts("# general")
        f.puts("# ------------------------------")
        org_list = "000"
        _org_num_total.times do |i|
            org_list = "#{org_list},#{"%03d" % i}" if 0 < i
        end
        f.puts("FABRIC_ORG_NUM=#{org_list}")
        f.puts("FABRIC_PEER_NUM=0,1")
        f.puts("FABRIC_ENDORSER_NUM=#{_endorser_num}")
        f.puts("FABRIC_CHANNEL_NAME=#{CHANNEL_NAME}")
        candidate_list = "001"
        2.upto (_org_num_total - 1) do |i|
            candidate_list = "#{candidate_list},#{"%03d" % i}"
        end
        f.puts("FABRIC_ENDORSER_CANDIDATE=#{candidate_list}")
        f.puts("# ------------------------------")
        f.puts("# orderer")
        f.puts("# ------------------------------")
        # CORE_PEER_LOCALMSPID
        f.puts("FABRIC_CORE_PEER_LOCALMSPID_ORDERER=OrdererMSP")
        # CORE_PEER_TLS_ROOTCERT_FILE
        f.puts("FABRIC_CORE_PEER_TLS_ROOTCERT_FILE_ORDERER=#{PATH_ORDERER_ORGS}/#{DOMAIN}/orderers/orderer.#{DOMAIN}/msp/tlscacerts/tlsca.#{DOMAIN}-cert.pem")
        # CORE_PEER_MSPCONFIGPATH
        f.puts("FABRIC_CORE_PEER_MSPCONFIGPATH_ORDERER=#{PATH_ORDERER_ORGS}/#{DOMAIN}/users/Admin@#{DOMAIN}/msp")
        # CORE_PEER_ADDRESS
        f.puts("FABRIC_CORE_PEER_ADDRESS_ORDERER=orderer.#{DOMAIN}:7050")
        _org_num_total.times do |i|
            org_num = "%03d" % i
            f.puts("# ------------------------------")
            f.puts("# org#{org_num}")
            f.puts("# ------------------------------")
            # CORE_PEER_LOCALMSPID
            key = "peer0.org#{org_num}.#{DOMAIN}"
            tmp = access_container_env(key, 'CORE_PEER_LOCALMSPID')
            f.puts("FABRIC_CORE_PEER_LOCALMSPID_ORG#{org_num}=#{tmp.split("=")[1]}")
            # CORE_PEER_ADDRESS (peer0)
            key = "peer0.org#{org_num}.#{DOMAIN}"
            tmp = access_container_env(key, 'CORE_PEER_ADDRESS')
            f.puts("FABRIC_CORE_PEER_ADDRESS_PEER0_ORG#{org_num}=#{tmp.split("=")[1]}")
            # CORE_PEER_ADDRESS (peer1)
            key = "peer1.org#{org_num}.#{DOMAIN}"
            tmp = access_container_env(key, 'CORE_PEER_ADDRESS')
            f.puts("FABRIC_CORE_PEER_ADDRESS_PEER1_ORG#{org_num}=#{tmp.split("=")[1]}")
            # CORE_PEER_TLS_ROOTCERT_FILE
            f.puts("FABRIC_CORE_PEER_TLS_ROOTCERT_FILE_ORG#{org_num}=#{PATH_PEER_ORGS}/org#{org_num}.#{DOMAIN}/peers/peer0.org#{org_num}.#{DOMAIN}/tls/ca.crt")
            # CORE_PEER_MSPCONFIGPATH
            f.puts("FABRIC_CORE_PEER_MSPCONFIGPATH_ORG#{org_num}=#{PATH_PEER_ORGS}/org#{org_num}.#{DOMAIN}/users/Admin@org#{org_num}.#{DOMAIN}/msp")
        end
    end
end

if ARGV.size() < 3 then
	puts("Usage: ruby #{File.basename(__FILE__)} <HOST> <Org Num> <Endorser Num>")
	exit
end

setup_fabric(ORG_NUM)
generate(ORG_NUM, ENDORSER_NUM)
