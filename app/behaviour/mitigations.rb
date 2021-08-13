# frozen_string_literal: true

module Mitigations
  def chain_name
    "serveme-#{id}"
  end

  def anti_dos?
    true
  end

  def enable_mitigations
    return unless anti_dos?

    server.ssh_exec(
      %(
        sudo iptables -w 1 -N #{chain_name} &&
        sudo iptables -w 1 -A #{chain_name} -p tcp -m limit --limit 100/s --limit-burst 100 -j ACCEPT &&
        sudo iptables -w 1 -A #{chain_name} -p udp -m limit --limit 300/s --limit-burst 300 -j ACCEPT &&
        sudo iptables -w 1 -A #{chain_name} -j DROP &&
        sudo iptables -w 1 -A INPUT -p udp --destination-port #{server.port} -j #{chain_name} &&
        sudo iptables -w 1 -A INPUT -p tcp --destination-port #{server.port} -j #{chain_name}
      ), verbose: true
    )
  end

  def disable_mitigations
    return unless anti_dos?

    server.ssh_exec(
      %(
        sudo iptables -w 1 -D INPUT -p udp --destination-port #{server.port} -j #{chain_name} &&
        sudo iptables -w 1 -D INPUT -p tcp --destination-port #{server.port} -j #{chain_name} &&
        sudo iptables -w 1 --flush #{chain_name} &&
        sudo iptables -w 1 -X #{chain_name}
      ), verbose: true
    )
  end

  def allow_reservation_player(rp)
    return unless anti_dos?
    return if rp.duplicates.whitelisted.any?

    server.ssh_exec(
      %(
        sudo iptables -w 1 -I #{chain_name} 1 -s #{rp.ip} -j ACCEPT -m comment --comment "#{chain_name}-#{rp.steam_uid}"
      ), verbose: true
    )
    rp.update_column(:whitelisted, true)

    Rails.logger.info "Whitelisted player #{rp.name} (#{rp.steam_uid}) with IP #{rp.ip} in the firewall for reservation #{rp.reservation_id}"
  end
end
