module VNMMAD

require 'erb'

class NFDHCPDDriver < VNMDriver

    DRIVER                 = "NFDHCPD"
    XPATH_FILTER           = "TEMPLATE/NIC[NFDHCPD='YES']"
    GLOBAL_CHAIN           = "opennebula"
    NFQUEUE_QUEUE_NUM      = 42
    BINDING_FILES_DATAPATH = "/var/lib/opennebula-nfdhcpd/"

    def initialize(vm_64, deploy_id = nil, hypervisor = nil, xpath_filter = nil)
        vm_xml = Base64::decode64(vm_64)

        if xpath_filter
                XPATH_FILTER.replace xpath_filter
        end

        @chains = []
        @rules = []
        @locking = true

        super(vm_xml, XPATH_FILTER, deploy_id, hypervisor)

        OpenNebula.log_info(vm_xml)
    end

    def activate
        lock

        # Get iptables chains
        @chains = get_chains

        # Bootstrap if GLOBAL_CHAIN doesn't exist
        bootstrap unless @chains.include?(GLOBAL_CHAIN)

        # Only attaching NICs and with NFDHCPD activated
        attach_nic_id = @vm['TEMPLATE/NIC[ATTACH="YES" and NFDHCPD="YES"]/NIC_ID']

        @vm.nics.each do |nic|
            next if attach_nic_id && attach_nic_id != nic[:nic_id]

            OpenNebula.log_info(nic)

            commands = VNMNetwork::Commands.new

            # Create NFDHCPD binding file
            binding_file = NFDHCPDBindingFile.new("one-#{vm['ID']}", nic[:tap], nic[:mac], nic[:ip], nic[:network_address], nic[:network_mask], nic[:gateway], nic[:dns])
            binding_file.save("#{BINDING_FILES_DATAPATH}/one-#{vm['ID']}-#{nic[:nic_id]}")

            chain = "one-#{vm['ID']}-#{nic[:nic_id]}-nfdhcpd"

            # Create NIC chain
            commands.add :iptables, "-t mangle -N #{chain}"

            # Add NFDHCPD rule to NIC chain
            commands.add :iptables, "-t mangle -A #{chain} -m physdev --physdev-in #{nic[:tap]} -p udp --dport bootps -j NFQUEUE --queue-num #{NFQUEUE_QUEUE_NUM}"

            # Add link from global chain to NIC chain
            commands.add :iptables, "-t mangle -I #{GLOBAL_CHAIN} -m physdev --physdev-in #{nic[:tap]} -j #{chain}"

            # Run commands!
            commands.run!
        end

        unlock
    end

    def deactivate
        lock

        # Get iptables chains
        @chains = get_chains
        @rules = get_rules

        # Only dettaching NICs and with NFDCHPD activated
        attach_nic_id = @vm['TEMPLATE/NIC[ATTACH="YES" and NFDHCPD="YES"]/NIC_ID']

        @vm.nics.each do |nic|
            next if attach_nic_id && attach_nic_id != nic[:nic_id]

            commands = VNMNetwork::Commands.new

            chain = "one-#{vm['ID']}-#{nic[:nic_id]}-nfdhcpd"

            # Remove link from global chain to NIC chain
            @rules.each do |rule|
                if rule.include?(chain)
                    commands.add :iptables, "-t mangle -D #{rule}"
                end
            end

            # Remove NIC chain
            if @chains.include?(chain)
                commands.add :iptables, "-t mangle -F #{chain}"
                commands.add :iptables, "-t mangle -X #{chain}"
            end

            # Remove binding file in #{BINDING_FILES_DATAPATH}/one-<vm_id>-<vnet_id>
            commands.add :rm, "-f #{BINDING_FILES_DATAPATH}/one-#{vm['ID']}-#{nic[:nic_id]}"

            # Run commands!
            commands.run!
        end

        unlock
    end

    private

    def get_rules
        res = []

        commands = VNMNetwork::Commands.new

        commands.add :iptables, "-t mangle -S #{GLOBAL_CHAIN}"
        iptables_s_mangle = commands.run!

        iptables_s_mangle.split("\n").each do |l|
            if l =~ /^-A (.*)/
                res << $1
            end
        end

        OpenNebula.log_info(res)
        res
    end

    def get_chains
              res = []

        commands = VNMNetwork::Commands.new

        commands.add :iptables, "-t mangle -S"
        iptables_s_mangle = commands.run!

              iptables_s_mangle.split("\n").each do |l|
                        if l =~ /^-N (.*)/
                                  res << $1
                        end
        end

              OpenNebula.log_info(res)
              res
    end

    def bootstrap
        commands = VNMNetwork::Commands.new

        commands.add :iptables, "-t mangle -N #{GLOBAL_CHAIN}"
        commands.add :iptables, "-t mangle -A PREROUTING -j #{GLOBAL_CHAIN}"
        commands.add :iptables, "-t mangle -A #{GLOBAL_CHAIN} -j ACCEPT"

        commands.run!
    end

end

class NFDHCPDBindingFile
    TEMPLATE = %{<% @items.each do |k,v| %><%= k %>=<%= v %>
<% end %>}

    def initialize(hostname, indev, mac, ip, network_address, network_mask, gateway, nameservers)
        @items = {
          :HOSTNAME => hostname,
          :INDEV => indev,
          :MAC => mac,
          :IP => ip,
          :SUBNET => "#{network_address}/#{network_mask}",
          :GATEWAY => gateway,
          :NAMESERVERS => nameservers,
          :MTU => "1450"
        }
    end

    def render()
        ERB.new(TEMPLATE).result(binding)
    end

    def save(file)
        File.open(file, "w+") do |f|
            f.write(render)
        end
    end

end

end

